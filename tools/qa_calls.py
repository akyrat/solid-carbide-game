"""Where a QA run spends its calls (T-358): reads the qa-integration subagent transcripts, prints tables.

Usage: python tools/qa_calls.py [--from DATE_OR_TIME] [--to DATE_OR_TIME] [--dir TRANSCRIPT_DIR]
                                [--out FILE] [--top N] [--detail AGENT_ID ...]

Same layout, range rules and deduplication as tools/token_report.py: <dir>/<session>/subagents/agent-*.jsonl
with a .meta.json naming the agent type; only qa-integration transcripts are read, streamed line by line and
never modified. A call is one model call (message id, counted once across files); a call counts when its
timestamp is inside the range. For each QA run it prints the ticket it checked (from its description or
prompt), calls, cache read, its tool calls grouped by kind, and its failed tool calls by kind; then totals by
kind. --detail prints one QA run's tool calls in order (kind, failure, first 120 characters of the command or
path), so a dear run can be looked at without reading its transcript.
"""
import argparse
import collections
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from token_report import DEFAULT_DIR, error_kind, in_range, usage_of  # noqa: E402

QA_TYPE = "qa-integration"
KINDS = (
    "test run",
    "poll / wait",
    "qa_check.py",
    "ticket and diff",
    "screenshots / images",
    "git",
    "ticket edit",
    "read / search other files",
    "other",
)
IMAGE = re.compile(r"\.(png|jpe?g|gif|webp|bmp)\b", re.I)
TICKET_PATH = re.compile(r"tasks[/\\]+T-\d+[^/\\]*\.md", re.I)
LOG_PATH = re.compile(r"\.(output|log|txt)\b|[/\\]tasks[/\\]\w+\.output|AppData[/\\]Local[/\\]Temp", re.I)


def classify(name, inp):
    """The kind of one tool call, from its tool name and input."""
    inp = inp or {}
    if name in ("Monitor", "BashOutput", "TaskOutput", "KillShell", "TaskStop", "Sleep", "Wait"):
        return "poll / wait"
    if name in ("Bash", "PowerShell"):
        c = inp.get("command") or ""
        if TICKET_PATH.search(c) and re.search(r">>|\.write\(|write_text|sed\s+-i", c):
            return "ticket edit"  # a shell or python write to the ticket file
        if re.search(r"\bpython[\w.]*\s+(\S*[/\\])?qa_check\.py", c):
            return "qa_check.py"
        if LOG_PATH.search(c) and not re.search(r"\b(python|git|bash|godot)\b", c, re.I) \
                and re.search(r"\b(cat|tail|head|grep|Get-Content)\b", c):
            return "poll / wait"  # reading a background job's output or log to see whether it finished
        if re.match(r"\s*(sleep|Start-Sleep|timeout)\b", c) or re.search(r"&&\s*sleep\b|;\s*sleep\b|\bwhile\b.*\bsleep\b", c):
            return "poll / wait"
        if re.match(r"\s*(cd\s+\S+\s*(&&|;)\s*)?(tail|Get-Content\b.*-Tail)", c) and LOG_PATH.search(c):
            return "poll / wait"
        if (re.fullmatch(r"\s*echo\s+[\w ]{0,40}\s*", c) or re.match(r"\s*(until|while)\b", c)
                or re.search(r"[/\\]tasks[/\\]\w+\.output", c) or re.search(r"\bGet-Process\b", c)):
            return "poll / wait"  # an echo between waits, a wait loop, or reading a background job's output file
        lead = re.match(r"\s*(cd\s+\S+\s*(&&|;)\s*)?git\s+(\w+)", c)
        if lead:  # a command that starts with git: its commit message may mention anything
            return "ticket and diff" if lead.group(3) in ("diff", "show") else "git"
        if re.search(r"screenshot|capture|\.png\b|\.jpe?g\b", c, re.I):
            return "screenshots / images"
        if re.search(r"run_tests|unittest|pytest|gut_cmdln|addons/gut|--headless|check_audio", c, re.I):
            return "test run"
        if re.search(r"task_status\.py", c):
            return "ticket edit"
        if re.search(r"git\s+(diff|show)\b", c) or TICKET_PATH.search(c):
            return "ticket and diff"
        if re.search(r"\bgit\s", c):
            return "git"
        if re.search(r"\b(cat|sed|head|grep|rg|ls|find|wc|awk|less|Select-String|Get-Content|Get-ChildItem|dir|tree)\b", c):
            return "read / search other files"
        return "other"
    path = str(inp.get("file_path") or inp.get("path") or inp.get("notebook_path") or "")
    if name in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        return "ticket edit" if TICKET_PATH.search(path) else "other"
    if name == "Read":
        if IMAGE.search(path):
            return "screenshots / images"
        if TICKET_PATH.search(path):
            return "ticket and diff"
        if LOG_PATH.search(path):
            return "poll / wait"
        return "read / search other files"
    if name in ("Grep", "Glob", "LS"):
        return "read / search other files"
    return "other"


