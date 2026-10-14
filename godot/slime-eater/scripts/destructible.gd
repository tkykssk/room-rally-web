class_name Destructible extends Area3D





@export var model_scene: PackedScene
@export var size_tier: int = 0
@export var score_value: int = 10
@export var target_height: float = 1.0
@export var target_scale: float = 0.0
@export var base_y: float = 0.0

@export var tint: Color = Color(0, 0, 0, 0)

var _manager: Node = null
var _destroyed: bool = false
var _solid: StaticBody3D = null


const OCCLUDED_ALPHA:= 0.1
const FADE_SPEED:= 12.0
var _fade_mats: Array = []
var _cur_alpha: float = 1.0
var _occlude_radius: float = 1.0
var _vehicle: Node = null
var _occ_target: float = 1.0
var _occ_timer: float = 0.0


const EAT_TIME:= 0.7
var _eater: Node3D = null
var _eat_t: float = 0.0
var _model: Node3D = null
var _palette: Array = []
static var _palette_cache:= { }


const IMPACT_SFX:= preload("res://audio/impact.ogg")
static var _debris_mesh_shared: Mesh = null

static func _get_debris_mesh() -> Mesh:
	if _debris_mesh_shared == null:
		var m:= SphereMesh.new()
		m.radius = 0.25
		m.height = 0.5
		m.radial_segments = 8
		m.rings = 4
		var mat:= StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.2
		m.material = mat
		_debris_mesh_shared = m
	return _debris_mesh_shared

func _ready() -> void:
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
	if model_scene == null:
		return
	var model: Node3D = model_scene.instantiate()
	add_child(model)
	_model = model
	if tint.a > 0.0:
		_apply_tint(model)
	_palette = _get_palette(model)
	var aabb:= _local_aabb(model)
	var nh: float = maxf(aabb.size.y, 0.001)
	var s: float = target_scale if target_scale > 0.0 else target_height / nh
	model.scale = Vector3(s, s, s)
	model.position.y = base_y - aabb.position.y * s

	var w: float = maxf(aabb.size.x * s, 0.2)
	var d: float = maxf(aabb.size.z * s, 0.2)
	var hgt: float = aabb.size.y * s
	var box:= BoxShape3D.new()
	box.size = Vector3(w, hgt, d)

	var cx:= (aabb.position.x + aabb.size.x * 0.5) * s
	var cz:= (aabb.position.z + aabb.size.z * 0.5) * s
	var center:= Vector3(cx, base_y + hgt * 0.5, cz)

	var area_cs:= CollisionShape3D.new()
	area_cs.shape = box
	area_cs.position = center
	add_child(area_cs)

	_solid = StaticBody3D.new()
	add_child(_solid)
	var solid_cs:= CollisionShape3D.new()
	solid_cs.shape = box
	solid_cs.position = center
	_solid.add_child(solid_cs)

	_occlude_radius = 0.5 * maxf(w, d)
	if size_tier > 0:
		_prepare_fade(model)


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
					n.set_surface_override_material(si, dup)
					_fade_mats.append(dup)



func _apply_tint(model: Node3D) -> void:
	var mat:= StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.5
	for n in _mesh_instances(model):
		for si in n.mesh.get_surface_count():
			var m = n.get_active_material(si)
			if m == null or (m is BaseMaterial3D and m.albedo_texture == null and m.resource_name == "colormap"):
				n.set_surface_override_material(si, mat)



func _get_palette(model: Node3D) -> Array:
	var key:= model_scene.resource_path + str(tint)
	if _palette_cache.has(key):
		return _palette_cache[key]
	var areas:= { }
	for n in _mesh_instances(model):
		for si in n.mesh.get_surface_count():
			var m = n.get_active_material(si)
			var col:= Color(0.9, 0.9, 0.9)
			if m is BaseMaterial3D:
				col = m.albedo_color
			var area:= _surface_area(n.mesh, si) * (col.a if col.a < 1.0 else 1.0)
			var k:= Color(snappedf(col.r, 0.05), snappedf(col.g, 0.05), snappedf(col.b, 0.05)).to_html(false)
			areas[k] = areas.get(k, 0.0) + area
	var keys:= areas.keys()
	keys.sort_custom(func(a, b): return areas[a] > areas[b])
	keys = keys.slice(0, 3)
	var total:= 0.0
	for k in keys:
		total += areas[k]
	var pal:= []
	for k in keys:
		var c:= Color.html(k)

		var pig:= Color.from_hsv(c.h, clampf(c.s * 1.9 + 0.05, 0.0, 1.0), clampf(c.v, 0.35, 0.95))
		pal.append([pig, areas[k] / total if total > 0.0 else 1.0 / keys.size()])
	if pal.is_empty():
		pal.append([Color(0.8, 0.8, 0.8), 1.0])
	_palette_cache[key] = pal
	return pal

