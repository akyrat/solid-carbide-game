class_name TextLayout
extends RefCounted
## The text layout capture (task T-524), the Godot half. Used by screen_gallery.gd with --text-layout:
## it finds every visible node that shows player-facing text, describes it as a row (rect in
## screenshot pixels, the font, size, colours, outline, shadow, alignment, wrap... as Godot resolves
## them, theme overrides and theme defaults included), and blanks it for the "_blank" picture without
## moving anything: Labels and RichTextLabels get visible_characters = 0, Buttons and LineEdits get
## their text colours (and outline) made transparent, so layout, containers and sizes stay the same.
## screen_gallery.py adds the text inventory match, the templates and the coverage (text_layout.py).

const H_ALIGN := ["left", "center", "right", "fill"]
const V_ALIGN := ["top", "center", "bottom", "fill"]
const WRAP := ["off", "arbitrary", "word", "word_smart"]
const OVERRUN := ["no_trimming", "trim_char", "trim_word", "trim_ellipsis", "trim_word_ellipsis", "trim_ellipsis_force", "trim_word_ellipsis_force"]
## The colour names a Button or LineEdit draws its text in, by state (all made transparent to blank).
const BUTTON_COLORS := ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color",
		"font_hover_pressed_color", "font_outline_color"]
const LINE_EDIT_COLORS := ["font_color", "font_uneditable_color", "font_selected_color", "font_placeholder_color", "font_outline_color"]
const PopupTextScript := preload("res://scripts/hud/trick_popups.gd")


## The nodes under `root` that show text now: visible in the tree, something to show, not fully transparent.
static func find_nodes(root: Node, win: Vector2) -> Array:
	var out: Array = []
	_walk(root, win, out)
	return out


static func _walk(n: Node, win: Vector2, out: Array) -> void:
	if n is CanvasItem and (n as CanvasItem).is_visible_in_tree():
		if n is Control and _shows_text(n):
			if _alpha(n) > 0.02 and _bbox(n as Control, win).intersects(Rect2(Vector2.ZERO, win)):
				out.append(n)
		elif n is PopupTextScript.PopupText or n is ClockDigits:
			out.append(n)
	elif n is TimeUpScreen and (n as TimeUpScreen).visible and (n as TimeUpScreen).headline != "":
		out.append(n)
	for ch in n.get_children():
		_walk(ch, win, out)


static func _shows_text(c: Control) -> bool:
	if c is Label:
		return (c as Label).text != "" and (c as Label).visible_characters != 0
	if c is RichTextLabel:
		return (c as RichTextLabel).get_parsed_text() != ""
	if c is Button:
		return (c as Button).text != ""
	if c is LineEdit:
		return (c as LineEdit).text != "" or (c as LineEdit).placeholder_text != ""
	return false


## The product of the modulate alphas up the tree and the node's own self-modulate.
static func _alpha(n: CanvasItem) -> float:
	var a := n.self_modulate.a
	var p: Node = n
	while p is CanvasItem:
		a *= (p as CanvasItem).modulate.a
		p = p.get_parent()
	return a


static func _bbox(c: Control, win: Vector2) -> Rect2:
	var xf := c.get_global_transform_with_canvas()
	var final := c.get_tree().root.get_final_transform()
	return _aabb(final * xf, Rect2(Vector2.ZERO, c.size))


static func _aabb(xf: Transform2D, r: Rect2) -> Rect2:
	var pts := [xf * r.position, xf * Vector2(r.end.x, r.position.y), xf * r.end, xf * Vector2(r.position.x, r.end.y)]
	var lo: Vector2 = pts[0]
	var hi: Vector2 = pts[0]
	for p in pts:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	return Rect2(lo, hi - lo)


## Player-facing text drawn another way than a Control: the key pad's letters (draw_string).
static func not_capturable(root: Node, screen: String) -> Array:
	var out: Array = []
	_find_drawn(root, screen, out)
	return out


