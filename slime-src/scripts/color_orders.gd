extends CanvasLayer

## Colour orders: the goal on top of eating. A target colour is shown, mixed
## from the colours of two things that are in the world (shown as hint chips).
## Steer the slime's body colour to it by choosing what to eat, hold the match
## for a moment, and cash in for points and time. Orders run on a timer; a
## miss resets the streak multiplier.

const INK: = Color("3b2a4a")
const PINK: = Color("ff5c8a")
const GOLD: = Color("ffc93c")
const PANEL_BG: = Color(1, 1, 1, 0.88)

const ORDER_TIME: = 45.0
const HOLD_TIME: = 1.0
## Match (0..1) needed to count; 1 = identical.
const MATCH_GOAL: = 0.65
## OkLab distance that counts as a 0% match.
const MATCH_RANGE: = 0.4
const BASE_POINTS: = 60
const TIME_REWARD: = 6.0
const MAX_STREAK: = 4
## Markers over nearby things that have an ingredient colour.
const MAX_MARKERS: = 8
const MARKER_MATCH: = 0.8

var _gm: Node = null
var _slime: Node = null
var _active: = false
var _target: = Color.WHITE
var _time_left: = 0.0
var _hold: = 0.0
var _streak: = 0
var _done: = 0
var _rng: = RandomNumberGenerator.new()

var _root: Control
var _target_style: StyleBoxFlat
var _body_style: StyleBoxFlat
var _hint_styles: Array[StyleBoxFlat] = []
var _hint_plus: Label
var _hint_row: HBoxContainer
var _bar: ProgressBar
var _bar_fill: StyleBoxFlat
var _time_label: Label
var _streak_label: Label
var _reward: Label
var _picks: Array[Color] = []
var _markers: Array[MeshInstance3D] = []
var _marked: Array = []
var _marker_t: = 0.0

func _ready() -> void:
	_rng.randomize()
	_build_ui()
	_root.visible = false

func _process(delta: float) -> void:
	if _gm == null:
		_gm = get_tree().get_first_node_in_group("game_manager")
		_slime = get_tree().get_first_node_in_group("vehicle")
		if _gm == null or _slime == null:
			return
	var playing: bool = _gm.is_playing()
	_root.visible = playing
	if not playing:
		_hide_markers()
		return
	if not _active:
		if not _new_order():
			return
	_time_left -= delta
	var m: = color_match(_slime.get_body_color(), _target)
	_body_style.bg_color = _slime.get_body_color()
	_bar.value = m
	if m >= MATCH_GOAL:
		_hold += delta
		_bar_fill.bg_color = GOLD
	else:
		_hold = maxf(_hold - delta * 2.0, 0.0)
		_bar_fill.bg_color = PINK
	_time_label.text = "%d" % ceili(maxf(_time_left, 0.0))
	_time_label.add_theme_color_override("font_color", PINK if _time_left < 8.0 else INK)
	_update_markers(delta)
	if _hold >= HOLD_TIME:
		_complete()
	elif _time_left <= 0.0:
		_fail()

## Bobbing markers, in the ingredient colour, over the nearest edible things
## that give that colour, so it's clear what to go for.
func _update_markers(delta: float) -> void:
	if _markers.is_empty():
		_build_markers()
	_marker_t -= delta
	if _marker_t <= 0.0:
		_marker_t = 0.5
		_pick_marked()
	var bob: = sin(Time.get_ticks_msec() * 0.006) * 0.15
	var s: float = _slime.size_scale
	for i in _markers.size():
		var mk: = _markers[i]
		if i < _marked.size() and is_instance_valid(_marked[i][0]) and not _marked[i][0]._destroyed:
			var p: Destructible = _marked[i][0]
			mk.visible = true
			mk.global_position = Vector3(p.global_position.x, p.top_y() + (0.5 + bob) * s, p.global_position.z) + p.global_basis * Vector3(p.box_center.x, 0, p.box_center.z)
			mk.scale = Vector3.ONE * s
			mk.rotation.y += delta * 2.0
		else:
			mk.visible = false

