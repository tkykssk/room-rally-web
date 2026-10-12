extends CanvasLayer

@onready var score_label: Label = $Score
@onready var time_label: Label = $Time
@onready var toast_label: Label = $Toast

var _manager: Node = null
var _result: ColorRect = null
var _result_score: Label = null
var _toast_timer: float = 0.0

func _ready() -> void:
	_build_result_ui()
	_manager = get_tree().get_first_node_in_group("game_manager")
	if _manager:
		if _manager.has_signal("score_changed"): _manager.score_changed.connect(_on_score_changed)
		if _manager.has_signal("time_changed"): _manager.time_changed.connect(_on_time_changed)
		if _manager.has_signal("tier_unlocked"): _manager.tier_unlocked.connect(_on_tier_unlocked)
		if _manager.has_signal("game_over"): _manager.game_over.connect(_on_game_over)
		_on_score_changed(_manager.score)
		_on_time_changed(_manager.time_left)

func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast_label.visible = false

func _on_score_changed(s: int) -> void:
	score_label.text = "SCORE  %d" % s

func _on_time_changed(t: float) -> void:
	time_label.text = "TIME  %4.1f" % t

func _on_tier_unlocked(tier: int) -> void:
	_show_toast("TIER %d UNLOCKED!" % tier)

func _on_game_over(final_score: int) -> void:
	_result_score.text = "SCORE  %d" % final_score
	_result.visible = true

func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	_toast_timer = 1.6

func _on_retry() -> void:
	if _manager and _manager.has_method("restart"):
		_manager.restart()

func _build_result_ui() -> void:
	_result = ColorRect.new()
	_result.color = Color(0, 0, 0, 0.55)
	_result.mouse_filter = Control.MOUSE_FILTER_STOP
	_result.visible = false
	add_child(_result)
	_result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: = CenterContainer.new()
	_result.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)
	var title: = Label.new()
	title.text = "TIME UP!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	box.add_child(title)
	_result_score = Label.new()
	_result_score.text = "SCORE  0"
	_result_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_score.add_theme_font_size_override("font_size", 40)
	box.add_child(_result_score)
	var retry: = Button.new()
	retry.text = "RETRY"
	retry.custom_minimum_size = Vector2(200, 56)
	retry.pressed.connect(_on_retry)
	box.add_child(retry)
	var credit: = Label.new()
	credit.text = "Made with Godot Engine\n3D models & SFX: Kenney.nl (CC0)"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.add_theme_font_size_override("font_size", 18)
	credit.modulate = Color(1, 1, 1, 0.7)
	box.add_child(credit)
