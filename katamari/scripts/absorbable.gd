class_name Absorbable extends Area3D

## A prop that sticks to the Katamari once the game has unlocked its size tier.
## Until then it is a solid obstacle that fades out when it hides the player.

@export var model_scene: PackedScene
@export var size_tier: int = 0
@export var score_value: int = 10
@export var target_height: float = 1.0
@export var target_scale: float = 0.0
@export var base_y: float = 0.0

var _manager: Node = null
var _absorbed: bool = false
var _solid: StaticBody3D = null
var _model: Node3D = null
var _area_cs: CollisionShape3D = null
var _center: Vector3 = Vector3.ZERO
var _extent: float = 0.5

const OCCLUDED_ALPHA: = 0.1
const FADE_SPEED: = 12.0
var _fade_mats: Array = []
var _cur_alpha: float = 1.0
var _occlude_radius: float = 1.0
var _player: Node = null
var _occ_target: float = 1.0
var _occ_timer: float = 0.0

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

func is_absorbable() -> bool:
	if _manager == null:
		return true
	return size_tier <= _manager.unlocked_tier

func _build() -> void:
	if model_scene == null:
		return
	var model: Node3D = model_scene.instantiate()
	_model = model
	add_child(model)
	var aabb: = _local_aabb(model)
	var nh: float = maxf(aabb.size.y, 0.001)
	var s: float = target_scale if target_scale > 0.0 else target_height / nh
	model.scale = Vector3(s, s, s)
	model.position.y = base_y - aabb.position.y * s
	var w: float = maxf(aabb.size.x * s, 0.2)
	var d: float = maxf(aabb.size.z * s, 0.2)
	var hgt: float = aabb.size.y * s
	var box: = BoxShape3D.new()
	box.size = Vector3(w, hgt, d)
	var cx: = (aabb.position.x + aabb.size.x * 0.5) * s
	var cz: = (aabb.position.z + aabb.size.z * 0.5) * s
	var center: = Vector3(cx, base_y + hgt * 0.5, cz)
	_center = center
	_extent = 0.5 * maxf(maxf(w, d), hgt)
	_area_cs = CollisionShape3D.new()
	_area_cs.shape = box
	_area_cs.position = center
	add_child(_area_cs)
	_solid = StaticBody3D.new()
	add_child(_solid)
	var solid_cs: = CollisionShape3D.new()
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

func _update_solid() -> void:
	if _solid:
		_solid.collision_layer = 0 if is_absorbable() else 1

func _on_tier_unlocked(_tier: int) -> void:
	_update_solid()

func _process(delta: float) -> void:
	if _absorbed or _fade_mats.is_empty():
		return
	_occ_timer -= delta
	if _occ_timer <= 0.0:
		_occ_timer = 0.1
		_occ_target = OCCLUDED_ALPHA if (not is_absorbable() and _is_occluding_player()) else 1.0
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

func _is_occluding_player() -> bool:
	var cam: = get_viewport().get_camera_3d()
	if cam == null:
		return false
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return false
	var player_pos: Vector3 = _player.get_player_position()
	var cam_pos: = cam.global_position
	var prop_pos: = global_position + Vector3(0, target_height * 0.4, 0)
	var to_player: = player_pos - cam_pos
	var player_dist: = to_player.length()
	if player_dist < 0.01:
		return false
	var dir: = to_player / player_dist
	var to_prop: = prop_pos - cam_pos
	var t: = to_prop.dot(dir)
	if t <= 0.3 or t >= player_dist:
		return false
	var perp: = (to_prop - dir * t).length()
	return perp < (_occlude_radius + 1.8)

func can_absorb() -> bool:
	return not _absorbed and _model != null and is_absorbable()

func absorb_into(katamari: Node) -> void:
	_absorbed = true
	if _manager and _manager.has_method("add_score"):
		_manager.add_score(score_value)
	if not _fade_mats.is_empty():
		_apply_alpha(1.0)
	set_deferred("monitorable", false)
	_area_cs.set_deferred("disabled", true)
	if _solid:
		_solid.queue_free()
		_solid = null
	katamari.attach(_model, to_global(_center), _extent)
	queue_free()

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
