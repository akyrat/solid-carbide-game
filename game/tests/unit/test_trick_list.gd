extends GutTest
## Task T-382: the trick list scene: seven tricks, names from the text file, illustrations
## from one fixed path per trick, a code-made placeholder while a file is missing.

const TMP := "user://t382_tricks"
var list: TrickList


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(TMP)


func after_each() -> void:
	for f in DirAccess.get_files_at(TMP):
		DirAccess.remove_absolute(TMP + "/" + f)
	DirAccess.remove_absolute(TMP)


func _make(folder: String) -> TrickList:
	var l: TrickList = load("res://scenes/menu/trick_list.tscn").instantiate()
	l.illustration_folder = folder
	add_child_autofree(l)
	return l


func test_default_folder() -> void:
	list = _make(TrickList.DEFAULT_FOLDER)
	assert_eq(list.illustration_folder, "res://art/tutorial/tricks")
	assert_eq(list.illustration_path("airtime"), "res://art/tutorial/tricks/airtime.png")


func test_seven_tricks_with_names_from_the_file() -> void:
	list = _make(TMP)
	assert_eq(list.labels.size(), 7)
	for id in TrickList.TRICK_IDS:
		var expected: String = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/tutorial_text.json"))["trick"][id]
		assert_ne(expected, "")
		assert_eq(list.labels[id].text, expected, id)


func test_placeholder_when_files_missing() -> void:
	list = _make(TMP)
	for id in TrickList.TRICK_IDS:
		assert_true(list.is_placeholder(id), id)
		var tex: Texture2D = list.pictures[id].texture
		assert_not_null(tex)
		assert_eq(Vector2i(tex.get_size()), TrickList.ILLUSTRATION_SIZE)
		var c := tex.get_image().get_pixel(5, 5)
		# Not Greenbull's light green or yellow.
		assert_false(c.g > c.r and c.g > c.b and c.g > 0.6, "not light green")
		assert_false(c.r > 0.8 and c.g > 0.8 and c.b < 0.5, "not yellow")


func test_png_at_the_fixed_path_is_loaded() -> void:
	var img := Image.create(64, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 0, 1))
	img.save_png(TMP + "/airtime.png")
	list = _make(TMP)
	assert_false(list.is_placeholder("airtime"))
	assert_true(list.is_placeholder("three_sixty"))
	var got: Image = list.pictures["airtime"].texture.get_image()
	assert_eq(got.get_pixel(3, 3), Color(1, 0, 0, 1))


func test_illustration_is_drawn_nearest_at_a_whole_scale() -> void:
	list = _make(TMP)
	var pic: TextureRect = list.pictures["airtime"]
	assert_eq(pic.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_eq(pic.custom_minimum_size, Vector2(TrickList.ILLUSTRATION_SIZE * TrickList.SCALE))
