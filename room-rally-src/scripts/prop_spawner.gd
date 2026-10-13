extends Node3D

const PROP: = preload("res://scenes/props/prop.tscn")
const DECOR: = preload("res://scenes/props/decor.tscn")

## Lays out the current stage (see Stages): rugs, hand-placed furniture
## (optionally on a platform via "y"), items on top of furniture ("on_top",
## they fall when the furniture is smashed), then clutter scattered over an
## area ("rect", optional "y" for platform tops) away from furniture, walls,
## platforms, ramps and the start point.

@export var clear_radius: float = 5.0
@export var clutter_sep: float = 2.6
@export var rng_seed: int = 12345

var _stage: Dictionary
var _rng: = RandomNumberGenerator.new()
var _placed: Array = []
var _hx: float = 40.0
var _hz: float = 40.0
## Clutter that found no free spot (for tuning stage data).
var skipped: int = 0

func _ready() -> void:
	_stage = Stages.get_stage()
	_hx = _stage.get("hx", _stage.get("half", 40.0))
	_hz = _stage.get("hz", _stage.get("half", 40.0))
	_rng.seed = rng_seed
	skipped = 0
	# Journey: the world is split into zones that appear as the truck grows,
	# so only the part the player can reach is in the scene.
	_zones = _stage.get("zones", [])
	var first: Dictionary = _stage
	if not _zones.is_empty():
		first = _zones[0]
	for it in first.get("rugs", []):
		_add_rug(it)
	_spawn_set(first)
	_zones_spawned = 1
	_report_totals()
	_warmup_shaders()
	var gm: = get_tree().get_first_node_in_group("game_manager")
	if gm and not _zones.is_empty():
		_gm = gm
		gm.tier_unlocked.connect(_on_tier_unlocked)
		_spawn_due_zones()

var _zones: Array = []
var _zones_spawned: = 0
var _by_id: = {}
var _gm: Node = null
var _vehicle: Node = null
var _cull_timer: = 0.0
var _spawning: = false

func _add_rug(it: Dictionary) -> void:
	var d: Node3D = DECOR.instantiate()
	d.model_scene = load(it.p)
	d.target_width = it.w
	d.target_depth = it.d
	add_child(d)
	d.position = Vector3(it.x, it.get("y", 0.0), it.z)
	d.rotation.y = deg_to_rad(it.rot)

## Lays out one set (a stage, or one journey zone). With `per_frame` > 0 it
## spreads the work over frames so a zone appearing mid-run doesn't hitch.
func _spawn_set(data: Dictionary, per_frame: int = 0) -> void:
	var made: = 0
	for it in data.get("layout", []):
		var y: float = it.get("y", 0.0)
		var p: = _make(it, Vector3(it.x, y, it.z), deg_to_rad(it.get("rot", 0)))
		if it.has("id"):
			_by_id[it.id] = p
		_placed.append({"pos": Vector2(it.x, it.z), "sep": maxf(it.get("r", 3.0), p.footprint_radius + 1.0), "y": y})
		made += 1
		if per_frame > 0 and made % per_frame == 0:
			await get_tree().process_frame
	for it in data.get("on_top", []):
		# Untyped: the base may already have been culled (a freed object).
		var base = _by_id.get(it.on)
		if base == null or not is_instance_valid(base):
			push_warning("on_top: no layout id %s" % it.on)
			continue
		var spots: Array = []
		for i in it.get("c", 1):
			var pos: Vector3 = base.top_point(_rng)
			for attempt in 10:
				var ok: = true
				for q in spots:
					if Vector2(pos.x, pos.z).distance_to(q) < it.get("sep", 1.2):
						ok = false
						break
				if ok:
					break
				pos = base.top_point(_rng)
			spots.append(Vector2(pos.x, pos.z))
			var p: = _make(it, pos, _rng.randf() * TAU)
			p.set_support(base)
	# Bigger things first so small clutter fills the gaps around them; an item
	# with no free spot is skipped rather than dropped inside something else.
	var clutter: Array = data.get("clutter", []).duplicate()
	clutter.sort_custom(func(a, b): return a.h > b.h)
	for it in clutter:
		var y: float = it.get("y", 0.0)
		var rect: Array = it.get("rect", [-_hx + 4.0, -_hz + 4.0, _hx - 4.0, _hz - 4.0])
		var sep: float = it.get("sep", maxf(clutter_sep * 0.6, it.h * 1.2))
		for i in it.c:
			var pos = _find_spot(rect, y, sep)
			if pos == null:
				skipped += 1
				continue
			_make(it, Vector3(pos.x, y, pos.y), _rng.randf() * TAU)
			_placed.append({"pos": pos, "sep": sep, "y": y})
			made += 1
			if per_frame > 0 and made % per_frame == 0:
				await get_tree().process_frame

func _on_tier_unlocked(_tier: int) -> void:
	_spawn_due_zones()

## Zones appear one tier before the truck can get into them.
func _spawn_due_zones() -> void:
	if _spawning:
		return
	_spawning = true
	while _zones_spawned < _zones.size() and _gm.unlocked_tier >= _zones[_zones_spawned].get("spawn_tier", 0):
		var z: Dictionary = _zones[_zones_spawned]
		_zones_spawned += 1
		for it in z.get("rugs", []):
			_add_rug(it)
		await _spawn_set(z, 6)
	_spawning = false