static func _find_drawn(n: Node, screen: String, out: Array) -> void:
	if n is KeyPad and (n as KeyPad).is_visible_in_tree():
		var kp := n as KeyPad
		var xf := kp.get_tree().root.get_final_transform() * kp.get_global_transform_with_canvas()
		out.append({"screen": screen, "path": String(kp.get_path()).replace("/root/", ""), "source": "scripts/menu/key_pad.gd (draw_string)",
			"text": "W A S D", "rect": _r(_aabb(xf, Rect2(Vector2.ZERO, kp.size))), "why": "the letters are drawn with draw_string on the tutorial clips' key pad, not by a Label"})
	for ch in n.get_children():
		_find_drawn(ch, screen, out)


# ---- rows -----------------------------------------------------------------------------

static func row(n: Node, screen: String) -> Dictionary:
	if n is PopupTextScript.PopupText:
		return _popup_row(n, screen)
	if n is ClockDigits:
		return _clock_row(n as ClockDigits, screen)
	if n is TimeUpScreen:
		return _time_up_row(n as TimeUpScreen, screen)
	var c := n as Control
	var xf := c.get_tree().root.get_final_transform() * c.get_global_transform_with_canvas()
	var box := _aabb(xf, Rect2(Vector2.ZERO, c.size))
	var sx := xf.x.length()
	var sy := xf.y.length()
	var d := {"screen": screen, "path": String(c.get_path()).replace("/root/", ""), "class": c.get_class(),
		"script_class": _script_class(c), "rect": _r(box), "scale": [_f(sx), _f(sy)],
		"rotation_deg": _f(rad_to_deg(xf.get_rotation())), "alpha": _f(_alpha(c)), "kind": "control"}
	var font: Font
	var fsize := 16
	if c is Label:
		var l := c as Label
		d["text"] = l.text
		var ls := l.label_settings
		d["font_origin"] = "label_settings" if ls != null else ("override" if l.has_theme_font_override("font") else "theme")
		font = ls.font if ls != null and ls.font != null else l.get_theme_font("font")
		fsize = ls.font_size if ls != null else l.get_theme_font_size("font_size")
		d["color"] = (ls.font_color if ls != null else l.get_theme_color("font_color")).to_html(true)
		d["outline_size"] = ls.outline_size if ls != null else l.get_theme_constant("outline_size")
		d["outline_color"] = (ls.outline_color if ls != null else l.get_theme_color("font_outline_color")).to_html(true)
		d["shadow_color"] = (ls.shadow_color if ls != null else l.get_theme_color("font_shadow_color")).to_html(true)
		var so: Vector2 = ls.shadow_offset if ls != null else Vector2(l.get_theme_constant("shadow_offset_x"), l.get_theme_constant("shadow_offset_y"))
		d["shadow_offset"] = [_f(so.x), _f(so.y)]
		d["shadow_outline_size"] = ls.shadow_size if ls != null else l.get_theme_constant("shadow_outline_size")
		d["line_spacing"] = ls.line_spacing if ls != null else l.get_theme_constant("line_spacing")
		d["h_align"] = H_ALIGN[l.horizontal_alignment]
		d["v_align"] = V_ALIGN[l.vertical_alignment]
		d["autowrap"] = WRAP[l.autowrap_mode]
		d["uppercase"] = l.uppercase
		d["max_lines"] = l.max_lines_visible
		d["overrun"] = OVERRUN[l.text_overrun_behavior]
		d["clip"] = l.clip_text
		d["line_count"] = l.get_line_count()
		d["padding"] = _padding(l.get_theme_stylebox("normal"))
	elif c is RichTextLabel:
		var r := c as RichTextLabel
		d["text"] = r.get_parsed_text()
		d["bbcode"] = r.text if r.bbcode_enabled else ""
		d["font_origin"] = "override" if r.has_theme_font_override("normal_font") else "theme"
		font = r.get_theme_font("normal_font")
		fsize = r.get_theme_font_size("normal_font_size")
		d["color"] = r.get_theme_color("default_color").to_html(true)
		d["outline_size"] = r.get_theme_constant("outline_size")
		d["outline_color"] = r.get_theme_color("font_outline_color").to_html(true)
		d["shadow_color"] = r.get_theme_color("font_shadow_color").to_html(true)
		d["shadow_offset"] = [r.get_theme_constant("shadow_offset_x"), r.get_theme_constant("shadow_offset_y")]
		d["shadow_outline_size"] = r.get_theme_constant("shadow_outline_size")
		d["line_spacing"] = r.get_theme_constant("line_separation")
		d["h_align"] = "left"  # set inside the bbcode ([center], [right]) when it is not
		d["v_align"] = "top"
		d["autowrap"] = WRAP[r.autowrap_mode]
		d["uppercase"] = false
		d["max_lines"] = -1
		d["overrun"] = OVERRUN[r.text_overrun_behavior]
		d["clip"] = r.clip_contents
		d["line_count"] = r.get_line_count()
		d["padding"] = _padding(r.get_theme_stylebox("normal"))
	elif c is Button:
		var b := c as Button
		d["text"] = b.text
		d["font_origin"] = "override" if b.has_theme_font_override("font") else "theme"
		font = b.get_theme_font("font")
		fsize = b.get_theme_font_size("font_size")
		var mode := b.get_draw_mode()
		var cname := "font_color"
		var sname := "normal"
		match mode:
			BaseButton.DRAW_PRESSED:
				cname = "font_pressed_color"
				sname = "pressed"
			BaseButton.DRAW_HOVER:
				cname = "font_hover_color"
				sname = "hover"
			BaseButton.DRAW_DISABLED:
				cname = "font_disabled_color"
				sname = "disabled"
			BaseButton.DRAW_HOVER_PRESSED:
				cname = "font_hover_pressed_color"
				sname = "hover_pressed"
			_:
				if b.has_focus():
					cname = "font_focus_color"
		d["color"] = b.get_theme_color(cname).to_html(true)
		d["color_state"] = cname
		d["outline_size"] = b.get_theme_constant("outline_size")
		d["outline_color"] = b.get_theme_color("font_outline_color").to_html(true)
		d["shadow_color"] = "#00000000"
		d["shadow_offset"] = [0, 0]
		d["shadow_outline_size"] = 0
		d["line_spacing"] = b.get_theme_constant("line_spacing")
		d["h_align"] = H_ALIGN[b.alignment]
		d["v_align"] = "center"
		d["autowrap"] = WRAP[b.autowrap_mode]
		d["uppercase"] = false
		d["max_lines"] = -1
		d["overrun"] = OVERRUN[b.text_overrun_behavior]
		d["clip"] = b.clip_text
		d["has_icon"] = b.icon != null
		d["padding"] = _padding(b.get_theme_stylebox(sname))
	else:
		var e := c as LineEdit
		d["text"] = e.text if e.text != "" else e.placeholder_text
		d["is_placeholder"] = e.text == ""
		d["font_origin"] = "override" if e.has_theme_font_override("font") else "theme"
		font = e.get_theme_font("font")
		fsize = e.get_theme_font_size("font_size")
		d["color"] = e.get_theme_color("font_color" if e.text != "" else "font_placeholder_color").to_html(true)
		d["outline_size"] = e.get_theme_constant("outline_size")
		d["outline_color"] = e.get_theme_color("font_outline_color").to_html(true)
		d["shadow_color"] = "#00000000"
		d["shadow_offset"] = [0, 0]
		d["shadow_outline_size"] = 0
		d["line_spacing"] = 0
		d["h_align"] = H_ALIGN[e.alignment]
		d["v_align"] = "center"
		d["autowrap"] = "off"
		d["uppercase"] = false
		d["max_lines"] = 1
		d["overrun"] = "no_trimming"
		d["clip"] = true
		d["padding"] = _padding(e.get_theme_stylebox("normal"))
	d["font_size"] = fsize
	d["font_px"] = _f(fsize * sy)
	d.merge(_font_info(font))
	return d


