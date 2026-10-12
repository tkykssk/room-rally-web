extends Node

## Run flow (title -> playing <-> paused -> result), timer, size milestones,
## star rating and the saved best record.

signal state_changed(state: int)
signal time_changed(time_left: float)
signal milestone_reached(cm: float)
signal game_over(result: Dictionary)

enum State {TITLE, PLAYING, PAUSED, RESULT}

@export var game_duration: float = 180.0
## Diameters (cm) for 1, 2 and 3 stars.
@export var star_goals_cm: Array[float] = [100.0, 300.0, 600.0]
## Sizes (cm) announced with a "SIZE UP" toast and chime.
@export var milestones_cm: Array[float] = [25.0, 50.0, 75.0, 100.0, 150.0, 200.0, 250.0, 300.0, 400.0, 500.0, 750.0, 1000.0]

## World units -> centimetres (a Kenney fridge is ~9 units tall).
const CM_PER_UNIT: = 20.0
const SAVE_PATH: = "user://save.cfg"

## Set by restart() so a retry skips the title screen.
static var _skip_title: bool = false

var state: int = State.TITLE
var time_left: float = 0.0
var best_cm: float = 0.0
var _player: Node = null
var _next_milestone: int = 0
var _last_shown_time: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	time_left = game_duration
	best_cm = _load_best()
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.size_changed.connect(_on_size_changed)
	if _skip_title:
		_skip_title = false
		start.call_deferred()
	else:
		_set_state(State.TITLE)

func is_playing() -> bool:
	return state == State.PLAYING

func size_cm() -> float:
	return _player.get_diameter() * CM_PER_UNIT if _player else 0.0

func start() -> void:
	if state != State.TITLE:
		return
	time_left = game_duration
	_set_state(State.PLAYING)
	Audio.play("start")
	Audio.play_music()

func pause() -> void:
	if state == State.PLAYING:
		_set_state(State.PAUSED)

func resume() -> void:
	if state == State.PAUSED:
		_set_state(State.PLAYING)

func restart() -> void:
	_skip_title = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _set_state(s: int) -> void:
	state = s
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
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 10.0 and ceilf(time_left) < ceilf(before):
		Audio.play("tick", 1.0 if time_left > 3.0 else 1.25)
	var shown: = int(time_left * 10.0)
	if shown != _last_shown_time:
		_last_shown_time = shown
		time_changed.emit(time_left)
	if time_left <= 0.0:
		_finish()

func _on_size_changed(diameter: float) -> void:
	var cm: = diameter * CM_PER_UNIT
	while _next_milestone < milestones_cm.size() and cm >= milestones_cm[_next_milestone]:
		if state == State.PLAYING:
			milestone_reached.emit(milestones_cm[_next_milestone])
			Audio.play("milestone")
		_next_milestone += 1

func stars_for(cm: float) -> int:
	var n: = 0
	for g in star_goals_cm:
		if cm >= g:
			n += 1
	return n

func _finish() -> void:
	var cm: = size_cm()
	var new_best: = cm > best_cm
	if new_best:
		best_cm = cm
		_save_best(cm)
	_set_state(State.RESULT)
	Audio.stop_music()
	Audio.play("result")
	game_over.emit({
		"size_cm": cm,
		"items": _player.items if _player else 0,
		"stars": stars_for(cm),
		"best_cm": best_cm,
		"new_best": new_best,
	})

func _load_best() -> float:
	var cfg: = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0.0
	return float(cfg.get_value("records", "best_cm", 0.0))

func _save_best(cm: float) -> void:
	var cfg: = ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("records", "best_cm", cm)
	cfg.save(SAVE_PATH)
