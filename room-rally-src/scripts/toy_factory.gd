class_name ToyFactory extends RefCounted

## Small procedural props (coins, crayons, rubber ducks...) built from primitive
## meshes. They fill the bottom of the size ladder below the Kenney models, so
## the very first seconds of a run already have plenty to roll up.
## Each (kind, variant) mesh is built once and shared.

const KINDS: = {
	"coin": "Coin", "marble": "Marble", "button": "Button", "candy": "Candy",
	"die": "Dice", "donut": "Donut", "eraser": "Eraser", "crayon": "Crayon",
	"pencil": "Pencil", "block": "Toy Block", "duck": "Rubber Duck",
	"car": "Toy Car", "ball": "Ball", "cone": "Toy Cone", "teddy": "Teddy Bear",
	"cushion": "Cushion", "slipper": "Slipper", "apple": "Apple",
	"orange": "Orange", "remote": "TV Remote", "phone": "Phone",
	"tissue": "Tissue Box", "robot": "Toy Robot", "paper": "Paper Ball",
	"globe": "Globe", "basketball": "Basketball", "piggy": "Piggy Bank",
	"cactus": "Cactus", "suitcase": "Suitcase", "drum": "Toy Drum",
	"beachball": "Beach Ball", "guitar": "Guitar", "fan": "Electric Fan",
	"skateboard": "Skateboard", "dollhouse": "Dollhouse", "basket": "Laundry Basket",
	# garden
	"flower": "Flower", "rock": "Pebble", "mushroom": "Mushroom", "acorn": "Acorn",
	"hose": "Garden Hose", "bucket": "Bucket", "wateringcan": "Watering Can",
	"gnome": "Garden Gnome", "flamingo": "Lawn Flamingo", "bush": "Bush",
	"mailbox": "Mailbox", "hydrant": "Fire Hydrant", "grill": "BBQ Grill",
	"bench": "Garden Bench", "doghouse": "Doghouse", "parasol": "Parasol",
	"pool": "Paddling Pool", "lamppost": "Lamp Post", "tree": "Tree",
	"pine": "Pine Tree", "shed": "Garden Shed",
	# street
	"sedan": "Car", "van": "Van", "bus": "Bus", "house": "House", "trafficcone": "Traffic Cone",
	"bicycle": "Bicycle", "fountain": "Fountain", "gate": "Garden Gate",
	"trafficlight": "Traffic Light",
	"apartment": "Apartment", "shop": "Corner Shop", "utilitypole": "Utility Pole",
	"vending": "Vending Machine", "torii": "Torii Gate", "shrine": "Shrine", "slide": "Slide",
	"swing": "Swing", "ac": "Air Conditioner", "bikerack": "Parked Bikes",
}

const BRIGHT: = [
	Color("e8576d"), Color("3fa7c9"), Color("f2b33d"), Color("6c6fd1"),
	Color("5cbf7a"), Color("e57fb8"), Color("f08a3c"),
]

static var _meshes: Dictionary = {}
static var _material: StandardMaterial3D = null

static func display_name(kind: String) -> String:
	return KINDS.get(kind, kind.capitalize())

static func make(kind: String, variant: int = 0) -> Node3D:
	var key: = "%s/%d" % [kind, variant]
	if not _meshes.has(key):
		_meshes[key] = _build(kind, variant)
	var root: = Node3D.new()
	var mi: = MeshInstance3D.new()
	mi.mesh = _meshes[key]
	root.add_child(mi)
	return root

static func _mat() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.55
	return _material

static func _c(variant: int, offset: int = 0) -> Color:
	return BRIGHT[(variant + offset) % BRIGHT.size()]

