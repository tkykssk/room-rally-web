class_name Katamari extends RigidBody3D

## The rolling ball. Anything whose size is below PICK_RATIO x the ball's
## diameter sticks to it (see Absorbable) and grows it (see _add_item_growth).
## Slamming into something too big at speed knocks recent items back off.

signal size_changed(diameter: float)
signal item_absorbed(item_name: String, world_pos: Vector3, item_size: float)
signal items_lost(count: int)
signal bumped(strength: float)

## Props up to this fraction of the ball's diameter can be rolled up.
const PICK_RATIO: = 0.6
## How far (in item extents) a stuck item sinks below the surface.
const EMBED: = 0.35
const PROP_SCENE: = preload("res://scenes/props/prop.tscn")
const KNOB_COLORS: = [Color("ffd23f"), Color("3fd0c9"), Color("8ad24f"), Color("ff8a3c"), Color("b58cff")]

@export_group("Tuning")
@export var base_radius: float = 0.4
## Top speed at the starting size (units/s); scales with size ^ speed_exponent.
@export var base_speed: float = 3.4
@export var speed_exponent: float = 0.6
## How quickly the ball's spin approaches the target spin.
@export var spin_accel: float = 5.0
## Extra direct push (m/s^2) on top of rolling.
@export var push_force: float = 6.0
## Turn rate of the heading (and so the camera) in rad/s.
@export var turn_speed: float = 2.4
## Each item adds growth * item_size^growth_exponent to diameter^growth_exponent.
## 2 = items coat the surface (small things still count), 3 = pure volume.
@export var growth: float = 1.2
@export var growth_exponent: float = 2.0
## Cap on how much a single item can grow the diameter (1.04 = +4%).
@export var max_step_growth: float = 1.04
## Hitting an obstacle faster than this fraction of top speed loses items.
@export var knock_speed_ratio: float = 0.7
## Inner half-size of the room (walls are at +/- this).
@export var room_half: float = 40.0
## Stuck items beyond this count are dropped (oldest first) to bound draw calls.
@export var max_stuck: int = 150

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var core: MeshInstance3D = $Core
@onready var stuck_root: Node3D = $Stuck
@onready var pickup: Area3D = $Pickup
@onready var pickup_shape: CollisionShape3D = $Pickup/CollisionShape3D

var radius: float = 0.4
var size_scale: float = 1.0
var heading: float = 0.0
var input: Vector2
var items: int = 0

var _manager: Node = null
var _rp: float = 0.0
var _target_radius: float = 0.4
var _pending_lift: float = 0.0
var _pickup_tick: int = 0
var _reported_diameter: float = 0.0
var _knock_ready_at: int = 0
var _pruned_at_radius: float = 0.0
var _wedged_time: float = 0.0

static var _sparkle_mesh: QuadMesh = null

func get_player_position() -> Vector3: return global_position
func get_heading_yaw() -> float: return heading
func get_horizontal_speed() -> float: return Vector2(linear_velocity.x, linear_velocity.z).length()
func get_diameter() -> float: return radius * 2.0
func top_speed() -> float: return base_speed * pow(size_scale, speed_exponent)

func _ready() -> void:
	add_to_group("player")
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	# Shapes are per-instance so growing one ball never touches another.
	collision.shape = collision.shape.duplicate()
	pickup_shape.shape = pickup_shape.shape.duplicate()
	core.mesh = _build_ball_mesh()
	_rp = pow(base_radius, growth_exponent)
	_target_radius = base_radius
	_set_radius(base_radius)
	_manager = get_tree().get_first_node_in_group("game_manager")

func _is_playing() -> bool:
	return _manager == null or _manager.is_playing()

