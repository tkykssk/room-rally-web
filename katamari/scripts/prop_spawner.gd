extends Node3D

## Lays out the room. Furniture is hand placed by zone (kitchen, dining,
## living, bedroom, office, hall); small things are scattered per zone and on
## table tops, so the size ladder runs from coins at the start mat up to the
## fridge, and every zone has something to roll up at every size.

const PROP: = preload("res://scenes/props/prop.tscn")
const DECOR: = preload("res://scenes/props/decor.tscn")
const FUR: = "res://assets/models/furniture/"
const FOOD: = "res://assets/models/food/"

## Kenney models usable as clutter: path, display name, height (units).
const MODELS: = {
	"mug": [FOOD + "mug.glb", "Mug", 0.8, Color("e8576d")],
	"cup": [FOOD + "cup.glb", "Cup", 0.7, Color("f2b33d")],
	"glass": [FOOD + "glass.glb", "Glass", 0.9, Color("a8d8ea")],
	"soda-can": [FOOD + "soda-can.glb", "Soda Can", 1.0, Color("d9363e")],
	"soda-bottle": [FOOD + "soda-bottle.glb", "Soda Bottle", 2.0, Color("4fb06a")],
	"ketchup": [FOOD + "bottle-ketchup.glb", "Ketchup", 1.8, Color("d23b3b")],
	"carton": [FOOD + "carton.glb", "Milk Carton", 1.7, Color("6aa8e8")],
	"mouse": [FUR + "computerMouse.glb", "Computer Mouse", 0.4],
	"books": [FUR + "books.glb", "Books", 1.2],
	"plant-s": [FUR + "plantSmall2.glb", "Little Plant", 2.0],
	"blender": [FUR + "kitchenBlender.glb", "Blender", 2.6],
	"plant": [FUR + "plantSmall1.glb", "Plant", 2.4],
	"radio": [FUR + "radio.glb", "Radio", 2.0],
	"speaker": [FUR + "speaker.glb", "Speaker", 3.8],
	"box": [FUR + "cardboardBoxClosed.glb", "Box", 2.8],
	"trashcan": [FUR + "trashcan.glb", "Trash Can", 3.0],
}

const RUGS: = [
	{"p": FUR + "rugSquare.glb", "x": 0, "z": 0, "rot": 0, "w": 16, "d": 16, "style": 1},
	{"p": FUR + "rugRectangle.glb", "x": -24, "z": -11, "rot": 0, "w": 20, "d": 14, "style": 0},
	{"p": FUR + "rugSquare.glb", "x": 28, "z": 22, "rot": 0, "w": 14, "d": 14, "style": 3},
	{"p": FUR + "rugRectangle.glb", "x": -14, "z": 16, "rot": 90, "w": 14, "d": 12, "style": 2},
]

