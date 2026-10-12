extends CanvasLayer

## All 2D UI: in-game HUD (size meter with star goals, timer, pickup feed,
## toasts) and the title / pause / result screens. Built in code so the layout
## lives in one place.

const INK: = Color("3b2a4a")
const PINK: = Color("ff5c8a")
const GOLD: = Color("ffc93c")
const PANEL_BG: = Color(1, 1, 1, 0.88)

var _gm: Node = null
var _player: Node = null

var _hud: Control
var _size_label: Label
var _count_label: Label
var _goal_bar: GoalBar
var _time_label: Label
var _time_panel: PanelContainer
var _feed_label: Label
var _toast_label: Label
var _toast_tween: Tween
var _feed_tween: Tween

var _title: Control
var _pause: Control
var _result: Control
var _result_size: Label
var _result_items: Label
var _result_best: Label
var _result_stars: Array = []
var _blink_label: Label

func _ready() -> void:
	_gm = get_tree().get_first_node_in_group("game_manager")
	_player = get_tree().get_first_node_in_group("player")
	_build_hud()
	_build_title()
	_build_pause()
	_build_result()
	if _gm:
		_gm.state_changed.connect(_on_state_changed)
		_gm.time_changed.connect(_on_time_changed)
		_gm.milestone_reached.connect(_on_milestone)
		_gm.game_over.connect(_on_game_over)
		_on_state_changed(_gm.state)
		_on_time_changed(_gm.time_left)
	if _player:
		_player.size_changed.connect(_on_size_changed)
		_player.item_absorbed.connect(_on_item_absorbed)
		_player.items_lost.connect(_on_items_lost)
		_on_size_changed(_player.get_diameter())

# --- state -------------------------------------------------------------------

func _on_state_changed(state: int) -> void:
	_hud.visible = state == _gm.State.PLAYING or state == _gm.State.PAUSED
	_title.visible = state == _gm.State.TITLE
	_pause.visible = state == _gm.State.PAUSED
	_result.visible = state == _gm.State.RESULT

func _input(event: InputEvent) -> void:
	if _gm == null or _gm.state != _gm.State.TITLE:
		return
	var go: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventJoypadButton and event.pressed)
	if go:
		_gm.start()

func _process(delta: float) -> void:
	if _title.visible:
		_blink_label.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 260.0)

# --- HUD -----------------------------------------------------------------------

func _on_size_changed(diameter: float) -> void:
	var cm: float = diameter * _gm.CM_PER_UNIT if _gm else diameter * 20.0
	_size_label.text = _format_size(cm)
	_goal_bar.set_value(cm)
	if _player:
		_count_label.text = _things(_player.items)

func _on_time_changed(t: float) -> void:
	var s: = int(ceilf(t))
	_time_label.text = "%d:%02d" % [s / 60, s % 60]
	var urgent: = t <= 10.0 and t > 0.0
	_time_label.add_theme_color_override("font_color", PINK if urgent else INK)
	if urgent:
		var k: = 1.0 + 0.08 * absf(sin(t * PI))
		_time_panel.pivot_offset = _time_panel.size * 0.5
		_time_panel.scale = Vector2(k, k)

func _on_item_absorbed(item_name: String, _pos: Vector3, _size: float) -> void:
	if _player:
		_count_label.text = _things(_player.items)
	if item_name.is_empty():
		return
	_feed_label.text = item_name
	_feed_label.add_theme_color_override("font_color", Color.WHITE)
	_pop(_feed_label, 1.25)

func _on_items_lost(count: int) -> void:
	_feed_label.text = "Dropped %d!" % count
	_feed_label.add_theme_color_override("font_color", PINK)
	_pop(_feed_label, 1.4)
	if _player:
		_count_label.text = _things(_player.items)

func _on_milestone(cm: float) -> void:
	_toast_label.text = "%s!" % _format_size(cm)
	if _toast_tween:
		_toast_tween.kill()
	_toast_label.visible = true
	_toast_label.modulate.a = 1.0
	_toast_label.pivot_offset = _toast_label.size * 0.5
	_toast_label.scale = Vector2(0.4, 0.4)
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_interval(0.9)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.35)

func _pop(c: Control, from_scale: float) -> void:
	if _feed_tween:
		_feed_tween.kill()
	c.modulate.a = 1.0
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * from_scale
	_feed_tween = create_tween()
	_feed_tween.tween_property(c, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_OUT)
	_feed_tween.tween_interval(1.4)
	_feed_tween.tween_property(c, "modulate:a", 0.0, 0.4)

