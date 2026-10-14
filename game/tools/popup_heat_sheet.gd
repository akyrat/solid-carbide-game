extends SceneTree
## Bakes the trick popups at every combo heat step (task T-133) and saves one
## sheet: a column per heat step (plain, x2, x3, x4 up), on a dark and on a
## light background, enlarged with nearest neighbour. No renderer needed.
##
## Usage (normally through tools/popup_heat_sheet.sh):
##   godot --headless --path game -s res://tools/popup_heat_sheet.gd -- --out=C:/abs/sheet.png [--scale=3] [--frame=0]

const Art := preload("res://scripts/hud/trick_popup_art.gd")
const ROWS := [
	["ALT DRIFT! +0.5", "normal"],
	["LONG DRIFT! +0.05", "small"],
	["Trending! +120 Likes", "normal"],
]
const BACKGROUNDS := [Color8(30, 30, 38), Color8(196, 190, 176)]
const GAP := 6


func _initialize() -> void:
	var out := ""
	var scale := 3
	var frame := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--scale="):
			scale = int(a.substr(8))
		elif a.begins_with("--frame="):
			frame = int(a.substr(8))
	if out == "":
		printerr("popup_heat_sheet.gd: need --out=<file.png>")
		quit(1)
		return
	var sheet := build(scale, frame)
	var err := sheet.save_png(out)
	print("popup_heat_sheet.gd: saved %s" % out if err == OK else "popup_heat_sheet.gd: save failed")
	quit(0 if err == OK else 4)


static func build(scale: int, frame: int) -> Image:
	var imgs := []
	var col_w := []
	var row_h := []
	for h in Art.HEAT_STEPS:
		col_w.append(0)
	for r in ROWS.size():
		row_h.append(0)
		var line := []
		for h in Art.HEAT_STEPS:
			var img: Image = Art.bake(ROWS[r][0], ROWS[r][1], h, frame)
			line.append(img)
			col_w[h] = maxi(col_w[h], img.get_width())
			row_h[r] = maxi(row_h[r], img.get_height())
		imgs.append(line)
	var w := GAP
	for c in col_w:
		w += c + GAP
	var block_h := GAP
	for rh in row_h:
		block_h += rh + GAP
	var small := Image.create_empty(w, block_h * BACKGROUNDS.size(), false, Image.FORMAT_RGBA8)
	for b in BACKGROUNDS.size():
		small.fill_rect(Rect2i(0, b * block_h, w, block_h), BACKGROUNDS[b])
		var y := b * block_h + GAP
		for r in ROWS.size():
			var x := GAP
			for h in Art.HEAT_STEPS:
				var img: Image = imgs[r][h]
				var at := Vector2i(x + (col_w[h] - img.get_width()) / 2, y + (row_h[r] - img.get_height()) / 2)
				small.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
				x += col_w[h] + GAP
			y += row_h[r] + GAP
	small.resize(w * scale, small.get_height() * scale, Image.INTERPOLATE_NEAREST)
	return small