func _set_radius(r: float) -> void:
	radius = r
	size_scale = r / base_radius
	(collision.shape as SphereShape3D).radius = r
	(pickup_shape.shape as SphereShape3D).radius = r * 1.3
	core.scale = Vector3.ONE * size_scale
	var d: = r * 2.0
	if absf(d - _reported_diameter) > _reported_diameter * 0.01 or is_equal_approx(r, _target_radius):
		if not is_equal_approx(d, _reported_diameter):
			_reported_diameter = d
			size_changed.emit(d)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Growing the collision sphere would sink it into the floor; lift it by
	# the same amount so it stays resting on the ground.
	var xf: = state.transform
	var moved: = false
	if _pending_lift > 0.0:
		xf.origin.y += _pending_lift
		moved = true
	_pending_lift = 0.0
	# Hard room bounds: a huge ball being shoved (or lifted) into a wall must
	# never tunnel out of the world.
	var lim: = maxf(room_half - radius, 0.0)
	var v: = state.linear_velocity
	for axis in [0, 2]:
		if absf(xf.origin[axis]) > lim:
			xf.origin[axis] = clampf(xf.origin[axis], -lim, lim)
			if signf(v[axis]) == signf(xf.origin[axis]):
				v[axis] = 0.0
			moved = true
	if xf.origin.y < radius * 0.5:
		xf.origin.y = radius
		v.y = maxf(v.y, 0.0)
		moved = true
	if moved:
		state.transform = xf
		state.linear_velocity = v

func _physics_process(delta: float) -> void:
	_update_growth(delta)
	if _is_playing():
		input = Vector2(Input.get_axis("left", "right"), Input.get_axis("back", "forward"))
	else:
		input = Vector2.ZERO
	heading -= input.x * turn_speed * delta
	var forward: = Vector3(-sin(heading), 0.0, -cos(heading))
	# Rolling without slipping: spin axis = up x direction, rate = v / r.
	var target_spin: = Vector3.UP.cross(forward) * (input.y * top_speed() / radius)
	var spin: = angular_velocity
	var horizontal: = Vector3(spin.x, 0.0, spin.z)
	var rate: = spin_accel if absf(input.y) > 0.05 else spin_accel * 0.5
	horizontal = horizontal.lerp(target_spin, clampf(delta * rate, 0.0, 1.0))
	angular_velocity = Vector3(horizontal.x, spin.y * 0.9, horizontal.z)
	# A direct push as well as spin, so the ball can shove its way out of a
	# wedge instead of spinning in place.
	if absf(input.y) > 0.05:
		apply_central_force(forward * input.y * push_force * mass * sqrt(size_scale))
	_check_wedged(delta)
	_pickup_tick += 1
	if _pickup_tick % 2 == 0 and _is_playing():
		var d: = radius * 2.0
		for a in pickup.get_overlapping_areas():
			if a is Absorbable and a.can_be_absorbed_by(d):
				a.absorb_into(self)

## Pushing but not moving (e.g. jammed between a table and a chair, often
## after growing into the gap): hop up and away from whatever we're touching.
func _check_wedged(delta: float) -> void:
	if input.length() < 0.3 or get_horizontal_speed() > top_speed() * 0.08:
		_wedged_time = 0.0
		return
	_wedged_time += delta
	if _wedged_time < 0.7:
		return
	_wedged_time = 0.0
	var away: = Vector3.ZERO
	for b in get_colliding_bodies():
		if b.is_in_group("ground"):
			continue
		var c: Vector3 = (b as Node3D).global_position
		var owner_prop: = b.get_parent()
		if owner_prop is Absorbable:
			c = owner_prop.to_global(owner_prop._center)
		var d: = global_position - c
		d.y = 0.0
		away += d.normalized()
	if away == Vector3.ZERO:
		return
	away = away.normalized()
	apply_central_impulse((away * 4.0 + Vector3.UP * 2.0) * mass * sqrt(size_scale))

func _update_growth(delta: float) -> void:
	if is_equal_approx(radius, _target_radius):
		return
	var r: = lerpf(radius, _target_radius, clampf(delta * 8.0, 0.0, 1.0))
	if absf(r - _target_radius) < 0.002:
		r = _target_radius
	if r > radius:
		_pending_lift += r - radius
		_push_stuck_out(r - radius)
	_set_radius(r)
	if radius > _pruned_at_radius * 1.08:
		_pruned_at_radius = radius
		_prune_buried()

