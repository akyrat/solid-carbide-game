"""Claude (role: the only place that calls Claude). Every layer asks through one of these two objects.

RealClaude runs `claude -p --output-format stream-json --verbose --json-schema <schema>` with the prompt on
standard input (a long prompt does not fit on a Windows command line), reads the session's events as they
arrive, and returns the structured answer from the final `result` event with the call's
`permission_denials`, so the caller sees every refusal. When the caller names a ticket or goal (`activity`),
each event is appended as it arrives to .board/activity/<id>.jsonl in the main checkout (T-203), which the
task board turns into plain phrases (taskboard_sync.event_phrase).
FakeClaude has the same interface but answers from a JSON fixture: {"<step>": [answer, answer, ...]},
used in order, so tests and `run.py --fake` never call Claude. An answer may carry
"_permission_denials": [...] to play a refusal.

Pause is how any layer stops a run: its message is the reason written into the goal file.
"""

import json
import subprocess
import sys
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))   # tools/, for taskboard_sync
import taskboard_sync as tb  # noqa: E402

TIMEOUT = 1800   # seconds; a planning call reads several documents
ACTIVITY_DIR = Path(__file__).resolve().parents[2] / ".board" / "activity"   # git-ignored, like all of .board/


class Pause(Exception):
    """Stop the run and pause the goal; the message is the reason (goal file, `## Pauses`).
    `kind` names the stop rule (loop.KINDS), so `run.py resume` can tell whether the reason is cleared."""

    def __init__(self, message, kind="stop"):
        super().__init__(message)
        self.kind = kind


class Answer:
    def __init__(self, data, denials=()):
        self.data = data
        self.denials = list(denials)


class RealClaude:
    """`activity_dir`: where the activity logs go (T-203); the default is .board/activity in the checkout
    the runner runs from (the main checkout)."""

    def __init__(self, activity_dir=None):
        self.activity_dir = Path(activity_dir) if activity_dir else ACTIVITY_DIR

    def ask(self, step, prompt, schema, model=None, agent=None, session_id=None, cwd=None, allowed_tools=None,
            permission_mode=None, add_dir=None, tools=None, timeout=TIMEOUT, activity=None):
        """`activity`: the ticket or goal id whose activity log gets this session's events (none if None)."""
        cmd = ["claude", "-p", "--output-format", "stream-json", "--verbose", "--json-schema", json.dumps(schema)]
        for flag, value in (("--model", model), ("--agent", agent), ("--session-id", session_id),
                            ("--allowedTools", allowed_tools), ("--permission-mode", permission_mode),
                            ("--add-dir", add_dir), ("--tools", tools)):
            if value:
                cmd += [flag, value]
        try:
            proc = subprocess.Popen(cmd, cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE, text=True, encoding="utf-8", errors="replace")
        except OSError as e:
            raise Pause(f"Claude could not be run for step {step!r}: {e}")
        result, err, timed_out = self.stream(proc, prompt, step, timeout, activity)
        if timed_out:
            raise Pause(f"Claude could not be run for step {step!r}: it went past {timeout} seconds and was stopped.")
        if result is None:
            raise Pause(f"Claude gave no JSON for step {step!r} (exit {proc.returncode}): {err.strip()[:500]}")
        return Answer(parse(result, step), result.get("permission_denials") or [])

    def stream(self, proc, prompt, step, timeout, activity):
        """Send the prompt, then read the events one line at a time as they arrive, appending each to the
        activity log. Returns (the final `result` event or None, standard error, whether it timed out)."""
        errors, timed_out = [], threading.Event()
        reader = threading.Thread(target=lambda: errors.append(proc.stderr.read() or ""), daemon=True)
        reader.start()

        def stop():
            timed_out.set()
            proc.kill()
        timer = threading.Timer(timeout, stop)
        timer.daemon = True
        timer.start()
        result = None
        try:
            try:
                proc.stdin.write(prompt)
                proc.stdin.close()
            except OSError:
                pass                    # it stopped before reading the prompt: its exit and stderr say why
            for line in proc.stdout:
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(event, dict):
                    continue
                if activity:
                    tb.append_activity(self.activity_dir, activity, step, event)
                if event.get("type") == "result":
                    result = event
            proc.wait()
        finally:
            timer.cancel()
        reader.join(5)
        return result, "".join(errors), timed_out.is_set()


def parse(result, step):
    """The structured answer from `claude -p --output-format json`: `structured_output`, else `result` as JSON."""
    if result.get("is_error"):
        raise Pause(f"Claude reported an error for step {step!r}: {str(result.get('result'))[:500]}")
    data = result.get("structured_output")
    if data is None:
        try:
            data = json.loads(result.get("result") or "")
        except ValueError:
            raise Pause(f"Claude's answer for step {step!r} is not the structured JSON asked for.")
    return data


class FakeClaude:
    """Canned answers by step name, in order. `calls` records (step, prompt, options) for tests."""

    def __init__(self, fixture):
        self.answers = json.loads(Path(fixture).read_text(encoding="utf-8")) if not isinstance(fixture, dict) else fixture
        self.answers = {step: list(items) for step, items in self.answers.items() if not step.startswith("_")}
        self.calls = []

    def ask(self, step, prompt, schema, **options):
        self.calls.append((step, prompt, options))
        if not self.answers.get(step):
            raise Pause(f"The fake Claude has no answer left for step {step!r}.")
        data = dict(self.answers[step].pop(0))
        return Answer(data, data.pop("_permission_denials", []))
