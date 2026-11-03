class_name UiScale
extends RefCounted
## One way to scale the HUD and every screen with the window (task T-494; HUD and menus, Content,
## "The HUD scales with the window", and Decisions, "Every screen scales with the window").
## A screen is laid out at the base size (the board's layout page, 1152 x 648, the project's
## own window size) and drawn at one scale: the smaller of the window's width over the base width
## and its height over the base height. So a screen covers the same share of the window at any
## resolution, keeps its proportions, and on a wider window (ultrawide) keeps its height share
## with more room left and right. The world camera is never touched: only Controls are scaled.
## Pixel art stays hard-edged: `keep` turns on nearest filtering for the screen it scales.

## The board's layout page: the size every screen and the HUD are laid out at.
const BASE := Vector2(1152, 648)
const _META_BASE := &"ui_scale_base"
const _META_KEEPER := &"ui_scale_keeper"
const _META_VIEW := &"ui_scale_view"


## The scale for a window of `view` pixels and a screen laid out at `base` pixels.
static func fit(view: Vector2, base: Vector2 = BASE) -> float:
	if base.x <= 0.0 or base.y <= 0.0:
		return 1.0
	return maxf(minf(view.x / base.x, view.y / base.y), 0.01)


## Scales `target` (a screen's root Control, at its parent's top left) for a window of `view`
## pixels: it is laid out at the window's size divided by the scale and drawn at that scale, so it
## still fills the window, and every piece inside keeps its anchors and grows with the window.
static func apply(target: Control, view: Vector2, base: Vector2 = BASE) -> float:
	var s := fit(view, base)
	target.set_anchors_preset(Control.PRESET_TOP_LEFT)
	target.pivot_offset = Vector2.ZERO
	target.scale = Vector2(s, s)
	target.position = Vector2.ZERO
	target.size = view / s
	return s


## Keeps `target` scaled with the window: now (when in the tree), whenever it enters the tree,
## whenever the window changes size (the viewport's size_changed) and, as a catch-all, on any
## frame where the window's size differs from the one it was last scaled for (a headless or
## embedded window does not always send size_changed). Calling it again only changes its base.
static func keep(target: Control, base: Vector2 = BASE) -> void:
	target.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var known := target.has_meta(_META_BASE)
	target.set_meta(_META_BASE, base)
	if not known:
		# The keeper lives in the target's metadata, so it goes when the target is freed and
		# its signal connections go with it (no callable is left holding a freed Control).
		var keeper := _Keeper.new(target)
		target.set_meta(_META_KEEPER, keeper)
		target.tree_entered.connect(keeper.entered)
		target.tree_exiting.connect(keeper.exiting)
		if target.is_inside_tree():
			keeper.entered()
	elif target.is_inside_tree():
		refit(target)


## The screen's scale now (1.0 for a Control `keep` was never called on).
static func scale_of(target: Control) -> float:
	return target.scale.x if target.has_meta(_META_BASE) else 1.0


## The size `target` fills: its parent Control's size when it has one (a screen inside another
## screen), otherwise the window it is in (the viewport's visible size).
static func view_of(target: Control) -> Vector2:
	var parent := target.get_parent() as Control
	if parent != null:
		return parent.size
	return target.get_viewport().get_visible_rect().size


## Scales `target` for the window (or parent) it is in now.
static func refit(target: Control) -> void:
	if not is_instance_valid(target) or not target.is_inside_tree():
		return
	var base: Vector2 = target.get_meta(_META_BASE, BASE)
	var view := view_of(target)
	target.set_meta(_META_VIEW, view)
	apply(target, view, base)


## Follows one kept Control's window (UiScale.keep).
class _Keeper:
	extends RefCounted
	var _target: WeakRef

	func _init(target: Control) -> void:
		_target = weakref(target)

	func _get_target() -> Control:
		var t = _target.get_ref()
		return t as Control if t != null and t.is_inside_tree() else null

	func refit_now() -> void:
		var t := _get_target()
		if t != null:
			UiScale.refit(t)

	func poll() -> void:
		var t := _get_target()
		if t != null and UiScale.view_of(t) != t.get_meta(_META_VIEW, Vector2(-1, -1)):
			UiScale.refit(t)

	func entered() -> void:
		var t := _get_target()
		if t == null:
			return
		var vp := t.get_viewport()
		if vp != null and not vp.size_changed.is_connected(refit_now):
			vp.size_changed.connect(refit_now)
		var tree := t.get_tree()
		if not tree.process_frame.is_connected(poll):
			tree.process_frame.connect(poll)
		UiScale.refit(t)

	func exiting() -> void:
		var t := _get_target()
		if t == null:
			return
		var vp := t.get_viewport()
		if vp != null and vp.size_changed.is_connected(refit_now):
			vp.size_changed.disconnect(refit_now)
		var tree := t.get_tree()
		if tree.process_frame.is_connected(poll):
			tree.process_frame.disconnect(poll)
