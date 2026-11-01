extends SceneTree
## T-480: prints a hash of each sample popup image (golden values for the pixel test).
const Art := preload("res://scripts/hud/trick_popup_art.gd")
const BrokenArt := preload("res://scripts/hud/combo_broken_art.gd")
func _init() -> void:
	for c in [["FULL 360! +226K", "normal", 3, 2, true, false], ["FULL 360! +5,938", "normal", 2, 0, true, true], ["THREAD THE NEEDLE! +12.0K", "normal", 0, 0, true, false], ["ALT DRIFT! +0.5", "normal", 1, 0, false, false], ["LONG DRIFT!", "small", 0, 0, false, false], ["LONG DRIFT! +12.0K", "small", 3, 5, true, false], ["TRENDING! +120 SUBS!", "normal", 3, 1, false, false], ["AIR 180!", "normal", 2, 0, false, false]]:
		var img: Image = Art.bake(c[0], c[1], c[2], c[3], c[4], c[5])
		print("TRICK|%s|%s|%d|%d|%s|%s|%d|%d|%d" % [c[0], c[1], c[2], c[3], c[4], c[5], img.get_width(), img.get_height(), hash(img.get_data())])
	for c in [["COMBO BROKEN!", "normal", false], ["COMBO BROKEN!", "normal", true], ["TIME'S UP!", "small", true]]:
		var imgs: Array = BrokenArt.bake(c[0], c[1], c[2])
		print("BROKEN|%s|%s|%s|%d|%d|%d|%d" % [c[0], c[1], c[2], imgs[0].get_width(), imgs[0].get_height(), hash(imgs[0].get_data()), hash(imgs[1].get_data())])
	quit()