static func _popup_row(p: Node, screen: String) -> Dictionary:
	# A trick popup is a baked picture (TrickPopupArt): the text is part of the bubble's image.
	var px := 2.0  # TrickPopups.PIXEL_SCALE
	var full := Vector2.ZERO  # the whole picture, rings and flames included
	var bubble := Vector2.ZERO  # the plain bubble the text sits in
	if p.broken:
		var halves: Array = p.broken_textures()
		bubble = Vector2(halves[0].get_size().x + halves[1].get_size().x, halves[0].get_size().y) * px
		full = bubble
	else:
		full = Vector2((p.texture() as Texture2D).get_size()) * px
		bubble = p.size()
	var xf: Transform2D = p.get_tree().root.get_final_transform() * p.get_global_transform_with_canvas()
	var box := _aabb(xf, Rect2(-bubble / 2.0, bubble))
	var art_box := _aabb(xf, Rect2(-full / 2.0, full))
	var style: String = TrickPopupArt.style_for(p.font_size)
	var st: Dictionary = TrickPopupArt.STYLES[style]
	var font := HudStyle.new_comic_font()
	var d := {"screen": screen, "path": String(p.get_path()).replace("/root/", ""), "class": "PopupText",
		"script_class": "TrickPopups.PopupText", "kind": "baked_popup", "rect": _r(box), "art_rect": _r(art_box), "scale": [_f(xf.x.length()), _f(xf.y.length())],
		"rotation_deg": _f(rad_to_deg(xf.get_rotation())), "alpha": _f(_alpha_of_popup(p)), "text": p.text,
		"font_origin": "baked", "font_size": int(st["font_px"]), "font_px": _f(int(st["font_px"]) * px * xf.y.length()),
		"color": "#000000ff", "outline_size": 0, "outline_color": "#00000000", "shadow_color": "#00000000", "shadow_offset": [0, 0],
		"shadow_outline_size": 0, "line_spacing": 0, "h_align": "center", "v_align": "center", "autowrap": "off", "uppercase": false,
		"max_lines": 1, "overrun": "no_trimming", "clip": false, "padding": [0, 0, 0, 0], "heat": p.heat,
		"broken": p.broken, "multiplier_amount": p.multiplier_amount, "bake_scale": px,
		"note": "the text is baked into the bubble picture (TrickPopupArt); the blank picture hides the whole bubble"}
	d.merge(_font_info(font))
	return d


