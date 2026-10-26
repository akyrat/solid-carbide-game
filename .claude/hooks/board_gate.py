"""Claude Code hook: keeps the local task board and the Project Lead connected.

Wired in .claude/settings.json. One script for every event; it reads the hook's JSON from stdin.

- SessionStart: starts the local task board (tools/taskboard/server.py) if it isn't running,
  and tells the board and the Project Lead its address, the session's id and name, and how to
  register a name and start the watcher (tools/board_inbox.py).
- PreToolUse Edit/Write/MultiEdit: refuses changes to a task file's status, qa_rounds or lead
  line. Moves and owners go through tools/task_status.py, which checks the workflow rules.
- PreToolUse Bash/PowerShell: refuses shell commands that could write those lines into a task file, or
  whose writes it can't read. Commands that only read (grep, sed -n, head, Get-Content, ...), run the
  status script, git or a test run, write files other than tickets, or append plain text without such a
  line to a ticket may mention them (T-143, T-161, T-181). A script run from a file (python x.py, bash x.sh)
  is judged by its own code: it passes unless that code writes or matches a guarded header line, or names
  task files and writes files; the game's test runner counts as a test run. A refusal names the part of the
  command that caused it and why (T-212). On `git commit` it also checks every ticket
  that would be committed against the status script's record (tools/guard_ledger.py, T-149): the backstop
  for any write the command check can't see.
- PreToolUse Agent: refuses to start an agent on a task unless it runs on the task's model
  (tasks/README.md, "Models").
- UserPromptSubmit, PostToolUse Agent: hands the Project Lead the board's moves on the task
  board that concern this session and that it hasn't heard yet (tools/board_inbox.py reads
  .board/board-inbox.jsonl with this session's own cursor), so it acts on them. Until the
  session has a name, the hand-over reminds it to ask the board for one.
- Stop: if the board moved something while the Project Lead was working, it gets one more turn
  to act on it before finishing.

The task board reads the task files directly, so it is never behind: an agent's move shows up
on the page within a couple of seconds, and the board's drags are real status changes.
"""

import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools" / "taskboard"))
import taskboard_sync as tb  # noqa: E402
import board_inbox as bi  # noqa: E402
import guard_ledger as gl  # noqa: E402

TASK_FILE_RE = re.compile(r"(?:^|[\\/])tasks[\\/](T-\d+)[^\\/]*\.md[ .]*$", re.I)
GUARDED = ("status", "qa_rounds", "lead")
STATUS_SCRIPT = "python tools/task_status.py"
SERVER = ROOT / "tools" / "taskboard" / "server.py"


def out(obj):
    print(json.dumps(obj))
    return 0


def deny(reason):
    return out({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                       "permissionDecision": "deny", "permissionDecisionReason": reason}})


# --- Status lines change only through task_status.py ---

def guarded_fields(text):
    fields = tb.parse_header(text) or {}
    out = {k: fields.get(k) for k in GUARDED}
    out["lead"] = out["lead"] or ""   # no lead line and an empty one mean the same: no owner
    return out


def edited_text(tool, tool_input, current):
    if tool == "Write":
        return tool_input.get("content", "")
    edits = tool_input.get("edits") if tool == "MultiEdit" else [tool_input]
    text = current.replace("\r\n", "\n")   # the Edit tool matches LF text in CRLF files too
    for e in edits or []:
        old, new = e.get("old_string", "").replace("\r\n", "\n"), e.get("new_string", "").replace("\r\n", "\n")
        text = text.replace(old, new) if e.get("replace_all") else text.replace(old, new, 1)
    return text


def resolve(path, cwd=None):
    """The absolute, symlink-free path a tool call means, whatever its spelling (relative, other case on
    Windows, trailing dots)."""
    return os.path.realpath(os.path.abspath(os.path.join(cwd or os.getcwd(), path)))


def task_path_match(path, cwd=None):
    """The match of a path that names a task file (tasks/T-nnn-*.md) under any spelling, or None."""
    for candidate in (path, os.path.abspath(os.path.join(cwd or os.getcwd(), path)), resolve(path, cwd)):
        match = TASK_FILE_RE.search(candidate)
        if match:
            return match
    return None


def keys_changed(before, after):
    """The guarded keys whose lines differ between two states (guard_ledger.state), repeated lines included."""
    def values(st, key):
        return [v for k, v in (st or ()) if k == key]
    return [k for k in GUARDED if values(before, k) != values(after, k)]


def new_task_ok(content):
    d = dict(gl.state(content) or ())
    return d.get("status") in (None, "open", "blocked") and d.get("qa_rounds") in (None, "0") and not d.get("lead")


def pre_edit(tool, tool_input, cwd=None):
    path = tool_input.get("file_path") or ""
    match = task_path_match(path, cwd)
    file = Path(resolve(path, cwd)) if path else Path("")
    current = file.read_bytes().decode("utf-8", "replace") if path and file.is_file() else None
    # a task file is also recognised by its header, whatever the path or the file's name
    task = match.group(1) if match else (gl.task_id(current) if current else None)
    if not task:
        return 0
    if current is None:
        content = tool_input.get("content", "")
        if new_task_ok(content):
            return 0
        return deny("A new task starts as open (or blocked, when it depends on unfinished tasks) with qa_rounds: 0 "
                    f"and an empty lead: line; set its lead afterwards with {STATUS_SCRIPT} <T-id> --lead <Name>.")
    after_state = gl.state(edited_text(tool, tool_input, current))
    changed = keys_changed(gl.state(current), after_state)
    if not changed:
        return 0
    after = dict(after_state or ())
    args = []
    if "status" in changed or "qa_rounds" in changed:
        args.append(after.get("status") or "<status>")
    if "lead" in changed:
        args.append(f"--lead {after.get('lead') or '<Name>'}")
    return deny(f"A task's {' and '.join(changed)} line changes only through the status script, which checks "
                f"the workflow rules. Run: {STATUS_SCRIPT} {task} {' '.join(args)} "
                f"(from a task's branch folder, use the main repo's copy: python {ROOT / 'tools' / 'task_status.py'}). "
                f"Run it with just the task id to see the allowed moves.")


READ_ONLY_COMMANDS = {
    "grep", "egrep", "fgrep", "rg", "sed", "head", "tail", "cat", "awk", "wc", "cut", "tr", "nl", "less", "more",
    "echo", "cd", "ls", "type", "findstr", "git",
    "select-string", "sls", "get-content", "gc", "select-object", "select", "where-object", "where",
    "measure-object", "get-childitem", "write-output", "test", "[", "true", "false", "printf", "pwd",
}
GIT_READ_ONLY = {"diff", "log", "show", "grep", "blame", "status", "merge-base", "rev-parse", "rev-list", "ls-files",
                 "cat-file", "for-each-ref", "check-ignore", "check-attr", "ls-tree", "describe", "show-ref",
                 "name-rev", "shortlog", "count-objects", "version", "help", "var", "cherry", "whatchanged"}
PIP_NAMES = {"pip", "pip3", "pip.exe", "pip3.exe"}
PIP_READ_ONLY = {"list", "show", "freeze", "check", "help", "--version", "-V"}


