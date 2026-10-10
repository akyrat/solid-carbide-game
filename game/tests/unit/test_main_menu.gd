extends GutTest

var menu: MainMenu


func before_each() -> void:
	menu = load("res://scenes/menu/main_menu.tscn").instantiate()
	add_child_autofree(menu)


func test_title_and_subtitle() -> void:
	assert_eq(menu.title_label.text, "SOLID CARBIDE")
	assert_eq(menu.subtitle_label.text, "(work in progress)")


func test_button_labels_are_the_approved_text() -> void:
	assert_eq(menu.start_button.text, "Start")
	assert_eq(menu.garage_button.text, "Garage")
	assert_eq(menu.exit_button.text, "Exit")


func test_start_button_signal() -> void:
	watch_signals(menu)
	menu.start_button.pressed.emit()
	assert_signal_emitted(menu, "start_pressed")
	assert_signal_not_emitted(menu, "garage_pressed")
	assert_signal_not_emitted(menu, "exit_pressed")


func test_garage_button_signal() -> void:
	watch_signals(menu)
	menu.garage_button.pressed.emit()
	assert_signal_emitted(menu, "garage_pressed")
	assert_signal_not_emitted(menu, "start_pressed")


func test_exit_button_signal() -> void:
	watch_signals(menu)
	menu.exit_button.pressed.emit()
	assert_signal_emitted(menu, "exit_pressed")
	assert_signal_not_emitted(menu, "start_pressed")
