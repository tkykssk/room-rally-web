class_name Absorbable extends Area3D

## A prop that sticks to the Katamari once the ball is big enough for it.
## "Big enough" is judged from the prop's real size (see pick_size), not from a
## hand-assigned tier, so what you can roll up always matches what you see.
## Until then it is a solid obstacle; tall ones fade when they hide the player.

signal absorbed

## Either a scene to instance (Kenney models) or a ready-made node (toys,
## items knocked back off the ball).
@export var model_scene: PackedScene
var model_node: Node3D = null

@export var display_name: String = ""
@export var target_height: float = 1.0
@export var target_scale: float = 0.0
@export var base_y: float = 0.0
## Palette accent for fabric surfaces; -1 keeps the model's own materials.
@export var style: int = -1
## Colour for untextured models (alpha 0 = none). See Palette.apply.
@export var tint: Color = Color(0, 0, 0, 0)

## Optional prop this one rests on (e.g. a mug on a table). When the support is
## rolled up, this prop drops to the floor.
var support: Absorbable = null

## Size used for the pickup check, in world units.
var pick_size: float = 0.0
var dims: Vector3 = Vector3.ZERO

var _absorbed: bool = false
var _available_at: int = 0
var _model: Node3D = null
var _scale: float = 1.0
var _solid: StaticBody3D = null
var _area_cs: CollisionShape3D = null
var _center: Vector3 = Vector3.ZERO
var _extent: float = 0.5
var _player: Node = null

const FADE_MIN_HEIGHT: = 2.0
const OCCLUDED_ALPHA: = 0.15
const FADE_SPEED: = 12.0
var _fade_mats: Array = []
var _cur_alpha: float = 1.0
var _occlude_radius: float = 1.0
var _occ_target: float = 1.0
var _occ_timer: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
	_build()
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.size_changed.connect(_on_size_changed)
		_on_size_changed(_player.radius * 2.0)
	if support:
		support.absorbed.connect(_fall)
	_occ_timer = randf() * 0.1
	set_process(not _fade_mats.is_empty())

## Block re-pickup for a moment (used for items knocked off the ball).
func set_cooldown(seconds: float) -> void:
	_available_at = Time.get_ticks_msec() + int(seconds * 1000.0)

func can_be_absorbed_by(diameter: float) -> bool:
	return not _absorbed and _model != null and Time.get_ticks_msec() >= _available_at \
		and pick_size <= diameter * Katamari.PICK_RATIO

## A random point on top of this prop, in world space (for placing clutter).
func top_point(rng: RandomNumberGenerator, inset: float = 0.65) -> Vector3:
	var local: = Vector3(
		_center.x + rng.randf_range(-0.5, 0.5) * dims.x * inset,
		base_y + dims.y,
		_center.z + rng.randf_range(-0.5, 0.5) * dims.z * inset)
	return to_global(local)

func _build() -> void:
	var model: Node3D = model_node
	if model == null:
		if model_scene == null:
			return
		model = model_scene.instantiate()
	if style >= 0:
		Palette.apply(model, style, tint)
	_model = model
	add_child(model)
	var aabb: = _local_aabb(model)
	var nh: float = maxf(aabb.size.y, 0.001)
	var s: float = target_scale if target_scale > 0.0 else target_height / nh
	_scale = s
	model.scale = Vector3(s, s, s)
	model.position = Vector3(0.0, base_y - aabb.position.y * s, 0.0)
	var w: float = maxf(aabb.size.x * s, 0.05)
	var d: float = maxf(aabb.size.z * s, 0.05)
	var hgt: float = maxf(aabb.size.y * s, 0.02)
	dims = Vector3(w, hgt, d)
	var longest: = maxf(hgt, maxf(w, d))
	pick_size = 0.5 * longest + 0.5 * pow(w * hgt * d, 1.0 / 3.0)
	var box: = BoxShape3D.new()
	box.size = Vector3(maxf(w, 0.2), maxf(hgt, 0.2), maxf(d, 0.2))
	var cx: = (aabb.position.x + aabb.size.x * 0.5) * s
	var cz: = (aabb.position.z + aabb.size.z * 0.5) * s
	_center = Vector3(cx, base_y + hgt * 0.5, cz)
	_extent = 0.5 * longest
	_area_cs = CollisionShape3D.new()
	_area_cs.shape = box
	_area_cs.position = _center
	add_child(_area_cs)
	_solid = StaticBody3D.new()
	_solid.physics_material_override = slippery()
	add_child(_solid)
	var solid_cs: = CollisionShape3D.new()
	var solid_box: = BoxShape3D.new()
	solid_box.size = Vector3(w, hgt, d)
	solid_cs.shape = solid_box
	solid_cs.position = _center
	_solid.add_child(solid_cs)
	_occlude_radius = 0.5 * maxf(w, d)
	_tune_geometry(model, longest)
	if hgt >= FADE_MIN_HEIGHT:
		_prepare_fade(model)