def pip_read_only(words):
    """`pip list`, `pip show x`, `pip freeze`, `python -m pip list`, ...: pip commands that only print (T-216)."""
    if words and words[0].lower() in PIP_NAMES:
        rest = words[1:]
    elif words and words[0].lower() in PYTHON_NAMES and "-m" in words and words[words.index("-m") + 1:][:1] == ["pip"]:
        rest = words[words.index("-m") + 2:]
    else:
        return False
    sub = next((w for w in rest if not w.startswith("-") or w in PIP_READ_ONLY), None)
    return sub in PIP_READ_ONLY


XARGS_VALUE_OPTIONS = {"-n", "-L", "-P", "-s", "-d", "-E", "-I", "-a", "-l"}


def xargs_command(words):
    """The command `xargs ...` runs, as a Segment whose input words are an unknown `$XARGS` argument, or None when
    it names none (T-216: `git ls-files -m | xargs git checkout --` is the git command it runs)."""
    i = 1
    while i < len(words) and words[i].startswith("-"):
        i += 2 if words[i] in XARGS_VALUE_OPTIONS else 1
    if i >= len(words):
        return None
    seg = Segment()
    seg.chars = list(quote_words(words[i:]) + " $XARGS")
    return seg


def quote_words(words):
    """Words joined back into a command line that words_of splits into the same words."""
    return " ".join(w if not re.search(r"[\s'\"]", w) else ("'" + w + "'" if "'" not in w else '"' + w + '"')
                    for w in words)


def segment_of(words, like=None):
    """A Segment running `words`, with the redirections and here-documents of `like`."""
    seg = Segment()
    seg.chars = list(quote_words(words))
    if like is not None:
        seg.redirects, seg.heredocs = like.redirects, like.heredocs
    return seg


ASSIGNMENT_RE = re.compile(r"[A-Za-z_]\w*=")
GODOT_BIN_SET_RE = re.compile(r"(?<![$\w{])GODOT_BIN\s*=")


def assignment_reason(seg, words, cwd, in_tasks, bases, godot_var_ok):
    """T-248: `tmp=...` only sets a shell variable; `X=1 cmd` is judged as `cmd`, unless a value it hands that
    command names the tasks folder or a ticket (TMPDIR=tasks mktemp)."""
    i = 0
    while i < len(words) and ASSIGNMENT_RE.match(words[i]):
        i += 1
    if i == len(words):
        return ""
    hit = next((w for w in words[:i] if TICKET_PATH_RE.search(w.split("=", 1)[1])
                or CODE_TOUCHES_RE.search(w.split("=", 1)[1])), None)
    if hit:
        return f"`{hit}` hands `{words[i]}` a path in a tasks folder"
    return why_risky(segment_of(words[i:], seg), cwd, in_tasks, bases, godot_var_ok)


# find (T-248): reads, unless it deletes (-delete), runs a command (-exec ...) or writes a file (-fprint ...)
FIND_EXEC = {"-exec", "-execdir", "-ok", "-okdir"}
FIND_WRITES = {"-fprint": 1, "-fprint0": 1, "-fls": 1, "-fprintf": 2}
FIND_EXEC_END = {";", "\\;", "+", "\\"}   # an unquoted \; leaves a lone \ (the segment splits at the ;)
FIND_WALK_LIMIT = 20000


def find_parts(words):
    """(starting points, follows links, [-exec commands], [files -fprint writes], deletes) of a find command."""
    i, follow = 1, False
    while i < len(words):
        if words[i] in ("-H", "-L", "-P"):
            follow = follow or words[i] == "-L"
            i += 1
        elif words[i] == "-D":
            i += 2
        elif re.fullmatch(r"-O\d", words[i]):
            i += 1
        else:
            break
    starts = []
    while i < len(words) and not re.match(r"[-(!)]|\\[()!]", words[i]):
        starts.append(words[i])
        i += 1
    execs, written, delete = [], [], False
    while i < len(words):
        w = words[i]
        if w in FIND_EXEC:
            j = i + 1
            while j < len(words) and words[j] not in FIND_EXEC_END:
                j += 1
            execs.append(words[i + 1:j])
            i = j + 1
            continue
        if w in FIND_WRITES:
            written.append(words[i + 1] if i + 1 < len(words) else "")
            i += 1 + FIND_WRITES[w]
            continue
        delete = delete or w == "-delete"
        follow = follow or w == "-follow"
        i += 1
    return starts or ["."], follow, execs, written, delete


def holds_tickets(start, bases, in_tasks, follow):
    """Whether a folder find starts from could hold a ticket: a tasks folder or ticket path, a name the shell
    expands, or a folder with a tasks folder anywhere under it (looked up on disk). A path that doesn't exist
    holds nothing."""
    if in_tasks or ticket_path(start):
        return True
    for base in bases:
        path = Path(windows_path(start))
        path = path if path.is_absolute() else Path(windows_path(str(base))) / path
        try:
            path = Path(os.path.realpath(path))
            if not path.exists():
                continue
            if not path.is_dir():
                if task_path_match(str(path)):
                    return True
                continue
            if path.name.lower() == "tasks":
                return True
            seen = 0
            for _, dirs, _ in os.walk(path, followlinks=follow):
                if any(d.lower() == "tasks" for d in dirs):
                    return True
                seen += len(dirs)
                if seen > FIND_WALK_LIMIT:
                    return True
        except OSError:
            return True
    return False


def find_reason(words, cwd, in_tasks, bases, godot_var_ok):
    """Why a find command could write a ticket, or "" (T-248). It only reads unless it deletes, writes a file or
    runs a command: -fprint into a file that could be a ticket, -delete under a folder that could hold tickets,
    and -exec of anything but a read on files that could be tickets are refused; the commands it runs on other
    files are judged as themselves."""
    starts, follow, execs, written, delete = find_parts(words)
    hit = next((f for f in written if ticket_path(f, cwd, in_tasks)), None)
    if hit is not None:
        return f"`find` writes `{hit or '?'}`, which could be a ticket"
    if not delete and not execs:
        return ""
    bases = bases or [cwd or os.getcwd()]
    under = [s for s in starts if holds_tickets(s, bases, in_tasks, follow)]
    if delete and under:
        return f"`find -delete` under `{under[0]}`, which could hold tickets"
    for run in execs:
        if not run:
            continue
        if under:
            if read_only_segment(quote_words(run)):
                continue
            return f"`find -exec {run[0]}` on files under `{under[0]}`, which could be tickets"
        why = why_risky(segment_of([w.replace("{}", "found-file") for w in run]), cwd, in_tasks, bases, godot_var_ok)
        if why:
            return f"find -exec runs {why}"
    return ""


# Godot (T-248): a run of the game, its movie recording and its asset import
GODOT_RE = re.compile(r"(^|/)godot(4|[_-]v?\d[\w.-]*)?(\.exe)?$", re.I)   # godot, Godot_v4.6.2-stable_win64.exe
GODOT_VARS = {"$GODOT_BIN", "${GODOT_BIN}"}
GODOT_FILE_OPTIONS = {"--write-movie", "--log-file"}
GODOT_VALUE_OPTIONS = GODOT_FILE_OPTIONS | {
    "--path", "--fixed-fps", "--quit-after", "--resolution", "--position", "--rendering-driver",
    "--rendering-method", "--audio-driver", "--display-driver", "--screen", "--time-scale", "--max-fps",
    "--frame-delay", "--language", "-l", "--gpu-index"}
GODOT_FLAGS = {
    "--headless", "--import", "--quit", "-q", "--verbose", "-v", "--quiet", "--no-header", "--debug", "-d",
    "--windowed", "-w", "--fullscreen", "-f", "--maximized", "-m", "--always-on-top", "-t", "--disable-vsync",
    "--print-fps", "--single-window", "--editor", "-e", "--disable-crash-handler", "--debug-collisions",
    "--debug-paths", "--debug-navigation", "--debug-avoidance", "--disable-render-loop"}
