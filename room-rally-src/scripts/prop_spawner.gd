extends Node3D

const PROP: = preload("res://scenes/props/prop.tscn")
const DECOR: = preload("res://scenes/props/decor.tscn")
const FUR: = "res://assets/models/furniture/"
const FOOD: = "res://assets/models/food/"

const RUGS: = [
	{"p": FUR + "rugRectangle.glb", "x": -22, "z": -11, "rot": 0, "w": 20, "d": 14},
	{"p": FUR + "rugSquare.glb", "x": 30, "z": 24, "rot": 0, "w": 14, "d": 14},
]

const LAYOUT: = [
	{"p": FUR + "kitchenFridge.glb", "t": 6, "h": 9.2, "s": 500, "x": -18.0, "z": 37.5, "rot": 0, "r": 4, "sc": 10},
	{"p": FUR + "kitchenStove.glb", "t": 4, "h": 4.5, "s": 120, "x": -13.7, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	{"p": FUR + "kitchenSink.glb", "t": 4, "h": 4.9, "s": 110, "x": -9.4, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	{"p": FUR + "kitchenCabinet.glb", "t": 4, "h": 4.5, "s": 110, "x": -5.1, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	{"p": FUR + "kitchenCabinet.glb", "t": 4, "h": 4.5, "s": 110, "x": -0.8, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	{"p": FUR + "kitchenCabinet.glb", "t": 4, "h": 4.5, "s": 110, "x": 3.5, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	{"p": FUR + "kitchenMicrowave.glb", "t": 3, "h": 3.2, "s": 70, "x": -12.0, "z": 32.0, "rot": 0, "r": 3},
	{"p": FUR + "kitchenCoffeeMachine.glb", "t": 3, "h": 3.4, "s": 70, "x": -6.5, "z": 32.0, "rot": 0, "r": 3},
	{"p": FUR + "toaster.glb", "t": 2, "h": 2.2, "s": 40, "x": -1.0, "z": 32.0, "rot": 0, "r": 3},
	{"p": FUR + "table.glb", "t": 5, "h": 5.0, "s": 230, "x": -14, "z": 16, "rot": 0, "r": 5},
	{"p": FUR + "chair.glb", "t": 5, "h": 7.0, "s": 220, "x": -14, "z": 21, "rot": 180, "r": 3},
	{"p": FUR + "chair.glb", "t": 5, "h": 7.0, "s": 220, "x": -14, "z": 11, "rot": 0, "r": 3},
	{"p": FUR + "chair.glb", "t": 5, "h": 7.0, "s": 220, "x": -19, "z": 16, "rot": 90, "r": 3},
	{"p": FUR + "loungeSofaLong.glb", "t": 5, "h": 6.0, "s": 250, "x": -33, "z": -11, "rot": 90, "r": 7},
	{"p": FUR + "tableCoffee.glb", "t": 3, "h": 2.5, "s": 65, "x": -24, "z": -11, "rot": 0, "r": 3},
	{"p": FUR + "loungeChair.glb", "t": 5, "h": 6.0, "s": 200, "x": -22, "z": -21, "rot": 0, "r": 4},
	{"p": FUR + "cabinetTelevision.glb", "t": 4, "h": 3.0, "s": 120, "x": -13, "z": -11, "rot": -90, "r": 4},
	{"p": FUR + "televisionModern.glb", "t": 4, "h": 4.0, "s": 120, "x": -12, "z": -11, "rot": -90, "r": 3},
	{"p": FUR + "lampRoundFloor.glb", "t": 3, "h": 6.0, "s": 60, "x": -34, "z": -2, "rot": 0, "r": 3},
	{"p": FUR + "pottedPlant.glb", "t": 4, "h": 5.0, "s": 100, "x": -34, "z": -22, "rot": 0, "r": 3},
	{"p": FUR + "bedDouble.glb", "t": 6, "h": 4.8, "s": 450, "x": 33, "z": 26, "rot": 90, "r": 9},
	{"p": FUR + "sideTableDrawers.glb", "t": 4, "h": 4.0, "s": 120, "x": 33, "z": 17, "rot": 0, "r": 4},
	{"p": FUR + "bookcaseClosed.glb", "t": 6, "h": 10.0, "s": 500, "x": 35, "z": 4, "rot": 90, "r": 5},
	{"p": FUR + "desk.glb", "t": 5, "h": 4.5, "s": 230, "x": 29, "z": -30, "rot": 0, "r": 5},
	{"p": FUR + "chairDesk.glb", "t": 4, "h": 4.5, "s": 110, "x": 29, "z": -24, "rot": 180, "r": 3},
	{"p": FUR + "computerScreen.glb", "t": 2, "h": 2.5, "s": 35, "x": 29, "z": -32, "rot": 0, "r": 2.5},
	{"p": FUR + "coatRack.glb", "t": 3, "h": 8.0, "s": 60, "x": -2, "z": -35, "rot": 0, "r": 3},
	{"p": FUR + "stoolBar.glb", "t": 4, "h": 4.5, "s": 110, "x": 4, "z": -31, "rot": 0, "r": 3},
	{"p": FUR + "speaker.glb", "t": 3, "h": 3.8, "s": 65, "x": 10, "z": -34, "rot": 0, "r": 3},
	{"p": FUR + "trashcan.glb", "t": 3, "h": 3.6, "s": 60, "x": 15, "z": -34, "rot": 0, "r": 3},
	{"p": FUR + "radio.glb", "t": 2, "h": 2.0, "s": 35, "x": 20, "z": -34, "rot": 0, "r": 2.5},
	{"p": FUR + "cardboardBoxClosed.glb", "t": 5, "h": 5.0, "s": 180, "x": 24, "z": -32, "rot": 20, "r": 4},
	{"p": FUR + "plantSmall1.glb", "t": 2, "h": 2.4, "s": 40, "x": -10, "z": -33, "rot": 0, "r": 2.5},
]

const CLUTTER: = [
	{"p": FOOD + "mug.glb", "col": Color("e8576d"), "t": 0, "h": 0.8, "s": 10, "c": 6},
	{"p": FOOD + "cup.glb", "col": Color("f2b33d"), "t": 0, "h": 0.7, "s": 10, "c": 6},
	{"p": FOOD + "glass.glb", "col": Color("a8d8ea"), "t": 0, "h": 0.9, "s": 10, "c": 5},
	{"p": FOOD + "soda-can.glb", "col": Color("d9363e"), "t": 0, "h": 1.0, "s": 15, "c": 6},
	{"p": FUR + "computerMouse.glb", "t": 0, "h": 0.5, "s": 10, "c": 5},
	{"p": FUR + "books.glb", "t": 1, "h": 1.5, "s": 20, "c": 5},
	{"p": FOOD + "soda-bottle.glb", "col": Color("4fb06a"), "t": 1, "h": 2.0, "s": 30, "c": 4},
	{"p": FOOD + "bottle-ketchup.glb", "col": Color("d23b3b"), "t": 1, "h": 1.8, "s": 25, "c": 4},
	{"p": FOOD + "carton.glb", "col": Color("6aa8e8"), "t": 1, "h": 1.7, "s": 20, "c": 4},
]

@export var room_half: float = 34.0
@export var clear_radius: float = 5.0
@export var clutter_sep: float = 2.6
@export var rng_seed: int = 12345

func _ready() -> void:
	var placed: Array = []
	for it in RUGS:
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
	for it in LAYOUT:
		var scene: PackedScene = load(it.p)
		if scene == null:
			push_warning("layout model not found: %s" % it.p)
			continue
		_spawn(scene, it.t, it.h, it.s, Vector3(it.x, 0.0, it.z), deg_to_rad(it.rot), it.get("sc", 0.0))
		placed.append({"pos": Vector2(it.x, it.z), "sep": it.r})
	var rng: = RandomNumberGenerator.new()
	rng.seed = rng_seed
	for it in CLUTTER:
		var scene2: PackedScene = load(it.p)
		if scene2 == null:
			continue
		for i in it.c:
			var pos: = _find_spot(rng, placed, clutter_sep)
			_spawn(scene2, it.t, it.h, it.s, Vector3(pos.x, 0.0, pos.y), rng.randf() * TAU, 0.0, it.get("col", Color(0, 0, 0, 0)))
			placed.append({"pos": pos, "sep": clutter_sep})
	_warmup_shaders()

func _warmup_shaders() -> void:
	var paths: = {}
	for it in LAYOUT:
		paths[it.p] = true
	for it in CLUTTER:
		paths[it.p] = true
	for it in RUGS:
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

func _spawn(scene: PackedScene, t: int, h: float, s: int, pos: Vector3, rot_y: float, sc: float = 0.0, tint: Color = Color(0, 0, 0, 0)) -> void:
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

func _find_spot(rng: RandomNumberGenerator, placed: Array, sep: float) -> Vector2:
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