def short(name, inp):
    inp = inp or {}
    s = inp.get("command") or inp.get("file_path") or inp.get("path") or inp.get("pattern") or json.dumps(inp)[:120]
    return f"{name}: " + " ".join(str(s).split())[:120]


def ticket_of(meta, prompt):
    for text in (meta.get("description") or "", prompt or ""):
        m = re.search(r"T-\d+", text)
        if m:
            return m.group(0)
    return "?"


def qa_transcripts(root):
    """Yield (path, session id, agent id, meta) for every qa-integration subagent transcript under root."""
    for name in sorted(os.listdir(root)):
        sd = os.path.join(root, name, "subagents")
        if not os.path.isdir(sd):
            continue
        for fn in sorted(os.listdir(sd)):
            if not fn.endswith(".jsonl"):
                continue
            meta = {}
            try:
                with open(os.path.join(sd, fn[:-6] + ".meta.json"), encoding="utf-8") as mf:
                    meta = json.load(mf) or {}
            except (OSError, ValueError):
                pass
            if meta.get("agentType") == QA_TYPE:
                yield os.path.join(sd, fn), name, fn[len("agent-"):-6] if fn.startswith("agent-") else fn[:-6], meta


def analyze_run(path, lo, hi, seen_msg, seen_tool, detail=False):
    """Stream one QA transcript. Returns a dict, or None when it has no call in range."""
    run = {"calls": 0, "cache_read": 0, "tools": collections.Counter(), "fails": collections.Counter(),
           "fail_kind": collections.Counter(), "first": None, "prompt": None, "steps": []}
    pending = {}  # tool_use id -> (kind, index into steps)
    cur_ts = None
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if '"type":"assistant"' not in line and '"type":"user"' not in line:
                continue
            try:
                r = json.loads(line)
            except ValueError:
                continue
            ts = r.get("timestamp") or cur_ts
            if r.get("timestamp"):
                cur_ts = ts
            msg = r.get("message") or {}
            if r.get("type") == "user" and run["prompt"] is None and isinstance(msg.get("content"), str):
                run["prompt"] = msg["content"][:2000]
            if not in_range(ts, lo, hi):
                continue
            if r.get("type") == "assistant":
                mid = msg.get("id")
                if not mid:
                    continue
                if mid not in seen_msg:
                    seen_msg.add(mid)
                    run["calls"] += 1
                    run["cache_read"] += usage_of(msg)["cache_read"]
                    run["first"] = run["first"] or ts
                for b in msg.get("content") or []:
                    if not isinstance(b, dict) or b.get("type") != "tool_use":
                        continue
                    tid = b.get("id")
                    if tid in seen_tool:
                        continue
                    seen_tool.add(tid)
                    kind = classify(b.get("name"), b.get("input"))
                    run["tools"][kind] += 1
                    pending[tid] = (kind, len(run["steps"]))
                    if detail:
                        run["steps"].append([kind, "", short(b.get("name"), b.get("input"))])
                continue
            c = msg.get("content")
            if not isinstance(c, list):
                continue
            for b in c:
                if not isinstance(b, dict) or b.get("type") != "tool_result" or not b.get("is_error"):
                    continue
                kind, idx = pending.pop(b.get("tool_use_id"), (None, None))
                if kind is None:
                    continue
                cc = b.get("content")
                text = "".join(x.get("text", "") for x in cc if isinstance(x, dict)) if isinstance(cc, list) else str(cc or "")
                ek = error_kind(text)
                run["fails"][kind] += 1
                run["fail_kind"][ek] += 1
                if detail and idx is not None and idx < len(run["steps"]):
                    run["steps"][idx][1] = "FAIL " + ek + ": " + " ".join(text.split())[:100]
    return run if run["calls"] else None


