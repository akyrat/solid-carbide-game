extends GutTest
## Task T-417: a broken save never wipes progress (PlayerProgress, RunHistory, SafeSave).

var PATH := RunPaths.file("test_safe_progress.json")
var HPATH := RunPaths.file("test_safe_history.json")


func _clean(path: String) -> void:
	SafeSave.remove_all(path)


func before_each() -> void:
	_clean(PATH)
	_clean(HPATH)


func after_each() -> void:
	_clean(PATH)
	_clean(HPATH)


func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _read_raw(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _broken_files(path: String) -> Array:
	var out := []
	var d := DirAccess.open(path.get_base_dir())
	for f in d.get_files():
		if f.begins_with(path.get_file() + SafeSave.BROKEN):
			out.append(path.get_base_dir().path_join(f))
	return out


func _two_saves() -> void:
	# Two saves, so the backup holds the first (50 coins, 1 level) and the main the second.
	var p := PlayerProgress.new(null, PATH)
	p.coins = 50
	p.levels["acceleration"] = 1
	assert_true(p.save())
	p.coins = 90
	p.levels["acceleration"] = 2
	assert_true(p.save())


func test_truncated_main_loads_backup() -> void:
	_two_saves()
	var text := _read_raw(PATH)
	_write_raw(PATH, text.substr(0, text.length() / 2))
	var p := PlayerProgress.new(null, PATH)
	assert_eq(p.loaded_from, "backup")
	assert_eq(p.get_coins(), 50)
	assert_eq(p.level("acceleration"), 1)


func test_broken_main_is_moved_aside_not_overwritten() -> void:
	_two_saves()
	_write_raw(PATH, "{ not json")
	var p := PlayerProgress.new(null, PATH)
	assert_eq(_broken_files(PATH).size(), 1, "the broken file is kept")
	assert_eq(_read_raw(_broken_files(PATH)[0]), "{ not json")
	p.coins += 5
	assert_true(p.save())
	assert_eq(_broken_files(PATH).size(), 1, "still kept after a save")
	assert_eq(PlayerProgress.new(null, PATH).get_coins(), 55)


func test_broken_without_backup_is_new_player_and_kept() -> void:
	_write_raw(PATH, "garbage")
	var p := PlayerProgress.new(null, PATH)
	assert_eq(p.loaded_from, "none")
	assert_eq(p.get_coins(), 0)
	var kept := _broken_files(PATH)
	assert_eq(kept.size(), 1)
	assert_eq(_read_raw(kept[0]), "garbage")
	assert_false(FileAccess.file_exists(PATH), "nothing left to overwrite")
	p.coins = 7
	p.save()
	assert_eq(_read_raw(kept[0]), "garbage", "the kept file is untouched by the next save")


func test_two_broken_files_are_both_kept() -> void:
	_write_raw(PATH, "one")
	PlayerProgress.new(null, PATH)
	_write_raw(PATH, "two")
	PlayerProgress.new(null, PATH)
	assert_eq(_broken_files(PATH).size(), 2)


func test_wrong_shape_counts_as_broken() -> void:
	_write_raw(PATH, "[1, 2]")
	var p := PlayerProgress.new(null, PATH)
	assert_eq(p.get_coins(), 0)
	assert_eq(_broken_files(PATH).size(), 1)


func test_save_goes_through_a_temp_file() -> void:
	var p := PlayerProgress.new(null, PATH)
	p.coins = 12
	assert_true(p.save())
	assert_false(FileAccess.file_exists(PATH + SafeSave.TMP), "the temp file is renamed away")
	assert_eq(PlayerProgress.new(null, PATH).get_coins(), 12)


func test_save_cut_off_before_the_rename_keeps_the_old_file() -> void:
	var p := PlayerProgress.new(null, PATH)
	p.coins = 12
	p.save()
	var before := _read_raw(PATH)
	var ok := SafeSave.write(PATH, {"coins": 999, "levels": {}}, "coins", true)
	assert_false(ok)
	assert_eq(_read_raw(PATH), before, "the old file is intact")
	assert_eq(PlayerProgress.new(null, PATH).get_coins(), 12)


func test_a_stale_temp_file_is_ignored() -> void:
	var p := PlayerProgress.new(null, PATH)
	p.coins = 12
	p.save()
	_write_raw(PATH + SafeSave.TMP, "{ half a wri")
	assert_eq(PlayerProgress.new(null, PATH).get_coins(), 12)
	p.coins = 13
	assert_true(p.save())
	assert_eq(PlayerProgress.new(null, PATH).get_coins(), 13)


func test_a_broken_main_never_becomes_the_backup() -> void:
	_two_saves()
	_write_raw(PATH, "{ broken")
	var p := PlayerProgress.new(null, PATH)  # moves it aside, loads the backup
	p.save()
	p.coins = 60
	p.save()
	var bak := PlayerProgress.new(null, PATH + SafeSave.BACKUP)
	assert_eq(bak.get_coins(), 50, "the backup is the last good save, not the broken one")


func test_saves_carry_a_version() -> void:
	var p := PlayerProgress.new(null, PATH)
	p.save()
	var data: Dictionary = JSON.parse_string(_read_raw(PATH))
	assert_eq(int(data["version"]), SafeSave.CURRENT_VERSION)


func test_file_without_version_loads_as_version_1() -> void:
	_write_raw(PATH, '{"coins": 33, "levels": {"acceleration": 2}}')
	var p := PlayerProgress.new(null, PATH)
	assert_eq(p.loaded_version, 1)
	assert_eq(p.get_coins(), 33)
	assert_eq(p.level("acceleration"), 2)


func test_old_ids_are_mapped() -> void:
	var renames := {1: {"old_accel": "acceleration"}}
	var out := PlayerProgress._map_old_ids({"old_accel": 3, "car_health": 1}, 1, renames)
	assert_eq(out["acceleration"], 3)
	assert_false(out.has("old_accel"))
	assert_eq(out["car_health"], 1)
	var newer := PlayerProgress._map_old_ids({"old_accel": 3}, 2, renames)
	assert_true(newer.has("old_accel"), "a newer save is not renamed")
	var both := PlayerProgress._map_old_ids({"old_accel": 3, "acceleration": 5}, 1, renames)
	assert_eq(both["acceleration"], 5, "the level under the new id wins")


func test_history_truncated_main_loads_backup() -> void:
	var h := RunHistory.new(HPATH)
	h.add_run({"result": "win", "coins": 10})
	h.add_run({"result": "loss", "coins": 4})
	var text := _read_raw(HPATH)
	_write_raw(HPATH, text.substr(0, text.length() / 2))
	var h2 := RunHistory.new(HPATH)
	assert_eq(h2.loaded_from, "backup")
	assert_eq(h2.count(), 1)


func test_history_broken_without_backup_is_kept_aside() -> void:
	_write_raw(HPATH, "nope")
	var h := RunHistory.new(HPATH)
	assert_eq(h.count(), 0)
	assert_eq(_broken_files(HPATH).size(), 1)
	h.add_run({"result": "win", "coins": 1})
	assert_eq(_broken_files(HPATH).size(), 1)
	assert_eq(RunHistory.new(HPATH).count(), 1)


func test_history_saves_a_version_and_old_files_are_version_1() -> void:
	var h := RunHistory.new(HPATH)
	h.add_run({"result": "win", "coins": 1})
	var data: Dictionary = JSON.parse_string(_read_raw(HPATH))
	assert_eq(int(data["version"]), SafeSave.CURRENT_VERSION)
	_write_raw(HPATH, '{"runs": [{"result": "win"}]}')
	var h2 := RunHistory.new(HPATH)
	assert_eq(h2.loaded_version, 1)
	assert_eq(h2.count(), 1)


func test_history_cut_off_save_keeps_old_file() -> void:
	var h := RunHistory.new(HPATH)
	h.add_run({"result": "win", "coins": 1})
	var before := _read_raw(HPATH)
	SafeSave.write(HPATH, {"runs": []}, "runs", true)
	assert_eq(_read_raw(HPATH), before)
