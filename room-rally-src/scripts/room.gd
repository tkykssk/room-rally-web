extends Node3D

## Builds the stage's architecture from Stages data:
## - a rectangular room (plank floor, wallpapered outer walls with windows,
##   a door and pictures; an outer wall sinks if the camera ends up behind it)
## - interior walls with doorways, which fade when they hide the truck
## - raised platforms and ramps the truck can drive up
## - outdoor stages ("outdoor": true): a lawn with a fence around it instead of
##   the room shell, floor patches (the house floor, a patio, a sand pit) and
##   scenery beyond the fence. The house is built from interior walls, so the
##   truck rolls from inside to outside without a loading screen.

@export var wall_height: float = 12.0
@export var drop_margin: float = 1.5
@export var drop_speed: float = 8.0

## Physics layer (value) the camera spring arm collides with: outer walls only.
const CAMERA_BLOCK_LAYER: = 4
## Physics layer (value) of interior walls, for line-of-sight queries.
const INNER_WALL_LAYER: = 8
const INNER_WALL_HEIGHT: = 10.0
const FADED_ALPHA: = 0.18
const FLOOR_SHADER: = preload("res://scenes/floor_planks.gdshader")
const LAWN_SHADER: = preload("res://scenes/lawn.gdshader")
const FENCE_HEIGHT: = 3.2
const WALL_SHADER: = preload("res://scenes/wallpaper.gdshader")

var hx: float = 40.0
var hz: float = 40.0
var _walls: Array = []
var _inner: Array = []
var _fade_timer: float = 0.0
var _floor_mat: PhysicsMaterial = null
var _vehicle: Node = null

func _ready() -> void:
	var stage: = Stages.get_stage()
	hx = stage.get("hx", stage.get("half", 40.0))
	hz = stage.get("hz", stage.get("half", 40.0))
	_floor_mat = PhysicsMaterial.new()
	_floor_mat.friction = 6.0
	_floor_mat.rough = true
	var trim: = _mat(Color("f7f2ea"))
	if stage.get("outdoor", false):
		_build_outdoor(stage)
	else:
		_build_floor()
		_build_room_shell(stage, trim)
	for w in stage.get("walls", []):
		_build_inner_wall(w, stage.get("inner_wall", Color("e9dcc6")), trim)
	for p in stage.get("platforms", []):
		_build_platform(p)
	for r in stage.get("ramps", []):
		_build_ramp(r)

func _build_room_shell(stage: Dictionary, trim: Material) -> void:
	var paper: = ShaderMaterial.new()
	paper.shader = WALL_SHADER
	paper.set_shader_parameter("base_color", stage.wall)
	paper.set_shader_parameter("stripe_color", stage.stripe)
	# North gets windows, south the front door, east/west a window and a picture.
	_build_wall(Vector3(0, 0, hz), Vector3(0, 0, -1), hx, trim, paper, [
		{"type": "window", "x": -0.6}, {"type": "window", "x": 0.5}])
	_build_wall(Vector3(0, 0, -hz), Vector3(0, 0, 1), hx, trim, paper, [
		{"type": "door", "x": 0.15}, {"type": "picture", "x": -0.55, "c": Color("3fa7c9")}])
	_build_wall(Vector3(hx, 0, 0), Vector3(-1, 0, 0), hz, trim, paper, [
		{"type": "window", "x": -0.35}, {"type": "picture", "x": 0.4, "c": Color("f2b33d")}])
	_build_wall(Vector3(-hx, 0, 0), Vector3(1, 0, 0), hz, trim, paper, [
		{"type": "picture", "x": -0.3, "c": Color("e8576d")}, {"type": "window", "x": 0.5}])

func _process(delta: float) -> void:
	var cam: = get_viewport().get_camera_3d()
	if cam == null:
		return
	for w in _walls:
		var inside: float = (cam.global_position - w.origin).dot(w.normal)
		var target: = -wall_height - 0.5 if inside < drop_margin else 0.0
		var vis: Node3D = w.visual
		if not is_equal_approx(vis.position.y, target):
			vis.position.y = lerpf(vis.position.y, target, clampf(delta * drop_speed, 0.0, 1.0))
			vis.visible = vis.position.y > -wall_height
	_fade_inner_walls(cam, delta)

# --- floor & outer walls ----------------------------------------------------

# --- outdoors -------------------------------------------------------------------

