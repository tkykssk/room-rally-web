extends Node3D

## Chase camera that sits behind the Katamari's heading and pulls back as it grows.

@export var target: Katamari
## Optional: its shadow distance is stretched as the camera pulls back.
@export var sun: DirectionalLight3D

@export_group("Follow")
@export var follow_speed: float = 8.0
@export var rotate_speed: float = 5.0
@export var cam_lerp: float = 4.0

@export_group("Chase camera")
@export var cam_height: float = 2.6
@export var cam_back: float = 5.5
@export var cam_pitch_deg: float = -20.0

@export_group("Zoom")
@export var zoom_min: float = 0.95
@export var zoom_max: float = 1.15
@export var zoom_speed: float = 0.8
## Camera distance grows with size_scale ^ this exponent.
@export var size_exponent: float = 0.8

@onready var camera: Camera3D = $Camera

var _zoom: float = 1.0
var _base_shadow_distance: float = 0.0

func _ready() -> void:
	add_to_group("camera_rig")
	rotation = Vector3.ZERO
	camera.far = 300.0
	if sun:
		_base_shadow_distance = sun.directional_shadow_max_distance
	if target:
		global_position = target.get_player_position()
		rotation.y = target.get_heading_yaw()

func _physics_process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(target.get_player_position(), delta * follow_speed)
	rotation.y = lerp_angle(rotation.y, target.get_heading_yaw(), delta * rotate_speed)
	var top: float = target.max_speed * sqrt(target.size_scale)
	var sf: float = clampf(target.get_horizontal_speed() / top, 0.0, 1.0)
	_zoom = lerp(_zoom, remap(sf, 0.0, 1.0, zoom_min, zoom_max), delta * zoom_speed)
	var scl: float = pow(maxf(target.size_scale, 1.0), size_exponent)
	var target_pos: = Vector3(0.0, cam_height * _zoom * scl, cam_back * _zoom * scl)
	camera.position = camera.position.lerp(target_pos, delta * cam_lerp)
	if sun:
		sun.directional_shadow_max_distance = _base_shadow_distance * scl
	camera.rotation.x = lerp_angle(camera.rotation.x, deg_to_rad(cam_pitch_deg), delta * cam_lerp)
