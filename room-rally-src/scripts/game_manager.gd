extends Node

signal score_changed(new_score: int)
signal time_changed(time_left: float)
signal tier_unlocked(tier: int)
signal game_over(final_score: int)

@export var game_duration: float = 60.0

@export var tier_thresholds: Array[int] = [80, 280, 600, 1000, 1600, 2600]

var score: int = 0
var unlocked_tier: int = 0
var time_left: float = 0.0
var playing: bool = false
var _last_shown_time: int = -1

func _ready() -> void:
	reset()

func reset() -> void:
	score = 0
	unlocked_tier = 0
	time_left = game_duration
	playing = true
	score_changed.emit(score)
	time_changed.emit(time_left)

func _process(delta: float) -> void:
	if not playing:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		playing = false
		time_changed.emit(time_left)
		game_over.emit(score)
		return
	var shown: = int(time_left * 10.0)
	if shown != _last_shown_time:
		_last_shown_time = shown
		time_changed.emit(time_left)

func add_score(amount: int) -> void:
	if not playing:
		return
	score += amount
	score_changed.emit(score)
	_check_unlock()

func _check_unlock() -> void:
	while unlocked_tier < tier_thresholds.size() and score >= tier_thresholds[unlocked_tier]:
		unlocked_tier += 1
		tier_unlocked.emit(unlocked_tier)
		print("[GameManager] tier %d unlocked (score %d)" % [unlocked_tier, score])

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
