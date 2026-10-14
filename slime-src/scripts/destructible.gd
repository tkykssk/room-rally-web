class_name Destructible extends Area3D

## Emitted when this prop is smashed (props resting on it fall down).
signal destroyed

@export var model_scene: PackedScene
## Ready-made model (procedural toys) used instead of model_scene.
var model_node: Node3D = null
@export var size_tier: int = 0
@export var score_value: int = 10
@export var target_height: float = 1.0
@export var target_scale: float = 0.0
@export var base_y: float = 0.0
## Footprint fraction that is solid (trees and parasols collide with their
## trunk or pole only, not an invisible box around the canopy).
var solid_frac: = Vector2.ONE
## Colour for food models, whose colormap texture is missing (alpha 0 = keep).
@export var tint: Color = Color(0, 0, 0, 0)

var _manager: Node = null
var _destroyed: bool = false
var _solid: StaticBody3D = null
## Radius of a circle covering the footprint (used to keep clutter out from under furniture).
var footprint_radius: float = 0.0
## Prop this one rests on (e.g. a cup on a table); when it is smashed this
## one drops to the support's base height.
var support: Destructible = null
## Collision box in local space (top surface used for placing items on it).
var box_center: = Vector3.ZERO
var box_size: = Vector3.ZERO
## Local bounds, used to fade the prop when the camera ends up inside it.
var _bounds: AABB = AABB()

const OCCLUDED_ALPHA: = 0.1
const FADE_SPEED: = 12.0
var _fade_mats: Array = []
var _cur_alpha: float = 1.0
var _occlude_radius: float = 1.0
var _vehicle: Node = null
var _occ_target: float = 1.0
var _occ_timer: float = 0.0

## Absorption by the slime: the prop stays where it touched, sinks into the
## body and is eaten away from the contact point while its colours are
## released into the body as pigment.
const DISSOLVE_SHADER: = preload("res://shaders/prop_dissolve.gdshader")
const RELEASES_PER_COLOR: = 3
var _eater: Node3D = null
var _model: Node3D = null
var _palette: Array = []
static var _palette_cache: = {}
var _abs_t: float = 0.0
var _abs_time: float = 2.0
var _abs_start: Transform3D
var _abs_contact: Vector3
var _abs_extent: float = 1.0
var _abs_started: bool = false
var _released: int = 0
var _dissolve_mats: Array = []

const IMPACT_SFX: = preload("res://audio/impact.res")
static var _debris_mesh_shared: Mesh = null

static func _get_debris_mesh() -> Mesh:
	if _debris_mesh_shared == null:
		var m: = BoxMesh.new()
		m.size = Vector3(0.5, 0.5, 0.5)
		var mat: = StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.6
		m.material = mat
		_debris_mesh_shared = m
	return _debris_mesh_shared

## Confetti-coloured debris so a smash reads as a reward, not a crash.
static var _debris_colors: Gradient = null
static func _get_debris_colors() -> Gradient:
	if _debris_colors == null:
		_debris_colors = Gradient.new()
		_debris_colors.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
		_debris_colors.colors = PackedColorArray([Color("ffd23f"), Color("ff5c8a"), Color("3fd0c9"), Color("8ad24f"), Color("ff8a3c")])
		_debris_colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	return _debris_colors

func _ready() -> void:
	add_to_group("edible")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
	_manager = get_tree().get_first_node_in_group("game_manager")
	if _manager and _manager.has_signal("tier_unlocked"):
		_manager.tier_unlocked.connect(_on_tier_unlocked)
	_build()
	_update_solid()
	_occ_timer = randf() * 0.1

func is_destroyable() -> bool:
	if _manager == null:
		return true
	return size_tier <= _manager.unlocked_tier