func _on_game_over(r: Dictionary) -> void:
	_result_size.text = _format_size(r.size_cm)
	_result_items.text = _things(r.items) + " rolled up"
	_result_best.text = ("NEW BEST!  %s" if r.new_best else "BEST  %s") % _format_size(r.best_cm)
	_result_best.add_theme_color_override("font_color", PINK if r.new_best else INK)
	for i in _result_stars.size():
		var star: StarIcon = _result_stars[i]
		star.filled = i < r.stars
		star.queue_redraw()
		star.scale = Vector2.ZERO
		var tw: = create_tween()
		tw.tween_interval(0.5 + 0.25 * i)
		tw.tween_property(star, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func _things(n: int) -> String:
	return "%d thing" % n if n == 1 else "%d things" % n

static func _format_size(cm: float) -> String:
	if cm >= 100.0:
		return "%.2f m" % (cm / 100.0)
	return "%d cm" % int(cm)

func _build_hud() -> void:
	_hud = _full_rect()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)
	# Size meter (top left).
	var panel: = _panel(Vector2(24, 20))
	_hud.add_child(panel)
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	_size_label = _label("16 cm", 56, INK)
	box.add_child(_size_label)
	_goal_bar = GoalBar.new()
	_goal_bar.goals = _gm.star_goals_cm if _gm else [100.0, 300.0, 600.0]
	_goal_bar.custom_minimum_size = Vector2(300, 44)
	box.add_child(_goal_bar)
	_count_label = _label("0 things", 22, INK.lightened(0.25))
	box.add_child(_count_label)
	# Timer (top right) and pause button.
	_time_panel = _panel(Vector2.ZERO)
	_time_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_time_panel.offset_left = -200
	_time_panel.offset_right = -96
	_time_panel.offset_top = 20
	_time_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hud.add_child(_time_panel)
	_time_label = _label("3:00", 48, INK)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_panel.add_child(_time_label)
	var pause_btn: = _button("II", 30, Vector2(64, 64))
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -84
	pause_btn.offset_right = -20
	pause_btn.offset_top = 26
	pause_btn.offset_bottom = 90
	pause_btn.pressed.connect(func(): _gm.pause())
	_hud.add_child(pause_btn)
	# Last pickup (bottom centre).
	_feed_label = _label("", 44, Color.WHITE, 10)
	_feed_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_feed_label.offset_left = -400
	_feed_label.offset_right = 400
	_feed_label.offset_top = -110
	_feed_label.offset_bottom = -50
	_feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(_feed_label)
	# Milestone toast (upper centre).
	_toast_label = _label("", 84, GOLD, 16)
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_label.offset_left = -400
	_toast_label.offset_right = 400
	_toast_label.offset_top = 130
	_toast_label.offset_bottom = 240
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_color_override("font_outline_color", PINK.darkened(0.3))
	_toast_label.visible = false
	_hud.add_child(_toast_label)

func _build_title() -> void:
	_title = _overlay(Color(0.15, 0.08, 0.2, 0.5))
	var box: = _centered_box(_title, 14)
	var title: = _label("ROLL UP ROOM", 104, Color.WHITE, 24)
	title.add_theme_color_override("font_outline_color", PINK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub: = _label("Roll up everything in the room!", 34, Color.WHITE, 10)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var card: = _panel(Vector2.ZERO)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(card)
	var inner: = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	card.add_child(inner)
	var goal: = _label("Grow your ball as big as you can in 3:00", 28, INK)
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(goal)
	var stars_row: = HBoxContainer.new()
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 26)
	inner.add_child(stars_row)
	var goals: Array = _gm.star_goals_cm if _gm else [100.0, 300.0, 600.0]
	for i in goals.size():
		var cell: = HBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		for k in i + 1:
			var s: = StarIcon.new()
			s.filled = true
			s.custom_minimum_size = Vector2(26, 26)
			cell.add_child(s)
		cell.add_child(_label(" " + _format_size(goals[i]), 26, INK))
		stars_row.add_child(cell)
	var controls: = _label("WASD / Arrow keys: roll & turn   •   Touch: drag anywhere", 22, INK.lightened(0.3))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(controls)
	var hint: = _label("Small things stick. Big things block. Crash too hard and you'll drop stuff!", 20, INK.lightened(0.3))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(hint)
	if _gm and _gm.best_cm > 0.0:
		var best: = _label("BEST  " + _format_size(_gm.best_cm), 26, PINK)
		best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(best)
	_blink_label = _label("Click or tap to start", 40, Color.WHITE, 10)
	_blink_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_blink_label)
	_credit(_title)

