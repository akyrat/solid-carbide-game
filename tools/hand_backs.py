"""Hand-backs report: every subagent result that came back into a main session (T-359).

Usage: python tools/hand_backs.py --session ID [--from DATE_OR_TIME] [--to DATE_OR_TIME] [--dir TRANSCRIPT_DIR]
                                  [--top N] [--out FILE]

Reads <dir>/<session>.jsonl (streamed line by line, never modified), same layout, range rules and
character counting as tools/token_report.py (system reminders are not counted). Lists each result:
when, subagent type, characters, how it was delivered, the start of the Agent prompt, and whether
that prompt asked for a one-line hand-back.

Delivery kinds:
  SubagentHandback   a peer message "[Subagent hand-back]" (an async agent's final report)
  Agent tool result  the Agent tool's own result when it returned the report (not the launch acknowledgement)
  task notification  a notice that an agent finished: "(report)" carries the report, "(pointer)" only says it came as a message, "(failed)" says the agent was stopped (usage limit)
"""
import argparse
import collections
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from token_report import DEFAULT_DIR, SR, in_range  # noqa: E402

ASKS_ONE_LINE = re.compile(
    r"one[- ]line|one short line|single line|1 line|one sentence|hand[- ]?back is (one|a single|at most)|"
    r"at most (about )?\d+ characters|(about|under|max(imum)?|within) \d{2,4} characters|short hand[- ]?back",
    re.I)
KINDS = ("SubagentHandback", "Agent tool result", "task notification (report)", "task notification (pointer)", "task notification (failed)")
DEFAULT_TYPE = "general-purpose (default)"


def asks_one_line(prompt):
    return bool(ASKS_ONE_LINE.search(prompt or ""))


def clean_len(text):
    return len(SR.sub("", text or ""))


def body_len(kind, text):
    """Characters of the agent's own words, without the harness frame around them."""
    text = SR.sub("", text or "")
    if kind == "SubagentHandback":
        m = re.search(r"The report follows:\n(.*?)(?:\n</agent-message>|$)", text, re.S)
        return len(m.group(1)) if m else len(text)
    if kind in ("task notification (report)", "task notification (failed)"):
        m = re.search(r"<result>(.*?)</result>", text, re.S)
        return len(m.group(1)) if m else 0
    if kind == "task notification (pointer)":
        return 0
    return len(text)


def result_text(block):
    cc = block.get("content")
    if isinstance(cc, list):
        return "".join(x.get("text", "") for x in cc if isinstance(x, dict) and x.get("type") == "text")
    return cc if isinstance(cc, str) else json.dumps(cc or "")


def scan(path, lo, hi):
    """Stream one main transcript. Returns a list of result dicts."""
    launches = {}   # tool_use_id -> Agent input
    agents = {}     # agent id -> {"type", "prompt", "desc", "n"}
    results = []
    sent_to = collections.Counter()  # agent id -> SendMessages to it so far
    cur_ts = None
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if '"type":"assistant"' not in line and '"type":"user"' not in line:
                continue
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if r.get("timestamp"):
                cur_ts = r["timestamp"]
            ts = r.get("timestamp") or cur_ts
            t = r.get("type")
            c = (r.get("message") or {}).get("content")
            if t == "assistant" and isinstance(c, list):
                for b in c:
                    if not isinstance(b, dict) or b.get("type") != "tool_use":
                        continue
                    inp = b.get("input") or {}
                    if b.get("name") in ("Agent", "Task"):
                        launches[b.get("id")] = inp
                    elif b.get("name") == "SendMessage" and inp.get("to"):
                        sent_to[str(inp["to"])] += 1
                continue
            if t != "user":
                continue
            od = r.get("origin")
            origin = od.get("kind") if isinstance(od, dict) else None
            tur = r.get("toolUseResult")
            if isinstance(c, list):
                for b in c:
                    if not isinstance(b, dict) or b.get("type") != "tool_result":
                        continue
                    inp = launches.get(b.get("tool_use_id"))
                    if inp is None:
                        continue
                    stype = inp.get("subagent_type") or DEFAULT_TYPE
                    if isinstance(tur, dict) and tur.get("agentId"):
                        agents[tur["agentId"]] = {"type": stype, "prompt": inp.get("prompt") or tur.get("prompt") or "",
                                                  "desc": inp.get("description") or "", "n": 0}
                    launch_ack = isinstance(tur, dict) and tur.get("status") == "async_launched"
                    if in_range(ts, lo, hi):
                        results.append({"ts": ts, "kind": "launch acknowledgement" if launch_ack else "Agent tool result",
                                        "sub": not launch_ack, "agent": None, "type": stype,
                                        "chars": clean_len(result_text(b)), "body": clean_len(result_text(b)), "prompt": inp.get("prompt") or "",
                                        "desc": inp.get("description") or "", "resumed": False})
            elif isinstance(c, str):
                if origin == "peer":
                    m = re.search(r'<agent-message from="([^"]+)"', c)
                    kind = "SubagentHandback" if "[Subagent hand-back]" in c else "cross-session peer message"
                    results.append(_notice(ts, kind, m.group(1) if m else None, c, agents, sent_to, lo, hi))
                elif origin == "task-notification":
                    m = re.search(r"<task-id>([^<]+)</task-id>", c)
                    if not re.search(r"<summary>Agent\b", c):
                        kind = "background command notice"
                    elif re.search(r"<status>(failed|killed|stopped)</status>", c):
                        kind = "task notification (failed)"  # e.g. a usage limit stopped the agent
                    elif "delivered to you as a message" in c:
                        kind = "task notification (pointer)"  # only says the report came as a message
                    else:
                        kind = "task notification (report)"
                    results.append(_notice(ts, kind, m.group(1) if m else None, c, agents, sent_to, lo, hi))
    return [x for x in results if x]