func _pick_marked() -> void:
	_marked.clear()
	var me: Vector3 = _slime.get_vehicle_position()
	var cands: = []
	for p in get_tree().get_nodes_in_group("edible"):
		if p._destroyed or not p.is_destroyable() or p._palette.is_empty():
			continue
		var c: Color = p.eaten_color()
		for k in _picks.size():
			if color_match(c, _picks[k]) >= MARKER_MATCH:
				cands.append([p, k, me.distance_squared_to(p.global_position)])
				break
	cands.sort_custom(func(a, b): return a[2] < b[2])
	for c in cands.slice(0, MAX_MARKERS):
		_marked.append(c)
	for i in mini(_marked.size(), _markers.size()):
		(_markers[i].material_override as StandardMaterial3D).albedo_color = _picks[_marked[i][1]]

func _build_markers() -> void:
	var mesh: = PrismMesh.new()
	mesh.size = Vector3(0.5, 0.6, 0.5)
	for i in MAX_MARKERS:
		var mk: = MeshInstance3D.new()
		mk.mesh = mesh
		mk.rotation.x = PI
		var mat: = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mk.material_override = mat
		mk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mk.visible = false
		_slime.get_parent().add_child(mk)
		_markers.append(mk)

func _hide_markers() -> void:
	for mk in _markers:
		mk.visible = false

## Picks a target from the colours of things the slime can eat right now.
## The first order is a single colour to teach the idea.
func _new_order() -> bool:
	var tier: int = _gm.unlocked_tier
	var colours: Array[Color] = []
	for p in get_tree().get_nodes_in_group("edible"):
		if p._destroyed or p.size_tier > tier or p._palette.is_empty():
			continue
		var c: Color = p.eaten_color()
		var dup: = false
		for q in colours:
			if color_match(c, q) > 0.75:
				dup = true
				break
		if not dup:
			colours.append(c)
	if colours.is_empty():
		return false
	var body: Color = _slime.get_body_color()
	var picks: Array[Color] = []
	for attempt in 20:
		picks.clear()
		picks.append(colours[_rng.randi() % colours.size()])
		if _done > 0 and colours.size() > 1:
			var b: = colours[_rng.randi() % colours.size()]
			if color_match(picks[0], b) < 0.6:
				picks.append(b)
		var t: = mix(picks)
		# Don't ask for the colour the slime already has.
		if color_match(t, body) < MATCH_GOAL - 0.15:
			break
	_target = mix(picks)
	_picks = picks.duplicate()
	_marker_t = 0.0
	_target_style.bg_color = _target
	for i in _hint_styles.size():
		_hint_styles[i].bg_color = picks[mini(i, picks.size() - 1)]
	_hint_plus.visible = picks.size() > 1
	_hint_row.get_child(2).visible = picks.size() > 1
	_time_left = ORDER_TIME
	_hold = 0.0
	_active = true
	return true

func _complete() -> void:
	_active = false
	_streak = mini(_streak + 1, MAX_STREAK)
	_done += 1
	var mult: = 1.0 + 0.5 * (_streak - 1)
	var pts: = int(BASE_POINTS * pow(1.5, _gm.unlocked_tier) * mult)
	_gm.add_bonus(pts, TIME_REWARD)
	_streak_label.text = "STREAK x%.1f" % (1.0 + 0.5 * _streak)
	_show_reward("COLOUR MATCH!  +%d  +%ds" % [pts, int(TIME_REWARD)], GOLD)
	Audio.play("tier_up", 1.3)

func _fail() -> void:
	_active = false
	_streak = 0
	_streak_label.text = ""
	_show_reward("ORDER MISSED", Color.WHITE)
	Audio.play("tick", 0.6)