func _build_outdoor(stage: Dictionary) -> void:
	# Ground: one collider for the whole yard; the lawn reaches past the fence
	# so the world doesn't end at the edge.
	var body: = StaticBody3D.new()
	body.name = "Floor"
	body.add_to_group("ground")
	body.physics_material_override = _floor_mat
	add_child(body)
	var cs: = CollisionShape3D.new()
	var shape: = BoxShape3D.new()
	shape.size = Vector3(hx * 2.0, 0.2, hz * 2.0)
	cs.shape = shape
	cs.position.y = -0.1
	body.add_child(cs)
	var lawn: = ShaderMaterial.new()
	lawn.shader = LAWN_SHADER
	_plane(Vector2(hx * 2.0 + 160.0, hz * 2.0 + 160.0), Vector3.ZERO, lawn)
	var layer: = 0
	for f in stage.get("floors", []):
		layer += 1
		var r: Array = f.rect
		var size: = Vector2(absf(r[2] - r[0]), absf(r[3] - r[1]))
		var pos: = Vector3((r[0] + r[2]) * 0.5, 0.01 + layer * 0.004, (r[1] + r[3]) * 0.5)
		var m: Material
		if f.get("kind", "") == "planks":
			var sm: = ShaderMaterial.new()
			sm.shader = FLOOR_SHADER
			if f.has("a"):
				sm.set_shader_parameter("wood_a", f.a)
				sm.set_shader_parameter("wood_b", f.b)
			m = sm
		else:
			m = _mat(f.get("color", Color("d8cdb8")))
		_plane(size, pos, m)
	_build_fence(stage.get("fence", Color("f4ead8")))
	_build_scenery()

func _plane(size: Vector2, pos: Vector3, m: Material) -> void:
	var mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = size
	plane.material = m
	mi.mesh = plane
	mi.position = pos
	add_child(mi)

## Picket fence around the yard, with a tall invisible collider so a fully
## grown truck can't get over it. It is low, so the camera ignores it.
func _build_fence(color: Color) -> void:
	var paint: = _mat(color)
	for side in 4:
		var along_x: = side < 2
		var half: = hx if along_x else hz
		var sgn: = 1.0 if side % 2 == 0 else -1.0
		var origin: = Vector3(0, 0, sgn * (hz + 0.3)) if along_x else Vector3(sgn * (hx + 0.3), 0, 0)
		var tangent: = Vector3.RIGHT if along_x else Vector3.BACK
		var body: = StaticBody3D.new()
		body.physics_material_override = Destructible.obstacle_material()
		add_child(body)
		var cs: = CollisionShape3D.new()
		var shape: = BoxShape3D.new()
		var length: = half * 2.0 + 2.0
		shape.size = Vector3(length, 60.0, 1.0) if along_x else Vector3(1.0, 60.0, length)
		cs.shape = shape
		cs.position = origin + Vector3(0, 30.0, 0) + (Vector3(0, 0, sgn * 0.5) if along_x else Vector3(sgn * 0.5, 0, 0))
		body.add_child(cs)
		# Two rails plus pickets (one mesh per picket is fine: ~100 per side
		# would not be, so pickets are 1.5 apart and share one material).
		var rail_size: = Vector3(length, 0.25, 0.15) if along_x else Vector3(0.15, 0.25, length)
		_box(self, rail_size, origin + Vector3(0, 1.0, 0), paint)
		_box(self, rail_size, origin + Vector3(0, 2.3, 0), paint)
		var n: = int(length / 1.5)
		var mm: = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var picket: = BoxMesh.new()
		picket.size = Vector3(0.7, FENCE_HEIGHT, 0.12) if along_x else Vector3(0.12, FENCE_HEIGHT, 0.7)
		picket.material = paint
		mm.mesh = picket
		mm.instance_count = n
		for i in n:
			var t: = -length * 0.5 + (i + 0.5) * length / n
			mm.set_instance_transform(i, Transform3D(Basis(), origin + tangent * t + Vector3(0, FENCE_HEIGHT * 0.5, 0)))
		var mmi: = MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)

