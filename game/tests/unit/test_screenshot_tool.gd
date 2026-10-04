extends GutTest
## Tests the argument parsing of the screenshot tool (tools/screenshot.gd).
## The capture itself needs a real window, so it is checked by running
## tools/screenshot.sh or tools/screenshot.ps1, not here.

const ScreenshotTool := preload("res://tools/screenshot.gd")

var _tool: Object


func before_each() -> void:
	_tool = ScreenshotTool.new()


func after_each() -> void:
	_tool.free()


func test_parses_key_value_args() -> void:
	var args: Dictionary = _tool._parse_args(PackedStringArray([
		"--scene=res://a/b.tscn", "--frames=12", "--out=C:/x/y z.png"]))
	assert_eq(args.get("scene"), "res://a/b.tscn")
	assert_eq(args.get("frames"), "12")
	assert_eq(args.get("out"), "C:/x/y z.png")


func test_keeps_equals_signs_in_values() -> void:
	var args: Dictionary = _tool._parse_args(PackedStringArray(["--out=C:/a=b.png"]))
	assert_eq(args.get("out"), "C:/a=b.png")


func test_ignores_args_without_value() -> void:
	var args: Dictionary = _tool._parse_args(PackedStringArray(["--verbose", "stray"]))
	assert_eq(args.size(), 0)
