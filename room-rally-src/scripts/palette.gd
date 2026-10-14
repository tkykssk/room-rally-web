class_name Palette extends RefCounted

## Re-colours the pastel Kenney furniture materials into a warmer, more
## saturated toy-room palette. Fabric ("carpet") takes a per-object accent
## colour so two sofas don't look identical. Materials are cached and shared.

const FABRIC: = [
	Color("e8576d"), Color("3fa7c9"), Color("f2b33d"), Color("6c6fd1"),
	Color("5cbf7a"), Color("e57fb8"),
]

const FIXED: = {
	"wood": Color("d39a62"),
	"woodDark": Color("8f5d3b"),
	"carpetWhite": Color("f6efe2"),
	"metal": Color("cfd6da"),
	"metalLight": Color("f1f4f5"),
	"metalMedium": Color("98a6ab"),
	"metalDark": Color("5f6b72"),
	"glass": Color("a8d8ea"),
	"plant": Color("47b06d"),
	"plant2": Color("2f9a5a"),
	"lamp": Color("ffe7a3"),
}

static var _cache: Dictionary = {}

## `tint` recolours untextured models (the food kit's colormap texture is not
## shipped, so those surfaces would otherwise render plain white).
static func apply(root: Node, variant: int, tint: Color = Color(0, 0, 0, 0)) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D and n.mesh != null:
			for si in n.mesh.get_surface_count():
				var m = n.mesh.surface_get_material(si)
				if m is StandardMaterial3D:
					n.set_surface_override_material(si, _styled(m, variant, tint))

static func _styled(src: StandardMaterial3D, variant: int, tint: Color) -> StandardMaterial3D:
	var name: = src.resource_name
	var is_fabric: = name == "carpet" or name == "carpetDarker"
	var tinted: = tint.a > 0.0 and (name == "colormap" or name == "_defaultMat")
	var key: = "%d/%d/%s" % [src.get_instance_id(), variant if is_fabric else 0, tint.to_html() if tinted else ""]
	if _cache.has(key):
		return _cache[key]
	var m: StandardMaterial3D = src.duplicate()
	m.metallic = 0.0
	m.roughness = 0.75
	if tinted:
		m.albedo_texture = null
		m.albedo_color = tint
		m.roughness = 0.4
	elif is_fabric:
		var c: Color = FABRIC[variant % FABRIC.size()]
		m.albedo_color = c.darkened(0.2) if name == "carpetDarker" else c
	elif FIXED.has(name):
		m.albedo_color = FIXED[name]
		if name.begins_with("metal") or name == "glass":
			m.roughness = 0.35
		if name == "lamp":
			m.emission_enabled = true
			m.emission = FIXED[name]
			m.emission_energy_multiplier = 0.6
	_cache[key] = m
	return m
