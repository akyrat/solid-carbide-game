extends RefCounted
## Dev settings for playtests (task T-045): read from res://data/playtest.json,
## a dictionary of independent keys (other tasks add their own). Never shown
## to the player: no UI, no text (HUD and menus, Decisions: such settings go
## under an internal dev flag players never see).
##
## This file reads the run timer setting:
##
##   "run_timer_start": { "enabled": true, "minutes": 1, "seconds": 30 }
##
## With `enabled` true, every run starts with that time on the clock instead
## of 8:00 (RunState.RUN_SECONDS): the run is fast-forwarded, as if the
## missing time had already passed (RunState.time_elapsed() counts from 8:00),
## so the boss time comes at 1:00 left as usual. `enabled` false, or a missing
## or invalid value, means a normal 8:00 run.
##
## `enabled` (the static flag below) switches every dev setting off at once:
## the GUT suite's pre-run hook (tests/pre_run_hook.gd) does that, so tests
## run the game as players get it whatever playtest.json says; a test that
## checks a dev setting turns it back on and passes its own file.

const FILE := "playtest"
const RUN_SECONDS := 480.0

## False: every dev setting is off (tests).
static var enabled := true
## The settings file read (res://data/<file>.json); tests point it at their own.
static var file := FILE


## The time on the clock when a run starts, in seconds: the run timer setting
## when it is on, otherwise RUN_SECONDS. Clamped to 1 s .. RUN_SECONDS.
static func run_start_time_left(from_file: String = "") -> float:
	if not enabled:
		return RUN_SECONDS
	var r := GameData.load_file(from_file if from_file != "" else file)
	if not r.ok or typeof(r.data) != TYPE_DICTIONARY:
		return RUN_SECONDS
	var s = r.data.get("run_timer_start", null)
	if typeof(s) != TYPE_DICTIONARY or not bool(s.get("enabled", false)):
		return RUN_SECONDS
	var total := float(s.get("minutes", 0)) * 60.0 + float(s.get("seconds", 0))
	if total <= 0.0:
		return RUN_SECONDS
	return clampf(total, 1.0, RUN_SECONDS)
