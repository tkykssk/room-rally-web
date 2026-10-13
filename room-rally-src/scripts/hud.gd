extends CanvasLayer

## All 2D UI: in-game HUD (score + tier gauge, timer, score popups, tier-up
## banner) and the title / pause / result screens. Built in code.

const INK: = Color("3b2a4a")
const PINK: = Color("ff5c8a")
const GOLD: = Color("ffc93c")
const PANEL_BG: = Color(1, 1, 1, 0.88)

var _gm: Node = null

var _hud: Control
var _score_label: Label
var _tier_label: Label
var _tier_bar: ProgressBar
var _time_label: Label
var _time_panel: PanelContainer
var _banner: Label
var _banner_sub: Label
var _banner_tween: Tween
var _popups: Control

var _title: Control
var _pause: Control
var _result: Control
var _result_score: Label
var _result_tier: Label
var _result_best: Label
var _result_stars: Array = []
var _next_btn: Button
var _result_bonus: Label
var _result_title: Label
var _goal_label: Label

func _ready() -> void:
	_gm = get_tree().get_first_node_in_group("game_manager")
	_build_hud()
	_build_title()
	_build_pause()
	_build_result()
	if _gm == null:
		return
	_gm.state_changed.connect(_on_state_changed)
	_gm.score_changed.connect(_on_score_changed)
	_gm.time_changed.connect(_on_time_changed)
	_gm.tier_unlocked.connect(_on_tier_unlocked)
	_gm.game_over.connect(_on_game_over)
	_gm.smashed.connect(_on_smashed)
	_gm.room_cleared.connect(_on_room_cleared)
	_on_state_changed(_gm.state)
	_on_score_changed(_gm.score)
	_on_time_changed(_gm.time_left)

func _on_state_changed(state: int) -> void:
	_hud.visible = state == _gm.State.PLAYING or state == _gm.State.PAUSED
	_title.visible = state == _gm.State.TITLE
	_pause.visible = state == _gm.State.PAUSED
	_result.visible = state == _gm.State.RESULT

func _unhandled_input(event: InputEvent) -> void:
	if _gm and _gm.state == _gm.State.TITLE and event is InputEventKey and event.pressed \
			and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		_gm.play_stage(Stages.current)

# --- HUD events -------------------------------------------------------------

func _on_score_changed(s: int) -> void:
	_score_label.text = "%d" % s
	var tier: int = _gm.unlocked_tier
	var next: int = _gm.next_threshold()
	_tier_label.text = "TIER %d" % tier if next < 0 else "TIER %d  →  %d" % [tier, next]
	var prev: int = 0 if tier == 0 else _gm.tier_thresholds[tier - 1]
	_tier_bar.value = 1.0 if next < 0 else clampf(float(s - prev) / float(next - prev), 0.0, 1.0)
	var stars: int = _gm.stars_for(s)
	if _gm.star_goals.is_empty():
		_goal_label.text = ""
	else:
		_goal_label.text = "ALL STARS!" if stars >= _gm.star_goals.size() else "Star %d at %d" % [stars + 1, _gm.star_goals[stars]]

func _on_time_changed(t: float) -> void:
	var s: = int(ceilf(t))
	_time_label.text = "%d:%02d" % [s / 60, s % 60]
	var urgent: = t <= 10.0 and t > 0.0
	_time_label.add_theme_color_override("font_color", PINK if urgent else INK)

func _on_tier_unlocked(tier: int) -> void:
	_banner.text = "TIER %d!" % tier
	_banner_sub.text = "Bigger things can be smashed now"
	if _banner_tween:
		_banner_tween.kill()
	for c in [_banner, _banner_sub]:
		c.visible = true
		c.modulate.a = 1.0
		c.pivot_offset = c.size * 0.5
	_banner.scale = Vector2(0.3, 0.3)
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_interval(1.1)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.35)
	_banner_tween.parallel().tween_property(_banner_sub, "modulate:a", 0.0, 0.35)

func _on_room_cleared(bonus: int) -> void:
	_result_bonus.text = "ROOM CLEARED!  Time bonus +%d" % bonus
	_result_bonus.visible = true

## "+120" rising from the smashed prop.
func _on_smashed(world_pos: Vector3, points: int, height: float) -> void:
	var cam: = get_viewport().get_camera_3d()
	if cam == null or cam.is_position_behind(world_pos):
		return
	var l: = _label("+%d" % points, int(clampf(28.0 + height * 4.0, 28.0, 64.0)), GOLD if points >= 100 else Color.WHITE, 8)
	_popups.add_child(l)
	l.position = cam.unproject_position(world_pos) - Vector2(40, 20)
	var tw: = l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 70.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)

