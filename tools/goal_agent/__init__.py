"""The goal runner (role: package). The board gives it a goal; it plans, finds the gaps, writes and builds the tickets.

Layer 1, priority scoring: prioritize.py. Layer 2, gap detection: gaps.py and tickets.py.
Layer 3, code writing (building the tickets with the agents): build.py. Layer 4, the iteration loop: loop.py.
The goal file: goal_file.py. Claude: claude_call.py. The command line: run.py.
Test support: temp_repo.py and fake_team.py. QA's helper: try_fixture.py.
The plan, layer by layer: course-material/goal-oriented-code-agent/README.md.
"""

import sys
from pathlib import Path

TOOLS = str(Path(__file__).resolve().parent.parent)
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)   # the studio's shared helpers (taskboard_sync, task_status) live in tools/
