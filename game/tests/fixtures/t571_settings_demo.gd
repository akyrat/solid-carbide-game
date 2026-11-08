extends Node
## T-571 screenshots: the main menu with its Settings button, and the Settings screen
## (throwaway settings file, never the player's real one).
@export var show := "menu"  # "menu", "settings" or "settings_sfx" (the SFX switch on)


func _ready() -> void:
	GameSettings.path = RunPaths.file("t571_demo.cfg")
	DirAccess.remove_absolute(GameSettings.path)
	GameSettings.save_rain_enabled(true)
	if show == "menu":
		var m: MainMenu = load("res://scenes/menu/main_menu.tscn").instantiate()
		add_child(m)
		m.settings_button.grab_focus()
		return
	GameSettings.sfx_enabled_override = 1 if show == "settings_sfx" else -1
	var s: SettingsScreen = load("res://scenes/menu/settings_screen.tscn").instantiate()
	add_child(s)