func _on_game_over(final_score: int) -> void:
	_result_score.text = "%d" % final_score
	_result_title.text = "CLEARED!" if _gm.props_left <= 0 else "TIME UP!"
	var stars: int = _gm.stars_for(final_score)
	for i in _result_stars.size():
		var star: StarIcon = _result_stars[i]
		star.filled = i < stars
		star.queue_redraw()
		star.scale = Vector2.ZERO
		var tw: = create_tween()
		tw.tween_interval(0.4 + 0.25 * i)
		tw.tween_property(star, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_next_btn.visible = _gm.has_next_stage()
	_result_tier.text = "Reached TIER %d" % _gm.unlocked_tier
	var new_best: bool = final_score >= _gm.best_score and final_score > 0
	_result_best.text = ("NEW BEST!  %d" if new_best else "BEST  %d") % _gm.best_score
	_result_best.add_theme_color_override("font_color", PINK if new_best else INK)

# --- builders ---------------------------------------------------------------

func _build_hud() -> void:
	_hud = _full_rect()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)
	_popups = _full_rect()
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_popups)
	var panel: = _panel()
	panel.position = Vector2(24, 20)
	_hud.add_child(panel)
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	box.add_child(_label(Stages.get_stage().name.to_upper() + "  •  SCORE", 20, INK.lightened(0.3)))
	_score_label = _label("0", 54, INK)
	box.add_child(_score_label)
	_tier_bar = ProgressBar.new()
	_tier_bar.max_value = 1.0
	_tier_bar.show_percentage = false
	_tier_bar.custom_minimum_size = Vector2(280, 14)
	var bg: = StyleBoxFlat.new()
	bg.bg_color = Color(INK, 0.15)
	bg.set_corner_radius_all(7)
	var fill: = StyleBoxFlat.new()
	fill.bg_color = PINK
	fill.set_corner_radius_all(7)
	_tier_bar.add_theme_stylebox_override("background", bg)
	_tier_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_tier_bar)
	_tier_label = _label("TIER 0", 20, INK.lightened(0.2))
	box.add_child(_tier_label)
	_goal_label = _label("", 20, PINK)
	box.add_child(_goal_label)
	_time_panel = _panel()
	_time_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_time_panel.offset_left = -220
	_time_panel.offset_right = -96
	_time_panel.offset_top = 20
	_time_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hud.add_child(_time_panel)
	_time_label = _label("0:00", 44, INK)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_panel.add_child(_time_label)
	var pause_btn: = _button("II", 28, Vector2(60, 60))
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -84
	pause_btn.offset_right = -24
	pause_btn.offset_top = 24
	pause_btn.offset_bottom = 84
	pause_btn.pressed.connect(func(): _gm.pause())
	_hud.add_child(pause_btn)
	_banner = _label("", 88, GOLD, 18)
	_banner.add_theme_color_override("font_outline_color", PINK.darkened(0.3))
	_place_center_top(_banner, 120, 110)
	_hud.add_child(_banner)
	_banner_sub = _label("", 30, Color.WHITE, 10)
	_place_center_top(_banner_sub, 228, 44)
	_hud.add_child(_banner_sub)
	_banner.visible = false
	_banner_sub.visible = false

func _build_title() -> void:
	_title = _overlay(Color(0.15, 0.08, 0.2, 0.5))
	var box: = _centered_box(_title, 12)
	var title: = _label("ROOM RALLY", 100, Color.WHITE, 24)
	title.add_theme_color_override("font_outline_color", PINK)
	box.add_child(title)
	box.add_child(_label("Smash the room. Grow your truck!", 32, Color.WHITE, 10))
	var row: = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	for i in Stages.count():
		row.add_child(_stage_card(i))
	box.add_child(_label("Drive: WASD / Arrows / touch buttons   •   C: camera   •   P: pause", 22, Color.WHITE, 8))
	_credit(_title)

