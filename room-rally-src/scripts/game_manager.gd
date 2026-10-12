extends Node

## Score, timer and tier unlocks (unchanged rules), plus the run flow:
## title -> playing <-> paused -> result, and the saved best score.

signal score_changed(new_score: int)
signal time_changed(time_left: float)
signal tier_unlocked(tier: int)
signal game_over(final_score: int)
signal state_changed(state: int)
signal room_cleared(bonus: int)
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
var total_points: int = 0
var props_left: int = 0
var clear_bonus: int = 0
const CLEAR_BONUS_PER_SECOND: = 20

var stage: Dictionary
var star_goals: Array = []
## Per-stage records: {index: {"best": int, "stars": int}}.
var records: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stage = Stages.get_stage()
	game_duration = stage.time
	tier_thresholds.assign(stage.tiers)
	records = _load_records()
	best_score = record(Stages.current).best
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

## Start the selected stage (from the title / stage select).
func play_stage(i: int) -> void:
	if not is_unlocked(i):
		return
	if i != Stages.current:
		Stages.current = i
		_skip_title = true
		get_tree().reload_current_scene()
		return
	start()

func start() -> void:
	if state != State.TITLE:
		return
	_set_state(State.PLAYING)
	CG.gameplay_start()
	Audio.play("start")
	Audio.play_music()

func pause() -> void:
	if state == State.PLAYING:
		_set_state(State.PAUSED)
		CG.gameplay_stop()

func resume() -> void:
	if state == State.PAUSED:
		_set_state(State.PLAYING)
		CG.gameplay_start()

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

## Called by the prop spawner once the stage is laid out.
func set_stage_props(count: int, points: int) -> void:
	props_left = count
	total_points = points
	star_goals.clear()
	for f in Stages.STAR_FRACTIONS:
		star_goals.append(points if f >= 1.0 else int(round(points * f / 50.0)) * 50)
	score_changed.emit(score)

func add_score(amount: int) -> void:
	if not playing:
		return
	score += amount
	props_left -= 1
	score_changed.emit(score)
	_check_unlock()
	if props_left <= 0:
		# Everything smashed: end early, remaining time becomes bonus points.
		clear_bonus = int(ceilf(time_left)) * CLEAR_BONUS_PER_SECOND
		score += clear_bonus
		score_changed.emit(score)
		room_cleared.emit(clear_bonus)
		_finish()

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

func stars_for(value: int) -> int:
	var n: = 0
	for g in star_goals:
		if value >= g:
			n += 1
	return n

func record(i: int) -> Dictionary:
	return records.get(i, {"best": 0, "stars": 0})

## A stage is open once the previous one has at least one star.
func is_unlocked(i: int) -> bool:
	return i == 0 or record(i - 1).stars >= 1

func has_next_stage() -> bool:
	return Stages.current + 1 < Stages.count() and is_unlocked(Stages.current + 1)

func _finish() -> void:
	var stars: = stars_for(score)
	var rec: Dictionary = record(Stages.current)
	var new_best: bool = score > rec.best
	if new_best or stars > rec.stars:
		records[Stages.current] = {"best": maxi(score, rec.best), "stars": maxi(stars, rec.stars)}
		_save_records()
	best_score = record(Stages.current).best
	CG.gameplay_stop()
	if new_best and score > 0:
		CG.happytime()
	_set_state(State.RESULT)
	Audio.stop_music()
	Audio.play("result")
	game_over.emit(score)

func restart() -> void:
	_reload_after_ad(Stages.current, true)

func next_stage() -> void:
	if has_next_stage():
		_reload_after_ad(Stages.current + 1, true)

func to_stage_select() -> void:
	_reload_after_ad(Stages.current, false)

## Between rounds is the natural break for a CrazyGames midgame ad.
func _reload_after_ad(stage_index: int, skip_title: bool) -> void:
	get_tree().paused = false
	CG.midgame_ad(func():
		Stages.current = stage_index
		_skip_title = skip_title
		get_tree().reload_current_scene())

func _load_records() -> Dictionary:
	var cfg: = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	return cfg.get_value("records", "stages", {})

func _save_records() -> void:
	var cfg: = ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("records", "stages", records)
	cfg.save(SAVE_PATH)
