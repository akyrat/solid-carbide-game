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
  line to a ticket may mention them (T-143, T-161, T-181). On `git commit` it also checks every ticket
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
                 "cat-file", "for-each-ref"}
SAFE_REDIRECT_RE = re.compile(r">&\d|>>?\s*(/dev/null|\$null|nul)\b", re.I)


HEREDOC_RE = re.compile(r"<<(?P<dash>-?)[ \t]*(?P<q>['\"]?)(?P<word>[\w.-]+)(?P=q)")
CD_TASKS_RE = re.compile(r"(^|[;&|\n])\s*(cd|pushd|set-location)\s+[^;&|\n]*\btasks\b", re.I)
CD_UNKNOWN_RE = re.compile(r"(^|[;&|\n])\s*(cd|pushd|set-location)\s+[^;&|\n]*[$`]", re.I)
EXPANDS_RE = re.compile(r"`|\$\(")
TICKET_PATH_RE = re.compile(r"(^|[\\/])tasks[ .]*([\\/]|$)|(^|[\\/])T-\d+[^\\/]*\.md[ .]*$", re.I)
# what inline code or a command substitution must not name: the tasks folder, a ticket's file name or a glob
CODE_TOUCHES_RE = re.compile(r"(?<![\w-])tasks(?![\w-])|T-\d+[^\s'\"\\/]*\.md|T-\d*[*?\[]|[*?\[][^\s'\"]*\.md\b|\*\*",
                             re.I)
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
    if in_tasks or not path or re.search(r"[$`*?\[{]", path):
        return True
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
        script = seg.split(None, 1)[1] if len(words) > 1 else ""
        if re.search(r"(^|\s)-[A-Za-z]*i|--in-place|--file|(^|\s)-f\b", script):
            return False
        if re.search(r"""(^|[\s;{}0-9$/'"])[wWe]\s*[\w./\\"'-]""", script):
            return False
    return True


PYTHON_NAMES = {"python", "python3", "py", "python.exe", "python3.exe", "py.exe"}
STATUS_SCRIPTS = {"task_status.py", "taskboard_sync.py"}
GIT_WRITERS = {"add", "commit", "checkout", "switch", "restore", "reset", "merge", "rebase", "stash", "branch",
               "worktree", "push", "pull", "fetch", "tag", "cherry-pick", "revert", "mv", "rm", "clean"}
INLINE_CODE_RE = re.compile(
    r"(^|\s)(python3?|py|perl|ruby|node|powershell|pwsh)(\.exe)?\s+(-\S*\s+)*-(c|e|command|encodedcommand)\b", re.I)
TOUCHES_RE = re.compile(r"(?<![\w-])tasks(?![\w-])|(?<![\w-])T-[\d*?\[]|[*?\[][^\s]*\.md\b|\*\*", re.I)
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


def is_test_run(words):
    """`python -m unittest ...` or `python -m pytest ...`: a test run, which works on its own temporary files."""
    if len(words) < 3 or words[0].lower() not in PYTHON_NAMES:
        return False
    i = 1
    while i < len(words) and words[i].startswith("-") and words[i] != "-m":
        i += 1
    return words[i:i + 1] == ["-m"] and words[i + 1:i + 2] in (["unittest"], ["pytest"])


def sed_files(words):
    """The files a `sed` command line names (its script left out), or None when its script comes from a file."""
    files, script_given, i = [], False, 1
    while i < len(words):
        w = words[i]
        if w in ("-f", "--file") or w.startswith("--file="):
            return None
        if w in ("-e", "--expression"):
            script_given, i = True, i + 2
            continue
        if w.startswith("--expression=") or (w.startswith("-") and not w.startswith("--") and w.endswith("e")):
            script_given = True
        elif not w.startswith("-"):
            files.append(w)
        i += 1
    return files if script_given else files[1:]


def risky_segment(seg, cwd=None, in_tasks=False):
    """Whether one simple command could write a ticket's status, qa_rounds or lead line, or the hook can't tell
    (T-181). Allowed: reads, real calls of the status script, git (its commits meet commit_check), test runs,
    inline code that names no task file, file writes (cp, mv, sed -i, Set-Content, ...) that can't reach a
    ticket, and appends of plain text with no such line (a result note). Any other command is risky."""
    words = words_of(seg.text)
    for op, _target in seg.redirects:
        if op != ">>" or not appended_text_ok(seg, words):
            return True
    if not words:
        return False
    if read_only_segment(seg.text) or script_call(seg.text) or git_writer(seg.text) or is_test_run(words):
        return False
    code = inline_code(seg, words)
    if code is not None:
        return in_tasks or bool(CODE_TOUCHES_RE.search(code))
    name = words[0].lower()
    if name == "sed":
        if re.search(r"""(^|[\s;{}0-9$/'"])[wWe]\s*[\w./\\"'-]""", " ".join(words[1:])):
            return True   # the script writes a file or runs a command
        files = sed_files(words)
        return files is None or any(ticket_path(f, cwd, in_tasks) for f in files)
    if name in FILE_WRITERS:
        return any(ticket_path(re.sub(r"^-+[\w-]*[:=]", "", w), cwd, in_tasks) for w in words[1:])
    return True


def risky_segments(cmd, cwd=None):
    """The parts of a shell command that could write a ticket's guarded lines, or the whole command when the
    hook can't read it (an open quote, a backtick, a computed file name, ...)."""
    in_tasks = runs_in_tasks(cmd, cwd)
    segments, unsafe = shell_segments(cmd, cwd, in_tasks)
    if unsafe:
        return [cmd]
    return [s.text or cmd for s in segments if risky_segment(s, cwd, in_tasks)]


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
    if not GUARD_WORD_RE.search(cmd) and not INLINE_CODE_RE.search(cmd):
        return 0
    risky = risky_segments(cmd, cwd)
    if not risky:
        return 0
    text = cmd   # a risky part anywhere makes the whole command suspect when it mentions the lines
    if INLINE_CODE_RE.search(text) or re.search(r"qa[\W_]*rounds|status", text, re.I):
        return deny(f"Task statuses change only through the status script: {STATUS_SCRIPT} <T-id> <status>.")
    if re.search(r"lead", text, re.I):
        return deny(f"A task's lead changes only through the status script: {STATUS_SCRIPT} <T-id> --lead <Name>.")
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