func _stage_card(i: int) -> Control:
	var st: Dictionary = Stages.get_stage(i)
	var unlocked: bool = _gm == null or _gm.is_unlocked(i)
	var rec: Dictionary = _gm.record(i) if _gm else {"best": 0, "stars": 0}
	# Narrower cards when there are more stages, so the row fits 1280 px.
	var w: = minf(250.0, (1220.0 - 14.0 * (Stages.count() - 1)) / Stages.count())
	var b: = _button("", 1, Vector2(w, 190), PINK if unlocked else Color("8a7fa0"))
	b.disabled = not unlocked
	b.add_theme_stylebox_override("disabled", b.get_theme_stylebox("normal"))
	b.pressed.connect(func(): _gm.play_stage(i))
	var v: = VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	v.add_child(_label("STAGE %d" % (i + 1), 20, Color(1, 1, 1, 0.85)))
	v.add_child(_label(st.name, 34, Color.WHITE, 6))
	var stars: = HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in 3:
		var star: = StarIcon.new()
		star.filled = k < rec.stars
		star.custom_minimum_size = Vector2(30, 30)
		stars.add_child(star)
	v.add_child(stars)
	var info: String = ("BEST %d" % rec.best) if unlocked else "Get 1 star in stage %d" % i
	v.add_child(_label(info, 18, Color.WHITE))
	v.add_child(_label("%d:%02d" % [int(st.time) / 60, int(st.time) % 60] if unlocked else "LOCKED", 18, Color(1, 1, 1, 0.8)))
	for c in v.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _build_pause() -> void:
	_pause = _overlay(Color(0.1, 0.05, 0.15, 0.55))
	var box: = _centered_box(_pause, 24)
	var t: = _label("PAUSED", 84, Color.WHITE, 16)
	t.add_theme_color_override("font_outline_color", PINK)
	box.add_child(t)
	var resume: = _button("RESUME", 36, Vector2(260, 72))
	resume.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume.pressed.connect(func(): _gm.resume())
	box.add_child(resume)
	var retry: = _button("RESTART", 30, Vector2(260, 64), Color("8a7fa0"))
	var quit: = _button("STAGES", 30, Vector2(260, 64), Color("8a7fa0"))
	quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit.pressed.connect(func(): _gm.to_stage_select())
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.pressed.connect(func(): _gm.restart())
	box.add_child(retry)
	box.add_child(quit)

func _build_result() -> void:
	_result = _overlay(Color(0.12, 0.06, 0.18, 0.6))
	var box: = _centered_box(_result, 12)
	_result_title = _label("TIME UP!", 92, Color.WHITE, 18)
	_result_title.add_theme_color_override("font_outline_color", PINK)
	box.add_child(_result_title)
	var card: = _panel()
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.custom_minimum_size = Vector2(480, 0)
	box.add_child(card)
	var inner: = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	card.add_child(inner)
	inner.add_child(_label("SCORE", 26, INK.lightened(0.3)))
	_result_score = _label("0", 88, INK)
	inner.add_child(_result_score)
	var stars: = HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 14)
	inner.add_child(stars)
	for i in 3:
		var star: = StarIcon.new()
		star.custom_minimum_size = Vector2(64, 64)
		star.pivot_offset = Vector2(32, 32)
		stars.add_child(star)
		_result_stars.append(star)
	_result_tier = _label("", 28, INK)
	inner.add_child(_result_tier)
	_result_bonus = _label("", 26, Color("3fae6a"))
	_result_bonus.visible = false
	inner.add_child(_result_bonus)
	_result_best = _label("", 30, INK)
	inner.add_child(_result_best)
	var buttons: = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	var stages_btn: = _button("STAGES", 30, Vector2(200, 72), Color("8a7fa0"))
	stages_btn.pressed.connect(func(): _gm.to_stage_select())
	buttons.add_child(stages_btn)
	var retry: = _button("RETRY", 34, Vector2(200, 72))
	retry.pressed.connect(func(): _gm.restart())
	buttons.add_child(retry)
	_next_btn = _button("NEXT STAGE", 34, Vector2(250, 72), Color("3fae6a"))
	_next_btn.pressed.connect(func(): _gm.next_stage())
	buttons.add_child(_next_btn)
	_credit(_result)

# --- widgets ----------------------------------------------------------------

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

func _place_center_top(c: Control, top: float, height: float) -> void:
	c.set_anchors_preset(Control.PRESET_CENTER_TOP)
	c.offset_left = -480
	c.offset_right = 480
	c.offset_top = top
	c.offset_bottom = top + height

func _label(text: String, size: int, color: Color, outline: int = 0) -> Label:
	var l: = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", INK)
	return l

func _panel() -> PanelContainer:
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
	var l: = _label("Made with Godot Engine  •  3D models & SFX: Kenney.nl (CC0)  •  Font: Fredoka (OFL)", 16, Color(1, 1, 1, 0.75))
	l.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	l.offset_left = -520
	l.offset_right = 520
	l.offset_top = -36
	l.offset_bottom = -10
	parent.add_child(l)


## Five-point star, gold when filled.
class StarIcon extends Control:
	var filled: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: = size * 0.5
		var r: = minf(size.x, size.y) * 0.5
		var pts: = PackedVector2Array()
		for i in 10:
			var a: = -PI / 2.0 + i * PI / 5.0
			pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
		draw_colored_polygon(pts, Color("ffc93c") if filled else Color(1, 1, 1, 0.35))
		pts.append(pts[0])
		draw_polyline(pts, Color("3b2a4a"), maxf(1.5, r * 0.08), true)
