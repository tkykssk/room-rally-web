class_name Vehicle extends Node3D

@export_group("Tuning")

@export var steering_strength: float = 5.0

@export var accel_rate: float = 6.0

@export var brake_rate: float = 8.0

@export var reverse_rate: float = 2.0

@export var roll_force: float = 100.0

@export var grip_min: float = 0.2
@export var grip_max: float = 1.0

@onready var sphere: RigidBody3D = $Sphere
@onready var raycast: RayCast3D = $Ground

var size_scale: float = 1.0
const BASE_MODEL_OFFSET: = 0.65
const MODEL_GROUND_LIFT: = 0.15
const GROW_PER_TIER: = 1.5

const SMASH_BASE_RADIUS: = 1.0
var _smasher: Area3D = null
var _smash_shape: SphereShape3D = null
var _smash_tick: int = 0

@onready var vehicle_model = $Container
@onready var model_root: Node3D = get_node_or_null("Container/Model")
@onready var vehicle_body = get_node_or_null("Container/Model/body")

@onready var wheel_fl = get_node_or_null("Container/Model/wheel-front-left")
@onready var wheel_fr = get_node_or_null("Container/Model/wheel-front-right")
@onready var wheel_bl = get_node_or_null("Container/Model/wheel-back-left")
@onready var wheel_br = get_node_or_null("Container/Model/wheel-back-right")

@onready var trail_left = get_node_or_null("Container/TrailLeft")
@onready var trail_right = get_node_or_null("Container/TrailRight")

@onready var screech_sound: AudioStreamPlayer3D = $Container / ScreechSound
@onready var engine_sound: AudioStreamPlayer3D = $Container / EngineSound
@onready var impact_sound: AudioStreamPlayer3D = $Container / ImpactSound

var input: Vector3
var normal: Vector3

var acceleration: float
var angular_speed: float
var linear_speed: float

var colliding: bool

var linear_velocity: Vector3
var prev_position: Vector3

var calculated_lean: float

func get_vehicle_position() -> Vector3: return vehicle_model.global_position
func get_heading_yaw() -> float: return vehicle_model.global_rotation.y

func _ready() -> void:
	add_to_group("vehicle")
	var gm: = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_signal("tier_unlocked"):
		gm.tier_unlocked.connect(_on_tier_unlocked)
	_build_smasher()

func _build_smasher() -> void:
	_smasher = Area3D.new()
	_smasher.collision_layer = 0
	_smasher.collision_mask = 2
	_smasher.monitoring = true
	_smash_shape = SphereShape3D.new()
	_smash_shape.radius = SMASH_BASE_RADIUS * size_scale
	var cs: = CollisionShape3D.new()
	cs.shape = _smash_shape
	_smasher.add_child(cs)
	vehicle_model.add_child(_smasher)

func _on_tier_unlocked(tier: int) -> void:
	set_size_scale(pow(GROW_PER_TIER, tier))

func set_size_scale(s: float) -> void:
	size_scale = s
	if model_root:
		var tw: = create_tween().set_parallel(true)
		tw.tween_property(model_root, "scale", Vector3(s, s, s), 0.3)
		tw.tween_property(model_root, "position:y", MODEL_GROUND_LIFT * (s - 1.0), 0.3)
	if _smash_shape:
		_smash_shape.radius = SMASH_BASE_RADIUS * s

