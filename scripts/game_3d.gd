extends Node3D
## 3D game content - tray, cup, dice, voxel chars. Called by game_2d for roll/spill.

@onready var tray: Tray = $Tray
@onready var dice_cup: DiceCup = $DiceCup
@onready var dice_container: Node3D = $DiceContainer
@onready var content_container: Node3D = $ContentContainer
@onready var camera: Camera3D = $Camera3D

var _dice: Array[Dice] = []
var _dice_in_cup: Array[Dice] = []
var _dice_scene: PackedScene
var _voxel_scene: PackedScene
var _tube_scene: PackedScene

func _ready() -> void:
	if camera:
		camera.make_current()
	_dice_scene = preload("res://scenes/dice/dice.tscn")
	_voxel_scene = preload("res://scenes/characters/voxel_character.tscn")
	_tube_scene = preload("res://scenes/props/tube.tscn")
	if dice_cup:
		dice_cup.pour_started.connect(_on_pour_started)
	call_deferred("_spawn_dice_in_cup")

## Spawn dice in cup, tilt cup, release and roll
func roll_dice() -> void:
	if _dice.is_empty():
		_spawn_dice_in_cup()
	if dice_cup:
		dice_cup.start_pour(1.0)
	await get_tree().create_timer(0.25).timeout
	_release_dice_from_cup()
	await get_tree().create_timer(0.6).timeout
	if dice_cup:
		dice_cup.stop_pour()
		dice_cup.reset()

func _on_pour_started() -> void:
	_release_dice_from_cup()

func _spawn_dice_in_cup() -> void:
	_clear_dice()
	if not dice_cup or not dice_container or not _dice_scene:
		return
	var dice_colors: Array[Color] = [Color(0.98, 0.95, 0.9), Color(0.85, 0.9, 1.0), Color(1.0, 0.92, 0.85)]
	for i in 3:
		var die: Dice = _dice_scene.instantiate() as Dice
		if die:
			die.dice_type = 6
			die.dice_size = 0.07
			die.dice_color = dice_colors[i % dice_colors.size()]
			die.freeze = true
			die.position = dice_cup.global_position + Vector3(randf_range(-0.02, 0.02), 0.05 + i * 0.018, randf_range(-0.02, 0.02))
			dice_container.add_child(die)
			_dice.append(die)
			_dice_in_cup.append(die)
			die.dice_settled.connect(_on_dice_settled)

func _release_dice_from_cup() -> void:
	for die in _dice_in_cup:
		die.freeze = false
		die.roll(1.8, Vector3(randf_range(-0.35, 0.35), -0.9, randf_range(-0.35, 0.35)))
	_dice_in_cup.clear()

func _on_dice_settled(_d: Dice, value: int) -> void:
	GameState.research += value

func _clear_dice() -> void:
	for die in _dice:
		if is_instance_valid(die):
			die.queue_free()
	_dice.clear()
	_dice_in_cup.clear()
	if content_container:
		for c in content_container.get_children():
			if is_instance_valid(c):
				c.queue_free()

func reset_roll() -> void:
	_clear_dice()
	if dice_cup:
		dice_cup.reset()
	_spawn_dice_in_cup()

## Spill tube contents onto tray - dice and voxel characters
func spill_tube(contents: Array) -> void:
	var container: Node3D = content_container if content_container else dice_container
	if not container or not tray:
		return

	# Spawn tube prop above tray, tip it, then remove
	if _tube_scene:
		var tube: Tube = _tube_scene.instantiate() as Tube
		if tube:
			tube.position = tray.global_position + Vector3(0.08, 0.18, 0)
			tube.rotation.y = randf() * 0.4 - 0.2
			add_child(tube)
			tube.play_open_animation(0.5)
			get_tree().create_timer(1.2).timeout.connect(func():
				if is_instance_valid(tube):
					tube.queue_free()
			)

	# Spawn contents after tube tips (brief delay)
	await get_tree().create_timer(0.35).timeout

	for item in contents:
		if item is Dictionary:
			if item.get("type") == "dice":
				var sides: int = int(item.get("sides", 6))
				var die: Dice = _dice_scene.instantiate() as Dice
				if die:
					die.dice_type = sides
					die.dice_size = 0.06
					var hue := randf() * 0.1 - 0.05  # Slight color variation
					die.dice_color = Color(0.95 + hue, 0.93 + hue, 0.88 + hue, 1)
					die.position = tray.global_position + Vector3(randf_range(-0.2, 0.2), 0.2, randf_range(-0.15, 0.15))
					container.add_child(die)
					die.roll(1.0, Vector3(randf_range(-0.25, 0.25), -0.6, randf_range(-0.25, 0.25)))
					_dice.append(die)
					die.dice_settled.connect(_on_dice_settled)
			elif item.get("type") == "character":
				var char_id: String = str(item.get("id", ""))
				var voxel_path: String = str(item.get("voxel", ""))
				var name_str: String = str(item.get("name", "Ally"))
				if GameState.allies.size() < GameState.MAX_ALLIES:
					GameState.add_ally(char_id, name_str, voxel_path)
				var vc = _voxel_scene.instantiate()
				if vc:
					vc.set("voxel_mesh_path", voxel_path)
					vc.set("mesh_scale", 0.035)
					vc.position = tray.global_position + Vector3(randf_range(-0.15, 0.15), 0.12, randf_range(-0.12, 0.12))
					vc.rotation.y = randf() * TAU
					container.add_child(vc)