## Trees and neighbours' houses beyond the fence (no collision).
func _build_scenery() -> void:
	var rng: = RandomNumberGenerator.new()
	rng.seed = 77
	var i: = 0
	for side in 4:
		var along_x: = side < 2
		var half: = hx if along_x else hz
		var sgn: = 1.0 if side % 2 == 0 else -1.0
		var n: = int(half / 9.0)
		for k in n * 2 + 2:
			var t: = -half - 8.0 + (k + rng.randf_range(0.2, 0.8)) * (half * 2.0 + 16.0) / (n * 2 + 2)
			var out: = rng.randf_range(7.0, 20.0)
			var p: = Vector3(t, 0, sgn * (hz + out)) if along_x else Vector3(sgn * (hx + out), 0, t)
			# The neighbours' houses stand behind the south fence.
			if side == 1 and out > 12.0:
				continue
			var tree: = ToyFactory.make("pine" if i % 3 == 0 else "tree", i % 4)
			var sc: = rng.randf_range(2.2, 3.4)
			tree.scale = Vector3(sc, sc, sc)
			tree.position = p
			tree.rotation.y = rng.randf() * TAU
			add_child(tree)
			i += 1
	var roof_colors: = [Color("c45a4a"), Color("4a6fc4"), Color("6b4a2b"), Color("4f8a5a")]
	for h in 5:
		var x: = -hx + (h + 0.5) * hx * 2.0 / 5.0
		var house: = Node3D.new()
		house.position = Vector3(x, 0, -hz - 34.0 - (h % 2) * 8.0)
		add_child(house)
		_box(house, Vector3(16, 10, 12), Vector3(0, 5, 0), _mat(Color("f4ead8").darkened(h * 0.04)))
		var roof: = MeshInstance3D.new()
		var prism: = PrismMesh.new()
		prism.size = Vector3(18, 6, 14)
		prism.material = _mat(roof_colors[h % roof_colors.size()])
		roof.mesh = prism
		roof.position = Vector3(0, 13, 0)
		house.add_child(roof)
		_box(house, Vector3(5, 3.5, 0.2), Vector3(-3, 6, 6.05), _glass())
		_box(house, Vector3(3, 6, 0.2), Vector3(4, 3, 6.05), _mat(Color("a8683f")))

func _build_floor() -> void:
	var body: = StaticBody3D.new()
	body.name = "Floor"
	body.add_to_group("ground")
	body.physics_material_override = _floor_mat
	add_child(body)
	var cs: = CollisionShape3D.new()
	var shape: = BoxShape3D.new()
	shape.size = Vector3(hx * 2.0, 0.2, hz * 2.0)
	cs.shape = shape
	cs.position.y = -0.1
	body.add_child(cs)
	var mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(hx * 2.0, hz * 2.0)
	var m: = ShaderMaterial.new()
	m.shader = FLOOR_SHADER
	plane.material = m
	mi.mesh = plane
	body.add_child(mi)

## `half_len` is half the wall's length; feature x is a fraction of it.
func _build_wall(origin: Vector3, normal: Vector3, half_len: float, trim: Material, paper: Material, features: Array) -> void:
	var length: = half_len * 2.0 + 1.0
	var tangent: = Vector3.UP.cross(normal)
	var pivot: = Node3D.new()
	pivot.transform = Transform3D(Basis(tangent, Vector3.UP, normal), origin)
	add_child(pivot)
	# Tall invisible collider so a fully grown truck can't get over the wall.
	var body: = StaticBody3D.new()
	body.physics_material_override = Destructible.obstacle_material()
	# Layer 1: blocks the truck. Layer 3: the camera's spring arm stops here.
	body.collision_layer = 1 | CAMERA_BLOCK_LAYER
	pivot.add_child(body)
	var cs: = CollisionShape3D.new()
	var shape: = BoxShape3D.new()
	shape.size = Vector3(length, 60.0, 1.0)
	cs.shape = shape
	cs.position = Vector3(0, 30.0, -0.5)
	body.add_child(cs)
	var visual: = Node3D.new()
	pivot.add_child(visual)
	_box(visual, Vector3(length, wall_height, 0.5), Vector3(0, wall_height * 0.5, -0.25), paper)
	_box(visual, Vector3(length, 0.7, 0.3), Vector3(0, 0.35, 0.1), trim)
	_box(visual, Vector3(length, 0.35, 0.2), Vector3(0, wall_height - 0.18, 0.05), trim)
	for f in features:
		var x: float = f.x * half_len
		match f.type:
			"window":
				_box(visual, Vector3(9.0, 6.5, 0.4), Vector3(x, 6.6, 0.1), trim)
				_box(visual, Vector3(8.0, 5.5, 0.42), Vector3(x, 6.6, 0.12), _glass())
				_box(visual, Vector3(0.3, 5.5, 0.5), Vector3(x, 6.6, 0.15), trim)
				_box(visual, Vector3(8.0, 0.3, 0.5), Vector3(x, 6.6, 0.15), trim)
				_box(visual, Vector3(10.0, 0.4, 1.0), Vector3(x, 3.3, 0.4), trim)
			"door":
				_box(visual, Vector3(6.4, 9.6, 0.35), Vector3(x, 4.8, 0.1), trim)
				_box(visual, Vector3(5.6, 9.2, 0.4), Vector3(x, 4.6, 0.15), _mat(Color("a8683f")))
				_box(visual, Vector3(0.5, 0.5, 0.3), Vector3(x + 2.0, 4.6, 0.45), _mat(Color("e8c25a")))
			"picture":
				_box(visual, Vector3(6.0, 4.5, 0.3), Vector3(x, 7.0, 0.1), _mat(Color("6b4a2b")))
				_box(visual, Vector3(5.2, 3.7, 0.35), Vector3(x, 7.0, 0.12), _mat(f.c))
				_box(visual, Vector3(2.4, 1.6, 0.4), Vector3(x - 0.8, 6.6, 0.14), _mat(f.c.lightened(0.45)))
	_walls.append({"origin": origin, "normal": normal, "visual": visual})

