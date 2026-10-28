"""Token spend report: reads Claude Code transcripts and the tickets, prints tables (T-342).

Usage: python tools/token_report.py [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--dir TRANSCRIPT_DIR]
                                    [--tasks TASKS_DIR] [--out FILE] [--session ID ...]

Transcripts are streamed line by line (never loaded whole). Usage is deduplicated by message.id;
a call counts when its timestamp's date is inside the range (both ends inclusive).
Layout: <dir>/<session>.jsonl for main sessions, <dir>/<session>/subagents/agent-*.jsonl (+ .meta.json) for subagents.
"""
import argparse
import collections
import json
import os
import re
import sys

DEFAULT_DIR = os.path.join(os.path.expanduser("~"), ".claude", "projects", "C--solid-carbide-game")
SR = re.compile(r"<system-reminder>.*?</system-reminder>", re.S)
KINDS = ("input", "cache_creation", "cache_read", "output")


def in_range(ts, lo, hi):
    if not ts:
        return True
    d = ts[:10]
    return (not lo or d >= lo) and (not hi or d <= hi)


def bash_kind(c):
    c = c or ""
    if re.search(r"git\s+merge|gh\s+pr\s+merge|git\s+push", c):
        return "git merge/push"
    m = re.search(r"tools/([\w\-\.]+\.(?:py|sh))", c)
    if m and not re.search(r"run_tests|check_audio", c):
        return "py/sh tool: " + m.group(1)
    if re.search(r"run_tests|unittest|pytest|gut_cmdln|addons/gut|check_audio|--headless", c, re.I):
        return "test run"
    if re.search(r"git\s+(diff|log|status|show|branch|rev-parse|ls-files|blame)", c):
        return "git inspect"
    if re.search(r"git\s+(add|commit|checkout|switch|worktree|stash|reset|rebase|pull|fetch)", c):
        return "git write/other"
    if re.match(r"\s*(cd\s+\S+\s*&&\s*)?(cat|sed|head|tail|less|wc|awk)\b", c):
        return "cat/sed/head/tail"
    if re.search(r"\b(grep|rg|findstr|Select-String)\b", c):
        return "grep/rg"
    if re.search(r"\b(ls|find|dir|tree)\b", c):
        return "ls/find"
    return "other"


def error_kind(text):
    t = text or ""
    if "has not been read yet" in t or "must Read" in t or "File has not been read" in t:
        return "edit before read"
    if "hook error" in t or "Refused because" in t:
        return "hook refusal"
    if re.search(r"\bsleep\b", t, re.I) and re.search(r"block|not allowed|refus", t, re.I):
        return "sleep blocked"
    if "doesn't want to proceed" in t or "permission" in t.lower():
        return "permission refusal"
    return "other error"


class Agg:
    """Everything one run collects. Counters merge by key, so files can be added one by one."""

    def __init__(self):
        self.usage = collections.defaultdict(lambda: collections.Counter())  # (scope, type, model) -> kinds + calls
        self.sessions = {}  # session id -> dict
        self.chars = collections.Counter()
        self.weighted = collections.Counter()
        self.bash_n = collections.Counter()
        self.bash_c = collections.Counter()
        self.errors = collections.Counter()
        self.error_scope = collections.Counter()
        self.tool_calls = collections.Counter()
        self.seen = set()


def usage_of(msg):
    u = msg.get("usage") or {}
    return {
        "input": u.get("input_tokens") or 0,
        "cache_creation": u.get("cache_creation_input_tokens") or 0,
        "cache_read": u.get("cache_read_input_tokens") or 0,
        "output": u.get("output_tokens") or 0,
    }