GODOT_SCENE_RE = re.compile(r"^res://|\.(tscn|scn)$|(^|[\\/])project\.godot$", re.I)


def is_godot(word, godot_var_ok):
    return ((bool(GODOT_RE.search(word.replace("\\", "/"))) and not SCRIPT_RE.search(word))
            or (godot_var_ok and word in GODOT_VARS))


def godot_reason(words, cwd, in_tasks):
    """Why a Godot run could write a ticket, or "" (T-248). It runs the game, records a movie or imports the
    project's assets; it is refused when it writes a movie or log into a file that could be a ticket, runs a
    project in a tasks folder, or takes an option or argument the guard doesn't know (--script, --export-...)."""
    i, path_given = 1, False
    while i < len(words):
        w = words[i]
        if w in ("--", "++") or w.startswith("#"):
            break   # the game's own arguments, or a shell comment
        opt, eq, value = w.partition("=")
        if opt in GODOT_VALUE_OPTIONS:
            if not eq:
                value = words[i + 1] if i + 1 < len(words) else ""
                i += 1
            if opt in GODOT_FILE_OPTIONS and ticket_path(value, cwd, in_tasks):
                return f"Godot's `{opt}` writes `{value or '?'}`, which could be a ticket"
            if opt == "--path":
                path_given = True
                if ticket_path(value, cwd, False) or (in_tasks and not os.path.isabs(windows_path(value))):
                    return f"Godot runs the project in `{value or '?'}`, which could be a tasks folder"
        elif w in GODOT_FLAGS or GODOT_SCENE_RE.search(w):
            pass
        else:
            return f"Godot with `{w}`, an option or argument the guard can't tell won't write a ticket"
        i += 1
    if in_tasks and not path_given:
        return "Godot runs the project in a tasks folder"
    return ""
SAFE_REDIRECT_RE = re.compile(r">&\d|>>?\s*(/dev/null|\$null|nul)\b", re.I)


HEREDOC_RE = re.compile(r"<<(?P<dash>-?)[ \t]*(?P<q>['\"]?)(?P<word>[\w.-]+)(?P=q)")
CD_TASKS_RE = re.compile(r"(^|[;&|\n])\s*(cd|pushd|set-location)\s+[^;&|\n]*\btasks\b", re.I)
CD_UNKNOWN_RE = re.compile(r"(^|[;&|\n])\s*(cd|pushd|set-location)\s+[^;&|\n]*[$`]", re.I)
EXPANDS_RE = re.compile(r"`|\$\(")
TICKET_PATH_RE = re.compile(r"(^|[\\/])tasks[ .]*([\\/]|$)|(^|[\\/])T-\d+[^\\/]*\.md[ .]*$", re.I)
# what inline code or a command substitution must not name: the tasks folder, a ticket's file name or a glob
# `**` as a recursive glob (`**/`, `/**`, `'**'`: between blanks, quotes or path separators), not as Markdown
# bold (`**Decision**`, `\n**Airtime:**`), T-248
GLOB_STARS = r"""(?<![^\s'"/\\(=])\*\*(?=[\s'"/\\)]|$)"""
CODE_TOUCHES_RE = re.compile(
    r"(?<![\w-])tasks(?![\w-])|T-\d+[^\s'\"\\/]*\.md|T-\d*[*?\[]|[*?\[][^\s'\"]*\.md\b|" + GLOB_STARS, re.I)
HEADER_LINE_RE = re.compile(r"^[ \t]*(status|qa[\W_]*rounds|lead)[ \t]*:", re.I)


def runs_in_tasks(cmd, cwd=None):
    """Whether the command runs inside a tasks folder (or a folder the hook can't name), so any file it
    writes could be a ticket."""
    return bool(CD_TASKS_RE.search(cmd) or CD_UNKNOWN_RE.search(cmd)
                or (cwd and re.search(r"[\\/]tasks[\\/]*$", str(cwd), re.I)))


def ticket_path(path, cwd=None, in_tasks=False):
    """Whether a file a command writes could be a ticket: a path in a tasks folder or the folder itself, a
    T-nnn*.md name, a name the shell expands ($, globs, braces), no name at all, or any file when the command
    runs in the tasks folder (T-181)."""
    if in_tasks or not path or re.search(r"[$`{]", path):
        return True
    if re.search(r"[*?\[]", path):
        # a glob can be a ticket unless its last part ends in a fixed extension other than .md (T-216: *.png)
        name = re.split(r"[\\/]", path)[-1]
        m = re.search(r"\.([A-Za-z0-9]+)$", name)
        if not m or m.group(1).lower() == "md" or re.search(r"[*?\[\]]", name[m.start():]):
            return True
        folder = path[:len(path) - len(name)]
        return bool(re.search(r"[*?\[]", folder) or TICKET_PATH_RE.search(folder))
    return bool(TICKET_PATH_RE.search(path) or task_path_match(path, cwd))


def words_of(text):
    """The words of a simple command, split at unquoted blanks, with the quotes taken off."""
    words, cur, quote, quoted = [], [], None, False
    for c in text:
        if quote:
            if c == quote:
                quote = None
            else:
                cur.append(c)
        elif c in "'\"":
            quote, quoted = c, True
        elif c in " \t\r\n":
            if cur or quoted:
                words.append("".join(cur))
            cur, quoted = [], False
        else:
            cur.append(c)
    if cur or quoted:
        words.append("".join(cur))
    return words


class Segment:
    """One simple command of a shell command line: its text (here-document bodies and redirections left out),
    the redirections of its output into files that could be tickets, as (">" or ">>", target), and its
    here-document bodies, as (body, delimiter was quoted)."""

    def __init__(self):
        self.chars, self.redirects, self.heredocs = [], [], []

    @property
    def text(self):
        return drop_keyword("".join(self.chars))


def heredoc_body(cmd, line_end, m):
    """(body, end) of the here-document `m` whose body starts on the line after line_end (the index of a
    newline): the text, and the index of the newline that ends its terminator line. None when it has no
    terminator or, with an unquoted delimiter, when the body runs a command (shells expand it)."""
    pos = line_end + 1
    while pos <= len(cmd):
        end = cmd.find("\n", pos)
        line = (cmd[pos:] if end < 0 else cmd[pos:end]).rstrip("\r")
        if (line.lstrip("\t") if m.group("dash") else line) == m.group("word"):
            body = cmd[line_end + 1:pos]
            if not m.group("q") and EXPANDS_RE.search(body):
                return None
            return body, (len(cmd) if end < 0 else end)
        if end < 0:
            return None
        pos = end + 1
    return None


def redirect_target(cmd, i):
    """The file name after the `>` or `>>` at i, and the index just past it."""
    j = i + 1
    if cmd.startswith(">", j):
        j += 1
    while j < len(cmd) and cmd[j] in " \t":
        j += 1
    if j < len(cmd) and cmd[j] in "'\"":
        k = cmd.find(cmd[j], j + 1)
        return (cmd[j + 1:k], k + 1) if k > 0 else ("", len(cmd))
    k = j
    while k < len(cmd) and cmd[k] not in " \t\r\n|;&<>":
        k += 1
    return cmd[j:k], k


