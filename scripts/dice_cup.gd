class_name DiceCup
extends Node3D
## A 3D cup that holds dice. Tilt or tap to spill dice onto the tray.

@export var cup_radius: float = 0.06
@export var cup_height: float = 0.12
@export var cup_color: Color = Color(0.35, 0.65, 0.45)  # Bright felt green
@export var tilt_speed: float = 3.0
@export var max_tilt: float = 60.0  # degrees

var _mesh_instance: MeshInstance3D
var _base_rotation: float = 0.0
var _is_pouring: bool = false
var _pour_direction: float = 1.0  # -1 or 1 for left/right

## Emitted when cup is tilted to pour - dice should be released
signal pour_started


func _ready() -> void:
	_setup_cup()


func _process(delta: float) -> void:
	if _is_pouring:
		_base_rotation += _pour_direction * tilt_speed * delta
		_base_rotation = clampf(_base_rotation, -deg_to_rad(max_tilt), deg_to_rad(max_tilt))
		rotation.z = _base_rotation


func _setup_cup() -> void:
	# Cylinder mesh - open top (no top face)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices: PackedInt32Array = []
	var segments := 24
	var r := cup_radius
	var h := cup_height

	# Bottom circle vertices
	for i in range(segments):
		var angle := TAU * i / float(segments)
		verts.append(Vector3(cos(angle) * r, 0, sin(angle) * r))
		normals.append(Vector3.DOWN)
	var center_bottom := verts.size()
	verts.append(Vector3(0, 0, 0))
	normals.append(Vector3.DOWN)

	# Bottom face triangles
	for i in range(segments):
		indices.append(center_bottom)
		indices.append(i)
		indices.append((i + 1) % segments)

	# Side - cylinder (no top cap)
	var side_start := verts.size()
	for i in range(segments + 1):
		var angle := TAU * i / float(segments)
		var dir := Vector3(cos(angle), 0, sin(angle))
		verts.append(dir * r)
		verts.append(dir * r + Vector3.UP * h)
		normals.append(dir)
		normals.append(dir)
	var idx := side_start
	for i in range(segments):
		indices.append(idx)
		indices.append(idx + 1)
		indices.append(idx + 2)
		indices.append(idx + 1)
		indices.append(idx + 3)
		indices.append(idx + 2)
		idx += 2

	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cup_color
	mat.roughness = 0.6
	mat.metallic = 0.05
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

	# Collision for dice containment (invisible, just defines the cup volume)
	var area := Area3D.new()
	area.name = "CupArea"
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.height = cup_height
	shape.radius = cup_radius
	col.shape = shape
	col.position = Vector3(0, cup_height / 2, 0)
	area.add_child(col)
	add_child(area)


## Start tilting the cup to pour dice
func start_pour(direction: float = 1.0) -> void:
	_is_pouring = true
	_pour_direction = sign(direction) if direction != 0 else 1.0
	pour_started.emit()


## Stop tilting
func stop_pour() -> void:
	_is_pouring = false


## Reset cup to upright
func reset() -> void:
	_base_rotation = 0.0
	rotation.z = 0
	_is_pouring = false