func _build() -> void:
	if model_scene == null and model_node == null:
		return
	var model: Node3D = model_node if model_node else model_scene.instantiate()
	var variant: = randi() % Palette.FABRIC.size()
	Palette.apply(model, variant, tint)
	add_child(model)
	_model = model
	_palette = _get_palette(model, variant)
	var aabb: = _local_aabb(model)
	var nh: float = maxf(aabb.size.y, 0.001)
	var s: float = target_scale if target_scale > 0.0 else target_height / nh
	model.scale = Vector3(s, s, s)
	model.position.y = base_y - aabb.position.y * s
	var w: float = maxf(aabb.size.x * s, 0.2)
	var d: float = maxf(aabb.size.z * s, 0.2)
	var hgt: float = aabb.size.y * s
	footprint_radius = 0.5 * Vector2(w, d).length() + Vector2(
		(aabb.position.x + aabb.size.x * 0.5) * s, (aabb.position.z + aabb.size.z * 0.5) * s).length()
	var box: = BoxShape3D.new()
	box.size = Vector3(w, hgt, d)
	var cx: = (aabb.position.x + aabb.size.x * 0.5) * s
	var cz: = (aabb.position.z + aabb.size.z * 0.5) * s
	var center: = Vector3(cx, base_y + hgt * 0.5, cz)
	box_center = center
	box_size = Vector3(w, hgt, d)
	var area_cs: = CollisionShape3D.new()
	area_cs.shape = box
	area_cs.position = center
	add_child(area_cs)
	_solid = StaticBody3D.new()
	_solid.physics_material_override = obstacle_material()
	add_child(_solid)
	if size_tier > 0 and _is_open_furniture():
		_add_mesh_collision(model)
	else:
		var solid_cs: = CollisionShape3D.new()
		if solid_frac == Vector2.ONE:
			solid_cs.shape = box
		else:
			var core: = BoxShape3D.new()
			core.size = Vector3(maxf(w * solid_frac.x, 0.2), hgt, maxf(d * solid_frac.y, 0.2))
			solid_cs.shape = core
		solid_cs.position = center
		_solid.add_child(solid_cs)
	_occlude_radius = 0.5 * maxf(w, d)
	_bounds = AABB(center - box.size * 0.5, box.size).grow(0.6)
	if size_tier > 0:
		_prepare_fade(model)

## Tables get a top slab plus four leg posts, so the truck can drive under
## them while it is small. (Their full mesh as collision trapped the ball in
## the leg braces; a plain box felt like an invisible wall.) Everything else,
## chairs included, keeps a box.
const OPEN_MODELS: = ["table.glb"]
const OPEN_MIN_HEIGHT: = 5.0

func _is_open_furniture() -> bool:
	return model_scene != null and target_height >= OPEN_MIN_HEIGHT \
		and model_scene.resource_path.get_file() in OPEN_MODELS

func _add_mesh_collision(model: Node3D) -> void:
	var inv: = global_transform.affine_inverse()
	var pts: = PackedVector3Array()
	var stack: Array = [model]
	while not stack.is_empty():
		var n = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D and n.mesh != null:
			var xf: Transform3D = inv * n.global_transform
			for v in n.mesh.get_faces():
				pts.append(xf * v)
	if pts.is_empty():
		return
	var top_y: = -INF
	var low_y: = INF
	for v in pts:
		top_y = maxf(top_y, v.y)
		low_y = minf(low_y, v.y)
	var h: = top_y - low_y
	# Tabletop (and apron): everything in the top 20%.
	var top: = AABB()
	var first: = true
	for v in pts:
		if v.y > top_y - h * 0.2:
			if first:
				top = AABB(v, Vector3.ZERO)
				first = false
			else:
				top = top.expand(v)
	_add_solid_box(top.position, top.end)
	# Legs: what is in the lower half, one post per quadrant.
	var c: = top.get_center()
	var legs: = {}
	for v in pts:
		if v.y < low_y + h * 0.5:
			var k: = int(v.x > c.x) * 2 + int(v.z > c.z)
			legs[k] = legs[k].expand(v) if legs.has(k) else AABB(v, Vector3.ZERO)
	for k in legs:
		var a: AABB = legs[k]
		_add_solid_box(Vector3(a.position.x, low_y, a.position.z), Vector3(a.end.x, top.position.y, a.end.z))

func _add_solid_box(from: Vector3, to: Vector3) -> void:
	var sz: = (to - from).abs()
	var shape: = BoxShape3D.new()
	shape.size = Vector3(maxf(sz.x, 0.1), maxf(sz.y, 0.1), maxf(sz.z, 0.1))
	var cs: = CollisionShape3D.new()
	cs.shape = shape
	cs.position = (from + to) * 0.5
	_solid.add_child(cs)

## Obstacles are slippery (the ball takes the lower friction, so it slides
## along instead of climbing them) with a little bounce.
static var _obstacle_mat: PhysicsMaterial = null
static func obstacle_material() -> PhysicsMaterial:
	if _obstacle_mat == null:
		_obstacle_mat = PhysicsMaterial.new()
		_obstacle_mat.friction = 0.0
		_obstacle_mat.bounce = 0.25
	return _obstacle_mat

