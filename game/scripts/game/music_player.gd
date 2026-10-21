class_name MusicPlayer
extends Node
## The board's two tracks (task T-209): track 1, then track 2, then track 1 again, and so
## on, for the whole game. One node, a child of the game flow (the main scene), so it is
## never rebuilt when the screen changes (menu, run, garage). It keeps playing while the
## tree is paused (process mode Always). Game loop architecture, Decisions, "Music".
##
## It plays on its own "Music" bus, separate from the sound effects: the bus volume is the
## music setting (GameSettings, 0 to 100).

const TRACKS: Array[String] = [
	"res://audio/music/demo_beat_1.mp3",
	"res://audio/music/demo_beat_2.mp3",
]

var player: AudioStreamPlayer
## Index in the tracks of the one now playing.
var track_index := -1
## How many times a track was started (tests).
var tracks_started := 0


func _init() -> void:
	name = "Music"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	GameSettings.apply_music_volume(GameSettings.load_music_volume())
	player = AudioStreamPlayer.new()
	player.name = "MusicPlayer"
	player.bus = GameSettings.MUSIC_BUS
	player.finished.connect(play_next)
	add_child(player)
	play_next()


## Starts the next track (the first one on the first call); after the last it is the first again.
func play_next() -> void:
	track_index = (track_index + 1) % TRACKS.size()
	var stream = load(TRACKS[track_index])
	if stream == null:
		push_error("Music file missing: %s" % TRACKS[track_index])
		return
	player.stream = stream
	player.play()
	tracks_started += 1


## The playback position in seconds in the current track.
func position_s() -> float:
	return player.get_playback_position() if player.playing else 0.0
