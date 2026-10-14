extends StaticBody3D

@export var wall_normal: Vector3 = Vector3(0, 0, 1)

@export var drop_distance: float = 7.0

@export var drop_height: float = 3.2

@export var lerp_speed: float = 8.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
var _vehicle: Node = null

func _ready() -> void:
	_vehicle = get_tree().get_first_node_in_group("vehicle")

func _process(delta: float) -> void:
	if _vehicle == null:
		_vehicle = get_tree().get_first_node_in_group("vehicle")
		return
	var car_pos: Vector3 = _vehicle.get_vehicle_position() if _vehicle.has_method("get_vehicle_position") else (_vehicle as Node3D).global_position
	var perp: = absf((car_pos - global_position).dot(wall_normal.normalized()))
	var target_y: = -drop_height if perp < drop_distance else 0.0
	mesh.position.y = lerpf(mesh.position.y, target_y, delta * lerp_speed)