## Things far smaller than the truck and out of its way are dropped from the
## scene (no points), so a big world keeps a bounded number of props.
func _process(delta: float) -> void:
	if _zones.is_empty() or _gm == null:
		return
	_cull_timer -= delta
	if _cull_timer > 0.0:
		return
	_cull_timer = 1.0
	if _vehicle == null:
		_vehicle = get_tree().get_first_node_in_group("vehicle")
		if _vehicle == null:
			return
	var t: int = _gm.unlocked_tier
	if _zones_spawned >= _zones.size() and not _spawning:
		var left: = 0
		for c in get_children():
			if c is Destructible and not c.is_queued_for_deletion():
				left += 1
		if left == 0:
			_gm.world_cleared()
			return
	if t < 4:
		return
	var p: Vector3 = _vehicle.get_vehicle_position()
	var far: float = 18.0 * _vehicle.size_scale
	for c in get_children():
		if c is Destructible and c.size_tier <= t - 4 and not c.is_queued_for_deletion():
			if Vector2(c.global_position.x - p.x, c.global_position.z - p.z).length() > far:
				c.queue_free()

## Spawn one prop from a stage entry: {p | toy, t, h, s, sc?, col?}.
func _make(it: Dictionary, pos: Vector3, rot_y: float) -> Destructible:
	var p: Destructible = PROP.instantiate()
	if it.has("toy"):
		p.model_node = ToyFactory.make(it.toy, _rng.randi() % 7)
	else:
		p.model_scene = load(it.p)
		p.tint = it.get("col", Color(0, 0, 0, 0))
	p.size_tier = it.t
	p.score_value = it.s
	p.target_height = it.h
	p.target_scale = it.get("sc", 0.0)
	if it.has("solid"):
		p.solid_frac = Vector2(it.solid[0], it.solid[1])
	add_child(p)
	p.position = pos
	p.rotation.y = rot_y
	return p

func _report_totals() -> void:
	var count: = 0
	var points: = 0
	var by_tier: = {}
	for c in get_children():
		if c is Destructible:
			count += 1
			points += c.score_value
			# Tier goals count only what sits on the floor: things up on
			# counters and lofts need a ramp or a bigger truck, so they
			# must not be required to grow.
			if c.global_position.y < 0.5:
				by_tier[c.size_tier] = by_tier.get(c.size_tier, 0) + c.score_value
	var gm: = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("set_stage_props"):
		gm.set_stage_props(count, points, by_tier)

func _warmup_shaders() -> void:
	var paths: = {}
	for data in [_stage] + _stage.get("zones", []):
		for key in ["layout", "clutter", "rugs", "on_top"]:
			for it in data.get(key, []):
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
	# Smash debris and see-through toys use their own shaders; draw them once
	# now so the first smash doesn't stall while WebGL compiles them.
	var fx: = CPUParticles3D.new()
	fx.mesh = Destructible._get_debris_mesh()
	fx.color_initial_ramp = Destructible._get_debris_colors()
	fx.amount = 4
	fx.lifetime = 0.5
	fx.scale_amount_min = 0.1
	fx.scale_amount_max = 0.1
	warm.add_child(fx)
	fx.position = _warm_pos(i)
	var toy: = ToyFactory.make("block")
	warm.add_child(toy)
	toy.scale = Vector3.ONE * 0.3
	toy.position = _warm_pos(i + 1)
	_make_transparent(toy)
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
					dup.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
					var col: Color = dup.albedo_color
					col.a = 0.5
					dup.albedo_color = col
					n.set_surface_override_material(si, dup)

## A free spot in `rect`, or null if there's no room left.
func _find_spot(rect: Array, y: float, sep: float):
	for attempt in 80:
		var p: = Vector2(_rng.randf_range(rect[0], rect[2]), _rng.randf_range(rect[1], rect[3]))
		if y == 0.0 and (p.length() < clear_radius or _blocked_by_structure(p)):
			continue
		var ok: = true
		for q in _placed:
			if absf(q.y - y) < 0.5 and p.distance_to(q.pos) < maxf(sep, q.sep):
				ok = false
				break
		if ok:
			return p
	return null

## Floor clutter stays clear of platforms, ramps and interior walls.
func _blocked_by_structure(p: Vector2) -> bool:
	for pl in _stage.get("platforms", []):
		var b: Array = pl.box
		if absf(p.x - b[0]) < b[2] * 0.5 + 1.2 and absf(p.y - b[1]) < b[3] * 0.5 + 1.2:
			return true
	for r in _stage.get("ramps", []):
		var a: = Vector2(r.from[0], r.from[1])
		var c: = Vector2(r.to[0], r.to[1])
		if Geometry2D.get_closest_point_to_segment(p, a, c).distance_to(p) < r.get("w", 3.0) * 0.5 + 1.2:
			return true
	for w in _stage.get("walls", []):
		var a: = Vector2(w.from[0], w.from[1])
		var c: = Vector2(w.to[0], w.to[1])
		if Geometry2D.get_closest_point_to_segment(p, a, c).distance_to(p) < 1.6:
			return true
		# Keep doorways clear too (a box dropped in front of a pet flap
		# would close it).
		for d in w.get("doors", []):
			var mid: = a + (c - a).normalized() * float(d[0])
			if p.distance_to(mid) < d[1] * 0.5 + 4.0:
				return true
	return false