static func _time_up_row(t: TimeUpScreen, screen: String) -> Dictionary:
	# The headline is two baked halves (ComboBrokenArt), the crack between words.
	var final := t.get_tree().root.get_final_transform()
	var box := Rect2()
	var first := true
	for sp in [t.left_half, t.right_half]:
		var tex_size := Vector2((sp as Sprite2D).texture.get_size())
		var b := _aabb(final * (sp as Sprite2D).get_global_transform_with_canvas(), Rect2(-tex_size / 2.0, tex_size))
		box = b if first else box.merge(b)
		first = false
	var st: Dictionary = HudStyle.POPUP_TEXT[TimeUpScreen.ART_STYLE]
	var scale: float = t.card.scale.x * final.y.length()
	var d := {"screen": screen, "path": String(t.card.get_path()).replace("/root/", ""), "class": "TimeUpScreen", "script_class": "TimeUpScreen",
		"kind": "baked_card", "rect": _r(box), "scale": [_f(scale), _f(scale)], "rotation_deg": 0.0, "alpha": 1.0, "text": t.headline,
		"font_origin": "baked", "font_size": int(st["font_px"]), "font_px": _f(int(st["font_px"]) * scale), "color": "#ffffffff",
		"outline_size": 0, "outline_color": "#000000ff", "shadow_color": "#00000000", "shadow_offset": [0, 0], "shadow_outline_size": 0,
		"line_spacing": 0, "h_align": "center", "v_align": "center", "autowrap": "off", "uppercase": false, "max_lines": 1,
		"overrun": "no_trimming", "clip": false, "padding": [0, 0, 0, 0],
		"note": "the headline is baked into the cracked card picture (ComboBrokenArt); the blank picture hides the card"}
	d.merge(_font_info(HudStyle.new_comic_font()))
	return d


static func _alpha_of_popup(p: Node) -> float:
	var a := 1.0
	var q: Node = p
	while q is CanvasItem:
		a *= (q as CanvasItem).modulate.a * (q as CanvasItem).self_modulate.a
		q = q.get_parent()
	return a


