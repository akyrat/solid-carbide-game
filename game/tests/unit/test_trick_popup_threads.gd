extends GutTest
## The popup pictures baked on worker threads (T-480) never come out empty (found in T-566's merge run).
## The baking font's text server data is made lazily, on its first get_rids(). When the first bakes of a
## fresh font ran on several worker threads at once, one could find no data yet (get_rids() empty), its
## bake failed, and a null texture was kept for the rest of the process, so every later popup with that
## text drew nothing and errored. The font's data is now made on the main thread before any worker starts,
## and a failed bake is never kept.

const Art := preload("res://scripts/hud/trick_popup_art.gd")
const BrokenArt := preload("res://scripts/hud/combo_broken_art.gd")

const TEXTS := ["FULL 360!", "AIR 180!", "LONG DRIFT!", "GRIND!", "ALT DRIFT! +0.5", "TRENDING!", "FULL 360! +1.0", "AIR 360!"]


func before_each() -> void:
	Art.clear_cache()
	BrokenArt.clear_cache()


func after_all() -> void:
	Art.clear_cache()
	BrokenArt.clear_cache()


func test_the_font_data_exists_before_any_worker_bakes() -> void:
	Art._font = null
	Art._warm_shared()
	assert_gt(Art._font.get_rids().size(), 0, "the font has its data once warmed on the main thread")


func test_first_bakes_of_a_fresh_font_on_many_threads_are_never_empty() -> void:
	# Repeated with a fresh font each time, since the old failure was a race between workers.
	for r in 20:
		Art.clear_cache()
		Art._font = null
		for t in TEXTS:
			for heat in Art.HEAT_STEPS:
				Art.request("%s %d" % [t, r], "normal", heat)
		Art.finish_requests()
		for t in TEXTS:
			for heat in Art.HEAT_STEPS:
				var key: String = Art.texture_key("%s %d" % [t, r], "normal", heat)
				assert_true(Art.is_cached(key), "round %d: %s at heat %d was baked" % [r, t, heat])
				var tex: ImageTexture = Art.texture("%s %d" % [t, r], "normal", heat)
				assert_not_null(tex, "round %d: %s at heat %d has a picture" % [r, t, heat])
	Art._font = null


func test_a_failed_bake_is_not_kept() -> void:
	# A worker whose bake failed hands back no image: it is dropped, and drawing bakes it again.
	var key: String = Art.texture_key("NOPE!", "normal", 0)
	Art._mutex.lock()
	Art._pending[key] = true
	Art._baked[key] = [null, true]
	Art._mutex.unlock()
	Art.poll()
	assert_false(Art.is_cached(key), "a failed bake leaves nothing in the cache")
	assert_not_null(Art.texture("NOPE!", "normal", 0), "it is baked again when drawn")