def substitution(cmd, i, cwd, in_tasks):
    """(segments, end) of the command substitution `$( ... )` at i: the commands inside it, and the index just
    past its `)`. None when it can't be read (arithmetic, a here-document, a backtick, a case, no closing
    parenthesis) or it names task files (T-181)."""
    if cmd.startswith("$((", i):
        return None
    depth, quote, j = 1, None, i + 2
    while j < len(cmd):
        c = cmd[j]
        if quote:
            if c == quote:
                quote = None
        elif c in "'\"":
            quote = c
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                break
        j += 1
    else:
        return None
    inner = cmd[i + 2:j]
    if "<<" in inner or "`" in inner or re.search(r"\bcase\b", inner) or CODE_TOUCHES_RE.search(inner):
        return None
    segments, unsafe = shell_segments(inner, cwd, in_tasks)
    return None if unsafe else (segments, j + 1)


def shell_segments(cmd, cwd=None, in_tasks=None):
    """(segments, unsafe): the command split at unquoted | ; & and newlines into Segments, and whether it holds
    something the hook can't read: a backtick, a process substitution, a command substitution that names task
    files or can't be read, a redirection into a computed file name, a here-document without its terminator
    (or, with an unquoted delimiter, one that runs a command) or an open quote. Here-document bodies are text,
    not commands; they are kept on their segment. The commands inside a readable `$( ... )` become segments of
    their own (T-181). Redirections into files that can't be tickets are left out (T-161)."""
    if in_tasks is None:
        in_tasks = runs_in_tasks(cmd, cwd)
    segments, seg, quote, unsafe, i = [], Segment(), None, False, 0
    pending = []   # (here-document, its segment) whose body starts on the line after the current one
    while i < len(cmd) and not unsafe:
        c = cmd[i]
        if quote:
            if c == quote:
                quote = None
            elif quote == '"' and cmd.startswith("$(cat <<", i) and HEREDOC_RE.match(cmd, i + 6):
                # "$(cat <<'EOF' ... EOF)": the usual way to hand a commit message over
                m = HEREDOC_RE.match(cmd, i + 6)
                nl = cmd.find("\n", m.end())
                body = heredoc_body(cmd, nl, m) if nl > 0 and not cmd[m.end():nl].strip() else None
                if body is None:
                    unsafe = True
                else:
                    i = body[1]
                    continue
            elif quote == '"' and cmd.startswith("$(", i):
                sub = substitution(cmd, i, cwd, in_tasks)
                if sub is None:
                    unsafe = True
                else:
                    segments.extend(sub[0])
                    seg.chars.append("$SUB")   # its output is unknown text
                    i = sub[1]
                    continue
            elif quote == '"' and c == "`":
                unsafe = True
            seg.chars.append(c)
        elif c in "'\"":
            quote = c
            seg.chars.append(c)
        elif cmd.startswith("<<", i) and not cmd.startswith("<<<", i) and HEREDOC_RE.match(cmd, i):
            m = HEREDOC_RE.match(cmd, i)
            pending.append((m, seg))
            i = m.end()
            continue
        elif cmd.startswith("$(", i):
            sub = substitution(cmd, i, cwd, in_tasks)
            if sub is None:
                unsafe = True
            else:
                segments.extend(sub[0])
                seg.chars.append("$SUB")
                i = sub[1]
                continue
        elif c == "`" or cmd.startswith("<(", i):
            unsafe = True
        elif c == ">":
            m = SAFE_REDIRECT_RE.match(cmd, i)
            if m:
                i = m.end()
                continue
            target, end = redirect_target(cmd, i)
            if re.search(r"`|\$\(|<\(", cmd[i:end]):
                unsafe = True   # a file name computed by a command
                continue
            if ticket_path(target, cwd, in_tasks):
                seg.redirects.append((">>" if cmd.startswith(">>", i) else ">", target))
            i = end
            continue
        elif c == "\n" and pending:
            for m, owner in pending:
                body = heredoc_body(cmd, i, m)
                if body is None:
                    unsafe = True
                    break
                owner.heredocs.append((body[0], bool(m.group("q"))))
                i = body[1]
            pending = []
            segments.append(seg)
            seg = Segment()
            continue
        elif c in "|;&\n":
            segments.append(seg)
            seg = Segment()
        else:
            seg.chars.append(c)
        i += 1
    segments.append(seg)
    return [s for s in segments if s.text or s.redirects], unsafe or quote is not None or bool(pending)


SHELL_KEYWORDS = {"if", "then", "else", "elif", "while", "until", "do", "!"}


def drop_keyword(seg):
    """A segment without its leading shell keyword: `if git merge x` is the command `git merge x`; a lone
    fi, done or esac is no command, and neither is the head of a loop, `for t in T-1 T-2` (T-181)."""
    seg = seg.strip()
    while seg.split(None, 1) and seg.split(None, 1)[0] in SHELL_KEYWORDS:
        seg = seg.split(None, 1)[1].strip() if len(seg.split(None, 1)) > 1 else ""
    if re.fullmatch(r"for\s+\w+(\s+in\b.*)?", seg, re.S):
        return ""
    return "" if seg in ("fi", "done", "esac") else seg


def git_subcommand(words):
    """The subcommand of a git command line, past its global options (-C <path>, -c <name=value>, --no-pager)."""
    i = 1
    while i < len(words) and words[i].startswith("-"):
        i += 2 if words[i] in ("-C", "-c", "--git-dir", "--work-tree", "--namespace") else 1
    return words[i] if i < len(words) else None


def read_only_segment(seg):
    words = seg.split()
    if not words:
        return False
    name = words[0].lower()
    if name not in READ_ONLY_COMMANDS:
        return False
    if name == "git" and (git_subcommand(words_of(seg)) not in GIT_READ_ONLY or "--output" in seg):
        return False
    if name == "rg" and "--pre" in seg:
        return False
    if name == "awk" and re.search(r"system|[|>]|-i\b|inplace", seg):
        return False
    if name == "sed":
        parsed = sed_parse(words_of(seg))
        return parsed is not None and not parsed[0] and not any(SED_WRITES_RE.search(s) for s in parsed[1])
    return True


# a sed command that writes a file (w, W, the s///w flag) or runs one (e, the s///e flag)
SED_WRITES_RE = re.compile(r"""(^|[\s;{}0-9$/'"!])[wWe](\s|$|[\w./\\"'-])""")


def sed_parse(words):
    """(in_place, scripts, files) of a sed command line, judged from its words (T-216: only the scripts are looked
    at for w and e commands, not the file names). None when a script comes from a file (-f)."""
    in_place, scripts, files, i = False, [], [], 1
    while i < len(words):
        w = words[i]
        if w == "--":
            files.extend(words[i + 1:])
            break
        if w.startswith("--"):
            if w.startswith("--in-place"):
                in_place = True
            elif w.startswith("--file"):
                return None
            elif w == "--expression":
                scripts.append(words[i + 1] if i + 1 < len(words) else "")
                i += 1
            elif w.startswith("--expression="):
                scripts.append(w.split("=", 1)[1])
        elif w.startswith("-") and len(w) > 1:
            for k, c in enumerate(w[1:], 1):
                if c == "i":
                    in_place = True
                    break   # the rest is the backup suffix
                if c == "f":
                    return None
                if c == "e":
                    rest = w[k + 1:]
                    if not rest:
                        scripts.append(words[i + 1] if i + 1 < len(words) else "")
                        i += 1
                    else:
                        scripts.append(rest)
                    break
                if c == "l":
                    if not w[k + 1:]:
                        i += 1   # the line length
                    break
        else:
            files.append(w)
        i += 1
    if not scripts:
        scripts, files = files[:1], files[1:]
    return in_place, scripts, files


