"""Tests for T-149: a task's status, qa_rounds and lead lines change only through tools/task_status.py.

Each test named after a gap reproduces a way past the hooks that was found on 2026-10-16 and shows it is refused now.
"""

import contextlib
import io
import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_task_status import Base, gate, task, ts, tb  # noqa: E402,F401
import guard_ledger as gl  # noqa: E402


def decide(fn, *args, **kwargs):
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        fn(*args, **kwargs)
    return json.loads(buf.getvalue())["hookSpecificOutput"]["permissionDecision"] if buf.getvalue() else "allow"


class EditGaps(Base):
    def setUp(self):
        super().setUp()
        self.path = self.put("T-001", status="in-qa")

    def edit(self, path, old="qa_rounds: 0", new="qa_rounds: 1", cwd=None):
        return decide(gate.pre_edit, "Edit", {"file_path": str(path), "old_string": old, "new_string": new}, cwd)

    def test_gap_a_repeated_line_hides_the_change(self):
        # a second qa_rounds line ABOVE the real one: the board's parser read the last line, the script the first
        self.assertEqual(self.edit(self.path, "qa_rounds: 0", "qa_rounds: 1\nqa_rounds: 0"), "deny")
        self.assertEqual(self.edit(self.path, "status: in-qa", "status: done\nstatus: in-qa"), "deny")

    def test_gap_b_relative_path(self):
        self.assertEqual(self.edit("tasks/T-001-test.md", cwd=self.root), "deny")
        self.assertEqual(self.edit("T-001-test.md", cwd=self.tasks), "deny")   # from inside the tasks folder

    def test_gap_c_other_case_and_trailing_dot(self):
        self.assertEqual(self.edit(str(self.path).replace("tasks", "TASKS").replace("T-001", "t-001")), "deny")
        self.assertEqual(self.edit(str(self.path) + "."), "deny")

    def test_gap_d_dot_dot_segments(self):
        self.assertEqual(self.edit(self.root / "tasks" / ".." / "tasks" / "T-001-test.md"), "deny")

    def test_gap_e_a_task_file_under_another_name(self):
        other = self.root / "copy.md"   # a task file is recognised by its header too
        other.write_bytes(self.path.read_bytes())
        self.assertEqual(self.edit(other), "deny")

    def test_gap_f_undecodable_file_does_not_fail_open(self):
        self.path.write_bytes(self.path.read_bytes() + b"\n\xe9\xff")
        self.assertEqual(self.edit(self.path), "deny")

    def test_other_edits_still_allowed(self):
        self.assertEqual(self.edit(self.path, "Something to build.", "Something else."), "allow")
        self.assertEqual(self.edit(self.root / "notes.md", "a", "b"), "allow")