func _show_reward(text: String, col: Color) -> void:
	_reward.text = text
	_reward.add_theme_color_override("font_color", col)
	_reward.visible = true
	_reward.modulate.a = 1.0
	_reward.scale = Vector2(0.6, 0.6)
	var tw: = _reward.create_tween()
	tw.tween_property(_reward, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.2)
	tw.tween_property(_reward, "modulate:a", 0.0, 0.4)

## Subtractive (log-space) mix, the same way the slime mixes pigment.
static func mix(cols: Array[Color]) -> Color:
	var acc: = Vector3.ZERO
	for c in cols:
		acc += Vector3(log(maxf(c.r, 0.03)), log(maxf(c.g, 0.03)), log(maxf(c.b, 0.03)))
	acc /= float(cols.size())
	return Color(exp(acc.x), exp(acc.y), exp(acc.z))

## 0..1 similarity from the perceptual (OkLab) distance.
static func color_match(a: Color, b: Color) -> float:
	return clampf(1.0 - oklab(a).distance_to(oklab(b)) / MATCH_RANGE, 0.0, 1.0)

static func oklab(c: Color) -> Vector3:
	var r: = c.srgb_to_linear()
	var l: = pow(0.4122214708 * r.r + 0.5363325363 * r.g + 0.0514459929 * r.b, 1.0 / 3.0)
	var m: = pow(0.2119034982 * r.r + 0.6806995451 * r.g + 0.1073969566 * r.b, 1.0 / 3.0)
	var s: = pow(0.0883024619 * r.r + 0.2817188376 * r.g + 0.6299787005 * r.b, 1.0 / 3.0)
	return Vector3(
		0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var panel: = PanelContainer.new()
	var sb: = StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_top = 20
	_root.add_child(panel)
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var head: = HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	var title: = _label("MAKE THIS COLOUR", 18, INK.lightened(0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_time_label = _label("", 22, INK)
	head.add_child(_time_label)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	_body_style = _chip(row, 40)
	row.add_child(_label(">", 28, INK.lightened(0.3)))
	_target_style = _chip(row, 56)
	_hint_row = HBoxContainer.new()
	_hint_row.add_theme_constant_override("separation", 4)
	_hint_row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_label("=", 24, INK.lightened(0.3)))
	row.add_child(_hint_row)
	_hint_styles.append(_chip(_hint_row, 26))
	_hint_plus = _label("+", 20, INK.lightened(0.3))
	_hint_row.add_child(_hint_plus)
	_hint_styles.append(_chip(_hint_row, 26))
	_bar = ProgressBar.new()
	_bar.max_value = 1.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(260, 12)
	var bg: = StyleBoxFlat.new()
	bg.bg_color = Color(INK, 0.15)
	bg.set_corner_radius_all(6)
	_bar_fill = StyleBoxFlat.new()
	_bar_fill.bg_color = PINK
	_bar_fill.set_corner_radius_all(6)
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", _bar_fill)
	box.add_child(_bar)
	_streak_label = _label("", 16, PINK)
	_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_streak_label)
	_reward = _label("", 40, GOLD, 10)
	_reward.add_theme_color_override("font_outline_color", PINK.darkened(0.3))
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_reward.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_reward.offset_top = 175
	_reward.offset_left = -400
	_reward.offset_right = 400
	_reward.pivot_offset = Vector2(400, 25)
	_reward.visible = false
	_root.add_child(_reward)

func _chip(parent: Control, size: float) -> StyleBoxFlat:
	var chip: = Panel.new()
	chip.custom_minimum_size = Vector2(size, size)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st: = StyleBoxFlat.new()
	st.set_corner_radius_all(int(size * 0.5))
	st.set_border_width_all(3)
	st.border_color = Color.WHITE
	st.shadow_color = Color(INK, 0.3)
	st.shadow_size = 2
	chip.add_theme_stylebox_override("panel", st)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(chip)
	return st

func _label(text: String, size: int, color: Color, outline: int = 0) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
