extends GutTest
## Task T-494: every screen scales with the window by the HUD's rule (HUD and menus, Content,
## "The HUD scales with the window"): one scale, the smaller of width / 1152 and height / 648,
## each screen laid out at the window's size divided by it. The shared helper is UiScale.

const RecapScene := preload("res://scenes/menu/recap_screen.tscn")
const MainMenuScene := preload("res://scenes/menu/main_menu.tscn")
const PauseScript := preload("res://scripts/ui/pause_screen.gd")
const LevelUpScript := preload("res://scripts/ui/level_up_screen.gd")
const PowerUpScript := preload("res://scripts/ui/power_up_screen.gd")
const EPS := 0.0005

## The window sizes the ticket names, with the expected scale.
const EXPECTED := {
	Vector2(1280, 720): 1280.0 / 1152.0,
	Vector2(1920, 1080): 1920.0 / 1152.0,
	Vector2(3840, 2160): 3840.0 / 1152.0,
	Vector2(3440, 1440): 1440.0 / 648.0,  # ultrawide: the height decides
	Vector2(1152, 648): 1.0,
}


func _window(size: Vector2) -> SubViewport:
	var sv := SubViewport.new()
	sv.size = Vector2i(size)
	add_child_autofree(sv)
	return sv


func test_fit_gives_the_expected_scale_at_each_size() -> void:
	for view in EXPECTED:
		assert_almost_eq(UiScale.fit(view), EXPECTED[view], EPS, "scale at %s" % view)


func test_fit_with_another_base() -> void:
	assert_almost_eq(UiScale.fit(Vector2(2560, 1440), Vector2(1280, 720)), 2.0, EPS)
	assert_almost_eq(UiScale.fit(Vector2.ZERO), 0.01, EPS, "never zero")


func test_the_hud_uses_the_same_rule() -> void:
	for view in EXPECTED:
		assert_almost_eq(Hud.scale_for(view, 100.0), UiScale.fit(view), EPS)
	assert_eq(Hud.LAYOUT_SIZE, UiScale.BASE)


func test_a_kept_screen_fills_the_window_at_each_size() -> void:
	for view in EXPECTED:
		var sv := _window(view)
		var c := Control.new()
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		UiScale.keep(c)
		var child := Button.new()
		child.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		c.add_child(child)
		sv.add_child(c)
		var s: float = EXPECTED[view]
		assert_almost_eq(c.scale.x, s, EPS, "scale at %s" % view)
		assert_almost_eq(UiScale.scale_of(c), s, EPS)
		assert_almost_eq(c.size.x * s, view.x, 0.01, "fills the width at %s" % view)
		assert_almost_eq(c.size.y * s, view.y, 0.01, "fills the height at %s" % view)
		assert_eq(c.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "pixel art stays hard-edged")


func test_a_kept_screen_follows_a_window_resize() -> void:
	var sv := _window(Vector2(1280, 720))
	var c := Control.new()
	UiScale.keep(c)
	sv.add_child(c)
	assert_almost_eq(c.scale.x, EXPECTED[Vector2(1280, 720)], EPS)
	sv.size = Vector2i(3840, 2160)
	assert_almost_eq(c.scale.x, EXPECTED[Vector2(3840, 2160)], EPS, "rescaled on size_changed")
	assert_almost_eq(c.size.x, 1152.0, 0.01)
	sv.remove_child(c)
	sv.size = Vector2i(1920, 1080)  # no longer listening once out of the tree
	assert_almost_eq(c.scale.x, EXPECTED[Vector2(3840, 2160)], EPS)
	c.free()


func test_the_main_menu_uses_it() -> void:
	var sv := _window(Vector2(3840, 2160))
	var menu: Control = MainMenuScene.instantiate()
	sv.add_child(menu)
	assert_almost_eq(menu.scale.x, EXPECTED[Vector2(3840, 2160)], EPS)
	assert_almost_eq(menu.size.x, 1152.0, 0.01)
	menu.queue_free()


func test_the_recap_uses_it() -> void:
	var sv := _window(Vector2(1920, 1080))
	var recap: Control = RecapScene.instantiate()
	sv.add_child(recap)
	assert_almost_eq(recap.scale.x, EXPECTED[Vector2(1920, 1080)], EPS)
	recap.queue_free()


func test_the_overlay_screens_use_it() -> void:
	# The pause (with its trick list and HUD layout editor), level-up and power-up screens all
	# keep their root Control scaled; the source is read so no run has to be built here.
	for script in [PauseScript, LevelUpScript, PowerUpScript]:
		var src: String = (script as GDScript).source_code
		assert_true(src.contains("UiScale.keep(_root)"), "%s scales its root" % script.resource_path)


func test_the_pause_screen_root_is_scaled_in_a_window() -> void:
	var sv := _window(Vector2(3440, 1440))
	var target := _FakeTarget.new()
	sv.add_child(target)
	var pause: CanvasLayer = PauseScript.new()
	pause.setup(target)
	sv.add_child(pause)
	var root: Control = pause._root
	assert_almost_eq(root.scale.x, EXPECTED[Vector2(3440, 1440)], EPS)
	assert_almost_eq(root.size.y, 648.0, 0.01)
	pause.free()


func test_the_layout_editor_maps_its_own_pixels_to_the_screen() -> void:
	var e := HudLayoutEditor.new()
	add_child_autofree(e)
	e.scale = Vector2(2, 2)
	e.position = Vector2.ZERO
	assert_eq(e._to_screen(Vector2(10, 20)), Vector2(20, 40))


## The least a pause screen needs from its target (a zoom; no HUD, so no layout editor).
class _FakeTarget:
	extends Node
	var zoom := 1.0
	var hud = null
