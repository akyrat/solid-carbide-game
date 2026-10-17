"""Claude Code hook: keeps the local task board and the Project Lead connected.

Wired in .claude/settings.json. One script for every event; it reads the hook's JSON from stdin.

- SessionStart: starts the local task board (tools/taskboard/server.py) if it isn't running,
  and tells the board and the Project Lead its address, the session's id and name, and how to
  register a name and start the watcher (tools/board_inbox.py).
- PreToolUse Edit/Write/MultiEdit: refuses changes to a task file's status, qa_rounds or lead
  line. Moves and owners go through tools/task_status.py, which checks the workflow rules.
- PreToolUse Bash/PowerShell: refuses shell commands that could rewrite those lines; commands that only
  read (grep, sed -n, head, Get-Content, ...) may mention them (T-143).
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
    "measure-object", "get-childitem", "write-output",
}
GIT_READ_ONLY = {"diff", "log", "show", "grep", "blame", "status", "merge-base", "rev-parse", "rev-list", "ls-files",
                 "cat-file", "for-each-ref"}
SAFE_REDIRECT_RE = re.compile(r">&\d|>>?\s*(/dev/null|\$null|nul)\b", re.I)


HEREDOC_RE = re.compile(r"<<(?P<dash>-?)[ \t]*(?P<q>['\"]?)(?P<word>[\w.-]+)(?P=q)")
CD_TASKS_RE = re.compile(r"(^|[;&|\n])\s*(cd|pushd|set-location)\s+[^;&|\n]*\btasks\b", re.I)
EXPANDS_RE = re.compile(r"`|\$\(")


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


def safe_target(target, cwd, in_tasks):
    """A redirection target that is plainly a file outside the tasks folder (T-161)."""
    return bool(target) and not in_tasks and not re.search(r"[$`*?\[(]", target) and not touches_tasks(target, cwd)


def shell_segments(cmd, cwd=None):
    """(segments, unsafe): the command split at unquoted | ; & and newlines, and whether it has an unquoted
    redirection into a file that could be a task file, a command substitution, a backtick or an open quote
    (anything that could write or run something). Here-document bodies are text, not commands, so they are
    left out, and so are redirections into plain files outside the tasks folder (T-161)."""
    segments, cur, quote, unsafe, i = [], [], None, False, 0
    pending = []   # here-documents whose body starts on the line after the current one
    in_tasks = bool(CD_TASKS_RE.search(cmd))
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
            elif quote == '"' and (c == "`" or cmd.startswith("$(", i)):
                unsafe = True
            cur.append(c)
        elif c in "'\"":
            quote = c
            cur.append(c)
        elif cmd.startswith("<<", i) and not cmd.startswith("<<<", i) and HEREDOC_RE.match(cmd, i):
            m = HEREDOC_RE.match(cmd, i)
            pending.append(m)
            i = m.end()
            continue
        elif c == "`" or cmd.startswith("$(", i) or cmd.startswith("<(", i):
            unsafe = True
            cur.append(c)
        elif c == ">":
            m = SAFE_REDIRECT_RE.match(cmd, i)
            if m:
                i = m.end()
                continue
            target, end = redirect_target(cmd, i)
            if safe_target(target, cwd, in_tasks):
                i = end
                continue
            unsafe = True
            cur.append(c)
        elif c == "\n" and pending:
            for m in pending:
                body = heredoc_body(cmd, i, m)
                if body is None:
                    unsafe = True
                    break
                i = body[1]
            pending = []
            segments.append("".join(cur))
            cur = []
            continue
        elif c in "|;&\n":
            segments.append("".join(cur))
            cur = []
        else:
            cur.append(c)
        i += 1
    segments.append("".join(cur))
    return [x for x in map(drop_keyword, segments) if x], unsafe or quote is not None or bool(pending)


SHELL_KEYWORDS = {"if", "then", "else", "elif", "while", "until", "do", "!"}


def drop_keyword(seg):
    """A segment without its leading shell keyword: `if git merge x` is the command `git merge x`; a lone
    fi, done or esac is no command."""
    seg = seg.strip()
    while seg.split(None, 1) and seg.split(None, 1)[0] in SHELL_KEYWORDS:
        seg = seg.split(None, 1)[1].strip() if len(seg.split(None, 1)) > 1 else ""
    return "" if seg in ("fi", "done", "esac") else seg


def read_only_segment(seg):
    words = seg.split()
    name = words[0].lower()
    if name not in READ_ONLY_COMMANDS:
        return False
    if name == "git" and (len(words) < 2 or words[1] not in GIT_READ_ONLY or "--output" in seg):
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


def read_only(cmd, cwd=None):
    """True only when every part of the shell command is known to just read. When unsure, False (refuse):
    a false refusal costs a retry, a missed write breaks the workflow rules (T-143)."""
    segments, unsafe = shell_segments(cmd, cwd)
    if unsafe or not segments:
        return False
    return all(read_only_segment(seg) for seg in segments)


PYTHON_NAMES = {"python", "python3", "py", "python.exe", "python3.exe", "py.exe"}
STATUS_SCRIPTS = {"task_status.py", "taskboard_sync.py"}
GIT_WRITERS = {"add", "commit", "checkout", "switch", "restore", "reset", "merge", "rebase", "stash", "branch",
               "worktree", "push", "pull", "fetch", "tag", "cherry-pick", "revert", "mv", "rm", "clean"}
INLINE_CODE_RE = re.compile(
    r"(^|\s)(python3?|py|perl|ruby|node|powershell|pwsh)(\.exe)?\s+(-\S*\s+)*-(c|e|command|encodedcommand)\b", re.I)
TOUCHES_RE = re.compile(r"(?<![\w-])tasks(?![\w-])|(?<![\w-])T-[\d*?\[]|[*?\[][^\s]*\.md\b|\*\*", re.I)
GUARD_WORD_RE = re.compile(r"qa[\W_]*rounds|status|\blead\b", re.I)


def script_call(seg):
    """True for `python [-u] path/task_status.py args`: a real call of the status script, not a mention of it."""
    words = [w for w in seg.split() if not re.fullmatch(r"\w+=\S*", w)]
    if len(words) < 2 or words[0].lower() not in PYTHON_NAMES:
        return False
    rest = [w for w in words[1:] if not w.startswith("-")]
    return bool(rest) and rest[0].strip("'\"").replace("\\", "/").rsplit("/", 1)[-1] in STATUS_SCRIPTS


def git_writer(seg):
    """A git subcommand that changes the repo (what it writes is committed state; commit_check covers commits)."""
    words = seg.split()
    if not words or words[0].lower() != "git":
        return False
    rest, i = words[1:], 0
    while i < len(rest) and rest[i] in ("-C", "-c"):
        i += 2
    return i < len(rest) and rest[i] in GIT_WRITERS


def touches_tasks(cmd, cwd=None):
    """Whether a shell command names task files: the tasks folder, a T-nnn path or glob, a *.md glob, or it
    runs inside the tasks folder."""
    return bool(TOUCHES_RE.search(cmd) or (cwd and re.search(r"[\\/]tasks[\\/]*$", str(cwd), re.I)))


def risky_segments(cmd, cwd=None):
    """The parts of a shell command that are neither reads, real calls of the status script, nor git writes."""
    segments, unsafe = shell_segments(cmd, cwd)
    if unsafe:
        return [cmd]   # a redirection into a file, a substitution or an open quote: judge the whole command
    return [s for s in segments if not (read_only_segment(s) or script_call(s) or git_writer(s))]


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
    if re.search(r"\blead\b", text, re.I):
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