# --- interior walls -----------------------------------------------------------

## {"from": [x, z], "to": [x, z], "doors": [[distance from `from`, width], ...]}
func _build_inner_wall(w: Dictionary, color: Color, trim: Material) -> void:
	var a: = Vector2(w.from[0], w.from[1])
	var b: = Vector2(w.to[0], w.to[1])
	var length: = a.distance_to(b)
	var dir: = (b - a) / length
	var h: float = w.get("h", INNER_WALL_HEIGHT)
	# Solid spans between doorways. Doorways are open to the top: a lintel
	# trapped the truck in a room once it grew taller than the door.
	var cuts: Array = []
	var lintels: Array = []
	for d in w.get("doors", []):
		cuts.append([d[0] - d[1] * 0.5, d[0] + d[1] * 0.5])
		# Optional third value: a low opening (pet flap) only a small truck fits.
		if d.size() > 2:
			lintels.append([d[0] - d[1] * 0.5, d[0] + d[1] * 0.5, d[2]])
	cuts.sort_custom(func(p, q): return p[0] < q[0])
	var spans: Array = []
	var t: = 0.0
	for c in cuts:
		if c[0] > t:
			spans.append([t, c[0], 0.0, h])
		t = c[1]
	if t < length:
		spans.append([t, length, 0.0, h])
	for l in lintels:
		spans.append([l[0], l[1], l[2], h])
	var mat: = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	# Alpha-blended from the start so fading never changes shader state.
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	var trim_mat: StandardMaterial3D = (trim as StandardMaterial3D).duplicate()
	trim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trim_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	var pivot: = Node3D.new()
	var basis: = Basis(Vector3(dir.x, 0, dir.y), Vector3.UP, Vector3(-dir.y, 0, dir.x))
	pivot.transform = Transform3D(basis, Vector3(a.x, 0, a.y))
	add_child(pivot)
	var body: = StaticBody3D.new()
	body.physics_material_override = Destructible.obstacle_material()
	body.collision_layer = 1 | INNER_WALL_LAYER
	pivot.add_child(body)
	for s in spans:
		var len: float = s[1] - s[0]
		var y0: float = s[2]
		var y1: float = s[3]
		var center: = Vector3((s[0] + s[1]) * 0.5, (y0 + y1) * 0.5, 0.0)
		var size: = Vector3(len, y1 - y0, 0.6)
		var cs: = CollisionShape3D.new()
		var shape: = BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		cs.position = center
		body.add_child(cs)
		_box(pivot, size, center, mat)
		if y0 == 0.0:
			_box(pivot, Vector3(len, 0.7, 0.8), Vector3(center.x, 0.35, 0.0), trim_mat)
	_inner.append({"a": a, "b": b, "h": h, "mats": [mat, trim_mat], "alpha": 1.0, "target": 1.0})

## Fade an interior wall while it sits between the camera and the truck.
func _fade_inner_walls(cam: Camera3D, delta: float) -> void:
	if _inner.is_empty():
		return
	_fade_timer -= delta
	if _fade_timer <= 0.0:
		_fade_timer = 0.1
		if _vehicle == null:
			_vehicle = get_tree().get_first_node_in_group("vehicle")
		if _vehicle:
			var car: Vector3 = _vehicle.get_vehicle_position() + Vector3(0, 0.5, 0)
			var c: = cam.global_position
			for w in _inner:
				w.target = FADED_ALPHA if _blocks(w, c, car) else 1.0
	for w in _inner:
		if is_equal_approx(w.alpha, w.target):
			continue
		w.alpha = lerpf(w.alpha, w.target, clampf(delta * 10.0, 0.0, 1.0))
		if absf(w.alpha - w.target) < 0.02:
			w.alpha = w.target
		for m in w.mats:
			var col: Color = m.albedo_color
			col.a = w.alpha
			m.albedo_color = col