SED_GUARD_FRAGMENT_RE = re.compile(r"stat|round|lead|qa", re.I)


def _sed_delimited(text, i, delim):
    """The text from i up to the next unescaped delim, and the index after it; None when there is none."""
    out = []
    while i < len(text):
        c = text[i]
        if c == "\\" and i + 1 < len(text):
            out.append(text[i:i + 2])
            i += 2
            continue
        if c == delim:
            return "".join(out), i + 1
        out.append(c)
        i += 1
    return None


def sed_body_script_ok(script):
    """T-297: True when a sed script is fully read and cannot write a `status`, `qa_rounds` or `lead` line of a
    ticket: only s commands (and d, a, i, c with literal text) whose pattern, replacement, text and address don't
    name those words (or hold a colon in a pattern or address), whose numeric address is not in the first lines,
    and with no w or e flag. Anything it can't parse is refused."""
    if SED_GUARD_FRAGMENT_RE.search(script):
        return False
    i, n = 0, len(script)
    while True:
        while i < n and script[i] in " \t\n;":
            i += 1
        if i >= n:
            return True
        address = False
        for _ in range(2):   # one address, or a range
            if i < n and script[i].isdigit():
                j = i
                while j < n and script[j].isdigit():
                    j += 1
                if int(script[i:j]) < 2:
                    return False
                i, address = j, "num"
            elif i < n and script[i] == "/":
                got = _sed_delimited(script, i + 1, "/")
                if got is None or ":" in got[0]:
                    return False
                i, address = got[1], address or "re"
            elif i < n and script[i] == "$":
                i, address = i + 1, address or "num"
            else:
                break
            if i < n and script[i] == "," and _ == 0:
                i += 1
            else:
                break
        while i < n and script[i] in " !":
            i += 1
        if i >= n:
            return False
        cmd = script[i]
        i += 1
        if cmd == "s":
            if i >= n or script[i].isalnum() or script[i] in "\\\n":
                return False
            delim = script[i]
            pat = _sed_delimited(script, i + 1, delim)
            if pat is None or ":" in pat[0]:
                return False
            rep = _sed_delimited(script, pat[1], delim)
            if rep is None:
                return False
            i = rep[1]
            j = i
            while j < n and script[j] not in " ;\n}":
                if script[j] not in "gpiIM0123456789":
                    return False   # w, e or anything else
                j += 1
            i = j
        elif cmd == "d":
            if address != "re":
                return False
        elif cmd in "aic":
            if address != "re":
                return False
            return True   # the rest of the script is the literal text (already free of the guarded words)
        else:
            return False


PYTHON_NAMES = {"python", "python3", "py", "python.exe", "python3.exe", "py.exe"}
STATUS_SCRIPTS = {"task_status.py", "taskboard_sync.py"}
GIT_WRITERS = {"add", "commit", "checkout", "switch", "restore", "reset", "merge", "rebase", "stash", "branch",
               "worktree", "push", "pull", "fetch", "tag", "cherry-pick", "revert", "mv", "rm", "clean"}
INLINE_CODE_RE = re.compile(
    r"(^|\s)(python3?|py|perl|ruby|node|powershell|pwsh)(\.exe)?\s+(-\S*\s+)*-(c|e|command|encodedcommand)\b", re.I)
TOUCHES_RE = re.compile(r"(?<![\w-])tasks(?![\w-])|(?<![\w-])T-[\d*?\[]|[*?\[][^\s]*\.md\b|" + GLOB_STARS, re.I)
# the bare words: `printf 'x\nlead: A'` holds "lead" right after the "n" of an escape (T-181)
GUARD_WORD_RE = re.compile(r"qa[\W_]*rounds|status|lead", re.I)


def script_call(seg):
    """True for `python [-u] path/task_status.py args`: a real call of the status script, not a mention of it."""
    words = [w for w in seg.split() if not re.fullmatch(r"\w+=\S*", w)]
    if len(words) < 2 or words[0].lower() not in PYTHON_NAMES:
        return False
    rest = [w for w in words[1:] if not w.startswith("-")]
    return bool(rest) and rest[0].strip("'\"").replace("\\", "/").rsplit("/", 1)[-1] in STATUS_SCRIPTS


def git_writer(seg):
    """A git subcommand that changes the repo (what it writes is committed state; commit_check covers commits)."""
    words = words_of(seg)
    return bool(words) and words[0].lower() == "git" and git_subcommand(words) in GIT_WRITERS


def touches_tasks(cmd, cwd=None):
    """Whether a shell command names task files: the tasks folder, a T-nnn path or glob, a *.md glob, or it
    runs inside the tasks folder."""
    return bool(TOUCHES_RE.search(cmd) or (cwd and re.search(r"[\\/]tasks[\\/]*$", str(cwd), re.I)))


TEXT_WRITERS = {"echo", "printf", "write-output"}
FILE_WRITERS = {"cp", "mv", "rm", "touch", "mkdir", "rmdir", "ln", "tee", "install", "truncate", "dd",
                "copy-item", "copy", "cpi", "move-item", "move", "mi", "remove-item", "ri", "del", "erase",
                "new-item", "ni", "rename-item", "rni", "ren", "set-content", "sc", "add-content", "ac",
                "out-file", "clear-content", "clc"}
INTERPRETERS = PYTHON_NAMES | {"perl", "ruby", "node", "bash", "sh", "powershell", "pwsh"}


def appended_text_ok(seg, words):
    """Whether what a segment appends to a ticket is literal text without a status, qa_rounds or lead field at
    a line start: echo, printf or Write-Output of plain words, or cat of a here-document. Every word, and
    every line after a newline or a \\n, counts as a line start; text the shell or printf could compute ($,
    backticks, numeric escapes) can't be read (T-181)."""
    if not words:
        return False
    name = words[0].lower()
    if name in TEXT_WRITERS and not seg.heredocs:
        pieces = words[1:]
    elif name == "cat" and seg.heredocs and all(w == "-" for w in words[1:]):
        if any(not quoted and "$" in body for body, quoted in seg.heredocs):
            return False
        pieces = [body for body, _ in seg.heredocs]
    else:
        return False
    for piece in pieces:
        if name != "cat" and re.search(r"[$`]|\\[0-7xuUc]", piece):
            return False
        if any(HEADER_LINE_RE.match(line) for line in re.split(r"\\[nrfv]|\r|\n", piece)):
            return False
    return True


def inline_code(seg, words):
    """The code a segment runs inline (python -c, perl -e, powershell -Command, or a here-document fed to an
    interpreter), with the rest of its command line, or None."""
    if INLINE_CODE_RE.search(seg.text):
        return seg.text
    if words and words[0].lower() in INTERPRETERS and seg.heredocs and all(w.startswith("-") for w in words[1:]):
        return "\n".join([seg.text] + [body for body, _ in seg.heredocs])
    return None


TEST_RUNNERS = {"game/tools/run_tests.sh", "game/tools/run_tests.ps1"}