static func _build(kind: String, v: int) -> ArrayMesh:
	var b: = _Builder.new()
	match kind:
		"coin":
			b.cyl(0.12, 0.03, Vector3(0, 0.015, 0), Color("f5c542"), 16)
			b.cyl(0.09, 0.034, Vector3(0, 0.015, 0), Color("e0a92a"), 16)
		"marble":
			b.sphere(0.08, Vector3(0, 0.08, 0), _c(v).lightened(0.2), 10)
		"button":
			b.cyl(0.1, 0.035, Vector3(0, 0.0175, 0), _c(v), 14)
			for i in 4:
				var a: = TAU * i / 4.0 + 0.6
				b.cyl(0.015, 0.04, Vector3(cos(a) * 0.035, 0.02, sin(a) * 0.035), _c(v).darkened(0.5), 6)
		"candy":
			b.sphere(0.08, Vector3(0, 0.08, 0), _c(v), 10)
			b.cone(0.07, 0.1, Vector3(0.12, 0.08, 0), _c(v).lightened(0.4), Vector3(0, 0, 90))
			b.cone(0.07, 0.1, Vector3(-0.12, 0.08, 0), _c(v).lightened(0.4), Vector3(0, 0, -90))
		"die":
			b.box(Vector3(0.16, 0.16, 0.16), Vector3(0, 0.08, 0), Color("f7f3ea"))
			for p in [Vector2(0, 0), Vector2(-0.04, -0.04), Vector2(0.04, 0.04), Vector2(-0.04, 0.04), Vector2(0.04, -0.04)]:
				b.sphere(0.014, Vector3(p.x, 0.16, p.y), Color("d23b3b"), 6)
		"donut":
			b.torus(0.06, 0.16, Vector3(0, 0.05, 0), Color("c98a4b"))
			b.torus(0.07, 0.15, Vector3(0, 0.075, 0), _c(v, 5).lightened(0.25), Vector3(1, 0.5, 1))
		"eraser":
			b.box(Vector3(0.3, 0.1, 0.15), Vector3(0, 0.05, 0), Color("f4a3b5"))
			b.box(Vector3(0.14, 0.105, 0.155), Vector3(0.05, 0.05, 0), _c(v, 1))
		"crayon":
			b.cyl(0.04, 0.4, Vector3(0, 0.04, 0), _c(v), 8, Vector3(0, 0, 90))
			b.cone(0.04, 0.08, Vector3(0.24, 0.04, 0), _c(v).darkened(0.2), Vector3(0, 0, -90))
		"pencil":
			b.cyl(0.04, 0.8, Vector3(0, 0.04, 0), Color("f2c230"), 6, Vector3(0, 0, 90))
			b.cone(0.04, 0.12, Vector3(0.46, 0.04, 0), Color("e8c49a"), Vector3(0, 0, -90))
			b.cyl(0.042, 0.08, Vector3(-0.44, 0.04, 0), Color("f4a3b5"), 8, Vector3(0, 0, 90))
		"block":
			b.box(Vector3(0.3, 0.3, 0.3), Vector3(0, 0.15, 0), _c(v))
			b.box(Vector3(0.2, 0.31, 0.2), Vector3(0, 0.15, 0), _c(v).lightened(0.35))
		"duck":
			b.sphere(0.22, Vector3(0, 0.18, 0), Color("ffd23f"), 12, Vector3(1.25, 0.85, 1))
			b.sphere(0.14, Vector3(0.14, 0.4, 0), Color("ffd23f"), 10)
			b.cone(0.06, 0.12, Vector3(0.3, 0.38, 0), Color("f08a3c"), Vector3(0, 0, -90))
			b.sphere(0.025, Vector3(0.24, 0.45, 0.07), Color("222222"), 6)
			b.sphere(0.025, Vector3(0.24, 0.45, -0.07), Color("222222"), 6)
		"car":
			b.box(Vector3(0.7, 0.18, 0.34), Vector3(0, 0.15, 0), _c(v))
			b.box(Vector3(0.36, 0.16, 0.3), Vector3(-0.05, 0.32, 0), _c(v).lightened(0.3))
			for w in [Vector2(0.22, 0.17), Vector2(-0.22, 0.17), Vector2(0.22, -0.17), Vector2(-0.22, -0.17)]:
				b.cyl(0.09, 0.07, Vector3(w.x, 0.09, w.y), Color("2b2b2b"), 10, Vector3(90, 0, 0))
		"ball":
			b.sphere(0.35, Vector3(0, 0.35, 0), _c(v), 14)
			b.torus(0.33, 0.37, Vector3(0, 0.35, 0), Color("ffffff"), Vector3(1, 1, 1), Vector3(90, 0, 0))
		"cone":
			b.box(Vector3(0.4, 0.05, 0.4), Vector3(0, 0.025, 0), Color("f08a3c"))
			b.cone(0.15, 0.55, Vector3(0, 0.32, 0), Color("f08a3c"))
			b.cyl(0.11, 0.08, Vector3(0, 0.3, 0), Color("ffffff"), 12)
		"teddy":
			var fur: = Color("b07a4f")
			b.sphere(0.5, Vector3(0, 0.55, 0), fur, 12, Vector3(1, 1.1, 0.9))
			b.sphere(0.38, Vector3(0, 1.3, 0), fur, 12)
			b.sphere(0.14, Vector3(0.28, 1.6, 0), fur, 8)
			b.sphere(0.14, Vector3(-0.28, 1.6, 0), fur, 8)
			b.sphere(0.15, Vector3(0, 1.22, 0.33), Color("e8c9a0"), 8)
			b.sphere(0.2, Vector3(0.45, 0.6, 0.15), fur, 8)
			b.sphere(0.2, Vector3(-0.45, 0.6, 0.15), fur, 8)
			b.sphere(0.22, Vector3(0.28, 0.15, 0.3), fur, 8)
			b.sphere(0.22, Vector3(-0.28, 0.15, 0.3), fur, 8)
			b.sphere(0.05, Vector3(0.13, 1.4, 0.33), Color("222222"), 6)
			b.sphere(0.05, Vector3(-0.13, 1.4, 0.33), Color("222222"), 6)
		"cushion":
			b.box(Vector3(1.6, 0.4, 1.6), Vector3(0, 0.2, 0), _c(v))
			b.box(Vector3(1.3, 0.46, 1.3), Vector3(0, 0.22, 0), _c(v).lightened(0.15))
		"slipper":
			b.box(Vector3(0.32, 0.08, 0.75), Vector3(0, 0.04, 0), _c(v).lightened(0.3))
			b.box(Vector3(0.32, 0.14, 0.32), Vector3(0, 0.11, 0.2), _c(v))
		"apple":
			b.sphere(0.18, Vector3(0, 0.17, 0), Color("d9363e"), 12)
			b.cyl(0.015, 0.08, Vector3(0, 0.37, 0), Color("6b4a2b"), 6)
			b.sphere(0.05, Vector3(0.05, 0.36, 0), Color("5cbf7a"), 6, Vector3(1.4, 0.4, 0.8))
		"orange":
			b.sphere(0.18, Vector3(0, 0.17, 0), Color("f58f29"), 12)
			b.sphere(0.03, Vector3(0, 0.35, 0), Color("4d8f3a"), 6)
		"remote":
			b.box(Vector3(0.2, 0.07, 0.6), Vector3(0, 0.035, 0), Color("2d2f36"))
			b.box(Vector3(0.06, 0.075, 0.06), Vector3(0, 0.04, -0.2), Color("e8576d"))
			for i in 3:
				b.box(Vector3(0.12, 0.075, 0.04), Vector3(0, 0.04, -0.05 + i * 0.08), Color("8a8f99"))
		"phone":
			b.box(Vector3(0.36, 0.04, 0.72), Vector3(0, 0.02, 0), Color("2d2f36"))
			b.box(Vector3(0.31, 0.045, 0.6), Vector3(0, 0.022, 0), _c(v, 1).lightened(0.3))
		"tissue":
			b.box(Vector3(0.6, 0.36, 0.4), Vector3(0, 0.18, 0), _c(v, 2).lightened(0.45))
			b.sphere(0.12, Vector3(0, 0.38, 0), Color("ffffff"), 8, Vector3(1.2, 0.8, 0.8))
		"robot":
			var steel: = Color("9aa7b4")
			b.box(Vector3(0.5, 0.55, 0.35), Vector3(0, 0.55, 0), steel)
			b.box(Vector3(0.38, 0.32, 0.32), Vector3(0, 1.0, 0), steel.lightened(0.2))
			b.box(Vector3(0.14, 0.3, 0.14), Vector3(0.13, 0.15, 0), steel.darkened(0.3))
			b.box(Vector3(0.14, 0.3, 0.14), Vector3(-0.13, 0.15, 0), steel.darkened(0.3))
			b.box(Vector3(0.1, 0.4, 0.1), Vector3(0.32, 0.6, 0), steel.darkened(0.15))
			b.box(Vector3(0.1, 0.4, 0.1), Vector3(-0.32, 0.6, 0), steel.darkened(0.15))
			b.sphere(0.05, Vector3(0.08, 1.04, 0.17), Color("5ad1ff"), 6)
			b.sphere(0.05, Vector3(-0.08, 1.04, 0.17), Color("5ad1ff"), 6)
			b.cyl(0.015, 0.15, Vector3(0, 1.23, 0), steel, 6)
			b.sphere(0.04, Vector3(0, 1.32, 0), Color("e8576d"), 6)
		"paper":
			b.sphere(0.15, Vector3(0, 0.14, 0), Color("f4f1e8"), 6)
		"globe":
			b.cyl(0.25, 0.08, Vector3(0, 0.04, 0), Color("6b4a2b"), 12)
			b.cyl(0.03, 0.4, Vector3(0, 0.25, 0), Color("c9a24b"), 6)
			b.sphere(0.45, Vector3(0, 0.85, 0), Color("3f8fd1"), 14)
			b.sphere(0.2, Vector3(0.22, 0.98, 0.25), Color("5cbf7a"), 8, Vector3(1.2, 1, 0.6))
			b.sphere(0.16, Vector3(-0.25, 0.72, 0.27), Color("5cbf7a"), 8, Vector3(1, 1.3, 0.6))
		"basketball":
			b.sphere(0.6, Vector3(0, 0.6, 0), Color("e8772e"), 16)
			b.torus(0.58, 0.62, Vector3(0, 0.6, 0), Color("3a2a20"), Vector3(1, 1, 1), Vector3(90, 0, 0))
			b.torus(0.58, 0.62, Vector3(0, 0.6, 0), Color("3a2a20"), Vector3(1, 1, 1), Vector3(0, 0, 90))
		"piggy":
			var pink: = Color("f4a3b5")
			b.sphere(0.4, Vector3(0, 0.45, 0), pink, 12, Vector3(1.3, 1, 1))
			b.cyl(0.13, 0.12, Vector3(0.55, 0.45, 0), pink.darkened(0.1), 10, Vector3(0, 0, 90))
			for p in [Vector2(0.25, 0.2), Vector2(-0.25, 0.2), Vector2(0.25, -0.2), Vector2(-0.25, -0.2)]:
				b.cyl(0.08, 0.15, Vector3(p.x, 0.075, p.y), pink.darkened(0.15), 8)
			b.cone(0.09, 0.14, Vector3(0.32, 0.82, 0.15), pink, Vector3(0, 0, 0))
			b.cone(0.09, 0.14, Vector3(0.32, 0.82, -0.15), pink, Vector3(0, 0, 0))
			b.box(Vector3(0.2, 0.03, 0.04), Vector3(0, 0.85, 0), Color("333333"))
		"cactus":
			b.cyl(0.25, 0.35, Vector3(0, 0.175, 0), Color("c8673d"), 12)
			b.sphere(0.22, Vector3(0, 0.7, 0), Color("3fae6a"), 10, Vector3(1, 1.9, 1))
			b.sphere(0.1, Vector3(0.2, 0.75, 0), Color("3fae6a"), 8, Vector3(1, 1.8, 1))
			b.sphere(0.05, Vector3(0, 1.12, 0), Color("e57fb8"), 6)
		"suitcase":
			b.box(Vector3(2.2, 1.5, 0.8), Vector3(0, 0.8, 0), _c(v, 3))
			b.box(Vector3(2.25, 0.12, 0.85), Vector3(0, 0.8, 0), _c(v, 3).darkened(0.3))
			b.box(Vector3(0.7, 0.12, 0.15), Vector3(0, 1.62, 0), Color("2d2f36"))
			for x in [-0.9, 0.9]:
				b.cyl(0.08, 0.1, Vector3(x, 0.06, 0.25), Color("2d2f36"), 8, Vector3(90, 0, 0))
		"drum":
			b.cyl(0.75, 0.8, Vector3(0, 0.4, 0), _c(v), 16)
			b.cyl(0.78, 0.08, Vector3(0, 0.82, 0), Color("f4f1e8"), 16)
			b.cyl(0.78, 0.08, Vector3(0, 0.04, 0), Color("f4f1e8"), 16)
			b.cyl(0.03, 0.9, Vector3(0.3, 1.0, 0), Color("c98a4b"), 6, Vector3(0, 0, 50))
		"beachball":
			for i in 6:
				var seg: = SphereMesh.new()
				seg.radius = 0.9
				seg.height = 1.8
				seg.radial_segments = 6
				seg.rings = 8
				b.add_xf(seg, Transform3D(Basis(Vector3.UP, i * TAU / 6.0).scaled(Vector3(1.0 - i * 0.001, 1, 1)), Vector3(0, 0.9, 0)), _c(v, i) if i % 2 == 0 else Color("ffffff"))
		"guitar":
			b.sphere(0.55, Vector3(-0.55, 0.2, 0), Color("c98a4b"), 12, Vector3(1, 0.35, 0.85))
			b.sphere(0.42, Vector3(0.15, 0.2, 0), Color("c98a4b"), 12, Vector3(1, 0.35, 0.8))
			b.cyl(0.18, 0.05, Vector3(-0.3, 0.38, 0), Color("3a2a20"), 12)
			b.box(Vector3(1.8, 0.1, 0.16), Vector3(1.3, 0.25, 0), Color("6b4a2b"))
			b.box(Vector3(0.4, 0.12, 0.28), Vector3(2.35, 0.25, 0), Color("3a2a20"))
		"fan":
			b.cyl(0.6, 0.15, Vector3(0, 0.075, 0), Color("f4f1e8"), 14)
			b.cyl(0.08, 1.9, Vector3(0, 1.1, 0), Color("f4f1e8"), 8)
			b.cyl(0.85, 0.35, Vector3(0, 2.4, 0), _c(v, 1).lightened(0.3), 16, Vector3(90, 0, 0))
			b.sphere(0.25, Vector3(0, 2.4, 0.25), Color("f4f1e8"), 10)
		"skateboard":
			b.box(Vector3(2.4, 0.1, 0.7), Vector3(0, 0.3, 0), _c(v, 2))
			b.box(Vector3(2.0, 0.11, 0.5), Vector3(0, 0.3, 0), Color("2d2f36"))
			for p in [Vector2(0.75, 0.25), Vector2(-0.75, 0.25), Vector2(0.75, -0.25), Vector2(-0.75, -0.25)]:
				b.cyl(0.11, 0.1, Vector3(p.x, 0.12, p.y), Color("f2b33d"), 10, Vector3(90, 0, 0))
		"dollhouse":
			b.box(Vector3(2.6, 1.8, 1.6), Vector3(0, 0.9, 0), Color("f6efe2"))
			b.box(Vector3(2.8, 0.9, 1.7), Vector3(0, 2.1, 0), _c(v))
			b.box(Vector3(0.5, 0.9, 0.05), Vector3(0, 0.45, 0.8), Color("a8683f"))
			b.box(Vector3(0.5, 0.45, 0.05), Vector3(-0.85, 1.2, 0.8), Color("bfe6ff"))
			b.box(Vector3(0.5, 0.45, 0.05), Vector3(0.85, 1.2, 0.8), Color("bfe6ff"))
		"basket":
			b.cyl(0.8, 1.3, Vector3(0, 0.65, 0), _c(v, 4).lightened(0.35), 16)
			b.cyl(0.84, 0.15, Vector3(0, 1.25, 0), _c(v, 4), 16)
			b.sphere(0.45, Vector3(0.1, 1.35, 0), _c(v, 1).lightened(0.3), 8, Vector3(1.4, 0.6, 1.2))
		# --- garden ---------------------------------------------------------
		"flower":
			b.cyl(0.03, 0.7, Vector3(0, 0.35, 0), Color("4f9e4a"), 6)
			b.sphere(0.12, Vector3(0.1, 0.25, 0), Color("5cbf7a"), 6, Vector3(1.6, 0.4, 0.8))
			for i in 5:
				var a: = TAU * i / 5.0
				b.sphere(0.11, Vector3(cos(a) * 0.13, 0.72, sin(a) * 0.13), _c(v), 6, Vector3(1, 0.5, 1))
			b.sphere(0.08, Vector3(0, 0.74, 0), Color("f5c542"), 6)
		"rock":
			b.sphere(0.5, Vector3(0, 0.3, 0), Color("9a9a96").lerp(Color("b5a58c"), (v % 3) / 2.0), 8, Vector3(1.3, 0.6, 1.0))
		"mushroom":
			b.cyl(0.12, 0.4, Vector3(0, 0.2, 0), Color("f4f1e8"), 8)
			b.sphere(0.32, Vector3(0, 0.42, 0), Color("e8463d"), 10, Vector3(1, 0.55, 1))
			for p in [Vector3(0.15, 0.58, 0.05), Vector3(-0.12, 0.56, 0.12), Vector3(0.0, 0.6, -0.15)]:
				b.sphere(0.05, p, Color("ffffff"), 6)
		"acorn":
			b.sphere(0.2, Vector3(0, 0.22, 0), Color("b97a3e"), 8, Vector3(1, 1.25, 1))
			b.sphere(0.22, Vector3(0, 0.38, 0), Color("6b4a2b"), 8, Vector3(1, 0.5, 1))
			b.cyl(0.03, 0.12, Vector3(0, 0.5, 0), Color("6b4a2b"), 6)
		"hose":
			for i in 3:
				b.torus(0.32 + i * 0.12, 0.42 + i * 0.12, Vector3(0, 0.06 + i * 0.07, 0), Color("4fb06a").darkened(i * 0.08))
			b.cyl(0.05, 0.3, Vector3(0.75, 0.08, 0), Color("f2b33d"), 6, Vector3(0, 0, 90))
		"bucket":
			var bm: = CylinderMesh.new()
			bm.top_radius = 0.42
			bm.bottom_radius = 0.32
			bm.height = 0.7
			bm.radial_segments = 14
			b.add(bm, Vector3(0, 0.35, 0), _c(v, 1))
			b.torus(0.38, 0.44, Vector3(0, 0.7, 0), _c(v, 1).darkened(0.25))
			b.torus(0.4, 0.43, Vector3(0, 0.7, 0), Color("9a9a96"), Vector3(1, 1, 1), Vector3(90, 0, 0))
		"wateringcan":
			b.cyl(0.35, 0.6, Vector3(0, 0.3, 0), Color("4fb06a"), 12)
			b.cyl(0.06, 0.8, Vector3(0.55, 0.5, 0), Color("4fb06a"), 6, Vector3(0, 0, -55))
			b.cyl(0.1, 0.06, Vector3(0.88, 0.74, 0), Color("3d8a52"), 8, Vector3(0, 0, -55))
			b.torus(0.18, 0.24, Vector3(-0.1, 0.72, 0), Color("3d8a52"), Vector3(1, 1, 1), Vector3(90, 0, 0))
		"gnome":
			b.cyl(0.32, 0.55, Vector3(0, 0.28, 0), Color("3f6fd1"), 10)
			b.sphere(0.24, Vector3(0, 0.68, 0), Color("f2c9a0"), 8)
			b.cone(0.26, 0.38, Vector3(0, 0.6, 0.13), Color("ffffff"), Vector3(-160, 0, 0))
			b.sphere(0.07, Vector3(0, 0.7, 0.24), Color("e8a07a"), 6)
			b.cone(0.27, 0.7, Vector3(0, 1.1, 0), Color("e8463d"))
			b.box(Vector3(0.5, 0.12, 0.35), Vector3(0, 0.06, 0.05), Color("6b4a2b"))
		"flamingo":
			b.cyl(0.02, 0.9, Vector3(0.04, 0.45, 0), Color("2d2f36"), 6)
			b.cyl(0.02, 0.9, Vector3(-0.04, 0.45, 0), Color("2d2f36"), 6)
			b.sphere(0.28, Vector3(0, 1.0, 0), Color("f07ab3"), 10, Vector3(1.5, 0.9, 0.9))
			b.cyl(0.05, 0.6, Vector3(0.3, 1.35, 0), Color("f07ab3"), 6, Vector3(0, 0, -20))
			b.sphere(0.1, Vector3(0.4, 1.66, 0), Color("f07ab3"), 8)
			b.cone(0.05, 0.16, Vector3(0.52, 1.62, 0), Color("2d2f36"), Vector3(0, 0, -110))
		"bush":
			var g: = Color("4f9e4a").lerp(Color("6cbf55"), (v % 4) / 3.0)
			b.sphere(0.8, Vector3(0, 0.7, 0), g, 10, Vector3(1.1, 0.85, 1.0))
			b.sphere(0.6, Vector3(0.6, 0.55, 0.2), g.lightened(0.08), 10)
			b.sphere(0.55, Vector3(-0.55, 0.5, -0.15), g.darkened(0.08), 10)
			if v % 2 == 0:
				for p in [Vector3(0.3, 1.25, 0.5), Vector3(-0.4, 1.0, 0.6), Vector3(0.8, 0.9, -0.3)]:
					b.sphere(0.09, p, _c(v, 5), 6)
		"mailbox":
			b.box(Vector3(0.18, 1.6, 0.18), Vector3(0, 0.8, 0), Color("6b4a2b"))
			b.box(Vector3(0.5, 0.45, 0.9), Vector3(0, 1.75, 0), _c(v, 1))
			b.cyl(0.25, 0.9, Vector3(0, 1.97, 0), _c(v, 1), 12, Vector3(90, 0, 0))
			b.box(Vector3(0.05, 0.4, 0.08), Vector3(0.28, 2.05, -0.2), Color("e8463d"))
		"hydrant":
			b.cyl(0.32, 1.0, Vector3(0, 0.5, 0), Color("e8463d"), 12)
			b.sphere(0.32, Vector3(0, 1.0, 0), Color("e8463d"), 10)
			b.cyl(0.4, 0.12, Vector3(0, 0.06, 0), Color("c23a33"), 12)
			b.cyl(0.12, 0.7, Vector3(0, 0.62, 0), Color("c23a33"), 8, Vector3(0, 0, 90))
			b.cyl(0.1, 0.2, Vector3(0, 1.3, 0), Color("c23a33"), 8)
		"grill":
			for a in [0.0, TAU / 3.0, 2.0 * TAU / 3.0]:
				b.cyl(0.04, 1.2, Vector3(cos(a) * 0.3, 0.55, sin(a) * 0.3), Color("2d2f36"), 6, Vector3(rad_to_deg(sin(a)) * 0.3, 0, -rad_to_deg(cos(a)) * 0.3))
			b.sphere(0.6, Vector3(0, 1.1, 0), Color("2d2f36"), 12, Vector3(1, 0.75, 1))
			b.cyl(0.62, 0.05, Vector3(0, 1.12, 0), Color("9a9a96"), 14)
			b.cyl(0.06, 0.12, Vector3(0, 1.58, 0), Color("6b4a2b"), 6)
		"bench":
			for z in [-0.25, 0.0, 0.25]:
				b.box(Vector3(2.6, 0.08, 0.2), Vector3(0, 0.75, z), Color("b9875a"))
			for y in [1.1, 1.35]:
				b.box(Vector3(2.6, 0.18, 0.06), Vector3(0, y, -0.38), Color("b9875a"))
			for x in [-1.1, 1.1]:
				b.box(Vector3(0.1, 0.75, 0.7), Vector3(x, 0.38, 0), Color("2d2f36"))
				b.box(Vector3(0.1, 0.75, 0.08), Vector3(x, 1.1, -0.38), Color("2d2f36"))
		"doghouse":
			b.box(Vector3(2.0, 1.4, 2.4), Vector3(0, 0.7, 0), _c(v, 3).lightened(0.25))
			b.add(_roof(), Vector3(0, 1.85, 0), Color("a8463d"), Vector3.ZERO, Vector3(2.3, 0.9, 2.7))
			b.box(Vector3(0.8, 0.9, 0.05), Vector3(0, 0.55, 1.2), Color("3a2a20"))
			b.box(Vector3(0.9, 0.2, 0.06), Vector3(0, 1.15, 1.21), Color("f4f1e8"))
		"parasol":
			b.cyl(0.4, 0.15, Vector3(0, 0.075, 0), Color("9a9a96"), 12)
			b.cyl(0.05, 2.6, Vector3(0, 1.3, 0), Color("f4f1e8"), 6)
			var cm: = CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = 1.6
			cm.height = 0.6
			cm.radial_segments = 8
			b.add(cm, Vector3(0, 2.55, 0), _c(v))
			b.sphere(0.07, Vector3(0, 2.88, 0), Color("f4f1e8"), 6)
		"pool":
			b.torus(1.5, 2.0, Vector3(0, 0.25, 0), _c(v, 1).lightened(0.2), Vector3(1, 2.0, 1))
			b.cyl(1.6, 0.3, Vector3(0, 0.15, 0), Color("6ecbe8"), 20)
			b.sphere(0.3, Vector3(0.5, 0.4, 0.3), Color("f5c542"), 8, Vector3(1, 0.8, 1))
		"lamppost":
			b.cyl(0.25, 0.3, Vector3(0, 0.15, 0), Color("2d2f36"), 10)
			b.cyl(0.08, 4.0, Vector3(0, 2.2, 0), Color("2d2f36"), 8)
			b.box(Vector3(0.55, 0.65, 0.55), Vector3(0, 4.45, 0), Color("fff2b0"))
			b.cone(0.5, 0.35, Vector3(0, 4.95, 0), Color("2d2f36"))
		"tree":
			b.cyl(0.35, 3.0, Vector3(0, 1.5, 0), Color("8a5a35"), 8)
			var g: = Color("4f9e4a").lerp(Color("7cc35a"), (v % 4) / 3.0)
			b.sphere(1.7, Vector3(0, 3.9, 0), g, 12)
			b.sphere(1.2, Vector3(1.1, 3.4, 0.4), g.lightened(0.08), 10)
			b.sphere(1.2, Vector3(-1.0, 3.5, -0.5), g.darkened(0.08), 10)
			b.sphere(1.0, Vector3(0.2, 5.0, -0.2), g.lightened(0.05), 10)
			if v % 3 == 0:
				for p in [Vector3(0.9, 4.2, 1.2), Vector3(-1.2, 3.8, 0.9), Vector3(0.3, 5.3, 0.8)]:
					b.sphere(0.16, p, Color("e8463d"), 6)
		"pine":
			b.cyl(0.25, 1.4, Vector3(0, 0.7, 0), Color("8a5a35"), 8)
			for i in 3:
				var cm2: = CylinderMesh.new()
				cm2.top_radius = 0.0
				cm2.bottom_radius = 1.5 - i * 0.35
				cm2.height = 1.8
				cm2.radial_segments = 10
				b.add(cm2, Vector3(0, 1.9 + i * 1.05, 0), Color("2f7a4a").lightened(i * 0.06))
		"shed":
			b.box(Vector3(4.0, 3.0, 3.2), Vector3(0, 1.5, 0), _c(v, 4).lightened(0.3))
			b.add(_roof(), Vector3(0, 3.8, 0), Color("6b4a2b"), Vector3.ZERO, Vector3(4.6, 1.6, 3.6))
			b.box(Vector3(1.4, 2.2, 0.05), Vector3(-0.6, 1.1, 1.61), Color("8a5a35"))
			b.box(Vector3(0.9, 0.7, 0.05), Vector3(1.1, 1.8, 1.61), Color("bfe6ff"))
		# --- street ---------------------------------------------------------
		"sedan":
			var body: = _c(v, 1)
			b.box(Vector3(4.2, 0.9, 1.9), Vector3(0, 0.75, 0), body)
			b.box(Vector3(2.3, 0.8, 1.7), Vector3(-0.2, 1.55, 0), body.lightened(0.1))
			b.box(Vector3(2.0, 0.6, 1.72), Vector3(-0.2, 1.55, 0), Color("bfe6ff"))
			b.box(Vector3(2.32, 0.6, 1.5), Vector3(-0.2, 1.55, 0), Color("bfe6ff"))
			for x in [-1.35, 1.35]:
				for z in [-0.85, 0.85]:
					b.cyl(0.4, 0.3, Vector3(x, 0.4, z), Color("2d2f36"), 12, Vector3(90, 0, 0))
			for z in [-0.6, 0.6]:
				b.box(Vector3(0.05, 0.22, 0.4), Vector3(2.1, 0.85, z), Color("fff2b0"))
		"van":
			var vb: = _c(v, 2).lightened(0.2)
			b.box(Vector3(4.8, 2.0, 2.0), Vector3(0, 1.4, 0), vb)
			b.box(Vector3(0.05, 0.8, 1.7), Vector3(2.41, 1.9, 0), Color("bfe6ff"))
			b.box(Vector3(3.2, 0.6, 2.02), Vector3(-0.6, 1.95, 0), Color("bfe6ff"))
			b.box(Vector3(4.82, 0.25, 2.02), Vector3(0, 1.0, 0), vb.darkened(0.25))
			for x in [-1.5, 1.5]:
				for z in [-0.9, 0.9]:
					b.cyl(0.45, 0.32, Vector3(x, 0.45, z), Color("2d2f36"), 12, Vector3(90, 0, 0))
		"bus":
			b.box(Vector3(10.0, 2.6, 2.5), Vector3(0, 1.85, 0), Color("f2b33d"))
			b.box(Vector3(9.0, 0.8, 2.52), Vector3(-0.3, 2.35, 0), Color("bfe6ff"))
			b.box(Vector3(0.05, 1.2, 2.1), Vector3(5.01, 2.2, 0), Color("bfe6ff"))
			b.box(Vector3(10.02, 0.2, 2.52), Vector3(0, 1.35, 0), Color("2d2f36"))
			for x in [-3.4, 3.4]:
				for z in [-1.15, 1.15]:
					b.cyl(0.55, 0.35, Vector3(x, 0.55, z), Color("2d2f36"), 12, Vector3(90, 0, 0))
		"house":
			# Four kinds of house, each in five colour schemes.
			var wall: Color = [Color("f4ead8"), Color("e8d3b0"), Color("cfe0e8"), Color("f0d0c8"), Color("dfe8c8")][v % 5]
			var roofc: Color = [Color("c45a4a"), Color("4a6fc4"), Color("6b4a2b"), Color("4f8a5a"), Color("5a5f6b")][(v + 2) % 5]
			match v % 4:
				0:  # two storeys, gable roof
					b.box(Vector3(10.0, 6.0, 8.0), Vector3(0, 3.0, 0), wall)
					b.add(_roof(), Vector3(0, 8.0, 0), roofc, Vector3(0, 90, 0), Vector3(9.0, 4.0, 11.0))
					b.box(Vector3(0.9, 2.2, 0.9), Vector3(2.8, 8.6, -1.5), Color("a8463d"))
				1:  # hip roof, wider
					b.box(Vector3(11.0, 5.6, 9.0), Vector3(0, 2.8, 0), wall)
					var hip: = CylinderMesh.new()
					hip.top_radius = 1.2
					hip.bottom_radius = 8.2
					hip.height = 3.2
					hip.radial_segments = 4
					hip.rings = 1
					b.add(hip, Vector3(0, 7.2, 0), roofc, Vector3(0, 45, 0), Vector3(1.0, 1.0, 0.82))
				2:  # modern, flat roof with a balcony
					b.box(Vector3(10.0, 6.4, 8.0), Vector3(0, 3.2, 0), wall.lightened(0.2))
					b.box(Vector3(10.4, 0.4, 8.4), Vector3(0, 6.6, 0), Color("5a5f6b"))
					b.box(Vector3(6.0, 0.25, 1.6), Vector3(-1.0, 3.3, 4.8), Color("9a9a96"))
					b.box(Vector3(6.0, 1.1, 0.1), Vector3(-1.0, 3.9, 5.55), Color("f4f1e8"))
				_:  # narrow, three storeys
					b.box(Vector3(7.0, 8.4, 8.0), Vector3(0, 4.2, 0), wall)
					b.add(_roof(), Vector3(0, 9.9, 0), roofc, Vector3(0, 90, 0), Vector3(9.0, 3.0, 7.8))
			b.box(Vector3(1.6, 3.0, 0.1), Vector3(-1.5, 1.5, 4.05), Color("a8683f"))
			for x in [-3.2, 2.4]:
				b.box(Vector3(1.8, 1.4, 0.1), Vector3(x * 0.8, 4.6, 4.05), Color("bfe6ff"))
				b.box(Vector3(1.8, 1.4, 0.1), Vector3(x * 0.8, 4.6, -4.05), Color("bfe6ff"))
			b.box(Vector3(1.8, 1.4, 0.1), Vector3(2.4, 1.8, 4.05), Color("bfe6ff"))
		"apartment":
			# A three/four-storey block of flats with balconies on the front.
			var floors: = 3 + v % 2
			var fh: = 2.8
			var aw: Color = [Color("efe8dc"), Color("d9d2c4"), Color("e6dccb"), Color("cfd6d8")][v % 4]
			b.box(Vector3(16.0, floors * fh, 7.0), Vector3(0, floors * fh * 0.5, 0), aw)
			b.box(Vector3(16.4, 0.4, 7.4), Vector3(0, floors * fh + 0.2, 0), Color("8a8a86"))
			for i in floors:
				var y: = i * fh
				b.box(Vector3(15.6, 0.2, 1.2), Vector3(0, y + 0.3, 4.1), Color("b8b2a6"))
				b.box(Vector3(15.6, 0.9, 0.1), Vector3(0, y + 0.8, 4.7), Color("f4f1e8"))
				for k in 4:
					b.box(Vector3(2.4, 1.6, 0.1), Vector3(-5.7 + k * 3.8, y + 1.5, 3.55), Color("9fc6dc"))
					b.box(Vector3(2.0, 1.2, 0.1), Vector3(-5.7 + k * 3.8, y + 1.6, -3.55), Color("9fc6dc"))
			b.box(Vector3(2.4, floors * fh + 1.2, 2.6), Vector3(8.6, (floors * fh + 1.2) * 0.5, -1.6), aw.darkened(0.08))
		"shop":
			# A corner shop / convenience store: glass front and a coloured band.
			var band: Color = [Color("3fae6a"), Color("e8576d"), Color("3f7fd1"), Color("f08a3c")][v % 4]
			b.box(Vector3(14.0, 4.6, 10.0), Vector3(0, 2.3, 0), Color("f4f1e8"))
			b.box(Vector3(14.2, 1.0, 10.2), Vector3(0, 4.1, 0), band)
			b.box(Vector3(14.22, 0.25, 10.22), Vector3(0, 3.5, 0), Color("ffffff"))
			b.box(Vector3(10.0, 2.6, 0.1), Vector3(-1.0, 1.4, 5.05), Color("bfe6ff"))
			b.box(Vector3(2.0, 2.6, 0.12), Vector3(4.8, 1.4, 5.06), Color("8fb8cf"))
			b.box(Vector3(3.0, 0.4, 3.0), Vector3(-3.0, 4.9, -2.0), Color("9a9a96"))
		"utilitypole":
			b.cyl(0.2, 12.0, Vector3(0, 6.0, 0), Color("9a958c"), 8)
			b.box(Vector3(2.6, 0.18, 0.18), Vector3(0, 11.0, 0), Color("6b6b66"))
			b.box(Vector3(2.0, 0.18, 0.18), Vector3(0, 10.0, 0), Color("6b6b66"))
			b.cyl(0.38, 1.1, Vector3(0.45, 8.6, 0.3), Color("8a8f94"), 10)
			for x in [-1.1, 0.0, 1.1]:
				b.cyl(0.07, 0.3, Vector3(x, 11.25, 0), Color("ffffff"), 6)
		"vending":
			var vc: Color = [Color("e8463d"), Color("3f7fd1"), Color("f4f1e8"), Color("3fae6a")][v % 4]
			b.box(Vector3(1.0, 1.8, 0.7), Vector3(0, 0.9, 0), vc)
			b.box(Vector3(0.8, 0.7, 0.05), Vector3(0, 1.3, 0.36), Color("dceef6"))
			for i in 6:
				b.box(Vector3(0.1, 0.14, 0.06), Vector3(-0.3 + (i % 3) * 0.3, 0.95 - (i / 3) * 0.12, 0.37), _c(v, i))
			b.box(Vector3(0.6, 0.2, 0.05), Vector3(0, 0.35, 0.36), Color("2d2f36"))
		"torii":
			for x in [-2.0, 2.0]:
				b.cyl(0.22, 4.4, Vector3(x, 2.2, 0), Color("d9452e"), 10)
			b.box(Vector3(5.6, 0.35, 0.5), Vector3(0, 4.45, 0), Color("2d2f36"))
			b.box(Vector3(5.0, 0.3, 0.4), Vector3(0, 4.15, 0), Color("d9452e"))
			b.box(Vector3(4.6, 0.25, 0.3), Vector3(0, 3.5, 0), Color("d9452e"))
		"shrine":
			b.box(Vector3(6.0, 0.6, 5.0), Vector3(0, 0.3, 0), Color("b0a690"))
			b.box(Vector3(4.6, 2.6, 3.6), Vector3(0, 1.9, 0), Color("a8683f"))
			b.add(_roof(), Vector3(0, 4.0, 0), Color("4a4f5a"), Vector3(0, 90, 0), Vector3(5.2, 1.8, 6.2))
			b.box(Vector3(2.2, 1.8, 0.1), Vector3(0, 1.7, 1.85), Color("3a2a20"))
			b.box(Vector3(1.2, 0.5, 0.6), Vector3(0, 0.85, 2.6), Color("6b4a2b"))
		"slide":
			b.box(Vector3(1.4, 2.4, 1.4), Vector3(-1.6, 1.2, 0), _c(v, 2))
			b.box(Vector3(3.6, 0.15, 1.0), Vector3(0.6, 1.2, 0), _c(v, 0))
			b.add(_roof(), Vector3(-1.6, 2.8, 0), _c(v, 4), Vector3.ZERO, Vector3(1.6, 0.8, 1.6))
		"swing":
			for x in [-1.8, 1.8]:
				b.cyl(0.08, 3.2, Vector3(x, 1.6, 0.8), Color("3f7fd1"), 6, Vector3(14, 0, 0))
				b.cyl(0.08, 3.2, Vector3(x, 1.6, -0.8), Color("3f7fd1"), 6, Vector3(-14, 0, 0))
			b.cyl(0.08, 3.8, Vector3(0, 3.1, 0), Color("3f7fd1"), 6, Vector3(0, 0, 90))
			for x in [-0.8, 0.8]:
				b.cyl(0.02, 2.2, Vector3(x, 2.0, 0), Color("9a9a96"), 4)
				b.box(Vector3(0.6, 0.08, 0.35), Vector3(x, 0.9, 0), _c(v, 1))
		"ac":
			b.box(Vector3(1.6, 1.0, 0.6), Vector3(0, 0.5, 0), Color("ecebe6"))
			b.cyl(0.36, 0.05, Vector3(0.3, 0.5, 0.31), Color("9a9a96"), 12, Vector3(90, 0, 0))
		"bikerack":
			for i in 3:
				var cx: = -1.2 + i * 1.2
				b.torus(0.36, 0.42, Vector3(cx, 0.42, -0.6), Color("2d2f36"), Vector3.ONE, Vector3(0, 90, 90))
				b.torus(0.36, 0.42, Vector3(cx, 0.42, 0.6), Color("2d2f36"), Vector3.ONE, Vector3(0, 90, 90))
				b.cyl(0.04, 1.2, Vector3(cx, 0.7, 0), _c(v, i), 6, Vector3(90, 0, 0))
		"trafficcone":
			b.box(Vector3(0.9, 0.08, 0.9), Vector3(0, 0.04, 0), Color("f08a3c"))
			b.cone(0.38, 1.1, Vector3(0, 0.6, 0), Color("f08a3c"))
			b.cyl(0.25, 0.14, Vector3(0, 0.62, 0), Color("ffffff"), 10)
		"bicycle":
			for x in [-0.8, 0.8]:
				b.torus(0.42, 0.5, Vector3(x, 0.5, 0), Color("2d2f36"), Vector3.ONE, Vector3(90, 0, 0))
			var fc: = _c(v, 3)
			b.cyl(0.04, 1.6, Vector3(0, 0.75, 0), fc, 6, Vector3(0, 0, 90))
			b.cyl(0.04, 0.9, Vector3(-0.35, 0.75, 0), fc, 6, Vector3(0, 0, 40))
			b.cyl(0.04, 0.9, Vector3(0.45, 0.8, 0), fc, 6, Vector3(0, 0, -20))
			b.box(Vector3(0.35, 0.08, 0.16), Vector3(-0.55, 1.15, 0), Color("2d2f36"))
			b.cyl(0.03, 0.6, Vector3(0.75, 1.2, 0), Color("9a9a96"), 6, Vector3(90, 0, 0))
		"fountain":
			b.torus(2.4, 2.9, Vector3(0, 0.35, 0), Color("cfc7b8"), Vector3(1, 1.6, 1))
			b.cyl(2.5, 0.5, Vector3(0, 0.3, 0), Color("6ecbe8"), 20)
			b.cyl(0.4, 2.2, Vector3(0, 1.4, 0), Color("cfc7b8"), 10)
			b.cyl(1.1, 0.3, Vector3(0, 2.5, 0), Color("cfc7b8"), 14)
			b.cyl(0.9, 0.12, Vector3(0, 2.62, 0), Color("6ecbe8"), 14)
			b.sphere(0.35, Vector3(0, 3.0, 0), Color("bfe6ff"), 8, Vector3(1, 1.5, 1))
		"gate":
			for x in [-2.35, 2.35]:
				b.box(Vector3(0.25, 1.6, 0.25), Vector3(x, 0.8, 0), Color("b9875a"))
			for y in [0.4, 1.15]:
				b.box(Vector3(4.6, 0.12, 0.1), Vector3(0, y, 0), Color("f4ead8"))
			for i in 13:
				b.box(Vector3(0.2, 1.45, 0.08), Vector3(-2.1 + i * 0.35, 0.75, 0.06), Color("f4ead8"))
		"trafficlight":
			b.cyl(0.12, 4.0, Vector3(0, 2.0, 0), Color("2d2f36"), 8)
			b.box(Vector3(0.5, 1.4, 0.45), Vector3(0, 4.4, 0), Color("2d2f36"))
			for i in 3:
				b.sphere(0.15, Vector3(0, 4.85 - i * 0.45, 0.22), [Color("e8463d"), Color("f2b33d"), Color("5cbf7a")][i], 8)
		_:
			b.box(Vector3(0.3, 0.3, 0.3), Vector3(0, 0.15, 0), _c(v))
	var mesh: = b.commit()
	mesh.surface_set_material(0, _mat())
	return mesh


