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


const DISSOLVE_SHADER:= preload("res://shaders/prop_dissolve.gdshader")
const RELEASES_PER_COLOR:= 3
var _eater: Node3D = null
var _model: Node3D = null
var _box_center: Vector3
var _box_size: Vector3
var _abs_t: float = 0.0
var _abs_time: float = 2.0
var _abs_start: Transform3D
var _abs_contact: Vector3
var _abs_extent: float = 1.0
var _abs_started: bool = false
var _released: int = 0
var _dissolve_mats: Array = []
var _palette: Array = []
static var _palette_cache:= { }


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
	_box_center = center
	_box_size = box.size

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
	if _manager and _manager.has_method("add_score"):
		_manager.add_score(score_value)


	var mouth: Vector3 = eater.get_mouth_position()
	var local_mouth:= global_transform.affine_inverse() * mouth
	var half:= _box_size * 0.5
	var local_contact:= local_mouth.clamp(_box_center - half, _box_center + half)
	var contact:= global_transform * local_contact
	if eater.has_method("absorb_begin"):
		eater.absorb_begin(contact, float(score_value))
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
	_abs_extent = maxf(_box_size.length(), 0.3)
	var slime_r: float = _eater.get_body_radius()
	_abs_time = clampf(1.2 + 1.8 * _box_size.length() / slime_r, 1.2, 4.0)
	_abs_started = true

func _make_dissolvable() -> void:
	if _model == null:
		return
	for n in _mesh_instances(_model):
		for si in n.mesh.get_surface_count():
			var m = n.get_active_material(si)
			var sm:= ShaderMaterial.new()
			sm.shader = DISSOLVE_SHADER
			if m is BaseMaterial3D:
				sm.set_shader_parameter("albedo", Color(m.albedo_color, 1.0))
				sm.set_shader_parameter("roughness", m.roughness)
			n.set_surface_override_material(si, sm)
			_dissolve_mats.append(sm)


func _process_eaten(delta: float) -> void:
	if not is_instance_valid(_eater):
		queue_free()
		return
	if not _abs_started:
		return
	_abs_t += delta
	var k:= clampf(_abs_t / _abs_time, 0.0, 1.0)
	var e:= 1.0 - (1.0 - k) * (1.0 - k)


	var s:= lerpf(1.0, 0.55, e)
	var target:= _abs_contact * lerpf(1.0, 0.15, e)
	transform = Transform3D(Basis.from_scale(Vector3(s, s, s)), target) * Transform3D(Basis(), -_abs_contact) * _abs_start

	var pivot: Node3D = _eater.body_pivot
	var contact_world:= pivot.global_transform * target
	var center_world:= global_transform * _box_center
	var edge: Color = _eater.get_body_color() if _eater.has_method("get_body_color") else Color(0.5, 1.0, 0.6)
	for m in _dissolve_mats:
		m.set_shader_parameter("contact", contact_world)
		m.set_shader_parameter("extent", _abs_extent * s)
		m.set_shader_parameter("progress", k)
		m.set_shader_parameter("edge_color", edge)
	if _eater.has_method("absorb_hold"):
		_eater.absorb_hold(contact_world, 1.0 - k)


	var total:= RELEASES_PER_COLOR * _palette.size()
	while _released < total and k >= (float(int(_released / _palette.size())) + 0.5) / RELEASES_PER_COLOR:
		var entry: Array = _palette[_released % _palette.size()]
		var front:= contact_world.lerp(center_world, minf(k * 1.4, 1.0))
		_eater.release_pigment(entry[0], float(score_value) * entry[1] / RELEASES_PER_COLOR, front)
		_released += 1
	if k >= 1.0:
		queue_free()


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
