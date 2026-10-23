extends GutTest
## Task T-276: the car's weapons as a column of icons beside the health bar:
## one per weapon the car has, in the order taken, "x{n}" beside the icon once
## the weapon is above tier 1, in the comic font. The health bar is 72 x 320
## with the heart under it and no "Car Health" label.

const RUN := preload("res://scenes/run/run.tscn")
const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")


func before_each() -> void:
	WeaponsScript.all_weapons_override = 0


func after_each() -> void:
	WeaponsScript.all_weapons_override = -1


func _run() -> Node2D:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var r: Node2D = RUN.instantiate()
	sv.add_child(r)
	return r


func _icon_order(icons: WeaponIcons) -> Array:
	var ids: Array = icons.order.duplicate()
	ids.sort_custom(func(a, b) -> bool: return icons.rows[a].icon.position.y < icons.rows[b].icon.position.y)
	return ids


func test_only_the_gun_at_the_start() -> void:
	var r := _run()
	var icons: WeaponIcons = r.hud.weapon_icons
	assert_eq(icons.order, ["gun"])
	assert_false(icons.rows["gun"].count.visible, "no count at tier 1")


func test_icon_per_weapon_in_the_order_taken() -> void:
	var r := _run()
	var icons: WeaponIcons = r.hud.weapon_icons
	r.weapons.upgrade("wiper")
	r.weapons.upgrade("flamethrower")
	r.weapons.upgrade("molotov")
	assert_eq(icons.order, ["gun", "wiper", "flamethrower", "molotov"])
	assert_eq(_icon_order(icons), icons.order, "the rows run top to bottom in that order")
	for id: String in icons.order:
		assert_eq(icons.rows[id].icon.texture, LevelUpScreen.weapon_image(id), "%s uses its card picture" % id)
		assert_eq(icons.rows[id].icon.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_false(icons.rows.has("underglow"), "a weapon the car does not have has no icon")


func test_count_shows_the_tier_and_updates() -> void:
	var r := _run()
	var icons: WeaponIcons = r.hud.weapon_icons
	r.weapons.upgrade("gun")
	assert_true(icons.rows["gun"].count.visible)
	assert_eq(icons.rows["gun"].count.text, "x2")
	r.weapons.upgrade("gun")
	assert_eq(icons.rows["gun"].count.text, "x3")
	r.weapons.gun.set_tier(8)
	assert_eq(icons.rows["gun"].count.text, "x8")
	assert_eq(icons.order, ["gun"], "an upgrade does not add a second icon")
	assert_eq(WeaponIcons.count_text(5), "x5")


func test_count_uses_the_comic_font_with_a_black_outline() -> void:
	var r := _run()
	r.weapons.upgrade("gun")
	var count: Label = r.hud.weapon_icons.rows["gun"].count
	assert_eq(count.get_theme_font("font"), Hud.comic_font())
	assert_eq(count.get_theme_color("font_outline_color"), Color(0, 0, 0))
	assert_gt(count.get_theme_constant("outline_size"), 0)


func test_a_new_run_empties_the_column_back_to_the_gun() -> void:
	var r := _run()
	var icons: WeaponIcons = r.hud.weapon_icons
	r.weapons.upgrade("wiper")
	r.weapons.upgrade("gun")
	r.weapons.reset_for_run()
	assert_eq(icons.order, ["gun"])
	assert_eq(icons.rows.keys(), ["gun"])
	await get_tree().process_frame
	assert_false(icons.get_children().any(func(c: Node) -> bool: return c.is_queued_for_deletion() == false and c.name.contains("wiper")), "the wiper's nodes are gone")


func test_all_five_weapons_at_tier_eight_fit_beside_the_bar() -> void:
	var r := _run()
	var hud: Hud = r.hud
	for id: String in r.weapons.weapons:
		r.weapons.get_weapon(id).set_tier(8)
	var bar := hud.health_bar.get_global_rect()
	var icons := hud.weapon_icons
	assert_eq(icons.order.size(), 5)
	var box := Rect2()
	for id: String in icons.order:
		var row: Dictionary = icons.rows[id]
		var rect: Rect2 = row.icon.get_global_rect().merge(Rect2(row.count.get_global_position(), row.count.size))
		box = rect if box.size == Vector2.ZERO else box.merge(rect)
	assert_gte(box.position.x, bar.end.x, "right of the bar")
	assert_lte(box.end.y, bar.end.y, "no taller than the bar")
	assert_lt(box.end.x, 1152.0 * 0.25, "in the left quarter, clear of the middle")
	assert_false(box.intersects(hud.timer_label.get_global_rect()), "clear of the timer")


func test_health_bar_size_and_heart() -> void:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	assert_eq(hud.health_bar.size, Vector2(72, 320))
	assert_eq(hud.health_bar.fill_mode, ProgressBar.FILL_BOTTOM_TO_TOP)
	assert_null(hud.get("health_label"), "the Car Health label is gone")
	assert_eq(hud.health_heart.texture, hud.heart.texture, "the likes bar's heart picture")
	assert_eq(hud.weapon_icons.order, [], "a bare HUD shows no weapons")
