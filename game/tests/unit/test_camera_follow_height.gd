extends GutTest
## Task T-228: the camera follows the car's height (camera_follow.gd), eased.

const CameraFollowScript := preload("res://scripts/driving/camera_follow.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const ElevationTestScene := preload("res://scenes/elevation_test/elevation_test.tscn")
const DT := 0.02


func _lift(h: float) -> Vector2:
	return CarSpriteScript.lift_for_height(h, 16.0)


func test_height_6_settles_with_the_car_in_the_middle() -> void:
	var c = CameraFollowScript.new()
	var ground := Vector2(100, 40)
	c.snap(ground, 0.0)
	for i in 100:  # 2 s
		c.step(ground, 0.0, DT, _lift(6.0))
	var drawn: Vector2 = ground + _lift(6.0)
	assert_lt((c.position - drawn).length(), 2.0, "the drawn car is at the screen's middle")


func test_the_street_is_exactly_as_before() -> void:
	var a = CameraFollowScript.new()
	var b = CameraFollowScript.new()
	for smooth in [false, true]:
		a.smoothing = smooth
		b.smoothing = smooth
		a.snap(Vector2.ZERO, 0.0)
		b.snap(Vector2.ZERO, 0.0, _lift(0.0))
		for i in 50:
			var t := Vector2(i * 7.0, -i * 3.0)
			a.step(t, 0.5, DT)
			b.step(t, 0.5, DT, _lift(0.0))
			assert_eq(a.position, b.position)
			if not smooth:
				assert_eq(a.position, t, "exactly on the car")


func test_a_sudden_height_change_eases_instead_of_jumping() -> void:
	var c = CameraFollowScript.new()
	c.snap(Vector2.ZERO, 0.0)
	c.step(Vector2.ZERO, 0.0, DT, _lift(6.0))
	var first: float = -c.position.y
	assert_gt(first, 0.0, "starts moving up")
	assert_lt(first, 96.0 * 0.15, "but only a small part of the 96 px in one step")
	var prev := first
	for i in 80:
		c.step(Vector2.ZERO, 0.0, DT, _lift(6.0))
		var now: float = -c.position.y
		assert_gt(now, prev - 0.0001, "never goes back")
		assert_lt(now - prev, 96.0 * 0.15, "never a jump")
		prev = now


func test_the_ground_part_keeps_its_smoothing() -> void:
	var c = CameraFollowScript.new()
	c.smoothing = true
	c.snap(Vector2.ZERO, 0.0)
	c.step(Vector2(100, 0), 0.0, DT, _lift(0.0))
	assert_almost_eq(c.position.x, 100.0 * (1.0 - exp(-CameraFollowScript.SMOOTHING_RATE * DT)), 0.001)


func test_snap_puts_the_camera_on_the_lifted_car() -> void:
	var c = CameraFollowScript.new()
	c.snap(Vector2(5, 5), 0.0, _lift(3.0))
	assert_eq(c.position, Vector2(5, 5 - 48))


func test_the_elevation_test_scene_centres_the_car_on_the_platform() -> void:
	var s: Node2D = ElevationTestScene.instantiate()
	add_child_autofree(s)
	s.car.use_keyboard = false
	s.car.height_model.height = 3.0
	s.car.height_model.airborne = true
	s.sync_view(true)
	assert_almost_eq(s.camera.position.y, s.car_sprite.position.y, 0.01)
