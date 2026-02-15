class_name Dice
extends RigidBody3D
## A physics-enabled polyhedral die. Supports D4, D6, D8, D10, D12, D20.

@export_range(4, 20) var dice_type: int = 6

@export var dice_size: float = 0.08
@export var dice_color: Color = Color.WHITE
@export var number_color: Color = Color.BLACK

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

# Which face is "up" for reading the result (simplified - uses top-most face)
var _settled: bool = false
var _settle_timer: float = 0.0
const SETTLE_THRESHOLD := 0.5


func _ready() -> void:
	_setup_dice()


func _physics_process(delta: float) -> void:
	if not _settled and linear_velocity.length() < 0.1 and angular_velocity.length() < 0.1:
		_settle_timer += delta
		if _settle_timer > SETTLE_THRESHOLD:
			_settled = true
			dice_settled.emit(self, get_top_value())
	else:
		_settle_timer = 0.0


## Emitted when dice stops rolling, with the top face value
signal dice_settled(dice: Dice, value: int)


func _setup_dice() -> void:
	# Create mesh from generator
	mesh_instance = MeshInstance3D.new()
	var mesh := DiceMeshGenerator.create_dice_mesh(dice_type, dice_size)
	mesh_instance.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = dice_color
	mat.roughness = 0.55
	mat.metallic = 0.15
	mesh_instance.material_override = mat

	add_child(mesh_instance)

	# Use BoxShape3D for stable physics (convex from complex meshes can crash)
	collision_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(dice_size * 2.2, dice_size * 2.2, dice_size * 2.2)
	collision_shape.shape = box
	add_child(collision_shape)

	# Physics defaults for dice rolling
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.3
	physics_material_override.friction = 0.4
	mass = 0.05  # ~50g equivalent for physics stability
	lock_rotation = false


func _refresh_mesh() -> void:
	if mesh_instance and mesh_instance.mesh:
		var mesh := DiceMeshGenerator.create_dice_mesh(dice_type, dice_size)
		mesh_instance.mesh = mesh


## Apply a random spin and toss force for rolling
func roll(impulse_strength: float = 2.0, direction: Vector3 = Vector3.ZERO) -> void:
	_settled = false
	_settle_timer = 0.0

	if direction == Vector3.ZERO:
		direction = Vector3(randf_range(-0.5, 0.5), 1.0, randf_range(-0.5, 0.5)).normalized()

	apply_central_impulse(direction * impulse_strength)
	apply_torque_impulse(Vector3(
		randf_range(-3, 3),
		randf_range(-3, 3),
		randf_range(-3, 3)
	))


## Simplified: returns a value 1..dice_type. For proper face detection, would need raycasting.
func get_top_value() -> int:
	# Placeholder - proper implementation would raycast up from center to find top face
	return randi_range(1, dice_type)