class ShellGaps(Base):
    def cmd(self, command, cwd=None):
        return decide(gate.pre_shell, {"command": command}, cwd)

    def test_gap_g_glob_paths(self):
        for c in ["sed -i 's/qa_rounds: 0/qa_rounds: 1/' tasks/*.md",
                  "sed -i 's/qa_rounds: 0/qa_rounds: 1/' tasks/T-14?-x.md",
                  "sed -i 's/status: open/status: done/' tasks/T-1*.md"]:
            with self.subTest(c=c):
                self.assertEqual(self.cmd(c), "deny")

    def test_gap_h_cd_into_the_tasks_folder_first(self):
        self.assertEqual(self.cmd("cd tasks && sed -i 's/qa_rounds: 0/qa_rounds: 1/' T-139-x.md"), "deny")
        self.assertEqual(self.cmd("cd C:/w/T-139/tasks; sed -i 's/qa_rounds: 0/qa_rounds: 1/' *.md"), "deny")
        # an earlier call left the shell inside tasks/
        self.assertEqual(self.cmd("sed -i 's/qa_rounds: 0/qa_rounds: 1/' T-139-x.md", cwd="C:/w/T-139/tasks"), "deny")

    def test_gap_i_the_script_name_in_a_comment_or_echo(self):
        self.assertEqual(self.cmd("sed -i 's/qa_rounds: 0/qa_rounds: 1/' tasks/T-139-x.md # task_status.py"), "deny")
        self.assertEqual(self.cmd("echo task_status.py; sed -i 's/status: open/status: done/' tasks/T-139-x.md"), "deny")
        self.assertEqual(self.cmd("python tools/test_task_status.py x; sed -i 's/lead:/lead: A/' tasks/T-1-x.md"), "deny")

    def test_gap_j_the_word_without_a_colon_or_split_up(self):
        for c in [r"sed -i 's/\(qa_rounds\): 0/\1: 1/' tasks/T-139-x.md",
                  "sed -i 's/rounds: 0/rounds: 1/' tasks/T-139-x.md  # qa_rounds",
                  "python -c \"import pathlib; [f.write_text(f.read_text().replace('qa_'+'rounds: 0','qa_'+'rounds: 1')) "
                  "for f in pathlib.Path('tasks').glob('T-139*')]\"",
                  "python -c \"import glob; [open(f,'w') for f in glob.glob('tasks/T-1*')]\"",
                  "perl -pi -e 's/qa_rounds: 0/qa_rounds: 1/' tasks/T-139-x.md"]:
            with self.subTest(c=c):
                self.assertEqual(self.cmd(c), "deny")

    def test_gap_k_a_lead_read_does_not_excuse_a_write_in_the_same_command(self):
        self.assertEqual(self.cmd("grep -n 'lead:' tasks/T-1-x.md; mv a tasks/T-1-x.md"), "deny")

    def test_reading_still_works(self):
        for c in ['grep -n "^qa_rounds:" tasks/T-139*.md', "cd tasks && grep -h '^status:' T-1*.md",
                  "head -20 tasks/*.md | grep lead:", "git log --oneline -3 -- tasks/T-139-x.md",
                  "git diff HEAD -- tasks/T-139-x.md | grep status",
                  'Select-String -Path tasks/*.md -Pattern "qa_rounds:"',
                  "grep lead: tasks/T-139-x.md"]:
            with self.subTest(c=c):
                self.assertEqual(self.cmd(c), "allow")
        self.assertEqual(self.cmd("grep -h '^status:' T-1*.md", cwd="C:/w/T-139/tasks"), "allow")

    def test_the_status_script_still_works(self):
        for c in ["python tools/task_status.py T-149 in-qa --note 'ok'",
                  "python C:/solid-carbide-game/tools/task_status.py T-149 in-qa --note \"status; qa_rounds: 1 tasks/\" "
                  "--reply 'x'",
                  "cd C:/solid-carbide-worktrees/T-149 && python C:/solid-carbide-game/tools/task_status.py T-149",
                  "PYTHONIOENCODING=utf-8 python -u tools/task_status.py T-1 --lead Tools",
                  "python tools/task_status.py T-1 blocked 2>&1"]:
            with self.subTest(c=c):
                self.assertEqual(self.cmd(c), "allow")

    def test_git_housekeeping_still_works(self):
        for c in ['git add tasks/T-149-x.md && git commit -m "T-149: status and qa_rounds guard, tasks/ lead"',
                  "git checkout -- tasks/T-149-x.md", "git merge --no-ff --no-commit task/T-149-x",
                  "git -C C:/solid-carbide-worktrees/T-149 add tasks"]:
            with self.subTest(c=c):
                self.assertEqual(self.cmd(c), "allow")


