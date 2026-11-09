extends GutTest
## Task T-612 (Enemies, Decisions, "The kaiju is animated"): the kaiju's walk,
## windup and death animations, read from res://data/enemies.json's
## "kaiju_animations"; the windup in place of the yellow rings; the death that
## plays before the coins and the win, with the kaiju still, harmless and no
## longer a target; the timer reaching 0:00 or a wreck during the death keeping
## the win; the frames swappable through the data.

const RunScene := preload("res://scenes/run/run.tscn")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const SpriteScript := preload("res://scripts/enemies/kaiju_sprite.gd")
const MeteorsScript := preload("res://scripts/enemies/kaiju_meteors.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
const DeathFx := preload("res://scripts/enemies/kaiju_death_fx.gd")
const DT := 0.02

var run: Node2D
var boss: Node
var data: EnemyData
var anims: Dictionary


func before_each() -> void:
	SpriteScript.config_override = {}
	KaijuBossScript.playtest_override = -1.0
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	boss = run.kaiju_boss
	boss.rng.seed = 612
	boss.meteors.rng.seed = 612
	run.minions.enabled = false
	run.car.use_keyboard = false
	data = EnemyData.new()
	anims = data.kaiju_animations()


func after_each() -> void:
	get_tree().paused = false
	SpriteScript.config_override = {}
	KaijuBossScript.playtest_override = -2.0
	FlameScript.playtest_override = -1


func _car_units() -> Vector2:
	return run.car.position / 16.0


func _kaiju_near(distance: float) -> Node:
	for i in 64:
		var p := _car_units() + Vector2.RIGHT.rotated(TAU * i / 64.0) * distance
		if boss.is_free_spot(p):
			return boss.appear_at(p)
	fail_test("no free spot %.1f units from the car" % distance)
	return null


func _to_boss_time() -> void:
	run.state.advance(RunState.RUN_SECONDS - RunState.BOSS_TIME_LEFT - run.state.time_elapsed() + 0.01)


## Steps the boss `seconds` (physics steps of DT).
func _boss_steps(seconds: float) -> void:
	for i in int(round(seconds / DT)):
		boss.step(DT)


func _frame_seconds(anim: String) -> float:
	return 1.0 / float(anims[anim].fps)


# ---- The data ----------------------------------------------------------------------------------

func test_the_data_names_three_animations_with_sheets_counts_and_speeds() -> void:
	for a in ["walk", "windup", "death"]:
		assert_true(anims.has(a), a)
		assert_gt(int(anims[a].frames), 0, a)
		assert_gt(float(anims[a].fps), 0.0, a)
		for d in ["e", "se", "s", "ne", "n"]:
			var tex := SpriteScript.anim_sheet(a, d)
			assert_not_null(tex, "%s %s" % [a, d])
			assert_eq(tex.get_height(), int(anims.frame_size), "%s %s" % [a, d])
			assert_gte(tex.get_width() / int(anims.frame_size), int(anims[a].frames), "the sheet holds its frames: %s %s" % [a, d])
	assert_true(bool(anims.walk.loop), "the walk loops")
	assert_false(bool(anims.windup.loop), "the windup plays once")
	assert_false(bool(anims.death.loop), "the death plays once")
	var end: Dictionary = anims.death_end
	var whole := float(anims.death.frames) / float(anims.death.fps) + float(end.hold_seconds) \
			+ float(end.crack_seconds) + float(end.explosion_seconds)
	assert_almost_eq(data.kaiju_death_seconds(), whole, 0.0001,
		"quick tuning 1: the death lasts frames / fps, then the hold, the cracks and the explosion")
	assert_almost_eq(SpriteScript.death_length(), whole, 0.0001, "the sprite reads the same")
	assert_gt(float(end.explosion_radius_px), 0.0)


# ---- T-613: the final death art for east and the explosion's art ---------------------------------

func test_the_east_death_is_the_final_art_and_the_other_directions_keep_the_placeholders() -> void:
	var east := SpriteScript.anim_sheet("death", "e")
	assert_eq(east.resource_path, String(anims.death.sheets.e), "east is the final art")
	assert_eq(east.get_width(), 16 * int(anims.frame_size), "16 frames, the data's count")
	for d in ["se", "s", "ne", "n"]:
		assert_eq(SpriteScript.anim_sheet("death", d).resource_path, String(anims.death.sheet) % d, d)
	assert_eq(SpriteScript.anim_sheet("walk", "e").resource_path, String(anims.walk.sheet) % "e", "the walk is unchanged")


func test_the_explosion_is_one_sheet_of_art_used_by_every_direction() -> void:
	var tex := SpriteScript.explosion_sheet()
	assert_not_null(tex)
	assert_eq(tex.get_height(), int(anims.frame_size))
	assert_eq(tex.get_width() / int(anims.frame_size), int(anims.explosion.frames))
	var n := int(anims.explosion.frames)
	assert_eq(SpriteScript.explosion_frame_at(0.0, n), 0)
	assert_eq(SpriteScript.explosion_frame_at(0.5, n), n / 2)
	assert_eq(SpriteScript.explosion_frame_at(1.0, n), n - 1, "never past the last frame")


func test_the_frame_format_is_written_for_the_art_task() -> void:
	var doc := FileAccess.get_file_as_string("res://docs/enemies/kaiju.md")
	assert_true(doc.contains("The kaiju's animations"), "a section on the format")
	for word in ["kaiju_animations", "frame_size", "feet", "frames", "fps", "kaiju_windup_", "kaiju_death_", "T-613"]:
		assert_true(doc.contains(word), word)


# ---- Walk ----------------------------------------------------------------------------------------

func test_the_walk_advances_through_the_facing_directions_frames_and_loops() -> void:
	var k := _kaiju_near(12.0)
	var s: Node2D = k.sprite
	s.facing = Vector2.RIGHT
	s.walk_seconds = 0.0
	var cur: Dictionary = s.current_frame()
	assert_eq(cur.anim, "walk")
	assert_eq(cur.texture, load(String(anims.walk.sheet) % "e"), "east's walk sheet")
	assert_false(cur.mirrored)
	var seen := []
	var n := int(anims.walk.frames)
	for i in n + 1:
		seen.append(s.current_frame().frame)
		s.advance(_frame_seconds("walk"))
	var expected := []
	for i in n:
		expected.append(i)
	expected.append(0)
	assert_eq_deep(seen, expected)
	s.facing = Vector2.DOWN
	assert_eq(s.current_frame().texture, load(String(anims.walk.sheet) % "s"), "south's sheet")
	s.facing = Vector2.LEFT
	assert_eq(s.current_frame().texture, load(String(anims.walk.sheet) % "e"), "west mirrors east")
	assert_true(s.current_frame().mirrored)


func test_the_walk_frame_stands_still_while_paused() -> void:
	var k := _kaiju_near(12.0)
	var s: Node2D = k.sprite
	await wait_process_frames(3)
	assert_gt(s.walk_seconds, 0.0, "it walks")
	get_tree().paused = true
	var at: float = s.walk_seconds
	var frame: int = s.current_frame().frame
	await wait_process_frames(30)
	assert_eq(s.walk_seconds, at, "paused: the walk stands still")
	assert_eq(s.current_frame().frame, frame)
	get_tree().paused = false
	await wait_process_frames(5)
	assert_gt(s.walk_seconds, at, "unpaused: it walks on")


# ---- Windup -------------------------------------------------------------------------------------

func test_the_windup_plays_during_the_meteor_windup_then_the_walk_again() -> void:
	var k := _kaiju_near(14.0)
	boss.enabled = false
	var s: Node2D = k.sprite
	var met: Node = boss.meteors
	met.start_attack()
	boss.update_drawing()
	assert_true(s.winding_up)
	var cur: Dictionary = s.current_frame()
	assert_eq(cur.anim, "windup")
	assert_eq(s.animation(), "windup")
	var dir: String = SpriteScript.SHEETS[SpriteScript.compass_index(s.facing)][0]
	assert_eq(cur.texture, load(String(anims.windup.sheet) % dir), "the facing direction's windup sheet")
	assert_eq(cur.frame, 0, "from its first frame")
	s.advance(_frame_seconds("windup") * 2.5)
	assert_eq(s.current_frame().frame, 2)
	s.advance(10.0)
	assert_eq(s.current_frame().frame, int(anims.windup.frames) - 1, "held on its last frame")
	for i in int(ceil(float(data.meteor_attack().windup_seconds) / DT)) + 1:
		met.step(DT)
	assert_false(met.is_winding_up())
	boss.update_drawing()
	assert_false(s.winding_up)
	assert_eq(s.current_frame().anim, "walk", "walking again after the windup")
	met.start_attack()
	boss.update_drawing()
	assert_eq(s.current_frame().frame, 0, "the next windup starts from its first frame")


func test_the_yellow_rings_are_gone() -> void:
	assert_false((MeteorsScript as Script).get_script_constant_map().has("WINDUP_COLOR"), "no ring colour")
	var src := FileAccess.get_file_as_string("res://scripts/enemies/kaiju_meteors.gd")
	assert_false(src.contains("draw_arc(head"), "no rings drawn above the head")
	assert_false(src.contains("a.is_winding_up()"), "the sky drawing does nothing for a windup")


# ---- Death --------------------------------------------------------------------------------------

func test_the_death_plays_once_with_the_kaiju_still_harmless_and_untargeted() -> void:
	_to_boss_time()
	var k: Node = boss.kaiju
	k.set_position_units(_car_units() + Vector2(2.3, 0.0))  # touching the car
	assert_true(k.touches_car(_car_units(), run.car.rotation))
	var s: Node2D = k.sprite
	var hearts: float = run.state.health
	run.state.invulnerable_left = 0.0
	k.take_damage(1e9)
	assert_true(k.is_dead())
	assert_true(boss.is_kaiju_dying())
	assert_almost_eq(boss.death_left, data.kaiju_death_seconds(), 0.0001, "for the data's length")
	assert_eq(s.animation(), "death")
	var cur: Dictionary = s.current_frame()
	assert_eq(cur.anim, "death")
	var dir: String = SpriteScript.SHEETS[SpriteScript.compass_index(s.facing)][0]
	assert_eq(cur.texture, SpriteScript.anim_sheet("death", dir))
	assert_eq(cur.frame, 0)
	assert_false(k.is_in_group("enemies"), "no weapon finds it in the group")
	assert_false(get_tree().get_nodes_in_group("enemies").has(k))
	await wait_physics_frames(2)
	assert_eq(k.collision_layer, 0, "its body left the enemies' layer")
	var q := PhysicsPointQueryParameters2D.new()
	q.position = k.global_position
	q.collision_mask = 4
	q.collide_with_bodies = true
	var hits: Array = k.get_world_2d().direct_space_state.intersect_point(q)
	assert_false(hits.any(func(h) -> bool: return h.collider == k), "a projectile's query does not find it")
	var at: Vector2 = k.position
	var half := data.kaiju_death_seconds() * 0.5
	run.state.invulnerable_left = 0.0
	_boss_steps(half - 4 * DT)
	assert_true(is_instance_valid(k), "still there while the death plays")
	assert_eq(k.position, at, "it does not move")
	assert_eq(run.state.health, hearts, "no contact damage")
	s.death_seconds = 0.0
	s.advance(_frame_seconds("death") * 3.5)
	assert_eq(s.current_frame().frame, 3, "the death's frames go on")
	s.advance(100.0)
	assert_eq(s.current_frame().frame, int(anims.death.frames) - 1, "plays once: held on its last frame")
	assert_almost_eq(s.shadow_alpha(), 0.0, 0.0001, "the shadow has faded with it")
	_boss_steps(half + 4 * DT)
	assert_false(boss.is_kaiju_dying(), "the death is over")
	await wait_process_frames(2)
	assert_false(is_instance_valid(k), "then it disappears")


func test_the_shadow_stays_while_it_lies_and_fades_with_the_explosion() -> void:
	var k := _kaiju_near(12.0)
	var s: Node2D = k.sprite
	assert_eq(s.shadow_alpha(), 1.0)
	k.take_damage(1e9)
	var end: Dictionary = anims.death_end
	var before_explosion := SpriteScript.death_fall_length() + float(end.hold_seconds) + float(end.crack_seconds)
	s.advance(before_explosion - 0.05)
	assert_eq(s.shadow_alpha(), 1.0, "full while it lies there and cracks")
	s.advance(0.05 + float(end.explosion_seconds) * 0.5)
	assert_almost_eq(s.shadow_alpha(), 0.5, 0.02, "fading with the explosion")
	s.advance(float(end.explosion_seconds))
	assert_eq(s.shadow_alpha(), 0.0, "gone with it")


# ---- Quick tuning 1: the longer death ---------------------------------------------------------

func test_the_death_goes_fall_hold_crack_explode_then_gone_in_that_order() -> void:
	var end: Dictionary = anims.death_end
	var fall := SpriteScript.death_fall_length()
	assert_almost_eq(fall, float(anims.death.frames) / float(anims.death.fps), 0.0001)
	var edges := [0.0, fall, fall + float(end.hold_seconds), fall + float(end.hold_seconds) + float(end.crack_seconds),
			SpriteScript.death_length()]
	var names := ["fall", "hold", "crack", "explode"]
	for i in names.size():
		var mid: float = (edges[i] + edges[i + 1]) * 0.5
		var ph: Dictionary = SpriteScript.death_phase_at(mid)
		assert_eq(ph.phase, names[i], "at %.2f s" % mid)
		assert_almost_eq(ph.progress, 0.5, 0.001, names[i])
	assert_eq(SpriteScript.death_phase_at(SpriteScript.death_length() + 0.01).phase, "gone")
	# On the kaiju: the death animation's last frame holds through the hold and the cracks.
	var k := _kaiju_near(12.0)
	var s: Node2D = k.sprite
	k.take_damage(1e9)
	s.advance(fall + float(end.hold_seconds) + float(end.crack_seconds) * 0.5)
	assert_eq(s.death_phase().phase, "crack")
	assert_eq(s.current_frame().frame, int(anims.death.frames) - 1, "lying in the last frame")


func test_the_kaiju_lies_on_the_ground_in_the_last_death_frame() -> void:
	for d in ["e", "s"]:
		var tex := SpriteScript.anim_sheet("death", d)
		var img := tex.get_image()
		var fs := int(anims.frame_size)
		var first := img.get_region(Rect2i(0, 0, fs, fs)).get_used_rect()
		var last := img.get_region(Rect2i((int(anims.death.frames) - 1) * fs, 0, fs, fs)).get_used_rect()
		assert_gt(last.size.x, 0, d)
		# T-613: east is the PixelLab art, which topples onto its back with its legs and plates up, so it is
		# lower than standing but not as flat as the placeholders.
		assert_lt(last.size.y, first.size.y * (0.9 if d == "e" else 0.75), "%s: flat on the ground, lower than standing" % d)
		assert_almost_eq(float(last.end.y), float(anims.feet[1]) + 2.0, 3.0, "%s: resting on the ground line" % d)


func test_the_cracks_follow_the_body_and_the_green_consumes_it() -> void:
	var tex := SpriteScript.anim_sheet("death", "e")
	var info: Dictionary = DeathFx.frame_info(tex, int(anims.death.frames) - 1, int(anims.frame_size))
	assert_false(info.is_empty())
	assert_gt(info.cracks.size(), 3, "several cracks")
	var img := tex.get_image()
	var off := (int(anims.death.frames) - 1) * int(anims.frame_size)
	for pts in info.cracks:
		for q in pts:
			assert_gt(img.get_pixel(off + int(q.x), int(q.y)).a, 0.5, "every crack point is on the body")
	assert_eq(DeathFx.consume_alpha(0.0), 0.0)
	assert_lt(DeathFx.consume_alpha(0.5), DeathFx.consume_alpha(0.9), "the green grows")
	assert_eq(DeathFx.consume_alpha(1.0), 1.0, "consumed at the end")
	assert_eq(DeathFx.crack_reveal(0, 9, 0.0), 0.0)
	assert_eq(DeathFx.crack_reveal(8, 9, 1.0), 1.0, "every crack has spread by the end")


func test_the_greens_and_the_explosion_are_not_greenbulls_and_follow_the_theme() -> void:
	var greenbull := [Color8(104, 220, 96), Color8(247, 208, 52), Color8(12, 76, 44)]
	for c in DeathFx.CRACK_COLOURS + DeathFx.EXPLOSION_COLOURS:
		for g in greenbull:
			var d := Vector3(c.r - g.r, c.g - g.g, c.b - g.b).length() * 255.0
			assert_gt(d, 40.0, "%s is not Greenbull's %s (rule 6)" % [c, g])
	assert_eq(DeathFx.CRACK_GREEN, Color8(140, 224, 26), "the minions' spill green")
	assert_true(DeathFx.EXPLOSION_COLOURS.has(Color8(184, 46, 255)), "the HUD's neon purple for the kaiju")


func test_every_phase_draws_without_errors() -> void:
	var k := _kaiju_near(12.0)
	boss.enabled = false
	var s: Node2D = k.sprite
	k.take_damage(1e9)
	var end: Dictionary = anims.death_end
	var fall := SpriteScript.death_fall_length()
	for t in [0.1, fall + 0.1, fall + float(end.hold_seconds) + 0.5,
			fall + float(end.hold_seconds) + float(end.crack_seconds) + 0.05,
			fall + float(end.hold_seconds) + float(end.crack_seconds) + 0.6]:
		s.death_seconds = t
		s.queue_redraw()
		await wait_process_frames(1)
	assert_true(true, "drawn through every phase")
	assert_almost_eq(s.explosion_radius_px(), float(end.explosion_radius_px), 0.0001)


func test_the_coins_and_the_win_come_only_when_the_death_has_played() -> void:
	_to_boss_time()
	var k: Node = boss.kaiju
	var ended := []
	run.state.run_ended.connect(func(r: String, c: int) -> void: ended.append([r, c]))
	var defeated := []
	boss.kaiju_defeated.connect(func(n: int) -> void: defeated.append(n))
	run.state.add_coins(2)
	k.take_damage(1e9)
	var length := data.kaiju_death_seconds()
	_boss_steps(length - 3 * DT)
	assert_true(boss.is_kaiju_dying())
	assert_eq(SpriteScript.death_phase_at(length - boss.death_left).phase, "explode",
		"quick tuning 1: the win waits for the explosion's end")
	assert_eq(run.state.coins, 2, "no coins yet")
	assert_eq(run.state.result, "", "no win yet")
	assert_true(run.state.is_running())
	assert_eq(ended.size(), 0)
	assert_eq(defeated.size(), 0)
	_boss_steps(5 * DT)
	var kc := data.kaiju_coins_on_defeat()
	assert_eq(defeated, [kc], "defeated once the death has played")
	assert_eq(run.state.coins, 2 + kc, "its coins added")
	assert_eq(run.state.result, "win")
	assert_eq_deep(ended, [["win", 2 + kc]])


func test_the_win_stands_when_the_timer_reaches_zero_during_the_death() -> void:
	_to_boss_time()
	var k: Node = boss.kaiju
	run.state.time_left = 0.3
	k.take_damage(1e9)
	run.state.advance(1.0)
	assert_eq(run.state.time_left, 0.0, "the clock holds at 0:00")
	assert_false(run.state.is_timed_out(), "no time's up while the kaiju dies")
	assert_eq(run.state.result, "")
	assert_false(get_tree().paused)
	_boss_steps(data.kaiju_death_seconds() + 3 * DT)
	assert_eq(run.state.result, "win", "the kaiju was killed in time: a win")
	assert_eq(run.state.coins, data.kaiju_coins_on_defeat())


func test_a_kill_on_the_step_the_clock_runs_out_still_plays_the_death_and_wins() -> void:
	_to_boss_time()
	var k: Node = boss.kaiju
	run.state.time_left = 0.01
	run.state.advance(0.02)
	assert_true(run.state.is_timed_out(), "the time's up started")
	k.take_damage(1e9)  # on the same step: a tie goes to the player (T-413)
	assert_false(run.state.is_timed_out(), "called off")
	assert_false(get_tree().paused, "the death can play")
	assert_true(run.state.is_running())
	_boss_steps(data.kaiju_death_seconds() + 3 * DT)
	assert_eq(run.state.result, "win")


func test_a_wreck_during_the_death_does_not_lose_the_win() -> void:
	_to_boss_time()
	var k: Node = boss.kaiju
	k.take_damage(1e9)
	run.state.invulnerable_left = 0.0
	run.state.damage_car(run.state.health + 10.0)
	assert_true(run.state.is_wrecked())
	run.state.advance(run.state.wreck_seconds + 1.0)
	assert_eq(run.state.result, "", "the wreck waits for the death")
	_boss_steps(data.kaiju_death_seconds() + 3 * DT)
	assert_eq(run.state.result, "win")


# ---- Swappable frames ------------------------------------------------------------------------

func test_the_frames_come_from_the_files_and_counts_in_the_data() -> void:
	var k := _kaiju_near(12.0)
	var s: Node2D = k.sprite
	s.facing = Vector2.RIGHT
	s.walk_seconds = 0.0
	var other: Dictionary = anims.duplicate(true)
	# Another file for the walk: the windup's sheet, 3 frames at 4 a second.
	other.walk = {"sheet": String(anims.windup.sheet), "frames": 3, "fps": 4.0, "loop": true}
	SpriteScript.config_override = other
	assert_eq(s.current_frame().texture, load(String(anims.windup.sheet) % "e"), "the file named in the data")
	var seen := []
	for i in 4:
		seen.append(s.current_frame().frame)
		s.advance(0.25)
	assert_eq_deep(seen, [0, 1, 2, 0])
	other.walk.frames = 2
	s.walk_seconds = 0.0
	seen = []
	for i in 3:
		seen.append(s.current_frame().frame)
		s.advance(0.25)
	assert_eq_deep(seen, [0, 1, 0])
	# The death's length follows its count too.
	other.death = {"sheet": String(anims.death.sheet), "frames": 4, "fps": 8.0, "loop": false}
	assert_almost_eq(SpriteScript.death_fall_length(), 0.5, 0.0001)
	other.death_end = {"hold_seconds": 0.0, "crack_seconds": 0.0, "explosion_seconds": 0.0}
	assert_almost_eq(SpriteScript.death_length(), 0.5, 0.0001, "and its end's numbers too")
	assert_almost_eq(EnemyData.animation_seconds(other.death), 0.5, 0.0001)
	# A missing windup sheet falls back to the walk.
	other.windup = {"sheet": "res://art/kaiju/missing_%s.png", "frames": 6, "fps": 6.0, "loop": false}
	s.set_winding_up(true)
	assert_eq(s.current_frame().anim, "walk")
