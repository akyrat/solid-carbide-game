"""The goal runner (role: package). The board gives it a goal; it plans, finds the gaps and writes the tickets.

Layer 1, priority scoring: prioritize.py. Layer 2, gap detection: gaps.py and tickets.py.
Layers 3 and 4 (building and the loop) come in T-163. The goal file: goal_file.py. Claude: claude_call.py.
The command line: run.py. The plan, layer by layer: course-material/goal-oriented-code-agent/README.md.
"""

import sys
from pathlib import Path

TOOLS = str(Path(__file__).resolve().parent.parent)
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)   # the studio's shared helpers (taskboard_sync, task_status) live in tools/