def analyze_file(path, lo, hi, agg, scope, sub_type=None, session_id=None):
    """Stream one transcript into agg. scope is 'main' or 'sub'. Returns the per-file summary."""
    calls = 0
    ctxs = []
    compactions = 0
    seen_uuid = set()
    file_seen = set()
    seen_blk = set()
    tool_by_id = {}
    open_c = collections.Counter()
    open_s = collections.Counter()
    chars = collections.Counter()
    weighted = collections.Counter()
    first = last = None
    cur_ts = None
    content = scope == "main"

    def add(key, n):
        if n > 0 and content:
            chars[key] += n
            open_c[key] += n
            open_s[key] += n * calls

    def close():
        for k in list(open_c):
            weighted[k] += open_c[k] * calls - open_s[k]
        open_c.clear()
        open_s.clear()

    def split_add(base, text):
        if not text:
            return
        sr = sum(len(p) for p in SR.findall(text))
        add(base, len(SR.sub("", text)))
        if sr:
            add("system reminders / hooks", sr)

    summary = {"calls": 0, "ctx_sum": 0, "ctx_peak": 0, "compactions": 0, "cache_read": 0, "first": None, "last": None}
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if '"type":"assistant"' not in line and '"type":"user"' not in line and '"compact_boundary"' not in line and '"type":"attachment"' not in line:
                continue
            try:
                r = json.loads(line)
            except ValueError:
                continue
            ts = r.get("timestamp") or cur_ts
            if r.get("timestamp"):
                cur_ts = ts
            if not in_range(ts, lo, hi):
                continue
            t = r.get("type")
            if t == "assistant":
                msg = r.get("message") or {}
                mid = msg.get("id")
                if mid and mid not in file_seen:
                    file_seen.add(mid)
                    calls += 1
                    u = usage_of(msg)
                    model = msg.get("model") or "?"
                    if mid not in agg.seen:  # totals count a message once even when a forked session copied it
                        agg.seen.add(mid)
                        key = (scope, sub_type or "-", model)
                        for k in KINDS:
                            agg.usage[key][k] += u[k]
                        agg.usage[key]["calls"] += 1
                    ctx = u["input"] + u["cache_creation"] + u["cache_read"]
                    ctxs.append(ctx)
                    summary["cache_read"] += u["cache_read"]
                    first = first or ts
                    last = ts
                elif not mid:
                    continue
                for b in msg.get("content") or []:
                    if not isinstance(b, dict):
                        continue
                    bk = hash((mid, json.dumps(b, sort_keys=True)))
                    if bk in seen_blk:
                        continue
                    seen_blk.add(bk)
                    bt = b.get("type")
                    if bt == "text":
                        add("assistant text", len(b.get("text", "")))
                    elif bt == "thinking":
                        add("assistant thinking", len(b.get("thinking", "") or ""))
                    elif bt == "tool_use":
                        name = b.get("name")
                        tool_by_id[b.get("id")] = (name, b.get("input") or {})
                        agg.tool_calls[name] += 1
                        add("tool input: " + str(name), len(json.dumps(b.get("input") or {}, ensure_ascii=False)))
                continue
            if t == "user":
                u_id = r.get("uuid")
                if u_id in seen_uuid:
                    continue
                seen_uuid.add(u_id)
                od = r.get("origin")
                origin = od.get("kind") if isinstance(od, dict) else None
                c = (r.get("message") or {}).get("content")
                if isinstance(c, str):
                    if origin == "human":
                        split_add("typed prompts", c)
                    elif origin in ("peer", "task-notification"):
                        split_add("subagent reports", c)
                    elif "<bash-input>" in c:
                        split_add("typed prompts", c)
                    else:
                        split_add("other user text", c)
                elif isinstance(c, list):
                    for b in c:
                        if not isinstance(b, dict):
                            continue
                        bt = b.get("type")
                        if bt == "tool_result":
                            cc = b.get("content")
                            if isinstance(cc, list):
                                text = "".join(x.get("text", "") for x in cc if isinstance(x, dict) and x.get("type") == "text")
                            else:
                                text = cc or ""
                            if not isinstance(text, str):
                                text = json.dumps(text)
                            name, inp = tool_by_id.get(b.get("tool_use_id"), ("?", {}))
                            if b.get("is_error"):
                                ek = error_kind(text)
                                agg.errors[ek] += 1
                                agg.error_scope[(scope, ek)] += 1
                            if name in ("Bash", "PowerShell"):
                                kind = bash_kind(inp.get("command"))
                                base = "tool result: Bash, " + kind
                                if content:
                                    agg.bash_n[kind] += 1
                                    agg.bash_c[kind] += len(text)
                            elif name in ("Agent", "Task"):
                                base = "subagent reports"
                            else:
                                base = "tool result: " + str(name)
                            split_add(base, text)
                        elif bt == "text":
                            txt = b.get("text", "")
                            if not txt.startswith("[Request interrupted"):
                                split_add("typed prompts", txt)
                continue
            if t == "attachment":
                u_id = r.get("uuid")
                if u_id in seen_uuid:
                    continue
                seen_uuid.add(u_id)
                rendered = r.get("rendered") or []
                total = sum(len(x.get("content", "")) for x in rendered if isinstance(x, dict) and isinstance(x.get("content", ""), str))
                add("system reminders / hooks", total)
                continue
            if t == "system" and r.get("subtype") == "compact_boundary":
                close()
                compactions += 1
    close()
    agg.chars.update(chars)
    agg.weighted.update(weighted)
    summary.update({
        "calls": calls, "ctx_sum": sum(ctxs), "ctx_peak": max(ctxs, default=0),
        "compactions": compactions, "first": first, "last": last,
    })
    return summary


