extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 12

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	for i in max_sfx_players:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_sfx(stream: AudioStream, pitch_variance: float = 0.0) -> void:
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			if pitch_variance > 0.0:
				player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
			else:
				player.pitch_scale = 1.0
			player.play()
			return