## A unit gable roof (prism): ridge along z, 1 wide, 1 tall, 1 deep.
static var _roof_mesh: PrismMesh = null
static func _roof() -> PrismMesh:
	if _roof_mesh == null:
		_roof_mesh = PrismMesh.new()
		_roof_mesh.size = Vector3(1, 1, 1)
	return _roof_mesh


## Merges transformed primitive meshes into one vertex-coloured surface.
class _Builder:
	var verts: = PackedVector3Array()
	var normals: = PackedVector3Array()
	var colors: = PackedColorArray()
	var indices: = PackedInt32Array()

	func add(mesh: PrimitiveMesh, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> void:
		add_xf(mesh, Transform3D(Basis.from_euler(rot_deg * (PI / 180.0)).scaled_local(scl), pos), color)

	func add_xf(mesh: PrimitiveMesh, xf: Transform3D, color: Color) -> void:
		var arrays: = mesh.get_mesh_arrays()
		var basis: = xf.basis
		var pos: = xf.origin
		var nb: = basis.inverse().transposed()
		var base: = verts.size()
		var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in vs.size():
			verts.append(basis * vs[i] + pos)
			normals.append((nb * ns[i]).normalized())
			colors.append(color)
		for idx in arrays[Mesh.ARRAY_INDEX]:
			indices.append(base + idx)

	func box(size: Vector3, pos: Vector3, color: Color) -> void:
		var m: = BoxMesh.new()
		m.size = size
		add(m, pos, color)

	func sphere(r: float, pos: Vector3, color: Color, seg: int = 10, scl: Vector3 = Vector3.ONE) -> void:
		var m: = SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = seg
		m.rings = maxi(seg / 2, 4)
		add(m, pos, color, Vector3.ZERO, scl)

	func cyl(r: float, h: float, pos: Vector3, color: Color, seg: int = 10, rot: Vector3 = Vector3.ZERO) -> void:
		var m: = CylinderMesh.new()
		m.top_radius = r
		m.bottom_radius = r
		m.height = h
		m.radial_segments = seg
		m.rings = 1
		add(m, pos, color, rot)

	func cone(r: float, h: float, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> void:
		var m: = CylinderMesh.new()
		m.top_radius = 0.0
		m.bottom_radius = r
		m.height = h
		m.radial_segments = 10
		m.rings = 1
		add(m, pos, color, rot)

	func torus(inner: float, outer: float, pos: Vector3, color: Color, scl: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> void:
		var m: = TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = 16
		m.ring_segments = 8
		add(m, pos, color, rot, scl)

	func commit() -> ArrayMesh:
		var arrays: = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh: = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh
