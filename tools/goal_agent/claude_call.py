"""Claude (role: the only place that calls Claude). Every layer asks through one of these two objects.

RealClaude runs `claude -p --output-format json --json-schema <schema>` with the prompt on standard
input (a long prompt does not fit on a Windows command line) and returns the structured answer with
the call's `permission_denials`, so the caller sees every refusal.
FakeClaude has the same interface but answers from a JSON fixture: {"<step>": [answer, answer, ...]},
used in order, so tests and `run.py --fake` never call Claude. An answer may carry
"_permission_denials": [...] to play a refusal.

Pause is how any layer stops a run: its message is the reason written into the goal file.
"""

import json
import subprocess
from pathlib import Path

TIMEOUT = 1800   # seconds; a planning call reads several documents


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
    def ask(self, step, prompt, schema, model=None, agent=None, session_id=None, cwd=None, allowed_tools=None,
            permission_mode=None, add_dir=None, tools=None, timeout=TIMEOUT):
        cmd = ["claude", "-p", "--output-format", "json", "--json-schema", json.dumps(schema)]
        for flag, value in (("--model", model), ("--agent", agent), ("--session-id", session_id),
                            ("--allowedTools", allowed_tools), ("--permission-mode", permission_mode),
                            ("--add-dir", add_dir), ("--tools", tools)):
            if value:
                cmd += [flag, value]
        try:
            done = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8",
                                  input=prompt, timeout=timeout)
        except (OSError, subprocess.TimeoutExpired) as e:
            raise Pause(f"Claude could not be run for step {step!r}: {e}")
        try:
            result = json.loads(done.stdout)
        except ValueError:
            raise Pause(f"Claude gave no JSON for step {step!r} (exit {done.returncode}): {done.stderr.strip()[:500]}")
        return Answer(parse(result, step), result.get("permission_denials") or [])


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