def is_test_run(words):
    """`python -m unittest ...`, `python -m pytest ...` or the game's own test runner (bash
    game/tools/run_tests.sh, run_tests.ps1, T-212): a test run, which works on its own temporary files."""
    if words and words[0].lower() in {"bash", "sh", "powershell", "pwsh", "powershell.exe", "pwsh.exe"}:
        if any(re.fullmatch(r"-(c|e|command|encodedcommand)", w, re.I) for w in words[1:]):
            return False
        script = next((w.replace("\\", "/") for w in words[1:] if re.search(r"\.(sh|ps1)$", w, re.I)), "")
        return any(script == r or script.endswith("/" + r) for r in TEST_RUNNERS)
    if len(words) < 3 or words[0].lower() not in PYTHON_NAMES:
        return False
    i = 1
    while i < len(words) and words[i].startswith("-") and words[i] != "-m":
        i += 1
    return words[i:i + 1] == ["-m"] and words[i + 1:i + 2] in (["unittest"], ["pytest"])


# What a script's own text must not hold for the guard to let it run on task files (T-212): a status, qa_rounds or
# lead header line it writes or looks for (`"status: done"`, `^lead:`), or the field names as quoted keys next to
# the tasks folder; and the tasks folder or a ticket's file name together with a file write.
SOURCE_HEADER_RE = re.compile(
    r"""(['"^]|\\n|\(\?m\))[ \t]*(status|qa[\W_]*rounds|lead)[ \t]*:|['"](status|qa_rounds|lead)['"]\s*,""", re.I)
# a path to the tasks folder or a ticket file, in code (a mention in a comment or a sentence is not one)
SOURCE_TASKS_RE = re.compile(r"""['"/\\]tasks['"/\\]|T-\d*[*?]|T-\d+[^\s'"]*\.md|TASKS_DIR""")
SOURCE_WRITES_RE = re.compile(
    r"write_text|write_bytes|\.write\(|open\([^)\n]*['\"][^'\"\n]*[wax+]|shutil\.|os\.(replace|rename|remove)|"
    r"\.(replace|rename|unlink)\(|Set-Content|Add-Content|Out-File|Copy-Item|Move-Item|sed\s+-i|(^|\s)(cp|mv|tee)\s|"
    r"[^>&\d]>>?\s*[\"'$\w/.]", re.I)
SCRIPT_RE = re.compile(r"\.(py|sh|ps1)$", re.I)
SCRIPT_RUN_RE = re.compile(r"\.(py|sh|ps1)\b", re.I)
SCRIPT_WRITES_LINES = "so it could write a status, qa_rounds or lead line"
SCRIPT_MAX_BYTES = 2_000_000


def windows_path(p):
    """A Git Bash path (/c/x) as Windows reads it (C:/x); other paths unchanged."""
    m = re.match(r"^/([a-zA-Z])(/|$)", p)
    return f"{m.group(1).upper()}:/{p[3:]}" if m and os.name == "nt" else p


def script_of(words):
    """The script file a segment runs (`python [-u] x.py args`, `bash x.sh`, `powershell -File x.ps1`), or None:
    no script file (inline code, a module, an interpreter alone) or not an interpreter."""
    if not words or words[0].lower() not in INTERPRETERS | {"powershell.exe", "pwsh.exe"}:
        return None
    for w in words[1:]:
        if re.fullmatch(r"-(c|e|m|command|encodedcommand)", w, re.I):
            return None
        if w.startswith("-"):
            continue
        return w if SCRIPT_RE.search(w) else None
    return None


def script_reason(script, bases):
    """Why the script a command runs could write a ticket's guarded lines, judged by its own text (T-212): ""
    when every copy found under the command's folders holds neither a guarded header line nor the tasks folder
    together with a file write. A script that can't be found or read is refused."""
    found = []
    for base in bases:
        path = Path(windows_path(script))
        path = path if path.is_absolute() else Path(windows_path(str(base))) / path
        try:
            if path.is_file() and path.stat().st_size <= SCRIPT_MAX_BYTES:
                found.append((path, path.read_bytes().decode("utf-8", "replace")))
        except OSError:
            continue
    if not found:
        return f"`{script}`: the guard can't find or read that script, so it can't tell what it writes"
    for path, src in found:
        m = SOURCE_HEADER_RE.search(src)
        if m:
            return f"`{script}`: its code holds `{m.group(0).strip()}`, {SCRIPT_WRITES_LINES}"
        if SOURCE_TASKS_RE.search(src) and SOURCE_WRITES_RE.search(src):
            return f"`{script}`: its code names task files and writes files"
    return ""


ARG_FIELD_RE = re.compile(r"(?<![\w-])(status|qa_rounds|lead)(?![\w-])", re.I)


def script_args_reason(script, words):
    """Why the arguments of a script run could make it write a ticket's guarded lines (T-213): they name a task
    file or the tasks folder and also hold a status, qa_rounds or lead line or field name, whatever the script's
    own code looks like (a generic writer script takes both as arguments). "" otherwise."""
    args = words[words.index(script) + 1:] if script in words else []
    for i, a in enumerate(args):
        if a.startswith("#"):
            args = args[:i]   # a shell comment
            break
    names = next((a for a in args if CODE_TOUCHES_RE.search(a) or TICKET_PATH_RE.search(a)), None)
    field = next((m.group(0) for a in args for m in [ARG_FIELD_RE.search(a)] if m), None)
    if names and field:
        return (f"`{script}`: its arguments name a task file (`{names}`) and hold a `{field}` line or field name, "
                f"{SCRIPT_WRITES_LINES}")
    return ""


def cd_bases(cmd, cwd=None):
    """The folders a command's relative paths could be read from: the working folder and every folder it cds into."""
    base = cwd or os.getcwd()
    bases = [base]
    for m in re.finditer(r"(?:\bcd|\bpushd|Set-Location)\s+(\"[^\"]+\"|'[^']+'|[^\s;&|]+)", cmd, re.I):
        bases.append(os.path.join(base, windows_path(m.group(1).strip("'\""))))
    return bases


