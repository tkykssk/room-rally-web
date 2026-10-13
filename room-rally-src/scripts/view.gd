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
	camera.near = 0.15
	var gm: = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_signal("tier_unlocked"):
		gm.tier_unlocked.connect(_on_tier_unlocked)
	if gm and gm.has_signal("smashed"):
		gm.smashed.connect(_on_smashed)
	if target and target.has_signal("bumped"):
		target.bumped.connect(func(k: float): _shake = maxf(_shake, 0.06 + 0.12 * k))

var _shake: float = 0.0

func _on_smashed(_pos: Vector3, _points: int, height: float) -> void:
	_shake = maxf(_shake, clampf(height * 0.04, 0.03, 0.4))

func _on_tier_unlocked(tier: int) -> void:
	zoom_offset += zoom_per_tier
	# A grown truck sees further: keep the far plane and the sun's shadow
	# range in step with its size (the journey grows it ~40x).
	var k: = sqrt(pow(Vehicle.GROW_PER_TIER, tier))
	camera.far = maxf(300.0, 300.0 * k)
	# Depth precision depends mostly on the near plane: push it out with the
	# camera distance so distant surfaces don't z-fight (flicker).
	camera.near = 0.15 * _cam_scale(pow(Vehicle.GROW_PER_TIER, tier))
	var sun: = get_tree().current_scene.get_node_or_null("Sun") as DirectionalLight3D if get_tree().current_scene else null
	if sun:
		if _sun_base < 0.0:
			_sun_base = sun.directional_shadow_max_distance
		# Capped: a huge shadow range costs a lot on big tiers for little gain.
		sun.directional_shadow_max_distance = _sun_base * clampf(k, 1.0, 3.0)

var _sun_base: = -1.0

## Camera distance for a truck of size `s`: sqrt up to tier 6 (as in the
## challenge stages), then pulling back faster so a giant truck (journey,
## up to ~38x) doesn't fill the screen.
static func _cam_scale(s: float) -> float:
	const KNEE: = 11.39
	s = maxf(s, 1.0)
	if s <= KNEE:
		return sqrt(s)
	return sqrt(KNEE) * pow(s / KNEE, 0.85)

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
	var scl: = _cam_scale(target.size_scale)
	var target_pos: = Vector3(0.0, h * _zoom * scl, b * _zoom * scl)
	# Spring arm: if a wall is between the truck and the camera's spot, move
	# the camera in front of it. Furniture fades instead (see Destructible).
	var follow: = delta * cam_lerp
	var from: = global_position + Vector3(0.0, 0.6 * scl, 0.0)
	var want: = to_global(target_pos)
	var q: = PhysicsRayQueryParameters3D.create(from, want, 4)
	if target.get("sphere"):
		q.exclude = [target.sphere.get_rid()]
	var hit: = get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var dist: = from.distance_to(hit.position)
		var safe: = from + (want - from).normalized() * maxf(dist - 0.6, 0.8)
		target_pos = to_local(safe)
		follow = delta * cam_lerp * 4.0
	camera.position = camera.position.lerp(target_pos, clampf(follow, 0.0, 1.0))
	if _shake > 0.002:
		camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0.0) * _shake * scl
		_shake = lerpf(_shake, 0.0, clampf(delta * 9.0, 0.0, 1.0))
	camera.rotation.x = lerp_angle(camera.rotation.x, deg_to_rad(p), delta * cam_lerp)
