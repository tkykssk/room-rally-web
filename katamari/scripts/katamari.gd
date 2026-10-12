class_name Katamari extends RigidBody3D

## The rolling ball. Objects small enough for the current tier stick to it
## (see Absorbable), and it grows each time GameManager unlocks a tier.

@export_group("Tuning")

## Top rolling speed at tier 0 (m/s). Scales with sqrt(size_scale).
@export var max_speed: float = 7.0

## How quickly the ball's spin approaches the target spin.
@export var spin_accel: float = 5.0

## Turn rate of the heading (and so the camera) in rad/s.
@export var turn_speed: float = 2.4

@export var base_radius: float = 0.6

## Stuck objects are dropped once this many are attached (oldest first).
@export var max_stuck: int = 80

const GROW_PER_TIER: = 1.5
const PICKUP_MARGIN: = 1.15
const EMBED: = 0.85

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var core: MeshInstance3D = $Core
@onready var stuck_root: Node3D = $Stuck
@onready var pickup: Area3D = $Pickup
@onready var pickup_shape: CollisionShape3D = $Pickup/CollisionShape3D
@onready var pickup_sound: AudioStreamPlayer = $PickupSound
@onready var bump_sound: AudioStreamPlayer = $BumpSound

var size_scale: float = 1.0
var radius: float = 0.6
var heading: float = 0.0
var input: Vector2

var _manager: Node = null
var _pending_lift: float = 0.0
var _pickup_tick: int = 0

func get_player_position() -> Vector3: return global_position
func get_heading_yaw() -> float: return heading
func get_horizontal_speed() -> float: return Vector2(linear_velocity.x, linear_velocity.z).length()

func _ready() -> void:
	add_to_group("player")
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	# Shapes are per-instance so growing one ball never touches another.
	collision.shape = collision.shape.duplicate()
	pickup_shape.shape = pickup_shape.shape.duplicate()
	_set_radius(base_radius)
	_manager = get_tree().get_first_node_in_group("game_manager")
	if _manager and _manager.has_signal("tier_unlocked"):
		_manager.tier_unlocked.connect(_on_tier_unlocked)

func _on_tier_unlocked(tier: int) -> void:
	size_scale = pow(GROW_PER_TIER, tier)
	var tw: = create_tween()
	tw.tween_method(_grow_to, radius, base_radius * size_scale, 0.4)
	tw.tween_callback(_prune_buried)

func _grow_to(r: float) -> void:
	_pending_lift += r - radius
	_set_radius(r)

func _set_radius(r: float) -> void:
	radius = r
	(collision.shape as SphereShape3D).radius = r
	(pickup_shape.shape as SphereShape3D).radius = r * PICKUP_MARGIN
	var k: = r / base_radius
	core.scale = Vector3(k, k, k)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Growing the collision sphere would sink it into the floor; lift it by
	# the same amount so it stays resting on the ground.
	if _pending_lift != 0.0:
		var xf: = state.transform
		xf.origin.y += _pending_lift
		state.transform = xf
		_pending_lift = 0.0

func _physics_process(delta: float) -> void:
	var playing: bool = _manager == null or _manager.playing
	if playing:
		input = Vector2(Input.get_axis("left", "right"), Input.get_axis("back", "forward"))
	else:
		input = Vector2.ZERO
	heading -= input.x * turn_speed * delta
	var forward: = Vector3(-sin(heading), 0.0, -cos(heading))
	# Rolling without slipping: spin axis = up x direction, rate = v / r.
	var speed: = max_speed * sqrt(size_scale)
	var target_spin: = Vector3.UP.cross(forward) * (input.y * speed / radius)
	var spin: = angular_velocity
	var horizontal: = Vector3(spin.x, 0.0, spin.z)
	var rate: = spin_accel if absf(input.y) > 0.05 else spin_accel * 0.5
	horizontal = horizontal.lerp(target_spin, clampf(delta * rate, 0.0, 1.0))
	# Steer the existing roll toward the new heading so turns don't skid.
	angular_velocity = Vector3(horizontal.x, spin.y * 0.9, horizontal.z)
	_pickup_tick += 1
	if _pickup_tick % 2 == 0:
		for a in pickup.get_overlapping_areas():
			if a is Absorbable and a.can_absorb():
				a.absorb_into(self)

## Re-parent an absorbed object's model onto the ball surface.
## `center` is the object's world-space centre, `extent` its rough radius.
func attach(model: Node3D, center: Vector3, extent: float) -> void:
	var dir: = center - global_position
	if dir.length() < 0.001:
		dir = Vector3.UP
	dir = dir.normalized()
	var target_center: = global_position + dir * (radius * EMBED)
	var gt: = model.global_transform
	gt.origin += target_center - center
	model.get_parent().remove_child(model)
	stuck_root.add_child(model)
	model.global_transform = gt
	model.set_meta("extent", extent)
	model.set_meta("center_offset", stuck_root.to_local(target_center).length())
	if stuck_root.get_child_count() > max_stuck:
		stuck_root.get_child(0).queue_free()
	pickup_sound.pitch_scale = randf_range(1.3, 1.7)
	pickup_sound.play()

## Objects that end up fully inside the grown ball are invisible; free them.
func _prune_buried() -> void:
	for c in stuck_root.get_children():
		var reach: float = c.get_meta("center_offset", 0.0) + c.get_meta("extent", 0.0)
		if reach < radius * 0.95:
			c.queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("ground") or bump_sound.playing:
		return
	var v: = get_horizontal_speed()
	if v < 1.0:
		return
	bump_sound.volume_db = clampf(remap(v, 1.0, 8.0, -20.0, 0.0), -20.0, 0.0)
	bump_sound.play()