func _physics_process(delta):
	handle_input(delta)
	var direction = sign(linear_speed)
	if direction == 0: direction = sign(input.z) if abs(input.z) > 0.1 else 1
	var steering_grip = clamp(abs(linear_speed), grip_min, grip_max)
	var target_angular = -input.x * steering_grip * steering_strength * direction
	angular_speed = lerp(angular_speed, target_angular, delta * 4)
	vehicle_model.rotate_y(angular_speed * delta)
	if raycast.is_colliding():
		if !colliding:
			if vehicle_body != null: vehicle_body.position = Vector3(0, 0.1, 0)
			input.z = 0
		normal = raycast.get_collision_normal()
		if normal.dot(vehicle_model.global_basis.y) > 0.5:
			var xform = align_with_y(vehicle_model.global_transform, normal)
			vehicle_model.global_transform = vehicle_model.global_transform.interpolate_with(xform, 0.2).orthonormalized()
	colliding = raycast.is_colliding()
	var target_speed = input.z
	if (target_speed < 0 and linear_speed > 0.01):
		linear_speed = lerp(linear_speed, 0.0, delta * brake_rate)
	else:
		if (target_speed < 0):
			linear_speed = lerp(linear_speed, target_speed / 2, delta * reverse_rate)
		else:
			linear_speed = lerp(linear_speed, target_speed, delta * accel_rate)
	acceleration = lerpf(acceleration, linear_speed + (abs(sphere.angular_velocity.length() * linear_speed) / 100), delta * 1)
	vehicle_model.position = sphere.position - Vector3(0, BASE_MODEL_OFFSET, 0)
	raycast.position = sphere.position
	linear_velocity = (vehicle_model.position - prev_position) / delta
	prev_position = vehicle_model.position
	effect_engine(delta)
	effect_body(delta)
	effect_wheels(delta)
	effect_trails()
	_smash_tick += 1
	if _smasher and _smash_tick % 4 == 0:
		for a in _smasher.get_overlapping_areas():
			if a is Destructible:
				a.try_smash()

func handle_input(delta):
	if raycast.is_colliding():
		input.x = Input.get_axis("left", "right")
		input.z = Input.get_axis("back", "forward")
	sphere.angular_velocity += vehicle_model.get_global_transform().basis.x * (linear_speed * roll_force * size_scale) * delta

func effect_body(delta):
	calculated_lean = lerp_angle(calculated_lean,-input.x / 5 * linear_speed, delta * 5)
	if vehicle_body != null:
		vehicle_body.rotation.x = lerp_angle(vehicle_body.rotation.x,-(linear_speed - acceleration) / 6, delta * 10)
		vehicle_body.rotation.z = calculated_lean
		vehicle_body.position = vehicle_body.position.lerp(Vector3(0, 0.2, 0), delta * 5)

func effect_wheels(delta):
	for wheel in [wheel_fl, wheel_fr, wheel_bl, wheel_br]:
		if wheel != null:
			wheel.rotation.x += acceleration
	if wheel_fl != null: wheel_fl.rotation.y = lerp_angle(wheel_fl.rotation.y,-input.x / 1.5, delta * 10)
	if wheel_fr != null: wheel_fr.rotation.y = lerp_angle(wheel_fr.rotation.y,-input.x / 1.5, delta * 10)

func effect_engine(delta):
	var speed_factor = clamp(abs(linear_speed), 0.0, 1.0)
	var throttle_factor = clamp(abs(input.z), 0.0, 1.0)
	var target_volume = remap(speed_factor + (throttle_factor * 0.5), 0.0, 1.5, -15.0, -5.0)
	engine_sound.volume_db = lerp(engine_sound.volume_db, target_volume, delta * 5.0)
	var target_pitch = remap(speed_factor, 0.0, 1.0, 0.5, 3)
	if throttle_factor > 0.1: target_pitch += 0.2
	engine_sound.pitch_scale = lerp(engine_sound.pitch_scale, target_pitch, delta * 2.0)

func effect_trails():
	var drift_intensity = abs(linear_speed - acceleration) + (abs(calculated_lean) * 2.0)
	var should_emit = drift_intensity > 0.25
	if trail_left != null: trail_left.emitting = should_emit
	if trail_right != null: trail_right.emitting = should_emit
	var target_volume = -80.0
	if should_emit: target_volume = remap(clamp(drift_intensity, 0.25, 2.0), 0.25, 2.0, -10.0, 0.0)
	screech_sound.pitch_scale = lerp(screech_sound.pitch_scale, clamp(abs(linear_speed), 1.0, 3.0), 0.1)
	screech_sound.volume_db = lerp(screech_sound.volume_db, target_volume, 10.0 * get_physics_process_delta_time())

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func _on_sphere_body_entered(_body: Node) -> void:
	if vehicle_body == null: return
	if not impact_sound.playing:
		var impact_velocity: = absf(linear_velocity.dot(vehicle_body.global_basis.z))
		impact_sound.volume_db = clampf(remap(impact_velocity, 0.0, 6.0, -20.0, 0.0), -20.0, 0.0)
		impact_sound.play()
