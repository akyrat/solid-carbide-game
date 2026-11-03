extends GutTest
## Task T-365: each garage row shows an icon beside it: game/art/garage/<key>.png when it exists,
## else a placeholder drawn in code; nearest filter; layout, buying and text unchanged.

var _dir := ProjectSettings.globalize_path("user://t365_icons")
var _saved := GarageScreen.icon_dir


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(_dir)
	GarageScreen.icon_dir = _dir
	PlayerProgress.path = RunPaths.file("test_progress_t365.json")
	DirAccess.remove_absolute(PlayerProgress.path)


func after_each() -> void:
	GarageScreen.icon_dir = _saved
	DirAccess.remove_absolute(_dir + "/acceleration.png")
	DirAccess.remove_absolute(PlayerProgress.path)
	TestSave.restore_progress()


func _screen() -> GarageScreen:
	var p := PlayerProgress.new()
	p.coins = 500
	var s := GarageScreen.new()
	s.progress = p
	add_child_autofree(s)
	return s


func test_placeholder_when_file_missing() -> void:
	var s := _screen()
	for id in GarageData.UPGRADES:
		var icon: TextureRect = s.find_child("Row_" + id, true, false).find_child("Icon", true, false)
		assert_not_null(icon, id)
		assert_eq(icon.texture.get_width(), 16)
		assert_eq(icon.texture.get_image().get_pixel(0, 0).a, 0.0, "corner transparent: placeholder")


func test_placeholder_has_no_greenbull_green() -> void:
	var img := GarageScreen.placeholder_texture().get_image()
	for y in 16:
		for x in 16:
			var c := img.get_pixel(x, y)
			assert_false(c.g > c.r + 0.2 and c.g > c.b + 0.2, "no green")


func test_file_is_picked_up() -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 0, 1))
	img.save_png(_dir + "/acceleration.png")
	var s := _screen()
	var icon: TextureRect = s.find_child("Row_acceleration", true, false).find_child("Icon", true, false)
	assert_eq(icon.texture.get_image().get_pixel(0, 0), Color(1, 0, 0, 1))
	var other: TextureRect = s.find_child("Row_car_health", true, false).find_child("Icon", true, false)
	assert_eq(other.texture.get_image().get_pixel(0, 0).a, 0.0)


func test_nearest_and_size() -> void:
	var s := _screen()
	for id in GarageData.UPGRADES:
		var icon: TextureRect = s.find_child("Row_" + id, true, false).find_child("Icon", true, false)
		assert_eq(icon.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
		assert_eq(icon.custom_minimum_size, Vector2(48, 48))


func test_buying_and_text_unchanged() -> void:
	var s := _screen()
	var row: Dictionary = s.rows["acceleration"]
	assert_eq(row.level.text, "Level 0")
	row.buy.pressed.emit()
	assert_eq(row.level.text, "Level 1")


## T-511: an export has only the imported texture, so the real icons must come through ResourceLoader.
func test_res_icons_load_as_imported_textures() -> void:
	GarageScreen.icon_dir = "res://art/garage"
	for id in GarageData.UPGRADES:
		var path := "res://art/garage/%s.png" % id
		if not ResourceLoader.exists(path):
			continue
		var tex := GarageScreen.icon_texture(id)
		assert_eq(tex.resource_path, path, "%s comes from the imported resource" % id)
