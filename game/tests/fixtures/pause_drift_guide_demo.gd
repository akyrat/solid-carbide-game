extends "res://tests/fixtures/pause_screen_demo.gd"
## Screenshot fixture (task T-518): the pause screen with the Drift Guide ticked (test settings file).
## bash game/tools/screenshot.sh res://tests/fixtures/pause_drift_guide_demo.tscn art-archive/T-518/screenshots/pause_checkbox.png 90


func _ready() -> void:
	GameSettings.path = "user://pause_drift_guide_demo_settings.cfg"
	GameSettings.save_drift_guide_enabled(true)
	super._ready()