def why_risky(seg, cwd=None, in_tasks=False, bases=None, godot_var_ok=True):
    """Why one simple command could write a ticket's status, qa_rounds or lead line, or why the hook can't tell
    (T-181, T-212); "" when it can't. Allowed: reads, real calls of the status script, git (its commits meet
    commit_check), test runs, inline code that names no task file, scripts whose own code can't write those lines
    (script_reason), file writes (cp, mv, sed -i, Set-Content, ...) that can't reach a ticket, and appends of
    plain text with no such line (a result note); since T-248 also shell variable assignments, find, mktemp and
    Godot runs that can't reach a ticket. Any other command is risky. `godot_var_ok`: $GODOT_BIN is Godot (the
    command doesn't set it itself)."""
    words = words_of(seg.text)
    for op, target in seg.redirects:
        if op != ">>":
            return f"`>` into `{target or '?'}`, which could be a ticket"
        if not appended_text_ok(seg, words):
            return f"what it appends to `{target or '?'}` could hold a status, qa_rounds or lead line"
    if not words:
        return ""
    if ASSIGNMENT_RE.match(words[0]):
        return assignment_reason(seg, words, cwd, in_tasks, bases, godot_var_ok)
    if (read_only_segment(seg.text) or script_call(seg.text) or git_writer(seg.text) or is_test_run(words)
            or pip_read_only(words)):
        return ""
    if words[0].lower() == "xargs":
        inner = xargs_command(words)
        if inner is None:
            return ""   # xargs alone only echoes its input
        why = why_risky(inner, cwd, in_tasks, bases, godot_var_ok)
        return f"xargs runs {why}" if why else ""
    if words[0].lower() in ("find", "find.exe"):
        return find_reason(words, cwd, in_tasks, bases, godot_var_ok)
    if is_godot(words[0], godot_var_ok):
        return godot_reason(words, cwd, in_tasks)
    if words[0].lower() == "mktemp":
        args, i = [], 1
        while i < len(words):
            w = re.sub(r"^--(tmpdir|suffix)=", "", words[i])
            if w in ("-p", "--suffix"):
                args.append(words[i + 1] if i + 1 < len(words) else "")
                i += 1
            elif not w.startswith("-"):
                args.append(w)
            i += 1
        hit = next((a for a in args if ticket_path(a, cwd, in_tasks)), None)
        return f"`mktemp` makes `{hit or '?'}`, which could be a ticket" if hit is not None else ""
    code = inline_code(seg, words)
    if code is not None:
        if in_tasks:
            return "inline code run inside a tasks folder"
        m = CODE_TOUCHES_RE.search(code)
        return f"inline code that names task files (`{m.group(0)}`)" if m else ""
    name = words[0].lower()
    if name == "sed":
        parsed = sed_parse(words)
        if parsed is None:
            return "a sed script read from a file"
        # T-297: a script read in full that can't write a status, qa_rounds or lead line (it also has no w or e)
        body_ok = bool(parsed[1]) and all(sed_body_script_ok(s) for s in parsed[1])
        if not body_ok and any(SED_WRITES_RE.search(s) for s in parsed[1]):
            return "a sed script that writes a file or runs a command"
        hit = next((f for f in parsed[2] if ticket_path(f, cwd, in_tasks)), None)
        if hit and body_ok:
            return ""
        return f"sed on `{hit}`, which could be a ticket" if hit else ""
    if name in FILE_WRITERS:
        hit = next((w for w in words[1:] if ticket_path(re.sub(r"^-+[\w-]*[:=]", "", w), cwd, in_tasks)), None)
        return f"`{name}` on `{hit}`, which could be a ticket" if hit else ""
    script = words[1] if name in ("source", ".") and len(words) > 1 else script_of(words)
    if script and not in_tasks:
        return script_args_reason(script, words) or script_reason(script, bases or [cwd or os.getcwd()])
    return f"`{words[0]}`: a command the guard can't tell won't write a ticket"


def risky_segment(seg, cwd=None, in_tasks=False, bases=None):
    return bool(why_risky(seg, cwd, in_tasks, bases))


def with_literal_vars(cmd, segments, cwd, in_tasks):
    """The segments, with `$name` and `${name}` replaced by the value after the segment that sets it, for each
    variable the command sets exactly once, to a literal value, in a segment of its own (`tmp=art-archive/T-243/x;
    mkdir -p $tmp`), and names nowhere else but in such uses (no `for name`, `read name`, ...) (T-248)."""
    sets = {}
    for i, s in enumerate(segments):
        words = words_of(s.text)
        if words and not s.redirects and all(ASSIGNMENT_RE.match(w) for w in words):
            for w in words:
                name, value = w.split("=", 1)
                sets.setdefault(name, []).append((i, value))
    known = {}
    for name, found in sets.items():
        if (len(found) == 1 and not re.search(r"[$`*?\[{~]", found[0][1])
                and len(re.findall(rf"(?<![$\w{{]){name}(?!\w)", cmd)) == 1):
            known[name] = found[0]
    if not known:
        return segments

    def put(text, i):
        for name, (at, value) in known.items():
            if i > at:
                text = re.sub(rf"\$(\{{{name}\}}|{name}(?!\w))", lambda _: value, text)
        return text

    out = []
    for i, s in enumerate(segments):
        new = Segment()
        new.chars = list(put("".join(s.chars), i))
        new.heredocs = s.heredocs
        new.redirects = [(op, t2) for op, t in s.redirects for t2 in [put(t, i)] if ticket_path(t2, cwd, in_tasks)]
        out.append(new)
    return out


def risky_parts(cmd, cwd=None):
    """[(part, why)]: the parts of a shell command that could write a ticket's guarded lines, with the reason, or
    the whole command when the hook can't read it (an open quote, a backtick, a computed file name, ...)."""
    in_tasks = runs_in_tasks(cmd, cwd)
    segments, unsafe = shell_segments(cmd, cwd, in_tasks)
    if unsafe:
        return [(cmd, "the guard can't read the command (a backtick, an open quote, a computed file name, a "
                      "command substitution that names task files, or a here-document without its end)")]
    bases = cd_bases(cmd, cwd)
    godot_var_ok = not GODOT_BIN_SET_RE.search(cmd)
    segments = with_literal_vars(cmd, segments, cwd, in_tasks)
    out = []
    for s in segments:
        why = why_risky(s, cwd, in_tasks, bases, godot_var_ok)
        if why:
            out.append((s.text or cmd, why))
    return out


def risky_segments(cmd, cwd=None):
    return [part for part, _ in risky_parts(cmd, cwd)]


def commit_check(cmd, cwd=None):
    """On `git commit`: refuses when a task file that would be committed has status, qa_rounds or lead lines the
    status script did not write (guard_ledger.py). Covers every way of editing the file."""
    if not re.search(r"\bgit\b[^;&|\n]*\bcommit\b", cmd):
        return 0
    ledger = gl.read()
    if ledger is None:
        return 0
    bases = {cwd or os.getcwd()}
    for m in re.finditer(r"(?:\bcd|\bgit\s+-C|Set-Location)\s+(\"[^\"]+\"|'[^']+'|[^\s;&|]+)", cmd):
        bases.add(os.path.join(cwd or os.getcwd(), m.group(1).strip("'\"")))
    for base in bases:
        top = gl.git(base, "rev-parse", "--show-toplevel")
        if not top:
            continue
        top = Path(top.strip())
        names = set()
        for args in (("diff", "--name-only", "HEAD", "--", "tasks"), ("diff", "--cached", "--name-only", "--", "tasks"),
                     ("ls-files", "--others", "--exclude-standard", "--", "tasks")):
            names.update((gl.git(top, *args) or "").split("\n"))
        for name in sorted(n for n in names if re.fullmatch(r"tasks/T-\d+[^/]*\.md", n)):
            working = (top / name).read_bytes().decode("utf-8", "replace") if (top / name).is_file() else None
            committed = gl.git(top, "show", f"HEAD:{name}")
            for text in (working, gl.git(top, "show", f":{name}")):
                tid = gl.task_id(text) if text else None
                if tid and not gl.ok(tid, text, committed, ledger):
                    return deny(f"{name}: its status, qa_rounds or lead line is not what the status script wrote, so "
                                "it can't be committed. Undo the hand edit (git checkout HEAD -- <file>, or "
                                f"restore the line), then change it with {STATUS_SCRIPT} <T-id> <status>.")
    return 0


