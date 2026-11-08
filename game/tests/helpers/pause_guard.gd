class_name PauseGuard
extends RefCounted
## Task T-589: a test must leave the tree unpaused. GUT's timed waits (wait_seconds, the time
## limits of wait_for_signal and wait_until) count in a node that stops while get_tree().paused is
## true, so a test that ends with the tree paused (an open level-up screen, a pause screen, a
## gift's overlay) makes the next timed wait, in any later script of the same process, wait for
## ever: the shard never ends. pre_run.gd calls watch() once; after every test (after after_each
## and the autofree) a paused tree is unpaused, so nothing later hangs, and the test is named;
## post_run.gd then fails the run.

static var leaks: Array[String] = []
static var _gut = null


static func watch(gut) -> void:
	_gut = gut
	leaks.clear()
	gut.end_test.connect(_on_end_test)


static func _on_end_test() -> void:
	check(_gut.get_tree(), _test_name())


## Unpauses `tree` and records `test_name` when the tree is paused. True when it was.
static func check(tree: SceneTree, test_name: String) -> bool:
	if not tree.paused:
		return false
	tree.paused = false
	leaks.append(test_name)
	if _gut != null:
		_gut.logger.error("T-589: %s left the tree paused (unpaused now). End every test unpaused: get_tree().paused = false in after_each." % test_name)
	return true


static func _test_name() -> String:
	var s = _gut.get_current_script_object()
	var t = _gut.get_current_test_object()
	var path := "?"
	if s != null and s.get_script() != null:
		path = s.get_script().resource_path
	return "%s:%s" % [path, t.name if t != null else "?"]