static func _clock_row(cd: ClockDigits, screen: String) -> Dictionary:
	var xf := cd.get_tree().root.get_final_transform() * cd.get_global_transform_with_canvas()
	var d := {"screen": screen, "path": String(cd.get_path()).replace("/root/", ""), "class": "ClockDigits",
		"script_class": "ClockDigits", "kind": "art_digits", "rect": _r(_aabb(xf, Rect2(Vector2.ZERO, cd.size))),
		"scale": [_f(xf.x.length()), _f(xf.y.length())], "rotation_deg": _f(rad_to_deg(xf.get_rotation())), "alpha": _f(_alpha(cd)),
		"text": cd.source.text if cd.source != null else "", "font_origin": "art", "font": "", "font_name": "seven-segment art (clock_digit_*.png)",
		"font_size": 0, "font_px": 0.0, "color": cd.source.get_theme_color("font_color").to_html(true) if cd.source != null else "#ffffffff",
		"outline_size": 0, "outline_color": "#00000000", "shadow_color": "#00000000", "shadow_offset": [0, 0], "shadow_outline_size": 0,
		"line_spacing": 0, "h_align": "center", "v_align": "center", "autowrap": "off", "uppercase": false, "max_lines": 1,
		"overrun": "no_trimming", "clip": false, "padding": [0, 0, 0, 0], "font_props": {},
		"note": "the digits are drawn art (ClockDigits), tinted with the label's colour; the blank picture hides them"}
	return d


static func _font_info(font: Font) -> Dictionary:
	var info := {"font": "", "font_name": "", "font_props": {}}
	var f: Font = font
	var props := {}
	var guard := 0
	while f is FontVariation and guard < 8:
		var fv := f as FontVariation
		props["variation_embolden"] = fv.variation_embolden
		props["spacing_glyph"] = fv.spacing_glyph
		props["spacing_space"] = fv.spacing_space
		props["spacing_top"] = fv.spacing_top
		props["spacing_bottom"] = fv.spacing_bottom
		f = fv.base_font
		guard += 1
	if f is FontFile:
		var ff := f as FontFile
		info["font"] = ff.resource_path
		info["font_name"] = ff.get_font_name()
		props["antialiasing"] = ff.antialiasing
		props["hinting"] = ff.hinting
		props["subpixel_positioning"] = ff.subpixel_positioning
		props["fixed_size"] = ff.fixed_size
		props["force_autohinter"] = ff.force_autohinter
		props["font_weight"] = ff.font_weight
		if ff.resource_path == "":
			# A copy made in code (duplicate()) has no path: find the font file whose bytes it holds.
			var found := _font_file_with_data(ff.data)
			if found != "":
				info["font"] = found
			elif not ff.data.is_empty() and out_dir != "":
				# Engine default font (not a file of the game): write its bytes out, the page needs a file.
				var slug := ff.get_font_name().replace(" ", "")
				DirAccess.make_dir_recursive_absolute(out_dir.path_join("fonts"))
				var fh := FileAccess.open(out_dir.path_join("fonts").path_join(slug + ".ttf"), FileAccess.WRITE)
				fh.store_buffer(ff.data)
				fh.close()
				info["font"] = ""
				info["font_extracted"] = "fonts/" + slug + ".ttf"
				info["font_name"] = ff.get_font_name() + " (Godot's built-in default font, written out of the engine)"
			else:
				info["font_name"] = ff.get_font_name() + " (no file path: embedded or generated)"
	elif f == null:
		info["font_name"] = "(none)"
	else:
		info["font_name"] = f.get_class() + " (engine default or system font)"
		if f == ThemeDB.fallback_font:
			info["font_name"] = "engine default font"
	info["font_props"] = props
	return info


static var _font_hashes := {}
## Where the capture writes (set by screen_gallery.gd); fonts that are not game files are written to fonts/ here.
static var out_dir := ""


static func _font_file_with_data(data: PackedByteArray) -> String:
	if data.is_empty():
		return ""
	if _font_hashes.is_empty():
		_scan_fonts("res://fonts")
	return String(_font_hashes.get(hash_bytes(data), ""))


