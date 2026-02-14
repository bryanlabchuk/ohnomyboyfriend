extends Node
## Global game state - research, tubes, allies. Mirrors onmbih browser game flow.

var research: int = 20  # Start with enough to buy a tube
var tubes: Array[Dictionary] = []  # [{rarity, contents: [...]}]
var allies: Array[Dictionary] = []  # [{id, name, voxel_mesh}]
const MAX_ALLIES := 5

# Tube config (from onmbih TUBE_RARITIES)
const TUBE_COSTS := {
	"common": 15,
	"uncommon": 30,
	"rare": 60,
	"epic": 100,
	"legendary": 200
}

# Character tube drops: townsfolkId -> voxel path
const CHARACTER_VOXELS := {
	"waitress": "res://assets/voxels/townsfolk/Waitress_voxel.obj",
	"cook": "res://assets/voxels/townsfolk/Cook_voxel.obj",
	"teenBoy02": "res://assets/voxels/townsfolk/TeenBoy02_voxel.obj",
	"teenGirl01": "res://assets/voxels/townsfolk/TeenGirl01_voxel.obj",
	"stonerTeenBoy": "res://assets/voxels/townsfolk/StonerTeenBoy_voxel.obj",
	"adultMan08": "res://assets/voxels/townsfolk/AdultMan08_voxel.obj",
	"dog": "res://assets/voxels/misc/Dog_voxel.obj",
	"ghostCostume": "res://assets/voxels/misc/Ghost_costume_voxel.obj",
	"historyTeacher": "res://assets/voxels/townsfolk/HistoryTeacher_voxel.obj",
	"oldMan": "res://assets/voxels/townsfolk/OldMan_voxel.obj",
	"businesswoman": "res://assets/voxels/townsfolk/Businesswoman_voxel.obj",
	"emoTeenGirl": "res://assets/voxels/townsfolk/EmoTeenGirl_voxel.obj",
	"blackCat": "res://assets/voxels/misc/CatBlack_voxel.obj",
	"scientist": "res://assets/voxels/townsfolk/Scientist_voxel.obj",
	"oldLady": "res://assets/voxels/townsfolk/Old_lady_voxel.obj",
	"oldWoman02": "res://assets/voxels/townsfolk/OldWoman02_voxel.obj",
	"adultMan06": "res://assets/voxels/townsfolk/AdultMan06_voxel.obj",
	"scifiHero": "res://assets/voxels/misc/ScifiHero_voxel.obj",
}

const CHARACTER_NAMES := {
	"waitress": "Donna Torrance",
	"cook": "Big Mike Garfield",
	"teenBoy02": "Marcus Chen",
	"teenGirl01": "Sarah Palmer",
	"stonerTeenBoy": "Chad Dunwich",
	"adultMan08": "Deputy Barnes",
	"dog": "Cujo Jr.",
	"ghostCostume": "Kenny Peterson",
	"historyTeacher": "Ms. Abigail Crane",
	"oldMan": "Ezra Whateley",
	"businesswoman": "Victoria Ashford",
	"emoTeenGirl": "Raven Blackwood",
	"blackCat": "Salem",
	"scientist": "Dr. Eleanor Marsh",
	"oldLady": "Nana Ruth",
	"oldWoman02": "Agnes Willow",
	"adultMan06": "Dr. Herbert West",
	"scifiHero": "Captain Nova",
}

# Rarity -> possible character IDs
const RARITY_CHARACTERS := {
	"common": ["waitress", "cook", "teenBoy02", "teenGirl01", "stonerTeenBoy", "adultMan08", "dog", "ghostCostume"],
	"uncommon": ["historyTeacher", "oldMan", "businesswoman", "emoTeenGirl", "blackCat"],
	"rare": ["scientist", "oldLady"],
	"epic": ["scientist", "oldLady"],
	"legendary": ["oldWoman02", "adultMan06", "scifiHero"]
}


func can_buy_tube(rarity: String) -> bool:
	return research >= TUBE_COSTS.get(rarity, 999)


func buy_tube(rarity: String) -> bool:
	var cost: int = int(TUBE_COSTS.get(rarity, 999))
	if research < cost:
		return false
	research -= cost
	var contents := _generate_tube_contents(rarity)
	tubes.append({"rarity": rarity, "contents": contents})
	return true


func _generate_tube_contents(rarity: String) -> Array:
	var contents: Array = []
	# 1-2 dice + 0-1 character
	var num_dice := randi_range(1, 2)
	var num_chars := randi_range(0, 1) if randf() > 0.5 else 0
	
	for i in num_dice:
		var sides: int = int([6, 6, 6, 8, 20][randi() % 5])
		contents.append({"type": "dice", "sides": sides})
	
	if num_chars > 0:
		var pool: Array = RARITY_CHARACTERS.get(rarity, RARITY_CHARACTERS.common)
		pool = pool + RARITY_CHARACTERS.common if pool.is_empty() else pool
		var char_id: String = str(pool[randi() % pool.size()])
		if CHARACTER_VOXELS.has(char_id) and allies.size() < MAX_ALLIES:
			contents.append({"type": "character", "id": char_id, "name": CHARACTER_NAMES.get(char_id, char_id), "voxel": CHARACTER_VOXELS[char_id]})
	
	return contents


func open_tube(index: int) -> Dictionary:
	if index < 0 or index >= tubes.size():
		return {}
	var tube := tubes[index]
	tubes.remove_at(index)
	return tube


func add_ally(char_id: String, name_str: String, voxel_path: String) -> void:
	if allies.size() >= MAX_ALLIES:
		return
	allies.append({"id": char_id, "name": name_str, "voxel": voxel_path})