func _prepare_fade(model: Node3D) -> void:
	var stack: Array = [model]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D and n.mesh != null:
			for si in n.mesh.get_surface_count():
				var m = n.get_active_material(si)
				if m is BaseMaterial3D:
					var dup: BaseMaterial3D = m.duplicate()
					# Alpha-blended from load, with depth writes so it looks
					# solid at alpha 1: fading then only changes a colour
					# uniform. Toggling `transparency` at runtime rebuilds the
					# shader and caused frame spikes. (Alpha hash renders black
					# in the Compatibility renderer, so it's not used.)
					dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					dup.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
					n.set_surface_override_material(si, dup)
					_fade_mats.append(dup)

func _update_solid() -> void:
	if _solid:
		_solid.collision_layer = 0 if is_destroyable() else 1

func _on_tier_unlocked(_tier: int) -> void:
	_update_solid()

func _process(delta: float) -> void:
	if _eater != null:
		_process_eaten(delta)
		return
	if _destroyed or _fade_mats.is_empty():
		return
	_occ_timer -= delta
	if _occ_timer <= 0.0:
		_occ_timer = 0.1
		_occ_target = OCCLUDED_ALPHA if (not is_destroyable() and _is_occluding_car()) else 1.0
	if not is_equal_approx(_cur_alpha, _occ_target):
		_cur_alpha = lerpf(_cur_alpha, _occ_target, clampf(delta * FADE_SPEED, 0.0, 1.0))
		if absf(_cur_alpha - _occ_target) < 0.02:
			_cur_alpha = _occ_target
		_apply_alpha(_cur_alpha)

func _apply_alpha(a: float) -> void:
	for m in _fade_mats:
		var col: Color = m.albedo_color
		col.a = a
		m.albedo_color = col

func _is_occluding_car() -> bool:
	var cam: = get_viewport().get_camera_3d()
	if cam == null:
		return false
	if _vehicle == null:
		_vehicle = get_tree().get_first_node_in_group("vehicle")
		if _vehicle == null:
			return false
	var car: Vector3 = _vehicle.get_vehicle_position() if _vehicle.has_method("get_vehicle_position") else (_vehicle as Node3D).global_position
	var cam_pos: = cam.global_position
	if _bounds.has_point(to_local(cam_pos)):
		return true
	var prop_pos: = global_position + Vector3(0, target_height * 0.4, 0)
	var to_car: = car - cam_pos
	var car_dist: = to_car.length()
	if car_dist < 0.01:
		return false
	var dir: = to_car / car_dist
	var to_prop: = prop_pos - cam_pos
	var t: = to_prop.dot(dir)
	if t <= 0.3 or t >= car_dist:
		return false
	var perp: = (to_prop - dir * t).length()
	return perp < (_occlude_radius + 1.8)

func try_smash() -> void:
	if not _destroyed and is_destroyable():
		_destroy()

func try_eat(eater: Node3D) -> void:
	if _destroyed or not is_destroyable():
		return
	_destroyed = true
	_eater = eater
	destroyed.emit()
	if _solid:
		_solid.collision_layer = 0
	set_deferred("monitorable", false)
	if _manager and _manager.has_method("add_score"):
		_manager.add_score(score_value)
		_manager.report_smash(global_position + Vector3(0, target_height, 0), score_value, target_height)
	# Contact point: the point of the collision box nearest the slime.
	var mouth: Vector3 = eater.get_mouth_position()
	var local_mouth: = global_transform.affine_inverse() * mouth
	var half: = box_size * 0.5
	var contact: = global_transform * local_mouth.clamp(box_center - half, box_center + half)
	eater.absorb_begin(contact, float(score_value))
	# Reparenting during the physics query that found us is not allowed.
	_begin_absorb.call_deferred(contact)

func _begin_absorb(contact_world: Vector3) -> void:
	if not is_instance_valid(_eater):
		queue_free()
		return
	if _solid:
		_solid.queue_free()
		_solid = null
	_fade_mats.clear()
	_make_dissolvable()
	var pivot: Node3D = _eater.body_pivot
	reparent(pivot)
	_abs_start = transform
	_abs_contact = pivot.global_transform.affine_inverse() * contact_world
	_abs_extent = maxf(box_size.length(), 0.3)
	_abs_time = clampf(1.2 + 1.8 * box_size.length() / _eater.get_body_radius(), 1.2, 4.0)
	_abs_started = true