## Grow by one item; returns the amount actually added to radius^exponent so
## a knock-off can take back exactly that much.
func _add_item_growth(item_size: float) -> float:
	var before: = _rp
	_rp += growth * pow(item_size * 0.5, growth_exponent)
	var r: = pow(_rp, 1.0 / growth_exponent)
	if r > _target_radius * max_step_growth:
		# One huge item shouldn't snowball the ball through the whole room.
		r = _target_radius * max_step_growth
		_rp = pow(r, growth_exponent)
	_target_radius = r
	return _rp - before

func _remove_item_growth(gain: float) -> void:
	_rp = maxf(_rp - gain, pow(base_radius, growth_exponent))
	_target_radius = pow(_rp, 1.0 / growth_exponent)

## Re-parent an absorbed object's model onto the ball surface.
## `center` is the object's world-space centre.
func attach(model: Node3D, center: Vector3, spec: Dictionary) -> void:
	var dir: = center - global_position
	if dir.length() < 0.001:
		dir = Vector3.UP
	dir = dir.normalized()
	var extent: float = spec.get("extent", 0.2)
	var target_center: = global_position + dir * maxf(radius - extent * EMBED, radius * 0.6)
	var gt: = model.global_transform
	model.get_parent().remove_child(model)
	stuck_root.add_child(model)
	model.global_transform = gt
	var start_pos: = model.position
	gt.origin += target_center - center
	model.global_transform = gt
	var end_pos: = model.position
	var s: float = spec.get("scale", 1.0)
	model.set_meta("spec", spec)
	# Snap-in: slide onto the surface with a little scale pop.
	model.position = start_pos
	model.scale = Vector3.ONE * s * 1.3
	var tw: = model.create_tween().set_parallel(true)
	tw.tween_property(model, "position", end_pos, 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, "scale", Vector3.ONE * s, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if stuck_root.get_child_count() > max_stuck:
		stuck_root.get_child(0).queue_free()
	var item_size: float = spec.get("size", 0.2)
	spec["gain"] = _add_item_growth(item_size)
	items += 1
	_sparkle(center, item_size)
	var rel: = clampf(item_size / (radius * 2.0 * PICK_RATIO), 0.0, 1.0)
	Audio.play("pickup_big" if rel > 0.55 else "pickup", lerpf(1.35, 0.8, rel) * randf_range(0.95, 1.05))
	item_absorbed.emit(spec.get("name", ""), center, item_size)

## Keep the collected junk riding on the surface as the core grows.
func _push_stuck_out(dr: float) -> void:
	for c in stuck_root.get_children():
		var p: Vector3 = c.position
		if p.length_squared() > 0.0001:
			c.position = p + p.normalized() * dr

## Items that have become specks relative to the ball are freed.
func _prune_buried() -> void:
	for c in stuck_root.get_children():
		var spec: Dictionary = c.get_meta("spec", {})
		if spec.get("extent", 0.0) < radius * 0.07:
			c.queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("ground"):
		return
	var v: = get_horizontal_speed()
	var strength: = clampf(v / top_speed(), 0.0, 1.5)
	if strength < 0.25:
		return
	bumped.emit(strength)
	Audio.play("bump", clampf(1.3 / pow(size_scale, 0.3), 0.5, 1.4) * randf_range(0.9, 1.1), lerpf(-14.0, 0.0, clampf(strength, 0.0, 1.0)))
	if strength >= knock_speed_ratio and Time.get_ticks_msec() >= _knock_ready_at and _is_playing():
		_knock_ready_at = Time.get_ticks_msec() + 900
		# Deferred: spawning props isn't allowed inside a physics callback.
		_knock_off.call_deferred(clampi(1 + int((strength - knock_speed_ratio) * 8.0), 1, 4))

## Drop the most recently collected items back into the room.
func _knock_off(count: int) -> void:
	var props_root: = get_tree().get_first_node_in_group("props_root")
	if props_root == null:
		return
	var lost: = 0
	var back: = -Vector3(linear_velocity.x, 0.0, linear_velocity.z).normalized()
	for i in range(stuck_root.get_child_count() - 1, -1, -1):
		if lost >= count:
			break
		var model: Node3D = stuck_root.get_child(i)
		if model.is_queued_for_deletion() or not model.has_meta("spec"):
			continue
		var spec: Dictionary = model.get_meta("spec")
		var from: = model.global_position
		stuck_root.remove_child(model)
		model.transform = Transform3D.IDENTITY
		var p: Absorbable = PROP_SCENE.instantiate()
		p.model_node = model
		p.display_name = spec.get("name", "")
		p.target_scale = spec.get("scale", 1.0)
		p.set_cooldown(1.5)
		var dir: = back.rotated(Vector3.UP, randf_range(-1.0, 1.0))
		var land: = global_position + dir * (radius + 1.0 + randf() * radius * 1.5)
		land.x = clampf(land.x, -38.0, 38.0)
		land.z = clampf(land.z, -38.0, 38.0)
		land.y = 0.0
		props_root.add_child(p)
		p.rotation.y = randf() * TAU
		_toss(p, from, land)
		_remove_item_growth(spec.get("gain", 0.0))
		items -= 1
		lost += 1
	if lost > 0:
		Audio.play("knock")
		items_lost.emit(lost)

func _toss(p: Node3D, from: Vector3, land: Vector3) -> void:
	p.global_position = from
	var peak: = 1.0 + radius
	p.create_tween().tween_method(_toss_step.bind(p, from, land, peak), 0.0, 1.0, 0.55)

func _toss_step(t: float, p: Node3D, from: Vector3, land: Vector3, peak: float) -> void:
	if not is_instance_valid(p):
		return
	var pos: = from.lerp(land, t)
	pos.y += 4.0 * peak * t * (1.0 - t)
	p.global_position = pos

func _sparkle(pos: Vector3, item_size: float) -> void:
	if _sparkle_mesh == null:
		_sparkle_mesh = QuadMesh.new()
		var mat: = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_sparkle_mesh.material = mat
	var fx: = CPUParticles3D.new()
	fx.one_shot = true
	fx.emitting = false
	fx.explosiveness = 1.0
	fx.amount = 6 if item_size < radius else 12
	fx.lifetime = 0.45
	fx.mesh = _sparkle_mesh
	fx.direction = Vector3.UP
	fx.spread = 180.0
	fx.gravity = Vector3(0, -2.0, 0)
	var k: = maxf(item_size, radius * 0.4)
	fx.initial_velocity_min = 1.5 * k
	fx.initial_velocity_max = 3.5 * k
	fx.scale_amount_min = 0.12 * k
	fx.scale_amount_max = 0.25 * k
	var ramp: = Gradient.new()
	ramp.set_color(0, Color(1, 1, 0.7, 1))
	ramp.set_color(1, Color(1, 0.6, 0.9, 0))
	fx.color_ramp = ramp
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(fx)
	fx.global_position = pos
	fx.emitting = true
	fx.finished.connect(fx.queue_free)

## Pink core with coloured knobs, so the roll reads clearly at any size.
func _build_ball_mesh() -> ArrayMesh:
	var b: = ToyFactory._Builder.new()
	var r: = base_radius
	b.sphere(r, Vector3.ZERO, Color("e0468a"), 20)
	var n: = 22
	for i in n:
		# Fibonacci sphere for an even spread of knobs.
		var y: = 1.0 - 2.0 * (i + 0.5) / n
		var ring: = sqrt(1.0 - y * y)
		var a: = i * 2.39996
		var normal: = Vector3(cos(a) * ring, y, sin(a) * ring)
		var basis: = Basis(Quaternion(Vector3.UP, normal))
		var stem: = CylinderMesh.new()
		stem.top_radius = r * 0.12
		stem.bottom_radius = r * 0.16
		stem.height = r * 0.3
		stem.radial_segments = 8
		stem.rings = 1
		b.add_xf(stem, Transform3D(basis, normal * r * 1.05), Color("c23a76"))
		var tip: = SphereMesh.new()
		tip.radius = r * 0.17
		tip.height = r * 0.34
		tip.radial_segments = 8
		tip.rings = 4
		b.add_xf(tip, Transform3D(basis, normal * r * 1.2), KNOB_COLORS[i % KNOB_COLORS.size()])
	var mesh: = b.commit()
	var mat: = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.45
	mesh.surface_set_material(0, mat)
	return mesh