def find_transcripts(root):
    """Yield (path, scope, subagent type, session id) for every transcript under root."""
    for name in sorted(os.listdir(root)):
        p = os.path.join(root, name)
        if name.endswith(".jsonl") and os.path.isfile(p):
            yield p, "main", None, name[:-6]
        elif os.path.isdir(p):
            sd = os.path.join(p, "subagents")
            if os.path.isdir(sd):
                for fn in sorted(os.listdir(sd)):
                    if fn.endswith(".jsonl"):
                        stype = "unknown"
                        meta = os.path.join(sd, fn[:-6] + ".meta.json")
                        try:
                            with open(meta, encoding="utf-8") as mf:
                                stype = json.load(mf).get("agentType") or "unknown"
                        except (OSError, ValueError):
                            pass
                        yield os.path.join(sd, fn), "sub", stype, name


def run(root, lo, hi, only=None):
    agg = Agg()
    per_file = []
    for path, scope, stype, sid in find_transcripts(root):
        if only and not any(sid.startswith(o) for o in only):
            continue
        s = analyze_file(path, lo, hi, agg, scope, stype, sid)
        s.update({"scope": scope, "type": stype, "session": sid, "path": path})
        per_file.append(s)
    return agg, per_file


def read_tickets(tasks_dir):
    """Per ticket: to, model, qa_rounds, whether any QA fail mark remains in the text, status."""
    out = []
    if not tasks_dir or not os.path.isdir(tasks_dir):
        return out
    for fn in sorted(os.listdir(tasks_dir)):
        if not re.match(r"T-\d+.*\.md$", fn):
            continue
        with open(os.path.join(tasks_dir, fn), encoding="utf-8", errors="replace") as f:
            text = f.read()
        head = text.split("---", 2)[1] if text.startswith("---") else ""
        d = {}
        for ln in head.splitlines():
            if ":" in ln:
                k, v = ln.split(":", 1)
                d[k.strip()] = v.strip()
        try:
            rounds = int(d.get("qa_rounds") or 0)
        except ValueError:
            rounds = 0
        out.append({
            "id": d.get("id", fn[:5]), "to": d.get("to") or "?", "model": d.get("model") or "(unset)",
            "qa_rounds": rounds, "status": d.get("status", "?"),
            "failed": bool(re.search(r"\(QA: fail", text)),
        })
    return out


# ---------- formatting ----------

def m(n):
    return "%.1fM" % (n / 1e6)


def table(header, rows):
    lines = ["| " + " | ".join(header) + " |", "|" + "|".join("---" for _ in header) + "|"]
    for r in rows:
        lines.append("| " + " | ".join(str(c) for c in r) + " |")
    return "\n".join(lines)


def pct(a, b):
    return "%.1f%%" % (100.0 * a / b) if b else "-"


