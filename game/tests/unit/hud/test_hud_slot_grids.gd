extends GutTest
## Task T-523: the weapon grid and the power-up grid, 3 slots each with tier pips (HUD and
## menus, Decisions, "Weapon and power-up slots").

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const WeaponsScript := preload("res://scripts/weapons/weapons.gd")


func before_each() -> void:
	WeaponsScript.all_weapons_override = 0


func after_each() -> void:
	WeaponsScript.all_weapons_override = -1


func _hud_with_rack() -> Array:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var hud: Hud = HUD_SCENE.instantiate()
	sv.add_child(hud)
	var rack: Node = WeaponsScript.new()
	add_child_autofree(rack)
	hud.bind_weapons(rack)
	var state := RunState.new()
	hud.bind(state)
	return [hud, rack, state]


func test_weapon_grid_has_three_slots_filled_in_order() -> void:
	var h := _hud_with_rack()
	var grid: SlotGrid = h[0].weapon_icons.weapon_grid
	assert_eq(grid.slots.size(), 3, "always three frames")
	assert_eq(grid.pips(0), [0, 0], "empty frames before any weapon")
	h[1].upgrade("gun")
	assert_gt(grid.pips(0)[0], 0, "the gun fills the first")
	assert_eq(grid.pips(1), [0, 0], "the others are empty frames")
	h[1].upgrade("wiper")
	assert_true(grid.pips(1)[0] > 0)
	assert_eq(grid.pips(2), [0, 0])
	h[1].upgrade("molotov")
	assert_eq(h[0].weapon_icons.order, ["gun", "wiper", "molotov"])
	for i in 3:
		assert_true(grid.pips(i)[0] > 0, "slot %d filled" % i)
	h[1].upgrade("flamethrower")
	assert_eq(grid.slots.size(), 3, "a fourth weapon adds no slot")
	assert_eq(h[0].weapon_icons.rows.size(), 3)


func test_power_up_grid_has_three_slots_filled_as_collected() -> void:
	var h := _hud_with_rack()
	var icons: WeaponIcons = h[0].weapon_icons
	var state: RunState = h[2]
	var grid := icons.power_grid
	assert_eq(grid.slots.size(), 3)
	for i in 3:
		assert_eq(grid.pips(i), [0, 0], "empty at the start")
	state.grant_power_up("jump")
	state.grant_power_up("rev_charge")
	assert_eq(icons.power_order, ["jump", "rev_charge"])
	assert_gt(grid.pips(0)[0], 0)
	assert_gt(grid.pips(1)[0], 0)
	assert_eq(grid.pips(2), [0, 0])
	assert_eq(icons.power_rows.keys().size(), 2)
	state.grant_power_up("bouncy_bumpers")
	assert_gt(grid.pips(2)[0], 0)
	state.start_run()
	assert_eq(icons.power_order, [], "a new run empties the slots")
	assert_eq(grid.pips(0), [0, 0])


func test_pips_are_the_max_tier_from_data_and_filled_to_the_tier() -> void:
	var h := _hud_with_rack()
	var rack: Node = h[1]
	var grid: SlotGrid = h[0].weapon_icons.weapon_grid
	rack.get_weapon("gun").set_tier(2)
	assert_eq(grid.pips(0), [rack.get_weapon("gun").max_tier(), 2])
	var pu := PowerUpData.new()
	var state: RunState = h[2]
	state.grant_power_up("jump")
	var pgrid: SlotGrid = h[0].weapon_icons.power_grid
	assert_eq(pgrid.pips(0), [pu.max_tier("jump"), 1])
	state.grant_power_up("jump")
	assert_eq(pgrid.pips(0), [pu.max_tier("jump"), mini(2, pu.max_tier("jump"))])


func test_the_piece_has_one_size_and_holds_both_grids() -> void:
	var h := _hud_with_rack()
	var icons: WeaponIcons = h[0].weapon_icons
	var size_before := icons.size
	assert_eq(size_before, WeaponIcons.piece_size())
	h[1].upgrade("wiper")
	h[2].grant_power_up("jump")
	assert_eq(icons.size, size_before, "filling slots never resizes the piece")
	var rect := icons.get_global_rect()
	assert_true(rect.encloses(icons.weapon_grid.get_global_rect()))
	assert_true(rect.encloses(icons.power_grid.get_global_rect()))
	assert_gt(icons.power_grid.position.x, icons.weapon_grid.size.x, "beside the weapon column")


func test_hud_size_slider_scales_both_grids() -> void:
	var h := _hud_with_rack()
	var hud: Hud = h[0]
	var icons: WeaponIcons = hud.weapon_icons
	var full := icons.get_global_rect().size
	hud.set_hud_size(50.0)
	var half := icons.get_global_rect().size
	assert_lt(half.x, full.x)
	assert_almost_eq(icons.power_grid.get_global_rect().size.x / icons.weapon_grid.get_global_rect().size.x,
		1.0, 0.01, "both scale together")


func test_the_layout_editor_places_the_piece_with_both_grids() -> void:
	var h := _hud_with_rack()
	var hud: Hud = h[0]
	var icons: WeaponIcons = hud.weapon_icons
	var area := hud.root.size
	var entry := HudLayout.entry_for(Vector2(300, 200), icons.size, area)
	hud.set_layout({"weapon_icons": entry})
	var at := hud.piece_rect("weapon_icons")
	assert_almost_eq(at.position, Vector2(300, 200), Vector2(0.5, 0.5))
	assert_eq(at.size, WeaponIcons.piece_size())
	assert_almost_eq(icons.power_grid.get_global_rect().position.x - icons.get_global_rect().position.x,
		WeaponIcons.power_column_x() * hud.hud_scale(), 0.5, "the grids moved together")
