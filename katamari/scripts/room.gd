extends Node3D

## Builds the room shell: plank floor, wallpapered walls with baseboards,
## windows, a door and a few framed pictures. A wall sinks out of the way
## whenever the camera ends up behind it.

@export var half_size: float = 40.0
@export var wall_height: float = 12.0
@export var drop_margin: float = 1.5
@export var drop_speed: float = 8.0

const FLOOR_SHADER: = preload("res://scenes/floor_planks.gdshader")
const WALL_SHADER: = preload("res://scenes/wallpaper.gdshader")

var _walls: Array = []

func _ready() -> void:
	_build_floor()
	var white: = _mat(Color("f7f2ea"))
	var wall_mat: = ShaderMaterial.new()
	wall_mat.shader = WALL_SHADER
	# North (kitchen) and east (bedroom) get windows, south the front door.
	_build_wall(Vector3(0, 0, half_size), Vector3(0, 0, -1), white, wall_mat, [
		{"type": "window", "x": -26.0}, {"type": "window", "x": 22.0}])
	_build_wall(Vector3(0, 0, -half_size), Vector3(0, 0, 1), white, wall_mat, [
		{"type": "door", "x": 5.0}, {"type": "picture", "x": -24.0, "c": Color("3fa7c9")}])
	_build_wall(Vector3(half_size, 0, 0), Vector3(-1, 0, 0), white, wall_mat, [
		{"type": "window", "x": -14.0}, {"type": "picture", "x": 16.0, "c": Color("f2b33d")}])
	_build_wall(Vector3(-half_size, 0, 0), Vector3(1, 0, 0), white, wall_mat, [
		{"type": "picture", "x": -11.0, "c": Color("e8576d")}, {"type": "window", "x": 22.0}])

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

func _build_floor() -> void:
	var body: = StaticBody3D.new()
	body.name = "Floor"
	body.add_to_group("ground")
	var pm: = PhysicsMaterial.new()
	pm.friction = 6.0
	pm.rough = true
	body.physics_material_override = pm
	add_child(body)
	var cs: = CollisionShape3D.new()
	var shape: = BoxShape3D.new()
	shape.size = Vector3(half_size * 2.0, 0.2, half_size * 2.0)
	cs.shape = shape
	cs.position.y = -0.1
	body.add_child(cs)
	var mi: = MeshInstance3D.new()
	var plane: = PlaneMesh.new()
	plane.size = Vector2(half_size * 2.0, half_size * 2.0)
	var m: = ShaderMaterial.new()
	m.shader = FLOOR_SHADER
	plane.material = m
	mi.mesh = plane
	body.add_child(mi)

func _build_wall(origin: Vector3, normal: Vector3, trim: Material, paper: Material, features: Array) -> void:
	var length: = half_size * 2.0 + 1.0
	var tangent: = Vector3.UP.cross(normal)
	var pivot: = Node3D.new()
	pivot.transform = Transform3D(Basis(tangent, Vector3.UP, normal), origin)
	add_child(pivot)
	# Tall invisible collider so a fully grown ball can't roll over the wall.
	var body: = StaticBody3D.new()
	body.physics_material_override = Absorbable.slippery()
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
		match f.type:
			"window":
				_box(visual, Vector3(9.0, 6.5, 0.4), Vector3(f.x, 6.6, 0.1), trim)
				_box(visual, Vector3(8.0, 5.5, 0.42), Vector3(f.x, 6.6, 0.12), _glass())
				_box(visual, Vector3(0.3, 5.5, 0.5), Vector3(f.x, 6.6, 0.15), trim)
				_box(visual, Vector3(8.0, 0.3, 0.5), Vector3(f.x, 6.6, 0.15), trim)
				_box(visual, Vector3(10.0, 0.4, 1.0), Vector3(f.x, 3.3, 0.4), trim)
			"door":
				_box(visual, Vector3(6.4, 9.6, 0.35), Vector3(f.x, 4.8, 0.1), trim)
				_box(visual, Vector3(5.6, 9.2, 0.4), Vector3(f.x, 4.6, 0.15), _mat(Color("a8683f")))
				_box(visual, Vector3(0.5, 0.5, 0.3), Vector3(f.x + 2.0, 4.6, 0.45), _mat(Color("e8c25a")))
			"picture":
				_box(visual, Vector3(6.0, 4.5, 0.3), Vector3(f.x, 7.0, 0.1), _mat(Color("6b4a2b")))
				_box(visual, Vector3(5.2, 3.7, 0.35), Vector3(f.x, 7.0, 0.12), _mat(f.c))
				_box(visual, Vector3(2.4, 1.6, 0.4), Vector3(f.x - 0.8, 6.6, 0.14), _mat(f.c.lightened(0.45)))
	_walls.append({"origin": origin, "normal": normal, "visual": visual})

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
