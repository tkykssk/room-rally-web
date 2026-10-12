extends Node

## Score, timer and tier unlocks (unchanged rules), plus the run flow:
## title -> playing <-> paused -> result, and the saved best score.

signal score_changed(new_score: int)
signal time_changed(time_left: float)
signal tier_unlocked(tier: int)
signal game_over(final_score: int)
signal state_changed(state: int)
## A prop was destroyed (for score popups and camera shake).
signal smashed(world_pos: Vector3, points: int, height: float)

enum State {TITLE, PLAYING, PAUSED, RESULT}

@export var game_duration: float = 60.0
@export var tier_thresholds: Array[int] = [80, 280, 600, 1000, 1600, 2600]

const SAVE_PATH: = "user://save.cfg"

## Set by restart() so a retry skips the title screen.
static var _skip_title: bool = false

var score: int = 0
var unlocked_tier: int = 0
var time_left: float = 0.0
var playing: bool = false
var state: int = State.TITLE
var best_score: int = 0
var _last_shown_time: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	best_score = _load_best()
	reset()
	if _skip_title:
		_skip_title = false
		start.call_deferred()
	else:
		_set_state(State.TITLE)

func reset() -> void:
	score = 0
	unlocked_tier = 0
	time_left = game_duration
	playing = false
	score_changed.emit(score)
	time_changed.emit(time_left)

func is_playing() -> bool:
	return state == State.PLAYING

func start() -> void:
	if state != State.TITLE:
		return
	_set_state(State.PLAYING)
	Audio.play("start")
	Audio.play_music()

func pause() -> void:
	if state == State.PLAYING:
		_set_state(State.PAUSED)

func resume() -> void:
	if state == State.PAUSED:
		_set_state(State.PLAYING)

func _set_state(s: int) -> void:
	state = s
	playing = s == State.PLAYING
	get_tree().paused = s == State.PAUSED
	state_changed.emit(s)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING:
			pause()
		elif state == State.PAUSED:
			resume()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	# Losing focus (tab switch, ad overlay) pauses the run.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pause()

func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	var before: = time_left
	time_left -= delta
	if time_left <= 10.0 and ceilf(time_left) < ceilf(before) and time_left > 0.0:
		Audio.play("tick", 1.0 if time_left > 3.0 else 1.25)
	if time_left <= 0.0:
		time_left = 0.0
		time_changed.emit(time_left)
		_finish()
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
		Audio.play("tier_up")

func report_smash(world_pos: Vector3, points: int, height: float) -> void:
	if playing:
		smashed.emit(world_pos, points, height)

## Score needed for the next tier, or -1 when every tier is open.
func next_threshold() -> int:
	return tier_thresholds[unlocked_tier] if unlocked_tier < tier_thresholds.size() else -1

func _finish() -> void:
	if score > best_score:
		best_score = score
		_save_best(score)
	_set_state(State.RESULT)
	Audio.stop_music()
	Audio.play("result")
	game_over.emit(score)

func restart() -> void:
	_skip_title = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _load_best() -> int:
	var cfg: = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("records", "best_score", 0))

func _save_best(value: int) -> void:
	var cfg: = ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("records", "best_score", value)
	cfg.save(SAVE_PATH)
