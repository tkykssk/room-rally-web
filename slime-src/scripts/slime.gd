class_name Slime extends Node3D

## Player slime (replaces the truck). It steers its velocity directly instead of
## spinning a ball, so it stops and turns quickly. The body jiggles with spring
## physics, and props it touches are absorbed in place and dissolved into
## pigment blobs that slosh around inside the body and diffuse into each other,
## so the body colour changes in real time.

## Bumped into something solid; strength 0..1 (for camera shake).
signal bumped(strength: float)

@export_group("Tuning")

@export var steering_strength: float = 3.5

## How quickly turning starts and stops (1/s).
@export var steer_response: float = 16.0

@export var accel_rate: float = 5.0

@export var brake_rate: float = 8.0

@export var reverse_rate: float = 2.0

## Ground speed at full throttle, per unit of size (the truck's top speed).
@export var top_speed: float = 7.0

## How quickly the velocity follows the heading and throttle (1/s). Higher
## means less sliding.
@export var grip: float = 10.0
@export var air_grip: float = 1.5

@export var jump_speed: float = 6.5

@export_group("Body")

@export var body_radius: float = 0.56
@export var base_color: Color = Color(0.45, 0.95, 0.6)
@export var base_blobs: int = 8
@export var base_blob_mass: float = 12.0



@onready var sphere: RigidBody3D = $Sphere
@onready var sphere_shape: SphereShape3D = $Sphere/CollisionShape.shape
@onready var raycast: RayCast3D = $Ground

@onready var body_root: Node3D = $Container
@onready var body_pivot: Node3D = $Container/Body
@onready var body_mesh: MeshInstance3D = $Container/Body/Mesh
@onready var eyes: Node3D = $Container/Body/Eyes
@onready var trail: CPUParticles3D = $Container/Trail

@onready var impact_sound: AudioStreamPlayer3D = $Container/ImpactSound
@onready var gulp_sound: AudioStreamPlayer3D = $Container/GulpSound


var size_scale: float = 1.0
var _vis_scale: float = 1.0
const GROW_PER_TIER:= 1.5
const SPHERE_BASE_RADIUS:= 0.52
const BODY_BOTTOM:= 0.6625


const MOUTH_BASE_RADIUS:= 0.72
var _mouth: Area3D = null
var _mouth_shape: SphereShape3D = null
var _mouth_tick: int = 0

var input: Vector3
var normal: Vector3

var angular_speed: float
var linear_speed: float

var colliding: bool

var linear_velocity: Vector3
var prev_position: Vector3
var _gm: Node = null
var _bump_ready_at: int = 0



const WOBBLE_K:= 90.0
const WOBBLE_C:= 7.0
const WOBBLE_GAIN:= 0.012
const SQUASH_K:= 160.0
const SQUASH_C:= 9.0
const SQUASH_GAIN:= 0.006
var _wobble: Vector3
var _wobble_v: Vector3
var _squash: float
var _squash_v: float
var _bulge_dir: Vector3 = Vector3.FORWARD
var _bulge: float



const MAX_BLOBS:= 24
const BLOB_LIMIT:= 0.82
const BLOB_FLOOR:= -0.5
const INERTIA:= 0.09
const SWIRL:= 0.6
const BUOYANCY:= 0.35
const REPEL_DIST:= 0.5
const REPEL_K:= 3.0
const DIFFUSE_DIST:= 0.6
const DIFFUSE_RATE:= 0.12
const TURBULENCE:= 1.5
const VISCOSITY:= 1.8
const MIN_COLOR:= 0.03

const DIGEST_TIME:= 10.0
const DIGEST_FLOOR:= 60.0
const MIN_MEAL_SHARE:= 0.1

var _bp: PackedVector3Array = []
var _bv: PackedVector3Array = []
var _bl: PackedVector3Array = []
var _bm: PackedFloat32Array = []
var _bd: PackedFloat32Array = []
var _shader_pos: PackedVector4Array = []
var _shader_col: PackedVector4Array = []
var _body_color: Color
var _color_tick: int = 0



