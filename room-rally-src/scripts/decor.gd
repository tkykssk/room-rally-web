extends Node3D

@export var model_scene: PackedScene
@export var target_width: float = 10.0
@export var target_depth: float = 7.0

func _ready() -> void:
	if model_scene == null:
		return
	var m: Node3D = model_scene.instantiate()
	Palette.apply(m, randi() % Palette.FABRIC.size())
	add_child(m)
	var a: = _local_aabb(m)
	var sx: float = target_width / maxf(a.size.x, 0.001)
	var sz: float = target_depth / maxf(a.size.z, 0.001)
	var sy: float = (sx + sz) * 0.5
	m.scale = Vector3(sx, sy, sz)
	m.position.y = 0.04 - a.position.y * sy

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
