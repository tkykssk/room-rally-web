extends Node3D

const PROP: = preload("res://scenes/props/prop.tscn")
const DECOR: = preload("res://scenes/props/decor.tscn")

## Lays out the current stage (see Stages): rugs, hand-placed furniture, then
## clutter scattered away from the furniture and the start point.

@export var clear_radius: float = 5.0
@export var clutter_sep: float = 2.6
@export var rng_seed: int = 12345

var _stage: Dictionary

func _ready() -> void:
	_stage = Stages.get_stage()
	var placed: Array = []
	for it in _stage.rugs:
		var rs: PackedScene = load(it.p)
		if rs == null:
			continue
		var d: Node3D = DECOR.instantiate()
		d.model_scene = rs
		d.target_width = it.w
		d.target_depth = it.d
		add_child(d)
		d.position = Vector3(it.x, 0.0, it.z)
		d.rotation.y = deg_to_rad(it.rot)
	for it in _stage.layout:
		var scene: PackedScene = load(it.p)
		if scene == null:
			push_warning("layout model not found: %s" % it.p)
			continue
		var fp: = _spawn(scene, it.t, it.h, it.s, Vector3(it.x, 0.0, it.z), deg_to_rad(it.rot), it.get("sc", 0.0))
		placed.append({"pos": Vector2(it.x, it.z), "sep": maxf(it.r, fp + 1.0)})
	var rng: = RandomNumberGenerator.new()
	rng.seed = rng_seed
	for it in _stage.clutter:
		for i in it.c:
			var pos: = _find_spot(rng, placed, clutter_sep)
			var rot: = rng.randf() * TAU
			if it.has("toy"):
				_spawn_node(ToyFactory.make(it.toy, rng.randi() % 7), it.t, it.h, it.s, Vector3(pos.x, 0.0, pos.y), rot)
			else:
				_spawn(load(it.p), it.t, it.h, it.s, Vector3(pos.x, 0.0, pos.y), rot, 0.0, it.get("col", Color(0, 0, 0, 0)))
			placed.append({"pos": pos, "sep": clutter_sep})
	_report_totals()
	_warmup_shaders()

func _report_totals() -> void:
	var count: = 0
	var points: = 0
	for c in get_children():
		if c is Destructible:
			count += 1
			points += c.score_value
	var gm: = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("set_stage_props"):
		gm.set_stage_props(count, points)

func _warmup_shaders() -> void:
	var paths: = {}
	for key in ["layout", "clutter", "rugs"]:
		for it in _stage[key]:
			if it.has("p"):
				paths[it.p] = true
	var warm: = Node3D.new()
	warm.name = "ShaderWarmup"
	add_child(warm)
	var i: = 0
	for p in paths.keys():
		var sc: PackedScene = load(p)
		if sc == null:
			continue
		var opaque: Node3D = sc.instantiate()
		warm.add_child(opaque)
		opaque.scale = Vector3.ONE * 0.12
		opaque.position = _warm_pos(i)
		i += 1
		var trans: Node3D = sc.instantiate()
		warm.add_child(trans)
		trans.scale = Vector3.ONE * 0.12
		trans.position = _warm_pos(i)
		_make_transparent(trans)
		i += 1
	get_tree().create_timer(1.0).timeout.connect(warm.queue_free)

func _warm_pos(i: int) -> Vector3:
	return Vector3(-2.6 + (i % 12) * 0.45, 0.3, -1.0 + float(i / 12) * 0.45)

func _make_transparent(node: Node3D) -> void:
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.push_back(c)
		if n is MeshInstance3D and n.mesh != null:
			for si in n.mesh.get_surface_count():
				var m = n.get_active_material(si)
				if m is BaseMaterial3D:
					var dup: BaseMaterial3D = m.duplicate()
					dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					var col: Color = dup.albedo_color
					col.a = 0.5
					dup.albedo_color = col
					n.set_surface_override_material(si, dup)

## Returns the spawned prop's footprint radius.
func _spawn(scene: PackedScene, t: int, h: float, s: int, pos: Vector3, rot_y: float, sc: float = 0.0, tint: Color = Color(0, 0, 0, 0)) -> float:
	var p: Destructible = PROP.instantiate()
	p.tint = tint
	p.model_scene = scene
	p.size_tier = t
	p.score_value = s
	p.target_height = h
	p.target_scale = sc
	add_child(p)
	p.position = pos
	p.rotation.y = rot_y
	return p.footprint_radius

func _spawn_node(model: Node3D, t: int, h: float, s: int, pos: Vector3, rot_y: float) -> void:
	var p: Destructible = PROP.instantiate()
	p.model_node = model
	p.size_tier = t
	p.score_value = s
	p.target_height = h
	add_child(p)
	p.position = pos
	p.rotation.y = rot_y

func _find_spot(rng: RandomNumberGenerator, placed: Array, sep: float) -> Vector2:
	var room_half: float = _stage.half - 5.0
	for attempt in 60:
		var p: = Vector2(rng.randf_range(-room_half, room_half), rng.randf_range(-room_half, room_half))
		if p.length() < clear_radius:
			continue
		var ok: = true
		for q in placed:
			if p.distance_to(q.pos) < maxf(sep, q.sep):
				ok = false
				break
		if ok:
			return p
	return Vector2(rng.randf_range(-room_half, room_half), rng.randf_range(-room_half, room_half))