func get_vehicle_position() -> Vector3: return body_root.global_position
func get_heading_yaw() -> float: return body_root.global_rotation.y
func get_body_color() -> Color: return _body_color
func get_mouth_position() -> Vector3: return body_pivot.global_position



func _ready() -> void:
	add_to_group("vehicle")
	var gm:= get_tree().get_first_node_in_group("game_manager")
	_gm = gm
	if gm and gm.has_signal("tier_unlocked"):
		gm.tier_unlocked.connect(_on_tier_unlocked)
	sphere_shape = sphere_shape.duplicate()
	$Sphere/CollisionShape.shape = sphere_shape
	body_mesh.material_override = body_mesh.material_override.duplicate()
	gulp_sound.stream = _make_gulp_stream()
	_build_mouth()
	_seed_blobs()
	_apply_scale()
	body_root.position = sphere.position - Vector3(0, sphere_shape.radius, 0)
	prev_position = body_root.global_position
	_update_body_color()
	_push_shader()

func _build_mouth() -> void:
	_mouth = Area3D.new()
	_mouth.collision_layer = 0
	_mouth.collision_mask = 2
	_mouth.monitoring = true
	_mouth_shape = SphereShape3D.new()
	var cs:= CollisionShape3D.new()
	cs.shape = _mouth_shape
	_mouth.add_child(cs)
	body_pivot.add_child(_mouth)

func _on_tier_unlocked(tier: int) -> void:

	set_size_scale(pow(GROW_PER_TIER, tier))

