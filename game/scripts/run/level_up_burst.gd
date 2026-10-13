extends CPUParticles2D
## The level-up effect (task T-112): a single burst of pixel particles around
## the car when the player levels up (Visual style, Decisions, "Level-up
## effect"). The run scene (scripts/run/run.gd) adds it, keeps it on the drawn
## car and calls play() on the run state's `level_up` signal.
##
## Every look and tuning setting (texture, count, speed, spread, lifetime,
## shrink) lives in scenes/run/level_up_burst.tscn, not here, so the art task
## (T-074) can swap the particles and retune them without touching code.
## Pixel rules: nearest-neighbour filtering, and no alpha fade (the colour
## ramp and colour stay fully opaque); particles shrink instead.
##
## The scene sets process_mode to Always, so the burst keeps playing while the
## run is paused for the level-up screen (T-052).


## Starts one burst from the start. Calling it again while a burst plays
## restarts it, so several level-ups in the same moment give one burst.
func play() -> void:
	restart()


## Whether a burst is playing now.
func is_playing() -> bool:
	return emitting