class FalseRefusals(Base):
    """T-161: the routine work of the Project Lead was refused although it edits no ticket line."""

    def cmd(self, command, cwd=None):
        return decide(gate.pre_shell, {"command": command}, cwd)

    TIMELINE = ("cat >> docs/timeline.md <<'EOF'\n### 2026-10-17 T-149\nThe board's guard: qa_rounds and status lines, "
                "tasks/README.md, then cd tasks and lead words.\nEOF\n")

    def test_worktree_cleanup_after_a_merge(self):
        # the branch name holds "qa-rounds" and the path "T-149": the check read that as a ticket edit
        branch = "task/T-149-guard-qa-rounds-hand-edits"
        remove = f"git worktree remove --force C:/solid-carbide-worktrees/T-149 && git branch -d {branch}"
        self.assertEqual(self.cmd(f"git merge-base --is-ancestor {branch} master && {remove}"), "allow")
        self.assertEqual(self.cmd(f"git merge-base --is-ancestor {branch} master && {remove} && "
                                  "python tools/task_status.py T-149"), "allow")

    def test_text_that_only_mentions_the_fields(self):
        self.assertEqual(self.cmd(self.TIMELINE + 'git add docs/timeline.md && git commit -m "T-149: qa_rounds, '
                                  'status, tasks/README.md, cd tasks"'), "allow")
        self.assertEqual(self.cmd(self.TIMELINE), "allow")
        self.assertEqual(self.cmd('git commit -F - <<EOF\nT-1: status and lead in tasks/ it\'s fine\nEOF'), "allow")
        self.assertEqual(self.cmd('git commit -m "$(cat <<\'EOF\'\nT-1: qa_rounds, status, tasks/T-1-x.md\n'
                                  'EOF\n)"'), "allow")
        self.assertEqual(self.cmd("echo 'qa_rounds: 1 in tasks/T-1-x.md' > docs/notes.md"), "allow")

    def test_the_merge_routine(self):
        """docs/working-with-the-board.md, "Merging": every step of it is allowed."""
        branch = "task/T-149-guard-qa-rounds-hand-edits"
        steps = [f"if git merge --no-ff --no-commit {branch}; then echo merged; fi",
                 "git checkout -- game/art/boulders/boulder_a.png.import",
                 f'python tools/task_status.py T-149 done --note "the board\'s review: qa_rounds ok"',
                 "python tools/generate_long_gdd.py",
                 "python tools/update_short_gdd_fingerprint.py",
                 "python -m unittest discover -s tools",
                 "python -m unittest discover -s game/tools",
                 "bash game/tools/run_tests.sh",
                 "git rev-parse -q --verify MERGE_HEAD",
                 self.TIMELINE.replace("T-149", "T-149 merge"),
                 "git add docs/timeline.md docs/long-gdd.md tasks/T-149-guard-qa-rounds-hand-edits.md "
                 "&& git commit -m 'Merge task/T-149 (done)'",
                 f"git merge-base --is-ancestor {branch} master && git worktree remove --force "
                 f"C:/solid-carbide-worktrees/T-149 && git branch -d {branch}"]
        for c in steps:
            with self.subTest(c=c):
                self.assertEqual(self.cmd(c), "allow")

    def test_the_gaps_stay_closed(self):
        for c in ["cat > tasks/T-1-x.md <<'EOF'\nstatus: done\nEOF",
                  "cat >> tasks/T-1-x.md <<'EOF'\nqa_rounds: 1\nEOF",
                  "cd tasks && cat > T-1-x.md <<'EOF'\nstatus: done\nEOF",
                  "cd tasks && echo 'status: done' > notes.md",
                  "echo 'status: done' > tasks/*.md",
                  "ls tasks; echo 'status: done' > $f",
                  "if true; then sed -i 's/status: open/status: done/' tasks/T-1-x.md; fi",
                  "python - <<'EOF'\nopen('tasks/T-1-x.md','w').write('status: done')\nEOF",
                  "cat <<EOF > docs/x.md\n$(sed -i 's/status: open/status: done/' tasks/T-1-x.md)\nEOF",
                  "cat <<EOF\nstatus: done tasks/\nEOF\nsed -i 's/qa_rounds: 0/qa_rounds: 1/' tasks/T-1-x.md",
                  "cat <<'EOF' > docs/x.md\nno terminator status tasks/"]:
            with self.subTest(c=c):
                self.assertEqual(self.cmd(c), "deny")
        self.assertEqual(self.cmd("echo status > notes.md", cwd="C:/w/T-1/tasks"), "deny")
        self.assertEqual(self.cmd("git merge-base a b; sed -i 's/qa_rounds: 0/qa_rounds: 1/' tasks/T-1-x.md"), "deny")


