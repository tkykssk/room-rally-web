extends Node

## Global sound player (autoload "Audio"). A small pool of players so rapid
## smashes overlap instead of cutting each other off, plus the looping BGM.

const SOUNDS: = {
	"smash": preload("res://audio/impact.res"),
	"pop": preload("res://audio/pickup_big.ogg"),
	"tier_up": preload("res://audio/milestone.ogg"),
	"tick": preload("res://audio/tick.ogg"),
	"click": preload("res://audio/click.ogg"),
	"start": preload("res://audio/start.ogg"),
	"result": preload("res://audio/result.ogg"),
}
const BGM: = preload("res://audio/bgm.ogg")
const POOL_SIZE: = 10

var music_db: float = -9.0
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p: = AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	var bgm: AudioStreamOggVorbis = BGM.duplicate()
	bgm.loop = true
	_music.stream = bgm
	_music.volume_db = music_db
	add_child(_music)

func play(sound: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = SOUNDS.get(sound)
	if stream == null:
		return
	var p: = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.pitch_scale = clampf(pitch, 0.1, 4.0)
	p.volume_db = volume_db - 4.0
	p.play()

func play_music() -> void:
	if not _music.playing:
		_music.volume_db = music_db
		_music.play()

func stop_music() -> void:
	var tw: = create_tween()
	tw.tween_property(_music, "volume_db", -40.0, 0.6)
	tw.tween_callback(_music.stop)

## Mute everything (e.g. while an ad plays).
func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(0, muted)