def collect(root, lo, hi, detail_ids=()):
    seen_msg, seen_tool = set(), set()
    runs = []
    for path, sid, aid, meta in qa_transcripts(root):
        want = any(aid.startswith(d) for d in detail_ids)
        r = analyze_run(path, lo, hi, seen_msg, seen_tool, detail=want)
        if r is None:
            continue
        r.update({"session": sid, "agent": aid, "ticket": ticket_of(meta, r["prompt"]),
                  "description": meta.get("description") or "", "model": meta.get("model") or ""})
        runs.append(r)
    return runs


def m(n):
    return f"{n / 1e6:.1f}M"


def table(header, rows):
    out = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    out += ["| " + " | ".join(str(x) for x in row) + " |" for row in rows]
    return "\n".join(out)


def kind_totals(runs):
    tools, fails, fk = collections.Counter(), collections.Counter(), collections.Counter()
    for r in runs:
        tools.update(r["tools"])
        fails.update(r["fails"])
        fk.update(r["fail_kind"])
    return tools, fails, fk


def report(runs, lo, hi, top=None):
    calls = sum(r["calls"] for r in runs)
    ntools = sum(sum(r["tools"].values()) for r in runs)
    tickets = sorted({r["ticket"] for r in runs})
    out = [f"## QA calls, {lo or 'start'} to {hi or 'end'}", "",
           f"{len(runs)} QA runs on {len(tickets)} tickets: {calls} calls, cache read {m(sum(r['cache_read'] for r in runs))}, "
           f"{ntools} tool calls, {sum(sum(r['fails'].values()) for r in runs)} failed. "
           f"Average {calls / len(runs) if runs else 0:.1f} calls per run, {calls / len(tickets) if tickets else 0:.1f} per ticket.", ""]
    tools, fails, fk = kind_totals(runs)
    out += ["### Tool calls by kind", "",
            table(["kind", "tool calls", "share", "failed"],
                  [[k, tools[k], f"{100 * tools[k] / ntools if ntools else 0:.0f}%", fails[k]] for k in KINDS if tools[k] or fails[k]]),
            "", "### Failures by kind", "",
            table(["failure", "count"], [[k, n] for k, n in fk.most_common()]) if fk else "None.", ""]
    per_ticket = collections.defaultdict(lambda: [0, 0, 0])
    for r in runs:
        t = per_ticket[r["ticket"]]
        t[0] += 1
        t[1] += r["calls"]
        t[2] += r["cache_read"]
    out += ["### By ticket", "",
            table(["ticket", "QA runs", "calls", "cache read"],
                  [[t, v[0], v[1], m(v[2])] for t, v in sorted(per_ticket.items(), key=lambda kv: -kv[1][1])]), ""]
    ordered = sorted(runs, key=lambda r: -r["calls"])
    if top:
        ordered = ordered[:top]
    short_k = {"test run": "tests", "poll / wait": "poll", "qa_check.py": "qa_check", "ticket and diff": "ticket/diff",
               "screenshots / images": "shots", "git": "git", "ticket edit": "ticket edit",
               "read / search other files": "read other", "other": "other"}
    out += ["### Per QA run (dearest first)" + (f", top {top}" if top else ""), "",
            table(["agent", "ticket", "start", "calls", "cache read"] + [short_k[k] for k in KINDS] + ["failed"],
                  [[r["agent"][:8], r["ticket"], (r["first"] or "")[:16], r["calls"], m(r["cache_read"])]
                   + [r["tools"][k] for k in KINDS]
                   + [", ".join(f"{k} {n}" for k, n in r["fail_kind"].most_common()) or "0"] for r in ordered]), ""]
    for r in runs:
        if r["steps"]:
            out += [f"### Detail: {r['agent']} ({r['ticket']}, {r['description']})", ""]
            out += [f"{i + 1}. [{k}] {s}" + (f"  <- {f}" if f else "") for i, (k, f, s) in enumerate(r["steps"])]
            out.append("")
    return "\n".join(out)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--from", dest="lo")
    ap.add_argument("--to", dest="hi")
    ap.add_argument("--dir", default=DEFAULT_DIR)
    ap.add_argument("--out")
    ap.add_argument("--top", type=int, help="list only the N dearest runs")
    ap.add_argument("--detail", action="append", default=[], help="agent id (prefix) whose tool calls to list in order")
    a = ap.parse_args(argv)
    text = report(collect(a.dir, a.lo, a.hi, a.detail), a.lo, a.hi, a.top)
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        with open(a.out, "w", encoding="utf-8", newline="\n") as f:
            f.write(text + "\n")
    else:
        sys.stdout.reconfigure(encoding="utf-8")
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
