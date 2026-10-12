extends CanvasLayer

## Floating virtual joystick: touch anywhere, drag to roll.
## Up/down rolls forward/back, left/right turns. Drives the same input actions
## as the keyboard, so Katamari only reads Input.get_axis().

@export var radius: float = 110.0
@export var dead_zone: float = 0.12

var _pad: Control
var _touch_index: int = -1
var _origin: Vector2
var _knob: Vector2

func _ready() -> void:
	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_origin = event.position
			_knob = Vector2.ZERO
			_apply()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_knob = Vector2.ZERO
			_apply()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_knob = (event.position - _origin).limit_length(radius)
		_apply()

func _apply() -> void:
	var v: = _knob / radius
	if v.length() < dead_zone:
		v = Vector2.ZERO
	_set_axis("left", "right", v.x)
	_set_axis("forward", "back", v.y)
	_pad.queue_redraw()

func _set_axis(negative: String, positive: String, value: float) -> void:
	if value < 0.0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	elif value > 0.0:
		Input.action_press(positive, value)
		Input.action_release(negative)
	else:
		Input.action_release(negative)
		Input.action_release(positive)

func _draw_pad() -> void:
	if _touch_index == -1:
		return
	var to_local: = _pad.get_global_transform_with_canvas().affine_inverse()
	var o: Vector2 = to_local * _origin
	_pad.draw_circle(o, radius, Color(1, 1, 1, 0.18))
	_pad.draw_arc(o, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 3.0)
	_pad.draw_circle(o + _knob, radius * 0.38, Color(1, 1, 1, 0.55))
