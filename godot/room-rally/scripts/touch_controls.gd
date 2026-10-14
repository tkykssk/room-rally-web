extends CanvasLayer




@export var force_show: bool = true
@export var button_size: float = 130.0

var _left: TouchScreenButton
var _right: TouchScreenButton
var _gas: TouchScreenButton
var _brake: TouchScreenButton

func _ready() -> void:
	if not force_show and not _is_touch():
		return
	_left = _make("left", "L", Color(0.3, 0.55, 0.95, 0.45))
	_right = _make("right", "R", Color(0.3, 0.55, 0.95, 0.45))
	_gas = _make("forward", "GAS", Color(0.4, 0.85, 0.5, 0.45))
	_brake = _make("back", "BRK", Color(0.95, 0.55, 0.4, 0.45))
	_make_cam_button()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _make_cam_button() -> void:
	var cam:= Button.new()
	cam.text = "CAM"
	cam.focus_mode = Control.FOCUS_NONE
	cam.anchor_left = 1.0
	cam.anchor_right = 1.0
	cam.offset_left = -150.0
	cam.offset_top = 90.0
	cam.offset_right = -24.0
	cam.offset_bottom = 138.0
	cam.add_theme_font_size_override("font_size", 24)
	cam.pressed.connect(_on_cam_toggle)
	add_child(cam)

func _on_cam_toggle() -> void:
	var rig:= get_tree().get_first_node_in_group("camera_rig")
	if rig and rig.has_method("toggle_mode"):
		rig.toggle_mode()

func _is_touch() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web")

func _make(action: String, glyph: String, color: Color) -> TouchScreenButton:
	var b:= TouchScreenButton.new()
	b.action = action
	b.shape_centered = true
	var s:= int(button_size)
	b.texture_normal = _circle_tex(s, color)
	b.texture_pressed = _circle_tex(s, Color(color.r, color.g, color.b, 0.85))
	var shape:= CircleShape2D.new()
	shape.radius = button_size * 0.5
	b.shape = shape
	add_child(b)
	var lbl:= Label.new()
	lbl.text = glyph
	lbl.size = Vector2(button_size, button_size)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", int(button_size * 0.32))
	b.add_child(lbl)
	return b

func _circle_tex(sz: int, color: Color) -> ImageTexture:
	var img:= Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c:= sz * 0.5
	var r:= c - 3.0
	for y in sz:
		for x in sz:
			if Vector2(x + 0.5 - c, y + 0.5 - c).length() <= r:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)

func _layout() -> void:
	if _left == null:
		return
	var vp:= get_viewport().get_visible_rect().size
	var s:= button_size
	var pad:= 48.0
	var gap:= 24.0
	var y:= vp.y - s - pad
	_left.position = Vector2(pad, y)
	_right.position = Vector2(pad + s + gap, y)
	_gas.position = Vector2(vp.x - s - pad, y)
	_brake.position = Vector2(vp.x - 2.0 * s - gap - pad, y)