func _make_dissolvable() -> void:
	if _model == null:
		return
	for n in _mesh_instances(_model):
		for si in n.mesh.get_surface_count():
			var m = n.get_active_material(si)
			var sm: = ShaderMaterial.new()
			sm.shader = DISSOLVE_SHADER
			if m is BaseMaterial3D:
				sm.set_shader_parameter("albedo", Color(m.albedo_color, 1.0))
				sm.set_shader_parameter("roughness", m.roughness)
				sm.set_shader_parameter("use_vertex_color", m.vertex_color_use_as_albedo)
			n.set_surface_override_material(si, sm)
			_dissolve_mats.append(sm)

func _process_eaten(delta: float) -> void:
	if not is_instance_valid(_eater):
		queue_free()
		return
	if not _abs_started:
		return
	_abs_t += delta
	var k: = clampf(_abs_t / _abs_time, 0.0, 1.0)
	var e: = 1.0 - (1.0 - k) * (1.0 - k)
	# Sink: shrink a little around the contact point while it moves inwards.
	var s: = lerpf(1.0, 0.55, e)
	var target: = _abs_contact * lerpf(1.0, 0.15, e)
	transform = Transform3D(Basis.from_scale(Vector3(s, s, s)), target) * Transform3D(Basis(), -_abs_contact) * _abs_start
	var pivot: Node3D = _eater.body_pivot
	var contact_world: = pivot.global_transform * target
	var center_world: = global_transform * box_center
	var edge: Color = _eater.get_body_color()
	for m in _dissolve_mats:
		m.set_shader_parameter("contact", contact_world)
		m.set_shader_parameter("extent", _abs_extent * s)
		m.set_shader_parameter("progress", k)
		m.set_shader_parameter("edge_color", edge)
	_eater.absorb_hold(contact_world, 1.0 - k)
	# Release the colours in steps from the dissolve front.
	var n: = _palette.size()
	while _released < RELEASES_PER_COLOR * n and k >= (float(int(_released / n)) + 0.5) / RELEASES_PER_COLOR:
		var entry: Array = _palette[_released % n]
		var front: = contact_world.lerp(center_world, minf(k * 1.4, 1.0))
		_eater.release_pigment(entry[0], _eater.pigment_mass(score_value) * entry[1] / RELEASES_PER_COLOR, front)
		_released += 1
	if k >= 1.0:
		queue_free()

## The colour eating this prop pushes the slime towards: its palette mixed
## the way the slime mixes pigment (log space, weighted by area).
func eaten_color() -> Color:
	var acc: = Vector3.ZERO
	for e in _palette:
		var c: Color = e[0]
		acc += Vector3(log(maxf(c.r, 0.03)), log(maxf(c.g, 0.03)), log(maxf(c.b, 0.03))) * float(e[1])
	return Color(exp(acc.x), exp(acc.y), exp(acc.z))

## Up to three dominant colours of the model, weighted by surface area and
## made more saturated so they show when mixed into the slime.
func _get_palette(model: Node3D, variant: int) -> Array:
	var key: = ""
	if model_scene:
		key = "%s|%d|%s" % [model_scene.resource_path, variant, tint]
		if _palette_cache.has(key):
			return _palette_cache[key]
	var areas: = {}
	for n in _mesh_instances(model):
		for si in n.mesh.get_surface_count():
			var m = n.get_active_material(si)
			var col: = Color(0.9, 0.9, 0.9)
			var use_vc: = false
			if m is BaseMaterial3D:
				col = m.albedo_color
				use_vc = m.vertex_color_use_as_albedo
			_add_surface_colors(n.mesh, si, col, use_vc, areas)
	var keys: = areas.keys()
	keys.sort_custom(func(a, b): return areas[a] > areas[b])
	keys = keys.slice(0, 3)
	var total: = 0.0
	for c in keys:
		total += areas[c]
	var pal: = []
	for c in keys:
		var col: = Color.html(c)
		var pig: = Color.from_hsv(col.h, clampf(col.s * 1.9 + 0.05, 0.0, 1.0), clampf(col.v, 0.35, 0.95))
		pal.append([pig, areas[c] / total if total > 0.0 else 1.0 / keys.size()])
	if pal.is_empty():
		pal.append([Color(0.8, 0.8, 0.8), 1.0])
	if key != "":
		_palette_cache[key] = pal
	return pal