## Tiny props skip shadows and are culled at distance; nobody sees a coin
## from across the room, and there are hundreds of them.
## Low friction for obstacles so the ball slides along them instead of
## jamming between two pieces of furniture (the ball uses min-friction).
static var _slippery: PhysicsMaterial = null
static func slippery() -> PhysicsMaterial:
	if _slippery == null:
		_slippery = PhysicsMaterial.new()
		_slippery.friction = 0.05
	return _slippery

func _tune_geometry(model: Node3D, longest: float) -> void:
	var stack: Array = [model]
	while not stack.is_empty():
		var n = stack.pop_back()
		stack.append_array(n.get_children())
		if n is GeometryInstance3D:
			if longest < 0.6:
				n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if longest < 2.0:
				n.visibility_range_end = 30.0 + longest * 25.0

func _prepare_fade(model: Node3D) -> void:
	var stack: Array = [model]
	while not stack.is_empty():
		var n = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D and n.mesh != null:
			for si in n.mesh.get_surface_count():
				var m = n.get_active_material(si)
				if m is BaseMaterial3D:
					var dup: BaseMaterial3D = m.duplicate()
					n.set_surface_override_material(si, dup)
					_fade_mats.append(dup)

func _on_size_changed(diameter: float) -> void:
	if _solid:
		_solid.collision_layer = 0 if can_be_absorbed_by(diameter) else 1

func _process(delta: float) -> void:
	if _absorbed:
		return
	_occ_timer -= delta
	if _occ_timer <= 0.0:
		_occ_timer = 0.1
		var blocking: bool = _solid != null and _solid.collision_layer != 0
		_occ_target = OCCLUDED_ALPHA if (blocking and _is_occluding_player()) else 1.0
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
	if cam == null or _player == null:
		return false
	var player_pos: Vector3 = _player.get_player_position()
	var cam_pos: = cam.global_position
	var prop_pos: = global_position + Vector3(0, dims.y * 0.4, 0)
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
	return perp < (_occlude_radius + _player.radius * 1.5)

func absorb_into(katamari: Node) -> void:
	_absorbed = true
	absorbed.emit()
	if not _fade_mats.is_empty():
		_apply_alpha(1.0)
	set_deferred("monitorable", false)
	_area_cs.set_deferred("disabled", true)
	if _solid:
		_solid.queue_free()
		_solid = null
	var spec: = {
		"name": display_name,
		"size": pick_size,
		"extent": _extent,
		"scale": _scale,
		"height": dims.y,
	}
	katamari.attach(_model, to_global(_center), spec)
	queue_free()

## The prop this one was resting on got rolled up: drop to the floor.
func _fall() -> void:
	if _absorbed or not is_inside_tree():
		return
	support = null
	var tw: = create_tween()
	tw.tween_property(self, "position:y", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "position:y", 0.15 + dims.y * 0.1, 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", 0.0, 0.12).set_ease(Tween.EASE_IN)

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