static func hash_bytes(b: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(b)
	return ctx.finish().hex_encode()


static func _scan_fonts(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.get_extension().to_lower() in ["ttf", "otf", "woff", "woff2"]:
			_font_hashes[hash_bytes(FileAccess.get_file_as_bytes(dir.path_join(f)))] = dir.path_join(f)
	for d in DirAccess.get_directories_at(dir):
		_scan_fonts(dir.path_join(d))


static func _padding(sb: StyleBox) -> Array:
	if sb == null:
		return [0, 0, 0, 0]
	return [_f(sb.get_margin(SIDE_LEFT)), _f(sb.get_margin(SIDE_TOP)), _f(sb.get_margin(SIDE_RIGHT)), _f(sb.get_margin(SIDE_BOTTOM))]


static func _script_class(c: Control) -> String:
	var s: Script = c.get_script()
	return String(s.get_global_name()) if s != null else ""


static func _f(v: float) -> float:
	return snappedf(v, 0.01)


static func _r(r: Rect2) -> Array:
	return [_f(r.position.x), _f(r.position.y), _f(r.size.x), _f(r.size.y)]


# ---- blanking --------------------------------------------------------------------------

## Makes each node's text invisible without moving anything; returns what restore() needs.
static func blank(nodes: Array) -> Array:
	var undo: Array = []
	for n in nodes:
		if n is Label or n is RichTextLabel:
			var sb: StyleBox = n.get_theme_stylebox("normal")
			if sb == null or sb is StyleBoxEmpty:
				# No background of its own: fade the node's own drawing, nothing else moves.
				undo.append({"node": n, "prop": "self_modulate", "old": n.self_modulate})
				n.self_modulate = Color(n.self_modulate.r, n.self_modulate.g, n.self_modulate.b, 0.0)
			elif n is Label and n.label_settings != null:
				undo.append({"node": n, "prop": "label_settings", "old": n.label_settings})
				var ls: LabelSettings = n.label_settings.duplicate()
				ls.font_color = Color(0, 0, 0, 0)
				ls.outline_color = Color(0, 0, 0, 0)
				ls.shadow_color = Color(0, 0, 0, 0)
				n.label_settings = ls
			else:
				var cnames := ["font_color", "font_outline_color", "font_shadow_color"] if n is Label else ["default_color", "font_outline_color", "font_shadow_color"]
				for cn in cnames:
					undo.append({"node": n, "color": cn, "had": n.has_theme_color_override(cn), "old": n.get_theme_color(cn) if n.has_theme_color_override(cn) else Color.BLACK})
					n.add_theme_color_override(cn, Color(0, 0, 0, 0))
		elif n is Button or n is LineEdit:
			var names: Array = BUTTON_COLORS if n is Button else LINE_EDIT_COLORS
			for cn in names:
				undo.append({"node": n, "color": cn, "had": n.has_theme_color_override(cn), "old": n.get_theme_color(cn) if n.has_theme_color_override(cn) else Color.BLACK})
				n.add_theme_color_override(cn, Color(0, 0, 0, 0))
		elif n is TimeUpScreen:
			undo.append({"node": n.card, "prop": "visible", "old": n.card.visible})
			n.card.visible = false
		else:  # baked popups and the clock's art digits
			undo.append({"node": n, "prop": "visible", "old": n.visible})
			n.visible = false
	return undo


static func restore(undo: Array) -> void:
	for u in undo:
		var n: Object = u["node"]
		if not is_instance_valid(n):
			continue
		if u.has("prop"):
			n.set(u["prop"], u["old"])
		elif u["had"]:
			n.add_theme_color_override(u["color"], u["old"])
		else:
			n.remove_theme_color_override(u["color"])


## How many of `nodes` have shown their text again (something re-set it during the blank frame).
static func leaked(nodes: Array) -> int:
	var k := 0
	for n in nodes:
		if not is_instance_valid(n):
			continue
		if (n is Label or n is RichTextLabel) and n.self_modulate.a > 0.01 and n.get_theme_color("font_color" if n is Label else "default_color").a > 0.01 and (n.get("label_settings") == null or n.label_settings.font_color.a > 0.01):
			k += 1
		elif (n is Button or n is LineEdit) and n.get_theme_color("font_color").a > 0.01:
			k += 1
		elif (n is PopupTextScript.PopupText or n is ClockDigits) and n.visible:
			k += 1
		elif n is TimeUpScreen and n.card.visible:
			k += 1
	return k