def _notice(ts, kind, aid, text, agents, sent_to, lo, hi):
    a = agents.get(aid) or {"type": "unknown", "prompt": "", "desc": "", "n": 0}
    # A resumed agent: its hand-back arrives after we sent it a message (SendMessage).
    resumed = kind == "SubagentHandback" and sent_to.get(aid, 0) > 0 and a["n"] > 0
    if kind == "SubagentHandback":
        a["n"] += 1
    if not in_range(ts, lo, hi):
        return None
    return {"ts": ts, "kind": kind, "sub": kind in KINDS, "agent": aid, "type": a["type"], "chars": clean_len(text), "body": body_len(kind, text),
            "prompt": a["prompt"], "desc": a["desc"], "resumed": resumed}


def table(header, rows):
    out = ["| " + " | ".join(header) + " |", "|" + "|".join("---" for _ in header) + "|"]
    out += ["| " + " | ".join(str(c) for c in r) + " |" for r in rows]
    return "\n".join(out)


def first80(prompt):
    return re.sub(r"\s+", " ", prompt or "").strip()[:80].replace("|", "/")


def format_report(everything, session, lo, hi, top=10):
    results = [r for r in everything if r["sub"]]
    others = collections.defaultdict(lambda: [0, 0])
    for r in everything:
        if not r["sub"]:
            others[r["kind"]][0] += 1
            others[r["kind"]][1] += r["chars"]
    L = ["Session %s, range %s to %s. %d results." % (session, lo or "start", hi or "end", len(results)), ""]
    total = sum(r["chars"] for r in results)
    L.append("Total characters of subagent results: %d, of which the agent's own words %d (the rest is the harness frame or notice around them)." % (
        total, sum(r["body"] for r in results)))
    L.append("")
    L.append("Other text token_report.py counts as 'subagent reports' (not subagent results), for the comparison:")
    L.append("")
    L.append(table(["kind", "items", "characters"], [[k, v[0], v[1]] for k, v in sorted(others.items())]))
    L.append("")
    L.append("Total as token_report.py counts it: %d." % (total + sum(v[1] for v in others.values())))
    L.append("")

    def group(key):
        g = collections.defaultdict(lambda: [0, 0, 0, 0])
        for r in results:
            x = g[key(r)]
            x[0] += 1
            x[1] += r["chars"]
            x[2] += 1 if asks_one_line(r["prompt"]) else 0
            x[3] += r["body"]
        return g
    for title, key in (("By subagent type", lambda r: r["type"]), ("By delivery kind", lambda r: r["kind"])):
        L.append(title + ":")
        L.append("")
        g = group(key)
        L.append(table(["group", "results", "characters", "average", "share", "of which the agent's own words", "prompt asked for one line"],
                       [[k, v[0], v[1], v[1] // max(v[0], 1), "%.1f%%" % (100.0 * v[1] / total) if total else "-", v[3], v[2]]
                        for k, v in sorted(g.items(), key=lambda kv: -kv[1][1])]))
        L.append("")
    L.append("Every result (time, type, kind, characters, asked for one line, resumed, prompt start):")
    L.append("")
    L.append(table(["time (UTC)", "type", "kind", "chars", "own words", "asked", "resumed", "prompt start"],
                   [[(r["ts"] or "")[:19], r["type"], r["kind"], r["chars"], r["body"], "yes" if asks_one_line(r["prompt"]) else "no",
                     "yes" if r["resumed"] else "", first80(r["prompt"])] for r in results]))
    L.append("")
    L.append("The %d longest:" % top)
    L.append("")
    L.append(table(["time (UTC)", "type", "kind", "chars", "own words", "asked", "agent", "prompt start"],
                   [[(r["ts"] or "")[:19], r["type"], r["kind"], r["chars"], r["body"], "yes" if asks_one_line(r["prompt"]) else "no",
                     (r["agent"] or "")[:8], first80(r["prompt"])]
                    for r in sorted(results, key=lambda r: -r["chars"])[:top]]))
    L.append("")
    return "\n".join(L)


def find_session(root, prefix):
    for name in sorted(os.listdir(root)):
        if name.endswith(".jsonl") and name.startswith(prefix):
            return os.path.join(root, name), name[:-6]
    return None, None


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--from", dest="lo")
    ap.add_argument("--to", dest="hi")
    ap.add_argument("--dir", default=DEFAULT_DIR)
    ap.add_argument("--session", required=True, help="a main session id, or its first characters")
    ap.add_argument("--top", type=int, default=10)
    ap.add_argument("--out")
    a = ap.parse_args(argv)
    path, sid = find_session(a.dir, a.session)
    if not path:
        print("No session starting with %s in %s" % (a.session, a.dir), file=sys.stderr)
        return 1
    text = format_report(scan(path, a.lo, a.hi), sid, a.lo, a.hi, a.top)
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