def pre_shell(tool_input, cwd=None):
    cmd = tool_input.get("command") or ""
    refused = commit_check(cmd, cwd)
    if refused:
        return refused
    if not touches_tasks(cmd, cwd):
        return 0
    mentions = bool(GUARD_WORD_RE.search(cmd) or INLINE_CODE_RE.search(cmd))
    if not mentions and not SCRIPT_RUN_RE.search(cmd):
        return 0
    risky = risky_parts(cmd, cwd)
    if not mentions:
        # T-212: the command doesn't name the lines, but a script it runs on a ticket's file has code that writes them
        risky = [(p, w) for p, w in risky if w.endswith(SCRIPT_WRITES_LINES)
                 and any(TICKET_PATH_RE.search(a) for a in words_of(p)[1:])]
        if risky:
            return deny(f"Task statuses and leads change only through the status script: {STATUS_SCRIPT} <T-id> "
                        f"<status>. Refused because of `{risky[0][0][:160]}`: {risky[0][1]}.")
    if not risky:
        return 0
    text = cmd   # a risky part anywhere makes the whole command suspect when it mentions the lines
    part, why = risky[0]
    short = part if len(part) <= 160 else part[:157] + "..."
    because = (f" Refused because of `{short}`: {why}. Commands that only read, run tests or the status script "
               "pass; run that part on its own, or change the ticket through the status script.")
    if INLINE_CODE_RE.search(text) or re.search(r"qa[\W_]*rounds|status", text, re.I):
        return deny(f"Task statuses change only through the status script: {STATUS_SCRIPT} <T-id> <status>.{because}")
    if re.search(r"lead", text, re.I):
        return deny(f"A task's lead changes only through the status script: {STATUS_SCRIPT} <T-id> --lead <Name>."
                    f"{because}")
    return 0


# --- An agent runs on its task's model (tasks/README.md, "Models") ---

TASK_ID_RE = re.compile(r"\bT-\d+\b")
QA_AGENT = "qa-integration"


def task_file(tid):
    files = sorted(tb.TASKS_DIR.glob(f"{tid}-*.md"))
    return files[0] if files else None


def model_needed(agent, text):
    """The model an agent must run on for a task, from the task file's text."""
    if agent == QA_AGENT:
        return "sonnet"  # QA always runs on sonnet (board, 2026-10-15: cut QA's token use)
    return (tb.parse_header(text) or {}).get("model")


def pre_agent(tool_input):
    agent = tool_input.get("subagent_type") or ""
    if agent == "fork":
        return 0
    match = TASK_ID_RE.search(tool_input.get("prompt") or "")
    file = task_file(match.group(0)) if match else None
    if file is None:
        return 0
    needed = model_needed(agent, file.read_bytes().decode("utf-8"))
    if not needed or tool_input.get("model") == needed:
        return 0
    why = ("QA always runs on sonnet"
           if agent == QA_AGENT else f"{file.name} says model: {needed}")
    given = tool_input.get("model") or "none (it would run on the Project Lead's model)"
    return deny(f"This agent works on {match.group(0)} and must run on {needed} ({why}); the call passes "
                f"model: {given}. Relaunch it with model: \"{needed}\", or change the task file's model "
                f"line first if the task now needs another model (tasks/README.md, \"Models\").")


# --- The local task board ---

def board_url():
    import server
    return f"http://localhost:{server.port()}"


def ensure_server():
    """(url, note) with the board running; starts it in the background when needed."""
    import server
    running = server.health()
    if running and Path(running["root"]) == ROOT:
        return board_url(), "already running"
    if running:
        return None, (f"port {server.port()} is taken by a board for {running['root']}; "
                      "set BOARD_PORT to run this repo's board on another port")
    tb.STATE_DIR.mkdir(exist_ok=True)
    log = (tb.STATE_DIR / "server.out").open("a", encoding="utf-8")
    flags = 0
    if os.name == "nt":
        flags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_NO_WINDOW
    subprocess.Popen([sys.executable, str(SERVER)], cwd=str(ROOT), stdin=subprocess.DEVNULL, stdout=log,
                     stderr=subprocess.STDOUT, creationflags=flags, close_fds=True,
                     start_new_session=(os.name != "nt"))
    for _ in range(30):
        time.sleep(0.2)
        if server.health():
            return board_url(), "started"
    return None, f"it didn't start; see {tb.STATE_DIR / 'server.out'}"


def session_id(data):
    """The hook's session id; a fixed stand-in if Claude Code ever leaves it out or sends an odd one."""
    sid = data.get("session_id") or ""
    return sid if bi.SESSION_ID_RE.fullmatch(sid) else "unknown-session"


def handover_text(data, always_remind=False):
    """The message for the moves that concern this session, or "" when there is nothing to say.
    Every move is read once per session (tools/board_inbox.py)."""
    sid = session_id(data)
    name, moves = bi.take(sid)
    parts = []
    if moves:
        parts.append(describe_moves([m for m, _ in moves]))
        unowned = [m["id"] for m, claim in moves if claim]
        if unowned:
            parts.append(bi.claim_note(list(dict.fromkeys(unowned)), name))
    if not name and (moves or always_remind):
        parts.append(bi.name_reminder(sid))
    return " ".join(parts)


def describe_moves(moves):
    parts = []
    for m in moves:
        part = f"{m['id']} {m['from']} → {m['to']}"
        if m.get("note"):
            part += f" (note: {m['note']})"
        parts.append(part)
    return ("The board moved these tasks on the task board (the task files are already changed): "
            + "; ".join(parts) + ". Act on them: for a task moved to planning, read the ticket and bring its open "
            "questions to the board; start the agent for a task moved to in-progress, run QA for one "
            "moved to in-qa, merge one the board marked done after a playtest, and tell the board what you did.")


def session_start(data):
    url, note = ensure_server()
    if url:
        msg = f"Task board: {url}"
        context = (f"The local task board is running at {url} ({note}). It reads the task files directly, so "
                   "it is always up to date. The board moves tasks by dragging cards; those moves reach you "
                   "through hooks.")
    else:
        msg = f"The task board isn't running: {note}."
        context = msg + " Tell the board."
    sid = session_id(data)
    name = bi.name_of(sid)
    context += (f" This session's id is {sid}. "
                + (f"Its name is {name} (rename it with: {bi.NAME_CMD} {sid} <Name>). " if name else "")
                + f"Start the watcher for the board's drags: python tools/board_inbox.py watch {sid}")
    text = handover_text(data, always_remind=True)
    if text:
        context += " " + text
    return out({"systemMessage": msg,
                "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": context}})


def hand_over(event, data=None):
    text = handover_text(data or {}, always_remind=(event == "UserPromptSubmit"))
    if not text:
        return 0
    return out({"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}})


def stop(data):
    if data.get("stop_hook_active"):
        return 0
    text = handover_text(data)
    if not text:
        return 0
    return out({"decision": "block", "reason": text})


def main():
    data = json.load(sys.stdin)
    if (tb.STATE_DIR / "debug").exists():
        tb.STATE_DIR.mkdir(exist_ok=True)
        with (tb.STATE_DIR / "hook-debug.jsonl").open("a", encoding="utf-8") as f:
            f.write(json.dumps(data, ensure_ascii=False)[:20000] + "\n")
    event, tool = data.get("hook_event_name"), data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}
    if event == "SessionStart":
        return session_start(data)
    if event == "PreToolUse":
        if tool in ("Edit", "Write", "MultiEdit"):
            return pre_edit(tool, tool_input, data.get("cwd"))
        if tool in ("Bash", "PowerShell"):
            return pre_shell(tool_input, data.get("cwd"))
        if tool == "Agent":
            return pre_agent(tool_input)
    if event == "UserPromptSubmit":
        return hand_over("UserPromptSubmit", data)
    if event == "PostToolUse" and tool == "Agent":
        return hand_over("PostToolUse", data)
    if event == "Stop":
        return stop(data)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:  # a broken hook must never block work silently
        print(json.dumps({"systemMessage": f"board_gate hook error: {e}"}))
        sys.exit(0)