class HarmlessMentions(Base):
    """T-181: commands refused on 2026-10-18 that could not write any ticket's status, qa_rounds or lead line."""

    def cmd(self, command, cwd=None):
        return decide(gate.pre_shell, {"command": command}, cwd)

    def test_allowed_1_commit_with_a_substitution_and_git_status(self):
        self.assertEqual(self.cmd(
            'cd /c/solid-carbide-game && test -z "$(git rev-parse -q --verify MERGE_HEAD)" && '
            'git add tasks/T-162-x.md && git commit -q -m "T-162: notes" && git log --oneline -1 && '
            'git status --short'), "allow")

    def test_allowed_2_claim_worktree_copy_env_and_start(self):
        self.assertEqual(self.cmd(
            "python tools/task_status.py T-162 --lead X && "
            "git worktree add -q -b task/T-162-x /c/solid-carbide-worktrees/T-162 master && "
            "cp .env /c/solid-carbide-worktrees/T-162/.env && "
            'python tools/task_status.py T-162 in-progress --reply "Started: the status line work."'), "allow")

    def test_allowed_3_a_loop_over_task_folders(self):
        for c in ['for t in T-151 T-152; do git -C $t add tasks/ && git -C $t commit -q -m "$t: notes"; done',
                  'for t in T-151 T-152; do git -C $t add tasks/ && git -C $t commit -q -m "$t: status notes"; done']:
            with self.subTest(c=c):
                self.assertEqual(self.cmd(c), "allow")

    def test_allowed_4_merges_then_inline_python_that_reads_settings(self):
        self.assertEqual(self.cmd(
            "git -C /c/solid-carbide-worktrees/G-002 merge -q --no-edit master; "
            "git -C /c/solid-carbide-worktrees/T-166 merge -q --no-edit playtest/G-002; "
            "python -c \"import json;print(len(json.load(open('.claude/settings.json'))['permissions']['allow']))\""),
            "allow")

    def test_allowed_5_a_result_note_appended_to_a_ticket(self):
        self.assertEqual(self.cmd(
            "printf '%s\\n' \"- 2026-10-18, Project Lead: the status check passed; the Project Lead's to run "
            "QA next.\" >> tasks/T-176-x.md"), "allow")

    def test_allowed_6_a_test_run_naming_the_status_script(self):
        self.assertEqual(self.cmd("python -m unittest tools.test_task_status"), "allow")
        self.assertEqual(self.cmd("cd /c/solid-carbide-worktrees/T-166 && python -m unittest tools.test_task_status"),
                         "allow")

    def test_allowed_7_a_python_heredoc_editing_code_files(self):
        for path in ["tools/task_status.py", "tools/goal_agent/goal_file.py"]:
            c = (f"cd /c/solid-carbide-worktrees/T-170 && python - <<'EOF'\nfrom pathlib import Path\n"
                 f"p = Path('{path}')\nt = p.read_text(encoding='utf-8')\n"
                 "t = t.replace('def status(', 'def current_status(')\n"
                 "p.write_text(t, encoding='utf-8')\nprint('status renamed')\nEOF")
            with self.subTest(path=path):
                self.assertEqual(self.cmd(c), "allow")

    def test_allowed_8_read_only_status_and_git_in_a_task_folder(self):
        self.assertEqual(self.cmd(
            "python /c/solid-carbide-game/tools/task_status.py T-166; "
            "git -C /c/solid-carbide-worktrees/T-166 log --oneline -3; "
            "git -C /c/solid-carbide-worktrees/T-166 diff --name-only"), "allow")

    def test_still_refused_writes_of_a_guarded_header_line(self):
        for c in ["printf 'status: done\\n' >> tasks/T-1-x.md",
                  "printf 'notes\\nlead: Tools\\n' >> tasks/T-1-x.md",
                  'echo "qa_rounds: 1" >> tasks/T-1-x.md',
                  "Write-Output 'Status : done' >> tasks/T-1-x.md",
                  "printf '%s\\n' \"$NOTE\" >> tasks/T-1-x.md  # status",
                  "printf 'x\\012status: done' >> tasks/T-1-x.md",
                  "cat >> tasks/T-1-x.md <<EOF\n$X status\nEOF",
                  "echo hi >> $(ls tasks/T-1*) # status",
                  "sed -i 's/^lead:.*/lead: Tools/' tasks/T-1-x.md",
                  "cp /tmp/T-1-status-done.md tasks/T-1-x.md",
                  "cd /c/w/T-1 && cp /tmp/x.md tasks/T-1-x.md && echo status",
                  "Set-Content -Path:tasks/T-1-x.md -Value 'lead: Tools'",
                  'cd /c/w/T-1 && test -z "$(sed -i \'s/status: open/status: done/\' tasks/T-1-x.md)"',
                  "for f in tasks/T-1*.md; do sed -i 's/status: open/status: done/' $f; done",
                  "python -c \"import pathlib; p=pathlib.Path('tasks/T-1-x.md'); "
                  "p.write_text(p.read_text().replace('qa_rounds: 0','qa_rounds: 1'))\"",
                  "cd /c/w/T-1 && python - <<'EOF'\nimport pathlib\np = pathlib.Path('tasks/T-1-x.md')\n"
                  "p.write_text(p.read_text().replace('status: open', 'status: done'))\nEOF",
                  "cd $T && sed -i 's/status: open/status: done/' T-1-x.md",
                  "python tools/fix_status.py tasks/T-1-x.md"]:
            with self.subTest(c=c):
                self.assertEqual(self.cmd(c), "deny")


