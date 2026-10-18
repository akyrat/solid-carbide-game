"""Test support (role: plays the agents and the QA/Integration Agent for tests and `run.py --fake` runs).

FakeTeam is a FakeClaude (answers by step name, in order, from a fixture) that also does what a headless
session would do in its folder, so layer 3 and 4 run for real on git without calling Claude:
- step "agent": writes the files in the answer's "_files" ({path: text}) and "_art" lines in the PixelLab
  generation log, writes its summary into the task file's result notes, and commits in the folder;
- step "qa": marks every acceptance criterion "(QA: pass)" or "(QA: fail, ...)" ("_marks": pass or fail,
  default pass) and commits the task file;
- step "gaps": a ticket named "title:<ticket title>" in an answer is replaced by that ticket's id, so a
  fixture works whatever ids the repo gives its tickets.
"""

import json
import re
import subprocess
from pathlib import Path

from task_status import add_note
from goal_agent.claude_call import FakeClaude
from goal_agent.build import ART_LOG

CRITERION_RE = re.compile(r"^(\s*- )\[[ xX]\]( .*?)\s*\(QA:[^)]*\)\s*$", re.M)


def git(folder, *args):
    subprocess.run(["git", "-C", str(folder), *args], capture_output=True, text=True, encoding="utf-8", check=True)


def task_file(folder, prompt):
    tid = re.search(r"T-\d+", prompt).group(0)
    return next(Path(folder, "tasks").glob(f"{tid}-*.md"))


class FakeTeam(FakeClaude):
    def ask(self, step, prompt, schema, **options):
        if step == "gaps":
            self.resolve_titles(options.get("cwd"))
        answer = super().ask(step, prompt, schema, **options)
        acts = self.calls[-1][2].setdefault("acts", {})
        folder = options.get("cwd")
        if step == "agent":
            self.agent(folder, prompt, answer.data, acts)
        elif step == "qa":
            self.qa(folder, prompt, answer.data.get("_marks", "pass"), acts)
        for key in [k for k in answer.data if k.startswith("_")]:
            answer.data.pop(key)
        return answer

    def agent(self, folder, prompt, data, acts):
        path = task_file(folder, prompt)
        for rel, text in (data.get("_files") or {}).items():
            Path(folder, rel).parent.mkdir(parents=True, exist_ok=True)
            Path(folder, rel).write_text(text, encoding="utf-8")
        log = Path(folder, ART_LOG)
        for i in range(int(data.get("_art") or 0)):
            log.parent.mkdir(parents=True, exist_ok=True)
            with log.open("a", encoding="utf-8") as f:
                f.write(json.dumps({"file": f"fake_{path.name[:5]}_{i}.png", "fake": True}) + "\n")
        text = path.read_bytes().decode("utf-8")
        path.write_bytes(add_note(text, f"Fake agent: {data.get('summary', '')}").encode("utf-8"))
        git(folder, "add", "-A")
        git(folder, "commit", "-q", "-m", f"{path.name[:5]}: fake agent work")
        acts["ticket"] = path.name[:5]

    def qa(self, folder, prompt, mark, acts):
        path = task_file(folder, prompt)
        new = "(QA: pass)" if mark == "pass" else "(QA: fail, the fake QA says no)"
        box = "x" if mark == "pass" else " "
        text = path.read_bytes().decode("utf-8")
        text = CRITERION_RE.sub(lambda m: f"{m.group(1)}[{box}]{m.group(2)} {new}", text)
        path.write_bytes(text.encode("utf-8"))
        git(folder, "add", "--", f"tasks/{path.name}")
        git(folder, "commit", "-q", "-m", f"{path.name[:5]}: fake QA, {mark}")
        acts["ticket"], acts["mark"] = path.name[:5], mark

    def resolve_titles(self, cwd):
        """Replace "title:<title>" in the next gaps answer with the id of the ticket that has that title,
        looked up in the main checkout's tasks/ (gap detection may run in the goal's build folder)."""
        if not cwd or not self.answers.get("gaps"):
            return
        common = subprocess.run(["git", "-C", str(cwd), "rev-parse", "--path-format=absolute", "--git-common-dir"],
                                capture_output=True, text=True, encoding="utf-8").stdout.strip()
        root = Path(common).parent if common else Path(cwd)
        titles = {}
        for p in Path(root, "tasks").glob("T-*.md"):
            m = re.search(r"^title: (.*)$", p.read_text(encoding="utf-8"), re.M)
            if m:
                titles[m.group(1).strip()] = p.name[:5]
        for v in self.answers["gaps"][0].get("verdicts", []):
            v["tickets"] = [titles.get(t[6:], t) if t.startswith("title:") else t for t in v.get("tickets", [])]
