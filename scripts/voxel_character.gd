class_name VoxelCharacter
extends Node3D
## Displays a voxel character mesh (converted from 2D pixel art with 10-depth extrusion).
## Used for allies/characters that spill from tubes or appear in the game world.

@export var character_id: String = ""
@export var mesh_scale: float = 0.01  # Match converter scale
@export var voxel_mesh_path: String = ""

var _mesh_instance: MeshInstance3D


func _ready() -> void:
	if voxel_mesh_path.is_empty() and character_id.is_empty():
		return
	_load_voxel_mesh()


func _load_voxel_mesh() -> void:
	var path := voxel_mesh_path
	if path.is_empty() and not character_id.is_empty():
		path = _get_mesh_path_for_character(character_id)
	if path.is_empty():
		return

	if not ResourceLoader.exists(path):
		push_warning("Voxel mesh not found: %s" % path)
		return

	var res = load(path)
	var mesh: Mesh = null
	if res is Mesh:
		mesh = res as Mesh
	elif res is PackedScene:
		var inst = (res as PackedScene).instantiate()
		if inst is MeshInstance3D:
			mesh = (inst as MeshInstance3D).mesh
		else:
			var mi = inst.get_node_or_null("MeshInstance3D")
			if mi is MeshInstance3D:
				mesh = (mi as MeshInstance3D).mesh
	if mesh == null:
		push_warning("Could not load mesh from %s" % path)
		return

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = mesh
	_mesh_instance.scale = Vector3.ONE * mesh_scale
	# OBJs have no materials - use fallback so voxels are visible under lighting
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.84, 0.78, 1)
	mat.roughness = 0.7
	mat.metallic = 0.0
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)


func _get_mesh_path_for_character(id: String) -> String:
	# Map townsfolk IDs to voxel mesh paths (mirrors diceTubes.js character entries)
	var map := {
		"waitress": "res://assets/voxels/townsfolk/Waitress_voxel.obj",
		"cook": "res://assets/voxels/townsfolk/Cook_voxel.obj",
		"teenBoy01": "res://assets/voxels/townsfolk/TeenBoy01_voxel.obj",
		"teenBoy02": "res://assets/voxels/townsfolk/TeenBoy02_voxel.obj",
		"teenBoy03": "res://assets/voxels/townsfolk/TeenBoy03_voxel.obj",
		"teenGirl01": "res://assets/voxels/townsfolk/TeenGirl01_voxel.obj",
		"teenGirl02": "res://assets/voxels/townsfolk/TeenGirl02_voxel.obj",
		"teenGirl03": "res://assets/voxels/townsfolk/TeenGirl03_voxel.obj",
		"stonerTeenBoy": "res://assets/voxels/townsfolk/StonerTeenBoy_voxel.obj",
		"adultMan08": "res://assets/voxels/townsfolk/AdultMan08_voxel.obj",
		"historyTeacher": "res://assets/voxels/townsfolk/HistoryTeacher_voxel.obj",
		"oldMan": "res://assets/voxels/townsfolk/OldMan_voxel.obj",
		"businesswoman": "res://assets/voxels/townsfolk/Businesswoman_voxel.obj",
		"emoTeenGirl": "res://assets/voxels/townsfolk/EmoTeenGirl_voxel.obj",
		"scientist": "res://assets/voxels/townsfolk/Scientist_voxel.obj",
		"oldLady": "res://assets/voxels/townsfolk/Old_lady_voxel.obj",
		"oldWoman02": "res://assets/voxels/townsfolk/OldWoman02_voxel.obj",
		"adultMan06": "res://assets/voxels/townsfolk/AdultMan06_voxel.obj",
		"dog": "res://assets/voxels/misc/Dog_voxel.obj",
		"blackCat": "res://assets/voxels/misc/CatBlack_voxel.obj",
		"whiteCat": "res://assets/voxels/misc/CatWhite_voxel.obj",
		"ghostCostume": "res://assets/voxels/misc/Ghost_costume_voxel.obj",
		"horseCostume": "res://assets/voxels/misc/Horse_costume_voxel.obj",
		"scifiHero": "res://assets/voxels/misc/ScifiHero_voxel.obj",
	}
	return map.get(id, "")