func set_size_scale(s: float) -> void:
	size_scale = s
	var tw:= create_tween()
	tw.tween_property(self, "_vis_scale", s, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_squash_v -= 3.0

func _apply_scale() -> void:
	var r:= body_radius * _vis_scale
	body_pivot.scale = Vector3(r, r, r)
	body_pivot.position.y = BODY_BOTTOM * r
	var sr:= SPHERE_BASE_RADIUS * _vis_scale
	if not is_equal_approx(sphere_shape.radius, sr):

		var dr:= sr - sphere_shape.radius
		sphere_shape.radius = sr
		if dr > 0.0:
			sphere.global_position += Vector3(0, dr, 0)
	raycast.target_position = Vector3(0, -(sr + 0.2), 0)
	trail.scale_amount_min = 0.5 * r / body_radius
	trail.scale_amount_max = 0.9 * r / body_radius

	_mouth.scale = Vector3.ONE * (MOUTH_BASE_RADIUS / body_radius)
	_mouth_shape.radius = 1.0

func _physics_process(delta):

	handle_input(delta)

	var direction = sign(linear_speed)
	if direction == 0: direction = sign(input.z) if abs(input.z) > 0.1 else 1


	var target_angular = -input.x * steering_strength * direction
	angular_speed = lerp(angular_speed, target_angular, 1.0 - exp(-steer_response * delta))

	body_root.rotate_y(angular_speed * delta)



	var was_colliding:= colliding
	colliding = raycast.is_colliding()
	if colliding:
		normal = raycast.get_collision_normal()
		if normal.dot(body_root.global_basis.y) > 0.5:
			var xform = align_with_y(body_root.global_transform, normal)
			body_root.global_transform = body_root.global_transform.interpolate_with(xform, 0.2).orthonormalized()
		if not was_colliding:

			_squash_v += clampf(-linear_velocity.y * 0.6, 0.0, 6.0)

	var target_speed = input.z

	if (target_speed < 0 and linear_speed > 0.01):
		linear_speed = lerp(linear_speed, 0.0, delta * brake_rate)
	else:
		if (target_speed < 0):
			linear_speed = lerp(linear_speed, target_speed / 2, delta * reverse_rate)
		else:
			linear_speed = lerp(linear_speed, target_speed, delta * accel_rate)



	_apply_scale()
	body_root.position = sphere.position - Vector3(0, sphere_shape.radius, 0)
	raycast.position = sphere.position



	var vel: Vector3 = (body_root.global_position - prev_position) / delta
	prev_position = body_root.global_position
	var acc: Vector3 = (vel - linear_velocity) / delta
	linear_velocity = vel
	if acc.length() > 80.0:
		acc = acc.normalized() * 80.0
	var a_local: Vector3 = body_root.global_basis.inverse() * acc



	_step_body(delta, a_local)
	_step_pigments(delta, a_local)
	_push_shader()

	_color_tick += 1
	if _color_tick % 6 == 0:
		_update_body_color()
	trail.emitting = colliding and vel.length() > 0.8


	_mouth_tick += 1
	if _mouth and _mouth_tick % 4 == 0:
		for a in _mouth.get_overlapping_areas():
			if a is Destructible:
				a.try_eat(self)



func handle_input(delta):

	var grounded:= raycast.is_colliding()
	if _gm and not _gm.is_playing():
		input.x = 0.0
		input.z = 0.0
	else:

		input.x = Input.get_axis("left", "right")
		input.z = Input.get_axis("back", "forward")
		if grounded and Input.is_action_just_pressed("bounce"):
			sphere.linear_velocity.y = jump_speed * sqrt(_vis_scale)
			_squash_v -= 5.0



	var fwd:= body_root.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var v:= sphere.linear_velocity
	var v_h:= Vector3(v.x, 0.0, v.z)
	var target:= fwd * linear_speed * top_speed * _vis_scale
	var touching:= grounded or sphere.get_contact_count() > 0
	var k:= 1.0 - exp(-(grip if touching else air_grip) * delta)
	v_h = v_h.lerp(target, k)
	sphere.linear_velocity = Vector3(v_h.x, v.y, v_h.z)
	# Spin to match (rolling without slipping), so the rough floor doesn't
	# brake the ball. The slime's material isn't rough, so against the
	# frictionless walls and boxes the spin can't climb them (it used to wedge
	# the ball up an obstacle, where the ground ray missed).
	sphere.angular_velocity = Vector3.UP.cross(v_h) / sphere_shape.radius



func _step_body(delta: float, a_local: Vector3) -> void:
	var scl:= 1.0 / sqrt(_vis_scale)
	_wobble_v += (-WOBBLE_K * _wobble - WOBBLE_C * _wobble_v - Vector3(a_local.x, 0.0, a_local.z) * WOBBLE_GAIN * WOBBLE_K * scl) * delta
	_wobble += _wobble_v * delta
	if _wobble.length() > 0.25:
		_wobble = _wobble.normalized() * 0.25

	_squash_v += (-SQUASH_K * _squash - SQUASH_C * _squash_v - a_local.y * SQUASH_GAIN * SQUASH_K * scl) * delta
	_squash += _squash_v * delta
	_squash = clampf(_squash, -0.35, 0.45)

	_bulge = move_toward(_bulge, 0.0, delta * 0.8)

	eyes.position = Vector3(_wobble.x, 0.0, _wobble.z) * 0.8
	eyes.scale = Vector3(1.0 + _squash * 0.5, 1.0 - _squash, 1.0 + _squash * 0.5)



func _seed_blobs() -> void:
	var lc:= _to_log(base_color)
	for i in base_blobs:
		var p:= Vector3(randf_range(-1, 1), randf_range(-0.4, 0.6), randf_range(-1, 1)).normalized() * randf_range(0.2, 0.6)
		_add_blob(p, Vector3.ZERO, lc, base_blob_mass, randf_range(-0.2, 0.2))

func absorb_begin(contact_world: Vector3, amount: float) -> void:
	_bulge_dir = _to_body_dir(contact_world)
	_bulge = 0.3
	_squash_v += 1.5
	gulp_sound.pitch_scale = clampf(1.3 / sqrt(maxf(amount / 20.0, 0.5)), 0.6, 1.6) * randf_range(0.9, 1.1)
	gulp_sound.play()


func absorb_hold(contact_world: Vector3, strength: float) -> void:
	_bulge_dir = _bulge_dir.slerp(_to_body_dir(contact_world), 0.2)
	_bulge = maxf(_bulge, 0.25 * strength)


func release_pigment(c: Color, mass: float, world_pos: Vector3) -> void:
	var p:= body_pivot.global_transform.affine_inverse() * world_pos
	if p.length() > BLOB_LIMIT:
		p = p.normalized() * BLOB_LIMIT
	p.y = maxf(p.y, BLOB_FLOOR)
	var v:= -p.normalized() * randf_range(0.6, 1.2) + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.3), randf_range(-0.3, 0.3))

	var dens:= clampf(0.6 - c.v, -0.6, 0.6)
	_add_blob(p, v, _to_log(c), mass, dens)