static func _surface_area(mesh: Mesh, si: int) -> float:
	var arr:= mesh.surface_get_arrays(si)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx = arr[Mesh.ARRAY_INDEX]
	var a:= 0.0
	if idx is PackedInt32Array and idx.size() > 0:
		for t in range(0, idx.size() - 2, 3):
			a += (v[idx[t + 1]] - v[idx[t]]).cross(v[idx[t + 2]] - v[idx[t]]).length()
	else:
		for t in range(0, v.size() - 2, 3):
			a += (v[t + 1] - v[t]).cross(v[t + 2] - v[t]).length()
	return a * 0.5

static func _mesh_instances(root: Node) -> Array:
	var out:= []
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D and n.mesh != null:
			out.append(n)
	return out


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
		m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if a >= 0.99 else BaseMaterial3D.TRANSPARENCY_ALPHA


func _is_occluding_car() -> bool:
	var cam:= get_viewport().get_camera_3d()
	if cam == null:
		return false
	if _vehicle == null:
		_vehicle = get_tree().get_first_node_in_group("vehicle")
		if _vehicle == null:
			return false
	var car: Vector3 = _vehicle.get_vehicle_position() if _vehicle.has_method("get_vehicle_position") else (_vehicle as Node3D).global_position
	var cam_pos:= cam.global_position
	var prop_pos:= global_position + Vector3(0, target_height * 0.4, 0)
	var to_car:= car - cam_pos
	var car_dist:= to_car.length()
	if car_dist < 0.01:
		return false
	var dir:= to_car / car_dist
	var to_prop:= prop_pos - cam_pos
	var t:= to_prop.dot(dir)

	if t <= 0.3 or t >= car_dist:
		return false
	var perp:= (to_prop - dir * t).length()
	return perp < (_occlude_radius + 1.8)


func try_eat(eater: Node3D) -> void:
	if _destroyed or not is_destroyable():
		return
	_destroyed = true
	_eater = eater
	if _solid:
		_solid.collision_layer = 0
	set_deferred("monitorable", false)
	if not _fade_mats.is_empty():
		_apply_alpha(1.0)
	if _manager and _manager.has_method("add_score"):
		_manager.add_score(score_value)
	var center:= global_position + Vector3(0, target_height * 0.5, 0)
	if eater.has_method("eat"):
		eater.eat(_palette, float(score_value), center)
	_spawn_effect(global_position, target_height)


func _process_eaten(delta: float) -> void:
	if not is_instance_valid(_eater):
		queue_free()
		return
	_eat_t += delta
	var k:= clampf(_eat_t / EAT_TIME, 0.0, 1.0)
	var s:= 1.0 - k * k
	scale = Vector3(s, s, s)
	var target: Vector3 = _eater.get_mouth_position() - Vector3(0, target_height * 0.5 * s, 0)
	global_position = global_position.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
	rotation.y += delta * 6.0
	if k >= 1.0:
		queue_free()


func _spawn_effect(pos: Vector3, h: float) -> void:
	var host:= get_parent()
	if host == null:
		return
	var fx:= CPUParticles3D.new()
	fx.emitting = false
	fx.one_shot = true
	fx.explosiveness = 1.0
	fx.amount = clampi(int(h * 6.0), 8, 32)
	fx.lifetime = 0.5
	fx.mesh = _get_debris_mesh()
	fx.direction = Vector3(0, 1, 0)
	fx.spread = 60.0
	fx.initial_velocity_min = 2.0 + h
	fx.initial_velocity_max = 5.0 + h * 1.5
	fx.gravity = Vector3(0, -9.8, 0)
	var sc:= clampf(h * 0.16, 0.12, 1.0)
	fx.scale_amount_min = sc * 0.7
	fx.scale_amount_max = sc
	if not _palette.is_empty():
		var grad:= Gradient.new()
		grad.offsets = PackedFloat32Array([0.0])
		grad.colors = PackedColorArray([_palette[0][0]])
		for i in range(1, _palette.size()):
			grad.add_point(float(i) / _palette.size(), _palette[i][0])
		grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		fx.color_initial_ramp = grad
	host.add_child(fx)
	fx.global_position = pos + Vector3(0, h * 0.5, 0)
	fx.emitting = true
	fx.finished.connect(fx.queue_free)

	var sfx:= AudioStreamPlayer3D.new()
	sfx.stream = IMPACT_SFX
	sfx.volume_db = -10.0
	sfx.pitch_scale = 1.6
	host.add_child(sfx)
	sfx.global_position = pos
	sfx.play()
	sfx.finished.connect(sfx.queue_free)


func _local_aabb(root: Node3D) -> AABB:
	var inv:= root.global_transform.affine_inverse()
	var result:= AABB()
	var first:= true
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