## Adds each triangle's area to `areas` under its (quantised) colour: the
## material colour, times the vertex colour for vertex-coloured toys.
static func _add_surface_colors(mesh: Mesh, si: int, base: Color, use_vc: bool, areas: Dictionary) -> void:
	var arr: = mesh.surface_get_arrays(si)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var vc = arr[Mesh.ARRAY_COLOR] if use_vc else null
	var idx = arr[Mesh.ARRAY_INDEX]
	var indexed: bool = idx is PackedInt32Array and idx.size() > 0
	var count: int = idx.size() if indexed else v.size()
	for t in range(0, count - 2, 3):
		var i0: int = idx[t] if indexed else t
		var i1: int = idx[t + 1] if indexed else t + 1
		var i2: int = idx[t + 2] if indexed else t + 2
		var col: = base
		if vc is PackedColorArray and vc.size() > i0:
			col = base * vc[i0]
		var a: = (v[i1] - v[i0]).cross(v[i2] - v[i0]).length() * 0.5 * minf(col.a, 1.0)
		var key: = Color(snappedf(col.r, 0.05), snappedf(col.g, 0.05), snappedf(col.b, 0.05)).to_html(false)
		areas[key] = areas.get(key, 0.0) + a

static func _mesh_instances(root: Node) -> Array:
	var out: = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D and n.mesh != null:
			out.append(n)
	return out

## Global height of this prop's top surface.
func top_y() -> float:
	return global_position.y + box_center.y + box_size.y * 0.5

## A random point on this prop's top surface, in world space.
func top_point(rng: RandomNumberGenerator) -> Vector3:
	var local: = Vector3(
		box_center.x + rng.randf_range(-0.35, 0.35) * box_size.x,
		box_center.y + box_size.y * 0.5,
		box_center.z + rng.randf_range(-0.35, 0.35) * box_size.z)
	return to_global(local)

## Rest on `s`; drop to its base height once it is smashed.
func set_support(s: Destructible) -> void:
	support = s
	s.destroyed.connect(_on_support_destroyed.bind(s.global_position.y))

func _on_support_destroyed(floor_y: float) -> void:
	if _destroyed or not is_inside_tree():
		return
	var tw: = create_tween()
	tw.tween_property(self, "global_position:y", floor_y, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "global_position:y", floor_y + 0.3, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", floor_y, 0.1).set_ease(Tween.EASE_IN)

func _destroy() -> void:
	_destroyed = true
	destroyed.emit()
	if _manager and _manager.has_method("add_score"):
		_manager.add_score(score_value)
		_manager.report_smash(global_position + Vector3(0, target_height, 0), score_value, target_height)
	_spawn_effect(global_position, target_height)
	queue_free()

## Smash effects alive right now. When the truck is huge it can wreck a dozen
## props in one frame; capping effects keeps that frame from stalling.
static var _active_fx: int = 0
const MAX_ACTIVE_FX: = 6

func _spawn_effect(pos: Vector3, h: float) -> void:
	var host: = get_parent()
	if host == null or _active_fx >= MAX_ACTIVE_FX:
		return
	_active_fx += 1
	host.get_tree().create_timer(0.6).timeout.connect(func(): _active_fx -= 1)
	var fx: = CPUParticles3D.new()
	fx.emitting = false
	fx.one_shot = true
	fx.explosiveness = 1.0
	fx.amount = clampi(int(h * 6.0), 8, 32)
	fx.lifetime = 0.5
	fx.mesh = _get_debris_mesh()
	fx.color_initial_ramp = _get_debris_colors()
	fx.angular_velocity_min = -360.0
	fx.angular_velocity_max = 360.0
	fx.direction = Vector3(0, 1, 0)
	fx.spread = 60.0
	fx.initial_velocity_min = 2.0 + h
	fx.initial_velocity_max = 5.0 + h * 1.5
	fx.gravity = Vector3(0, -9.8, 0)
	var sc: = clampf(h * 0.16, 0.12, 1.0)
	fx.scale_amount_min = sc * 0.7
	fx.scale_amount_max = sc
	host.add_child(fx)
	fx.global_position = pos + Vector3(0, h * 0.5, 0)
	fx.emitting = true
	fx.finished.connect(fx.queue_free)
	var sfx: = AudioStreamPlayer3D.new()
	sfx.stream = IMPACT_SFX
	host.add_child(sfx)
	sfx.global_position = pos
	sfx.pitch_scale = clampf(1.5 - h * 0.08, 0.6, 1.4)
	sfx.play()
	if h >= 3.0:
		Audio.play("pop", clampf(1.3 - h * 0.05, 0.7, 1.2), -6.0)
	sfx.finished.connect(sfx.queue_free)

func _local_aabb(root: Node3D) -> AABB:
	var inv: = root.global_transform.affine_inverse()
	var result: = AABB()
	var first: = true
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is VisualInstance3D:
			var a: AABB = inv * (n.global_transform * n.get_aabb())
			if first:
				result = a
				first = false
			else:
				result = result.merge(a)
	return result