func _blocks(w: Dictionary, cam: Vector3, car: Vector3) -> bool:
	var p: = Vector2(cam.x, cam.z)
	var q: = Vector2(car.x, car.z)
	# Camera right next to the wall also counts (it would clip into it).
	if Geometry2D.get_closest_point_to_segment(p, w.a, w.b).distance_to(p) < 1.5:
		return true
	var hit = Geometry2D.segment_intersects_segment(p, q, w.a, w.b)
	if hit == null:
		return false
	var t: float = p.distance_to(hit) / maxf(p.distance_to(q), 0.001)
	return lerpf(cam.y, car.y, t) < w.h

# --- platforms & ramps --------------------------------------------------------

## {"box": [x, z, width, depth, height], "color": Color}: a raised surface the
## truck can drive on. Slippery sides, grippy top.
func _build_platform(p: Dictionary) -> void:
	var b: Array = p.box
	var h: float = b[4]
	var pos: = Vector3(b[0], 0.0, b[1])
	var size: = Vector3(b[2], h, b[3])
	var color: Color = p.get("color", Color("c98a4b"))
	var body: = StaticBody3D.new()
	body.physics_material_override = Destructible.obstacle_material()
	body.position = pos
	add_child(body)
	_add_box_shape(body, Vector3(size.x, h - 0.1, size.z), Vector3(0, (h - 0.1) * 0.5, 0))
	var top: = StaticBody3D.new()
	top.add_to_group("ground")
	top.physics_material_override = _floor_mat
	top.position = pos
	add_child(top)
	_add_box_shape(top, Vector3(size.x, 0.1, size.z), Vector3(0, h - 0.05, 0))
	_box(self, size, pos + Vector3(0, h * 0.5, 0), _mat(color))
	_box(self, Vector3(size.x + 0.2, 0.25, size.z + 0.2), pos + Vector3(0, h - 0.12, 0), _mat(color.lightened(0.25)))

## {"from": [x, z, y], "to": [x, z, y], "w": width}: a board the truck can
## drive up; its top surface runs from `from` to `to`.
func _build_ramp(r: Dictionary) -> void:
	var a: = Vector3(r.from[0], r.from[2], r.from[1])
	var b: = Vector3(r.to[0], r.to[2], r.to[1])
	var w: float = r.get("w", 3.0)
	var fwd: = (b - a).normalized()
	var side: = Vector3.UP.cross(fwd).normalized()
	var up: = fwd.cross(side).normalized()
	var length: = a.distance_to(b)
	var thick: = 0.3
	var basis: = Basis(side, up, fwd)
	var center: = (a + b) * 0.5 - up * (thick * 0.5)
	var body: = StaticBody3D.new()
	body.add_to_group("ground")
	body.physics_material_override = _floor_mat
	body.transform = Transform3D(basis, center)
	add_child(body)
	_add_box_shape(body, Vector3(w, thick, length + 0.4), Vector3.ZERO)
	var mi: = MeshInstance3D.new()
	var bm: = BoxMesh.new()
	bm.size = Vector3(w, thick, length + 0.4)
	bm.material = _mat(r.get("color", Color("e0b27a")))
	mi.mesh = bm
	body.add_child(mi)

func _add_box_shape(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var cs: = CollisionShape3D.new()
	var shape: = BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	body.add_child(cs)

# --- helpers --------------------------------------------------------------------

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi: = MeshInstance3D.new()
	var bm: = BoxMesh.new()
	bm.size = size
	bm.material = mat
	mi.mesh = bm
	mi.position = pos
	parent.add_child(mi)

func _mat(c: Color) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m

var _glass_mat: StandardMaterial3D = null
func _glass() -> StandardMaterial3D:
	if _glass_mat == null:
		_glass_mat = _mat(Color("bfe6ff"))
		_glass_mat.emission_enabled = true
		_glass_mat.emission = Color("d9f1ff")
		_glass_mat.emission_energy_multiplier = 0.8
	return _glass_mat
