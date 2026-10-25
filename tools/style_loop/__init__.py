"""The style loop's tool (T-291; tasks/README.md, "The style loop").

The loop itself: loop.py. The command line, with its fake mode: run.py. Fixtures for the fake mode: fixtures/.
Every Claude call goes through tools/goal_agent/claude_call.py; the script checks are game/tools/style_rules.py.
"""

import sys
from pathlib import Path

TOOLS = str(Path(__file__).resolve().parent.parent)
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)   # the studio's shared helpers (taskboard_sync, task_status, goal_agent) live in tools/