## Furniture: id (for table tops), model, name, height, position, rotation,
## keep-out radius, optional fixed scale ("sc"), fabric palette ("style").
const LAYOUT: = [
	# Kitchen counter along the north wall.
	{"id": "fridge", "p": "kitchenFridge", "n": "Fridge", "h": 9.2, "x": -18.0, "z": 37.5, "rot": 0, "r": 4, "sc": 10},
	{"id": "stove", "p": "kitchenStove", "n": "Stove", "h": 4.5, "x": -13.7, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	{"id": "sink", "p": "kitchenSink", "n": "Sink", "h": 4.9, "x": -9.4, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	{"id": "c1", "p": "kitchenCabinet", "n": "Cabinet", "h": 4.5, "x": -5.1, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	{"id": "c2", "p": "kitchenCabinet", "n": "Cabinet", "h": 4.5, "x": -0.8, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	{"id": "c3", "p": "kitchenCabinet", "n": "Cabinet", "h": 4.5, "x": 3.5, "z": 37.5, "rot": 0, "r": 3, "sc": 10},
	# Dining.
	{"id": "dining", "p": "table", "n": "Dining Table", "h": 5.0, "x": -14, "z": 16, "rot": 0, "r": 5},
	{"p": "chair", "n": "Chair", "h": 7.0, "x": -14, "z": 21, "rot": 180, "r": 3},
	{"p": "chair", "n": "Chair", "h": 7.0, "x": -14, "z": 11, "rot": 0, "r": 3},
	{"p": "chair", "n": "Chair", "h": 7.0, "x": -20, "z": 16, "rot": 90, "r": 3},
	{"p": "chair", "n": "Chair", "h": 7.0, "x": -8, "z": 16, "rot": -90, "r": 3},
	# Living room.
	{"p": "loungeSofaLong", "n": "Sofa", "h": 6.0, "x": -33, "z": -11, "rot": 90, "r": 7, "style": 0},
	{"id": "coffee", "p": "tableCoffee", "n": "Coffee Table", "h": 2.5, "x": -24, "z": -11, "rot": 0, "r": 3},
	{"p": "loungeChair", "n": "Armchair", "h": 6.0, "x": -23, "z": -22, "rot": 0, "r": 4, "style": 2},
	{"id": "tvcab", "p": "cabinetTelevision", "n": "TV Stand", "h": 3.0, "x": -13, "z": -11, "rot": -90, "r": 4},
	{"p": "lampRoundFloor", "n": "Floor Lamp", "h": 6.0, "x": -35, "z": -1, "rot": 0, "r": 3},
	{"id": "endtable", "p": "sideTable", "n": "Side Table", "h": 3.2, "x": -34, "z": -22, "rot": 0, "r": 3},
	{"p": "pottedPlant", "n": "Potted Plant", "h": 5.0, "x": -16, "z": -2, "rot": 0, "r": 3},
	# Bedroom.
	{"p": "bedDouble", "n": "Bed", "h": 4.8, "x": 31, "z": 27, "rot": 90, "r": 9, "style": 3},
	{"id": "nightstand", "p": "sideTableDrawers", "n": "Nightstand", "h": 4.0, "x": 33, "z": 15, "rot": 0, "r": 4},
	{"id": "bookcase", "p": "bookcaseClosed", "n": "Bookcase", "h": 10.0, "x": 36, "z": 4, "rot": -90, "r": 5},
	{"p": "loungeSofa", "n": "Loveseat", "h": 5.5, "x": 18, "z": 33, "rot": 180, "r": 5, "style": 5},
	# Office.
	{"id": "desk", "p": "desk", "n": "Desk", "h": 4.5, "x": 29, "z": -31, "rot": 0, "r": 5},
	{"p": "chairDesk", "n": "Office Chair", "h": 4.5, "x": 29, "z": -24, "rot": 180, "r": 3, "style": 4},
	{"p": "trashcan", "n": "Trash Can", "h": 3.6, "x": 20, "z": -35, "rot": 0, "r": 3},
	{"p": "cardboardBoxClosed", "n": "Cardboard Box", "h": 5.0, "x": 17, "z": -24, "rot": 20, "r": 4},
	# Hall.
	{"p": "coatRack", "n": "Coat Rack", "h": 8.0, "x": -4, "z": -35, "rot": 0, "r": 3},
	{"p": "stoolBar", "n": "Stool", "h": 4.5, "x": 11, "z": -31, "rot": 0, "r": 3},
	{"p": "speaker", "n": "Speaker", "h": 3.8, "x": -12, "z": -35, "rot": 0, "r": 3},
	{"p": "radio", "n": "Radio", "h": 2.0, "x": -7, "z": -26, "rot": 30, "r": 2.5},
	{"p": "plantSmall1", "n": "Plant", "h": 2.4, "x": 13, "z": -16, "rot": 0, "r": 2.5},
]

## Things placed on top of furniture. "center" items sit in the middle.
const ON_TOP: = [
	{"on": "c1", "m": "kitchenMicrowave", "n": "Microwave", "h": 3.2, "center": true},
	{"on": "c2", "m": "kitchenCoffeeMachine", "n": "Coffee Maker", "h": 3.4, "center": true},
	{"on": "c3", "m": "toaster", "n": "Toaster", "h": 2.2, "center": true},
	{"on": "stove", "k": "blender"},
	{"on": "sink", "k": "glass"}, {"on": "sink", "k": "cup"},
	{"on": "dining", "k": "mug"}, {"on": "dining", "k": "mug"}, {"on": "dining", "k": "cup"},
	{"on": "dining", "k": "glass"}, {"on": "dining", "t": "apple"}, {"on": "dining", "t": "orange"},
	{"on": "dining", "t": "donut"}, {"on": "dining", "t": "donut"}, {"on": "dining", "k": "ketchup"},
	{"on": "coffee", "t": "remote"}, {"on": "coffee", "k": "books"}, {"on": "coffee", "k": "mug"},
	{"on": "coffee", "t": "candy"}, {"on": "coffee", "t": "candy"},
	{"on": "tvcab", "m": "televisionModern", "n": "Television", "h": 4.0, "center": true},
	{"on": "endtable", "t": "tissue"},
	{"on": "nightstand", "t": "phone"}, {"on": "nightstand", "k": "glass"}, {"on": "nightstand", "k": "books"},
	{"on": "bookcase", "t": "globe"}, {"on": "bookcase", "k": "books"},
	{"on": "desk", "m": "computerScreen", "n": "Monitor", "h": 2.5, "center": true},
	{"on": "desk", "k": "mouse"}, {"on": "desk", "t": "pencil"}, {"on": "desk", "t": "pencil"},
	{"on": "desk", "t": "eraser"}, {"on": "desk", "t": "cactus"}, {"on": "desk", "t": "paper"},
]

## Scatter zones: [x0, z0, x1, z1] and item counts. "t:" = toy, "k:" = model.
const ZONES: = [
	{"rect": [-8, -8, 8, 8], "items": {"t:coin": 16, "t:marble": 12, "t:button": 10, "t:candy": 10,
		"t:die": 8, "t:block": 6, "t:eraser": 4, "t:crayon": 8}},
	{"rect": [-37, -27, -15, 1], "items": {"t:block": 8, "t:crayon": 6, "t:duck": 3, "t:car": 4,
		"t:ball": 2, "t:cushion": 3, "t:paper": 4, "t:robot": 1, "t:teddy": 1, "t:coin": 6,
		"t:marble": 6, "t:basketball": 1, "t:drum": 1, "t:beachball": 1, "t:dollhouse": 1,
		"t:teddy@1.8": 1, "t:guitar": 1, "k:plant": 1}},
	{"rect": [-30, 5, 8, 33], "items": {"t:apple": 5, "t:orange": 5, "t:donut": 5, "t:candy": 6,
		"t:coin": 6, "k:soda-can": 4, "k:mug": 3, "k:cup": 3, "k:glass": 3, "k:carton": 3,
		"k:soda-bottle": 3, "k:ketchup": 2, "t:paper": 4, "t:basket": 1, "k:box": 2,
		"k:trashcan": 1, "t:fan": 1}},
	{"rect": [16, 2, 37, 36], "items": {"t:slipper": 4, "t:cushion": 3, "t:teddy": 1, "k:books": 4,
		"t:phone": 1, "t:piggy": 1, "t:ball": 2, "t:basketball": 1, "t:coin": 6, "t:button": 6,
		"t:tissue": 1, "t:suitcase": 2, "t:basket": 1, "t:guitar": 1, "t:teddy@1.8": 1,
		"t:beachball": 1, "k:radio": 1}},
	{"rect": [14, -37, 37, -14], "items": {"t:pencil": 6, "t:eraser": 4, "t:paper": 8, "t:phone": 1,
		"t:tissue": 2, "t:globe": 1, "t:cactus": 2, "k:mouse": 2, "t:coin": 4, "k:books": 3,
		"k:box": 2, "t:fan": 1, "k:speaker": 1, "t:robot@2.2": 1}},
	{"rect": [-14, -37, 13, -14], "items": {"t:slipper": 4, "t:coin": 8, "t:ball": 2, "t:cone": 3,
		"t:car": 2, "t:block": 4, "t:marble": 6, "t:paper": 3, "t:skateboard": 2, "t:suitcase": 1,
		"t:car@3.5": 2, "t:drum": 1, "k:plant": 1, "t:beachball": 1}},
	{"rect": [-37, -37, 37, 37], "items": {"t:coin": 10, "t:paper": 8, "t:button": 6, "t:marble": 6}},
]

## Keep-out radius for scattered items, by kind (default 0.7).
const SEP: = {"suitcase": 2.6, "drum": 2.2, "beachball": 2.4, "guitar": 2.8, "fan": 2.2,
	"skateboard": 2.4, "dollhouse": 3.2, "basket": 2.2, "plant": 2.0, "radio": 1.8, "speaker": 1.8,
	"box": 2.8, "trashcan": 2.6, "cushion": 2.4, "teddy": 2.2, "basketball": 2.0, "robot": 1.6, "globe": 1.8,
	"piggy": 1.4, "ball": 1.2, "tissue": 1.1, "cactus": 1.1, "soda-bottle": 1.2, "ketchup": 1.2,
	"carton": 1.1, "books": 1.2}

@export var room_half: float = 37.0
@export var clear_radius: float = 1.6
@export var rng_seed: int = 12345

var _rng: = RandomNumberGenerator.new()
var _placed: Array = []
var _by_id: Dictionary = {}

func _ready() -> void:
	add_to_group("props_root")
	_rng.seed = rng_seed
	for it in RUGS:
		var d: Node3D = DECOR.instantiate()
		d.model_scene = load(it.p)
		d.target_width = it.w
		d.target_depth = it.d
		d.style = it.style
		add_child(d)
		d.position = Vector3(it.x, 0.0, it.z)
		d.rotation.y = deg_to_rad(it.rot)
	for it in LAYOUT:
		var p: = _spawn_model(FUR + it.p + ".glb", it.n, it.h, Vector3(it.x, 0.0, it.z),
			deg_to_rad(it.rot), it.get("sc", 0.0), it.get("style", _rng.randi() % 6))
		if it.has("id"):
			_by_id[it.id] = p
		_placed.append({"pos": Vector2(it.x, it.z), "sep": it.r})
	_place_on_top()
	for zone in ZONES:
		for key in zone.items:
			for i in zone.items[key]:
				_scatter(key, zone.rect)
	_warmup_shaders()

func _place_on_top() -> void:
	var used: Dictionary = {}
	for it in ON_TOP:
		var base: Absorbable = _by_id.get(it.on)
		if base == null:
			continue
		var spots: Array = used.get(it.on, [])
		var pos: Vector3
		if it.get("center", false):
			pos = base.to_global(Vector3(base._center.x, base.base_y + base.dims.y, base._center.z))
		else:
			pos = base.top_point(_rng)
			for attempt in 12:
				var ok: = true
				for q in spots:
					if Vector2(pos.x, pos.z).distance_to(q) < 1.0:
						ok = false
						break
				if ok:
					break
				pos = base.top_point(_rng)
		spots.append(Vector2(pos.x, pos.z))
		used[it.on] = spots
		var rot: = base.rotation.y if it.get("center", false) else _rng.randf() * TAU
		var p: Absorbable
		if it.has("m"):
			p = _spawn_model(FUR + it.m + ".glb", it.n, it.h, pos, rot, 0.0, 0, base)
		else:
			p = _spawn_kind("t:" + it.t if it.has("t") else "k:" + it.k, pos, rot, base)
		p.position = pos

func _scatter(key: String, rect: Array) -> void:
	var kind: String = key.substr(2).get_slice("@", 0)
	var sep: float = SEP.get(kind, 0.7) * _scale_of(key)
	var spot: = _find_spot(rect, sep)
	_spawn_kind(key, Vector3(spot.x, 0.0, spot.y), _rng.randf() * TAU)
	_placed.append({"pos": spot, "sep": sep})

## "t:teddy@1.8" -> 1.8 (a giant teddy).
func _scale_of(key: String) -> float:
	return float(key.get_slice("@", 1)) if "@" in key else 1.0

func _spawn_kind(key: String, pos: Vector3, rot_y: float, support: Absorbable = null) -> Absorbable:
	var kind: String = key.substr(2).get_slice("@", 0)
	if key.begins_with("t:"):
		var scl: = _scale_of(key)
		var p: Absorbable = PROP.instantiate()
		p.model_node = ToyFactory.make(kind, _rng.randi() % 7)
		p.display_name = ("Giant " if scl > 1.5 else "") + ToyFactory.display_name(kind)
		p.target_scale = scl
		p.support = support
		add_child(p)
		p.position = pos
		p.rotation.y = rot_y
		return p
	var m: Array = MODELS[kind]
	var p: = _spawn_model(m[0], m[1], m[2], pos, rot_y, 0.0, _rng.randi() % 6, support, m[3] if m.size() > 3 else Color(0, 0, 0, 0))
	return p

func _spawn_model(path: String, display: String, h: float, pos: Vector3, rot_y: float,
		sc: float = 0.0, style: int = 0, support: Absorbable = null, tint: Color = Color(0, 0, 0, 0)) -> Absorbable:
	var p: Absorbable = PROP.instantiate()
	p.tint = tint
	p.model_scene = load(path)
	p.display_name = display
	p.target_height = h
	p.target_scale = sc
	p.style = style
	p.support = support
	add_child(p)
	p.position = pos
	p.rotation.y = rot_y
	return p

func _find_spot(rect: Array, sep: float) -> Vector2:
	var x0: float = maxf(rect[0], -room_half)
	var z0: float = maxf(rect[1], -room_half)
	var x1: float = minf(rect[2], room_half)
	var z1: float = minf(rect[3], room_half)
	var p: = Vector2.ZERO
	for attempt in 40:
		p = Vector2(_rng.randf_range(x0, x1), _rng.randf_range(z0, z1))
		if p.length() < clear_radius:
			continue
		var ok: = true
		for q in _placed:
			if p.distance_squared_to(q.pos) < pow(maxf(sep, q.sep * 0.5 + sep * 0.5), 2.0):
				ok = false
				break
		if ok:
			return p
	return p

## Instance every model once (opaque and see-through) as specks in front
## of the start camera for a second so the web build compiles shaders before play.
func _warmup_shaders() -> void:
	var paths: = {}
	for it in LAYOUT:
		paths[FUR + it.p + ".glb"] = true
	for it in ON_TOP:
		if it.has("m"):
			paths[FUR + it.m + ".glb"] = true
	for k in MODELS:
		paths[MODELS[k][0]] = true
	var warm: = Node3D.new()
	warm.name = "ShaderWarmup"
	add_child(warm)
	var i: = 0
	for p in paths.keys():
		var sc: PackedScene = load(p)
		var opaque: Node3D = sc.instantiate()
		Palette.apply(opaque, 0)
		warm.add_child(opaque)
		opaque.scale = Vector3.ONE * 0.05
		opaque.position = _warm_pos(i)
		i += 1
		var trans: Node3D = sc.instantiate()
		Palette.apply(trans, 0)
		warm.add_child(trans)
		trans.scale = Vector3.ONE * 0.05
		trans.position = _warm_pos(i)
		_make_transparent(trans)
		i += 1
	get_tree().create_timer(1.0).timeout.connect(warm.queue_free)

func _warm_pos(i: int) -> Vector3:
	return Vector3(-1.2 + (i % 12) * 0.2, 0.05, -4.0 - float(i / 12) * 0.2)

func _make_transparent(node: Node3D) -> void:
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		stack.append_array(n.get_children())
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
