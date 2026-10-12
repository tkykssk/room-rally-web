extends Node3D

enum Mode {CHASE, OVERHEAD}

@export_group("Properties")
@export var target: Vehicle
@export var mode: Mode = Mode.CHASE

@export_group("Follow")
@export var follow_speed: float = 6.0
@export var rotate_speed: float = 4.0
@export var cam_lerp: float = 5.0

@export_group("Chase camera")
@export var cam_height: float = 3.5
@export var cam_back: float = 7.0
@export var cam_pitch_deg: float = -16.0
@export var heading_offset_deg: float = 180.0

@export_group("Overhead camera")
@export var over_height: float = 16.0
@export var over_back: float = 8.0
@export var over_pitch_deg: float = -60.0
@export var over_yaw_deg: float = 30.0

@export_group("Zoom")
@export var zoom_min: float = 0.9
@export var zoom_max: float = 1.25
@export var zoom_speed: float = 0.6
@export var zoom_offset: float = 0.0
@export var zoom_per_tier: float = 0.0

@onready var camera: Camera3D = $Camera

var _zoom: float = 1.0

func _ready() -> void:
	add_to_group("camera_rig")
	rotation = Vector3.ZERO
	camera.far = 300.0
	var gm: = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_signal("tier_unlocked"):
		gm.tier_unlocked.connect(_on_tier_unlocked)
	if gm and gm.has_signal("smashed"):
		gm.smashed.connect(_on_smashed)

var _shake: float = 0.0

func _on_smashed(_pos: Vector3, _points: int, height: float) -> void:
	_shake = maxf(_shake, clampf(height * 0.04, 0.03, 0.4))

func _on_tier_unlocked(_tier: int) -> void:
	zoom_offset += zoom_per_tier

func toggle_mode() -> void:
	mode = Mode.OVERHEAD if mode == Mode.CHASE else Mode.CHASE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		toggle_mode()

func _physics_process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(target.get_vehicle_position(), delta * follow_speed)
	var target_yaw: float = rotation.y
	if mode == Mode.CHASE:
		if target.has_method("get_heading_yaw"):
			target_yaw = target.get_heading_yaw() + deg_to_rad(heading_offset_deg)
	else:
		target_yaw = deg_to_rad(over_yaw_deg)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * rotate_speed)
	var sf: float = clampf(absf(target.linear_speed), 0.0, 1.0)
	var z: float = remap(sf, 0.0, 1.0, zoom_min, zoom_max) + zoom_offset
	_zoom = lerp(_zoom, z, delta * zoom_speed)
	var h: float
	var b: float
	var p: float
	if mode == Mode.CHASE:
		h = cam_height
		b = cam_back
		p = cam_pitch_deg
	else:
		h = over_height
		b = over_back
		p = over_pitch_deg
	var scl: float = sqrt(maxf(target.size_scale, 1.0))
	var target_pos: = Vector3(0.0, h * _zoom * scl, b * _zoom * scl)
	camera.position = camera.position.lerp(target_pos, delta * cam_lerp)
	if _shake > 0.002:
		camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0.0) * _shake * scl
		_shake = lerpf(_shake, 0.0, clampf(delta * 9.0, 0.0, 1.0))
	camera.rotation.x = lerp_angle(camera.rotation.x, deg_to_rad(p), delta * cam_lerp)