class Git(Base):
    """The commit check and the script's own check, in a real git repository."""

    def setUp(self):
        super().setUp()
        self.repo = self.root / "repo"
        (self.repo / "tasks").mkdir(parents=True)
        self.git("init", "-q")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "t")
        self.git("config", "commit.gpgsign", "false")
        tb.TASKS_DIR = self.repo / "tasks"
        self.file = tb.TASKS_DIR / "T-001-test.md"
        self.file.write_bytes(task("T-001", status="in-progress", qa_rounds=0, notes="Done.").encode())
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "start")

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.repo), *args], capture_output=True, text=True, check=True).stdout

    def commit(self, command="git commit -am x"):
        return decide(gate.pre_shell, {"command": command}, str(self.repo))

    def hand_edit(self, old, new):
        self.file.write_bytes(self.file.read_bytes().replace(old.encode(), new.encode()))

    def move(self, new):
        return ts.move("T-001", new, folders={})

    def test_no_ledger_no_check(self):
        self.hand_edit("qa_rounds: 0", "qa_rounds: 1")
        self.assertEqual(self.commit(), "allow")

    def test_gap_l_a_file_edited_by_any_tool_cannot_be_committed(self):
        self.move("in-qa")   # creates the ledger
        self.git("commit", "-qam", "to qa")
        self.hand_edit("qa_rounds: 0", "qa_rounds: 1")   # as `python fix.py` or a mv would
        self.assertEqual(self.commit(), "deny")
        self.assertEqual(self.commit("cd " + str(self.repo) + " && git commit -m x"), "deny")
        self.git("add", "-A")
        self.hand_edit("qa_rounds: 1", "qa_rounds: 0")   # the staged version is still the bad one
        self.assertEqual(self.commit("git commit -m x"), "deny")
        self.git("checkout", "HEAD", "--", "tasks")
        self.assertEqual(self.commit(), "allow")

    def test_t181_a_header_hand_edit_is_still_refused_at_commit(self):
        # the shell check now lets more commands through; the ledger check still stops a hand-edited header
        self.move("in-qa")
        self.git("commit", "-qam", "to qa")
        self.hand_edit("status: in-qa", "status: done")   # as a script the shell check can't read would
        self.assertEqual(self.commit('git add tasks && git commit -q -m "T-001: notes"'), "deny")
        self.git("checkout", "HEAD", "--", "tasks")
        self.hand_edit("Done.", "Done.\n- 2026-10-18, Project Lead: notes.")   # a result note is fine
        self.assertEqual(self.commit('git add tasks && git commit -q -m "T-001: notes"'), "allow")

    def test_a_script_move_can_be_committed(self):
        self.move("in-qa")
        self.assertEqual(self.commit(), "allow")
        self.git("commit", "-qam", "to qa")
        self.file.write_bytes(self.file.read_bytes().replace(b"(QA: pass / fail)", b"(QA: pass)"))
        self.move("done")   # qa_rounds 0 -> 1 by the script
        self.assertEqual(self.commit(), "allow")

    def test_gap_m_the_t139_case_hand_edit_then_the_script(self):
        self.move("in-qa")
        self.hand_edit("qa_rounds: 0", "qa_rounds: 1")
        self.file.write_bytes(self.file.read_bytes().replace(b"(QA: pass / fail)", b"(QA: pass)"))
        with self.assertRaises(ts.Refused) as ctx:
            self.move("done")   # would have made it 2 after a single QA check
        self.assertIn("by hand", str(ctx.exception))
        self.assertIn(b"qa_rounds: 1", self.file.read_bytes())   # untouched

    def test_gap_n_a_hand_edit_of_status_then_a_claim(self):
        self.move("in-qa")
        self.hand_edit("status: in-qa", "status: done")
        with self.assertRaises(ts.Refused):
            ts.claim("T-001", "Tools", folders={})

    def test_a_new_task_in_its_starting_state_is_fine_but_not_a_finished_one(self):
        self.move("in-qa")
        new = tb.TASKS_DIR / "T-002-new.md"
        new.write_bytes(task("T-002", status="blocked").encode())
        self.assertEqual(self.commit(), "allow")
        new.write_bytes(task("T-002", status="done").encode())
        self.assertEqual(self.commit(), "deny")

    def test_committed_states_are_trusted(self):
        self.move("in-qa")
        self.git("commit", "-qam", "to qa")
        self.git("checkout", "-q", "HEAD~1", "--", "tasks")   # an older committed state comes back
        self.assertEqual(self.commit(), "allow")


class LedgerUnits(unittest.TestCase):
    def test_state_sees_every_line_and_ignores_the_comment_block(self):
        text = "---\nid: T-1\nstatus: open\nqa_rounds: 0\nlead:\nStatus : done\n---\n<!--\nstatus: x\n-->\n"
        self.assertEqual(gl.state(text), (("status", "open"), ("qa_rounds", "0"), ("status", "done")))
        self.assertIsNone(gl.state("no header"))

    def test_initial_states(self):
        self.assertTrue(gl.is_initial((("status", "open"), ("qa_rounds", "0"))))
        self.assertFalse(gl.is_initial((("status", "done"), ("qa_rounds", "0"))))
        self.assertFalse(gl.is_initial((("status", "open"), ("status", "done"))))


if __name__ == "__main__":
    unittest.main()