func _build_pause() -> void:
	_pause = _overlay(Color(0.1, 0.05, 0.15, 0.55))
	var box: = _centered_box(_pause, 24)
	var t: = _label("PAUSED", 84, Color.WHITE, 16)
	t.add_theme_color_override("font_outline_color", PINK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var resume: = _button("RESUME", 36, Vector2(260, 72))
	resume.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume.pressed.connect(func(): _gm.resume())
	box.add_child(resume)
	var retry: = _button("RESTART", 30, Vector2(260, 64), Color("8a7fa0"))
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.pressed.connect(func(): _gm.restart())
	box.add_child(retry)

func _build_result() -> void:
	_result = _overlay(Color(0.12, 0.06, 0.18, 0.6))
	var box: = _centered_box(_result, 12)
	var t: = _label("TIME UP!", 92, Color.WHITE, 18)
	t.add_theme_color_override("font_outline_color", PINK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var card: = _panel(Vector2.ZERO)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.custom_minimum_size = Vector2(520, 0)
	box.add_child(card)
	var inner: = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	card.add_child(inner)
	var cap: = _label("Your ball grew to", 26, INK.lightened(0.3))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(cap)
	_result_size = _label("0 cm", 88, INK)
	_result_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_result_size)
	var stars: = HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 16)
	inner.add_child(stars)
	for i in 3:
		var s: = StarIcon.new()
		s.custom_minimum_size = Vector2(72, 72)
		s.pivot_offset = Vector2(36, 36)
		stars.add_child(s)
		_result_stars.append(s)
	_result_items = _label("", 28, INK)
	_result_items.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_result_items)
	_result_best = _label("", 30, INK)
	_result_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_result_best)
	var retry: = _button("PLAY AGAIN", 38, Vector2(320, 80))
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.pressed.connect(func(): _gm.restart())
	box.add_child(retry)
	_credit(_result)

# --- widgets -----------------------------------------------------------------

func _full_rect() -> Control:
	var c: = Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c

func _overlay(tint: Color) -> Control:
	var bg: = ColorRect.new()
	bg.color = tint
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.visible = false
	add_child(bg)
	return bg

func _centered_box(parent: Control, sep: int) -> VBoxContainer:
	var center: = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", sep)
	center.add_child(box)
	return box

func _label(text: String, size: int, color: Color, outline: int = 0) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", INK)
	return l

func _panel(pos: Vector2) -> PanelContainer:
	var p: = PanelContainer.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", sb)
	p.position = pos
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _button(text: String, size: int, min_size: Vector2, color: Color = PINK) -> Button:
	var b: = Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	for state in ["normal", "hover", "pressed"]:
		var sb: = StyleBoxFlat.new()
		sb.bg_color = color.lightened(0.12) if state == "hover" else (color.darkened(0.12) if state == "pressed" else color)
		sb.set_corner_radius_all(int(min_size.y * 0.5))
		sb.shadow_color = Color(0, 0, 0, 0.25)
		sb.shadow_size = 4
		sb.shadow_offset = Vector2(0, 4)
		b.add_theme_stylebox_override(state, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.pressed.connect(func(): Audio.play("click"))
	return b

func _credit(parent: Control) -> void:
	var l: = _label("Made with Godot Engine  •  3D models: Kenney.nl (CC0)  •  Font: Fredoka (OFL)", 16, Color(1, 1, 1, 0.75))
	l.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	l.offset_left = -500
	l.offset_right = 500
	l.offset_top = -36
	l.offset_bottom = -10
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)


## Five-point star, gold when filled.
class StarIcon extends Control:
	var filled: bool = false

	func _draw() -> void:
		var c: = size * 0.5
		var r: = minf(size.x, size.y) * 0.5
		var pts: = PackedVector2Array()
		for i in 10:
			var a: = -PI / 2.0 + i * PI / 5.0
			var rr: = r if i % 2 == 0 else r * 0.45
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, Color("ffc93c") if filled else Color(0.75, 0.72, 0.8, 0.6))
		pts.append(pts[0])
		draw_polyline(pts, Color("3b2a4a").lightened(0.1) if filled else Color(0.55, 0.5, 0.6, 0.8), maxf(1.5, r * 0.08), true)


## Progress toward the star goals. Square-root scale so early growth shows.
class GoalBar extends Control:
	var goals: Array = [100.0, 200.0, 300.0]
	var value: float = 0.0

	func set_value(v: float) -> void:
		value = v
		queue_redraw()

	func _frac(v: float) -> float:
		return clampf(sqrt(v / goals[-1]), 0.0, 1.0)

	func _draw() -> void:
		var h: = 16.0
		var y: = size.y - h - 2.0
		var w: = size.x - 18.0
		draw_rect(Rect2(0, y, w, h), Color(0.23, 0.16, 0.29, 0.15))
		draw_rect(Rect2(0, y, w * _frac(value), h), Color("ff5c8a"))
		for i in goals.size():
			var x: float = w * _frac(goals[i])
			var reached: bool = value >= goals[i]
			var c: = Vector2(x, y + h * 0.5 - 12.0)
			var r: = 12.0
			var pts: = PackedVector2Array()
			for k in 10:
				var a: = -PI / 2.0 + k * PI / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.45))
			draw_colored_polygon(pts, Color("ffc93c") if reached else Color(0.8, 0.77, 0.85))
			pts.append(pts[0])
			draw_polyline(pts, Color("3b2a4a"), 1.5, true)