## Pigment mass the body digests down to. Grows with size like the props'
## points do, so a prop of the current size shifts the colour about as much
## at any size.
func _digest_floor() -> float:
	return DIGEST_FLOOR * pow(_vis_scale, 1.6)

## Pigment mass for a meal: its points, but at least a noticeable share of the
## body so small snacks still help steer the colour.
func pigment_mass(points: float) -> float:
	return maxf(points, MIN_MEAL_SHARE * _digest_floor())

func get_body_radius() -> float:
	return body_radius * _vis_scale

func _to_body_dir(world_pos: Vector3) -> Vector3:
	var local:= body_pivot.global_transform.affine_inverse() * world_pos
	return local.normalized() if local.length() > 0.01 else Vector3.FORWARD

func _add_blob(p: Vector3, v: Vector3, lc: Vector3, m: float, dens: float) -> void:
	if _bp.size() >= MAX_BLOBS:
		_merge_closest_pair()
	_bp.append(p)
	_bv.append(v)
	_bl.append(lc)
	_bm.append(m)
	_bd.append(dens)


func _merge_closest_pair() -> void:
	var best:= INF
	var bi:= 0
	var bj:= 1
	var n:= _bp.size()
	for i in n:
		for j in range(i + 1, n):
			var d:= _bp[i].distance_squared_to(_bp[j]) + _bl[i].distance_squared_to(_bl[j]) * 0.05
			if d < best:
				best = d
				bi = i
				bj = j
	var mi:= _bm[bi]
	var mj:= _bm[bj]
	var t:= mj / (mi + mj)
	_bp[bi] = _bp[bi].lerp(_bp[bj], t)
	_bv[bi] = _bv[bi].lerp(_bv[bj], t)
	_bl[bi] = _bl[bi].lerp(_bl[bj], t)
	_bd[bi] = lerpf(_bd[bi], _bd[bj], t)
	_bm[bi] = mi + mj
	_bp.remove_at(bj)
	_bv.remove_at(bj)
	_bl.remove_at(bj)
	_bm.remove_at(bj)
	_bd.remove_at(bj)

func _step_pigments(delta: float, a_local: Vector3) -> void:
	var n:= _bp.size()


	var inertial:= -a_local * INERTIA / sqrt(_vis_scale)
	var spin:= Vector3(0.0, angular_speed * SWIRL, 0.0)
	for i in n:
		var f:= inertial + Vector3(0.0, -BUOYANCY * _bd[i], 0.0) - spin.cross(_bp[i])
		_bv[i] += f * delta


	for i in n:
		for j in range(i + 1, n):
			var d:= _bp[j] - _bp[i]
			var dist:= d.length()
			if dist < REPEL_DIST and dist > 0.0001:
				var push:= d / dist * (REPEL_DIST - dist) / REPEL_DIST * REPEL_K * delta
				var mi:= _bm[i]
				var mj:= _bm[j]
				_bv[i] -= push * (mj / (mi + mj)) * 2.0
				_bv[j] += push * (mi / (mi + mj)) * 2.0
			if dist < DIFFUSE_DIST:

				var stir:= 1.0 + (_bv[i] - _bv[j]).length() * TURBULENCE
				var rate:= minf(DIFFUSE_RATE * stir * (1.0 - dist / DIFFUSE_DIST) * delta, 0.5)
				var li:= _bl[i]
				var lj:= _bl[j]
				var mi2:= _bm[i]
				var mj2:= _bm[j]
				_bl[i] = li.lerp(lj, rate * mj2 / (mi2 + mj2))
				_bl[j] = lj.lerp(li, rate * mi2 / (mi2 + mj2))




	var total:= 0.0
	for i in n:
		total += _bm[i]
	var floor_mass:= _digest_floor()
	if total > floor_mass:
		var k:= maxf(exp(-delta / DIGEST_TIME), floor_mass / total)
		for i in n:
			_bm[i] *= k

	var damp:= exp(-VISCOSITY * delta)
	for i in n:
		var v:= _bv[i] * damp
		var p:= _bp[i] + v * delta
		var r:= p.length()
		if r > BLOB_LIMIT:
			var nrm:= p / r
			p = nrm * BLOB_LIMIT
			var vn:= v.dot(nrm)
			if vn > 0.0:
				v -= nrm * vn * 1.5
		if p.y < BLOB_FLOOR:
			p.y = BLOB_FLOOR
			if v.y < 0.0:
				v.y = -v.y * 0.5
		_bp[i] = p
		_bv[i] = v

