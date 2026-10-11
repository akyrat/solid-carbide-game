extends GutTest
## Task T-092: the challenge popup. The run state's score signal shows T-048's
## text with the likes gained near the car, rising and fading.

const RunScene := preload("res://scenes/run/run.tscn")


func test_score_signal_shows_text_with_likes_near_car_then_goes() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var tp: Node2D = run.trick_popups
	var before: int = tp.popups().size()
	run.state.score.emit(25.0, "c-1")
	var shown: Array = tp.popups()
	assert_eq(shown.size(), before + 1)
	var pop = shown.back()
	assert_eq(pop.text, "Trending! +25 Likes")
	assert_lt(pop.position.distance_to(run.car_sprite.position), 80.0, "near the car")
	var start: Vector2 = pop.position
	pop.advance(0.5)
	assert_lt(pop.position.y, start.y, "rises")
	pop.advance(0.6)
	await get_tree().process_frame
	assert_false(is_instance_valid(pop), "goes away")


func test_completed_challenge_in_the_run_shows_the_popup() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	# Challenges are off in the MVP (T-097): the signal stands in for one.
	run.map.challenge_completed.emit(str(run.map.layout.challenges[0].id))
	var texts: Array = run.trick_popups.popups().map(func(x) -> String: return x.text)
	assert_eq(texts.size(), 1)
	assert_true(texts[0].begins_with("Trending! +"), texts[0])
	assert_true(texts[0].ends_with(" Likes"))
