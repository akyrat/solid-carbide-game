extends GutTest
## Tests for tools/check_audio.gd (the audio import checker).

const CheckAudio = preload("res://tools/check_audio.gd")
const FIXTURE_DIR := "res://tests/fixtures/audio"
const FIXTURE_WAV := "res://tests/fixtures/audio/silence_100ms.wav"


func test_finds_audio_files_in_folder():
	var files := CheckAudio.find_audio_files(FIXTURE_DIR)
	assert_eq(Array(files), [FIXTURE_WAV])


func test_finds_files_in_subfolders():
	var files := CheckAudio.find_audio_files("res://tests/fixtures")
	assert_true(FIXTURE_WAV in files)


func test_missing_folder_gives_no_files():
	assert_eq(CheckAudio.find_audio_files("res://tests/fixtures/does_not_exist").size(), 0)


func test_imported_wav_passes():
	assert_eq(CheckAudio.check_file(FIXTURE_WAV), "")


func test_missing_file_fails():
	assert_ne(CheckAudio.check_file("res://tests/fixtures/audio/missing.wav"), "")
