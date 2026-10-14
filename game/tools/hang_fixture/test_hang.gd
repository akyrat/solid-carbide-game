extends GutTest
## Hangs forever on purpose (task T-137). Lives outside tests/ so the normal suite never runs it;
## only tools/check_time_limit.sh points GUT at this folder.

func test_hangs_forever() -> void:
	while true:
		OS.delay_msec(100)