func _push_shader() -> void:
	var n:= _bp.size()
	_shader_pos.resize(MAX_BLOBS)
	_shader_col.resize(MAX_BLOBS)
	for i in n:
		var p:= _bp[i]
		var l:= _bl[i]
		_shader_pos[i] = Vector4(p.x, p.y, p.z, 0.0)
		_shader_col[i] = Vector4(l.x, l.y, l.z, _bm[i])
	var mat: ShaderMaterial = body_mesh.material_override
	mat.set_shader_parameter("blob_pos", _shader_pos)
	mat.set_shader_parameter("blob_col", _shader_col)
	mat.set_shader_parameter("blob_count", n)
	mat.set_shader_parameter("wobble", _wobble)
	mat.set_shader_parameter("squash", _squash)
	mat.set_shader_parameter("bulge", Vector4(_bulge_dir.x, _bulge_dir.y, _bulge_dir.z, _bulge))

func _update_body_color() -> void:
	var acc:= Vector3.ZERO
	var ws:= 0.0
	for i in _bp.size():
		acc += _bl[i] * _bm[i]
		ws += _bm[i]
	if ws <= 0.0:
		_body_color = base_color
	else:
		var l:= acc / ws
		_body_color = Color(exp(l.x), exp(l.y), exp(l.z))
	trail.color = Color(_body_color, 0.8)

static func _to_log(c: Color) -> Vector3:
	return Vector3(log(maxf(c.r, MIN_COLOR)), log(maxf(c.g, MIN_COLOR)), log(maxf(c.b, MIN_COLOR)))



func _make_gulp_stream() -> AudioStreamWAV:
	var rate:= 22050
	var length:= 0.2
	var n:= int(rate * length)
	var data:= PackedByteArray()
	data.resize(n * 2)
	var ph:= 0.0
	for i in n:
		var t:= float(i) / float(rate) / length
		var f:= lerpf(560.0, 150.0, pow(t, 0.6))
		ph += TAU * f / float(rate)
		var env:= pow(sin(PI * t), 0.7) * (1.0 - t * 0.5)
		var s:= sin(ph) * env * 0.55
		data.encode_s16(i * 2, int(s * 32767.0))
	var w:= AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w



func align_with_y(xform, new_y):

	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform



func _on_sphere_body_entered(body: Node) -> void:


	if body is StaticBody3D and not body.is_in_group("ground") and Time.get_ticks_msec() >= _bump_ready_at:
		var hit:= clampf(absf(linear_speed), 0.0, 1.0)
		if hit > 0.25:
			_bump_ready_at = Time.get_ticks_msec() + 250
			linear_speed *= 0.25
			bumped.emit(hit)
	var impact_velocity:= linear_velocity.length()
	_squash_v += clampf(impact_velocity * 0.4, 0.0, 3.0)
	if not impact_sound.playing:
		impact_sound.volume_db = clampf(remap(impact_velocity, 0.0, 6.0, -24.0, -4.0), -24.0, -4.0)
		impact_sound.play()