def report(agg, per_file, tickets, lo, hi):
    L = []
    L.append("# Token spend report")
    L.append("")
    L.append("Range: %s to %s (dates of the calls, both ends inclusive). Usage deduplicated by message.id." % (lo or "start", hi or "end"))
    L.append("Tokens in millions (M). Cache read is the bulk of the volume; output is the smallest.")
    L.append("")

    # 1 tokens
    L.append("## 1. Tokens by kind, model, scope and subagent type")
    L.append("")
    tot = collections.Counter()
    by_model = collections.defaultdict(collections.Counter)
    by_scope = collections.defaultdict(collections.Counter)
    by_type = collections.defaultdict(collections.Counter)
    for (scope, stype, model), c in agg.usage.items():
        tot.update(c)
        by_model[model].update(c)
        by_scope[scope].update(c)
        if scope == "sub":
            by_type[stype].update(c)

    def rows(d):
        out = []
        for k, c in sorted(d.items(), key=lambda kv: -kv[1]["cache_read"]):
            out.append([k, c["calls"], m(c["input"]), m(c["cache_creation"]), m(c["cache_read"]), m(c["output"])])
        return out

    H = ["", "calls", "input", "cache creation", "cache read", "output"]
    L.append("All: %d calls, input %s, cache creation %s, cache read %s, output %s." % (
        tot["calls"], m(tot["input"]), m(tot["cache_creation"]), m(tot["cache_read"]), m(tot["output"])))
    L.append("")
    L.append("By scope:")
    L.append("")
    L.append(table(["scope"] + H[1:], rows({"main sessions" if k == "main" else "subagents": v for k, v in by_scope.items()})))
    L.append("")
    L.append("By model:")
    L.append("")
    L.append(table(["model"] + H[1:], rows(by_model)))
    L.append("")
    L.append("Subagents by type:")
    L.append("")
    L.append(table(["subagent type"] + H[1:], rows(by_type)))
    L.append("")

    # 2 calls and context
    L.append("## 2. Calls, context size and compactions per session")
    L.append("")
    sess = collections.defaultdict(lambda: {"main": None, "sub_calls": 0, "sub_cr": 0})
    for s in per_file:
        if not s["calls"] and not s["compactions"]:
            continue
        if s["scope"] == "main":
            sess[s["session"]]["main"] = s
        else:
            sess[s["session"]]["sub_calls"] += s["calls"]
            sess[s["session"]]["sub_cr"] += s["cache_read"]
    mains = [(sid, v["main"]) for sid, v in sess.items() if v["main"] and v["main"]["calls"]]
    mains.sort(key=lambda kv: -kv[1]["cache_read"])
    L.append("Main sessions with calls in range: %d. Compactions in range: %d. Calls per session: average %.0f, median %d." % (
        len(mains), sum(s["compactions"] for _, s in mains),
        (sum(s["calls"] for _, s in mains) / len(mains)) if mains else 0,
        sorted(s["calls"] for _, s in mains)[len(mains) // 2] if mains else 0))
    L.append("")
    L.append("The 20 sessions with the most cache read:")
    L.append("")
    L.append(table(["session", "calls", "avg context", "peak context", "compactions", "cache read", "subagent calls", "subagent cache read"],
                   [[sid[:8], s["calls"], "%dk" % (s["ctx_sum"] / s["calls"] / 1000), "%dk" % (s["ctx_peak"] / 1000), s["compactions"],
                     m(s["cache_read"]), sess[sid]["sub_calls"], m(sess[sid]["sub_cr"])] for sid, s in mains[:20]]))
    L.append("")
    tc = sum(s["calls"] for _, s in mains)
    if tc:
        L.append("All main sessions together: %d calls, average context per call %dk tokens." % (
            tc, sum(s["ctx_sum"] for _, s in mains) / tc / 1000))
        L.append("")

    # 3 context content
    L.append("## 3. What fills the main sessions' context")
    L.append("")
    L.append("Share is the characters added. Weighted cost is characters x the calls that carried them (until the next compaction or the end of the session), a stand-in for the tokens re-read.")
    L.append("")
    totc = sum(agg.chars.values())
    totw = sum(agg.weighted.values())
    ordered = sorted(agg.chars, key=lambda k: -agg.weighted.get(k, 0))
    L.append(table(["category", "characters", "share", "weighted cost", "weighted share"],
                   [[k, "%.1fM" % (agg.chars[k] / 1e6), pct(agg.chars[k], totc), "%.1fG" % (agg.weighted[k] / 1e9), pct(agg.weighted[k], totw)] for k in ordered[:30]]))
    L.append("")
    groups = collections.Counter()
    gw = collections.Counter()
    for k in agg.chars:
        if k.startswith("tool result: Bash"):
            g = "tool results: Bash"
        elif k.startswith("tool result"):
            g = "tool results: other tools"
        elif k.startswith("tool input"):
            g = "tool inputs"
        else:
            g = k
        groups[g] += agg.chars[k]
        gw[g] += agg.weighted.get(k, 0)
    L.append("Grouped:")
    L.append("")
    L.append(table(["group", "share of characters", "share of weighted cost"],
                   [[g, pct(groups[g], totc), pct(gw[g], totw)] for g in sorted(gw, key=lambda g: -gw[g])]))
    L.append("")
    L.append("Bash results by command kind:")
    L.append("")
    L.append(table(["kind", "calls", "result characters", "average"],
                   [[k, agg.bash_n[k], "%.1fM" % (agg.bash_c[k] / 1e6), agg.bash_c[k] // max(agg.bash_n[k], 1)]
                    for k in sorted(agg.bash_c, key=lambda k: -agg.bash_c[k])]))
    L.append("")

    # 4 failures
    L.append("## 4. Failed tool calls")
    L.append("")
    totc_calls = sum(agg.tool_calls.values())
    L.append("Tool calls in main sessions and subagents: %d. Failed (is_error): %d (%s)." % (totc_calls, sum(agg.errors.values()), pct(sum(agg.errors.values()), totc_calls)))
    L.append("")
    L.append(table(["failure", "count", "of which in main sessions"],
                   [[k, n, agg.error_scope[("main", k)]] for k, n in agg.errors.most_common()]))
    L.append("")
    L.append("Top tools called:")
    L.append("")
    L.append(table(["tool", "calls"], [[k, n] for k, n in agg.tool_calls.most_common(12)]))
    L.append("")

    # 5 tickets
    L.append("## 5. Tickets: QA rounds, failures, model choice")
    L.append("")
    L.append("From all ticket files in the tasks folder (not limited by the date range; tickets carry no run date). A fail mark is replaced by QA's later pass mark, so the fail counts are a lower bound; QA rounds above 1 also show retries.")
    L.append("")
    if tickets:
        L.append("Tickets: %d. With at least one QA round: %d. Ever marked with a QA fail: %d." % (
            len(tickets), sum(1 for t in tickets if t["qa_rounds"] >= 1), sum(1 for t in tickets if t["failed"])))
        L.append("")
        by = collections.defaultdict(lambda: [0, 0, 0, 0])
        for t in tickets:
            for key in ((t["to"], t["model"]),):
                b = by[key]
                b[0] += 1
                b[1] += 1 if t["qa_rounds"] >= 1 else 0
                b[2] += t["qa_rounds"]
                b[3] += 1 if t["failed"] else 0
        L.append("QA fail rate by agent and model (fail rate = tickets with a QA fail mark / tickets that went to QA):")
        L.append("")
        L.append(table(["agent", "model", "tickets", "went to QA", "QA rounds", "with a fail", "fail rate"],
                       [[k[0], k[1], v[0], v[1], v[2], v[3], pct(v[3], v[1])] for k, v in sorted(by.items(), key=lambda kv: -kv[1][0])]))
        L.append("")
        mc = collections.Counter(t["model"] for t in tickets)
        L.append("Model choice counts:")
        L.append("")
        L.append(table(["model", "tickets"], [[k, n] for k, n in mc.most_common()]))
        L.append("")
        st = collections.Counter(t["status"] for t in tickets)
        L.append("By status: " + ", ".join("%s %d" % kv for kv in st.most_common()) + ".")
        L.append("")
    else:
        L.append("No ticket files found.")
        L.append("")
    return "\n".join(L)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--from", dest="lo")
    ap.add_argument("--to", dest="hi")
    ap.add_argument("--dir", default=DEFAULT_DIR)
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("--tasks", default=os.path.join(here, "tasks"))
    ap.add_argument("--out")
    ap.add_argument("--session", action="append", help="only sessions whose id starts with this (repeatable)")
    a = ap.parse_args(argv)
    agg, per_file = run(a.dir, a.lo, a.hi, a.session)
    text = report(agg, per_file, read_tickets(a.tasks), a.lo, a.hi)
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
