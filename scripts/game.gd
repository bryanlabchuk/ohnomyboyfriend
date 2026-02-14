extends Node3D
## Main game: roll dice (earn research), buy tubes, open tubes (dice + characters spill).

@onready var tray: Tray = $Tray
@onready var dice_cup: DiceCup = $DiceCup
@onready var dice_container: Node3D = $DiceContainer
@onready var content_container: Node3D = $ContentContainer
@onready var roll_button: Button = $CanvasLayer/UIControl/RollButton
@onready var reset_button: Button = $CanvasLayer/UIControl/ResetButton
@onready var research_label: Label = $CanvasLayer/UIControl/ResearchLabel
@onready var tube_shop_btn: Button = $CanvasLayer/UIControl/TubeShopBtn
@onready var open_tube_btn: Button = $CanvasLayer/UIControl/OpenTubeBtn
@onready var tube_count_label: Label = $CanvasLayer/UIControl/TubeCountLabel
@onready var shop_panel: PanelContainer = $CanvasLayer/ShopPanel
@onready var shop_close_btn: Button = $CanvasLayer/ShopPanel/MarginContainer/VBox/CloseBtn
@onready var shop_tubes_container: GridContainer = $CanvasLayer/ShopPanel/MarginContainer/VBox/TubesGrid

@export var dice_scene: PackedScene
@export var voxel_character_scene: PackedScene
@export var default_dice_count: int = 5
@export var dice_types: Array[int] = [6, 6, 6, 8, 20]

var _dice: Array[Dice] = []
var _dice_in_cup: Array[Dice] = []
var _pending_research: int = 0
var _shop_tube_buttons: Array[Button] = []


func _ready() -> void:
	if dice_scene == null:
		dice_scene = preload("res://scenes/dice/dice.tscn")
	if voxel_character_scene == null:
		voxel_character_scene = preload("res://scenes/characters/voxel_character.tscn")

	if dice_cup:
		dice_cup.pour_started.connect(_on_pour_started)
	if roll_button:
		roll_button.pressed.connect(_on_roll_pressed)
	if tube_shop_btn:
		tube_shop_btn.pressed.connect(_open_shop)
	if open_tube_btn:
		open_tube_btn.pressed.connect(_open_selected_tube)
	if shop_close_btn:
		shop_close_btn.pressed.connect(_close_shop)
	if reset_button:
		reset_button.pressed.connect(_reset_roll)

	_spawn_dice_in_cup()
	_update_ui()
	if shop_panel:
		shop_panel.visible = false


func _on_roll_pressed() -> void:
	if not dice_cup:
		return
	dice_cup.start_pour(1.0)
	await get_tree().create_timer(0.3).timeout
	_release_dice_from_cup()
	await get_tree().create_timer(0.5).timeout
	dice_cup.stop_pour()
	dice_cup.reset()


func _on_pour_started() -> void:
	_release_dice_from_cup()


func _spawn_dice_in_cup() -> void:
	_clear_dice()
	if not dice_cup or not dice_container or not dice_scene:
		return
	for i in default_dice_count:
		var die: Dice = dice_scene.instantiate() as Dice
		if die == null:
			continue
		die.dice_type = dice_types[i % dice_types.size()]
		die.dice_size = 0.06
		die.freeze = true
		die.position = dice_cup.position + Vector3(
			randf_range(-0.02, 0.02),
			0.04 + i * 0.015,
			randf_range(-0.02, 0.02)
		)
		dice_container.add_child(die)
		_dice.append(die)
		_dice_in_cup.append(die)
		die.dice_settled.connect(_on_dice_settled)


func _release_dice_from_cup() -> void:
	for die in _dice_in_cup:
		die.freeze = false
		die.roll(1.5, Vector3(randf_range(-0.3, 0.3), -0.8, randf_range(-0.3, 0.3)))
	_dice_in_cup.clear()


func _on_dice_settled(d: Dice, value: int) -> void:
	_pending_research += value
	_update_ui()


func _apply_pending_research() -> void:
	if _pending_research > 0:
		GameState.research += _pending_research
		_pending_research = 0
		_update_ui()


func _clear_dice() -> void:
	for die in _dice:
		if is_instance_valid(die):
			die.queue_free()
	_dice.clear()
	_dice_in_cup.clear()
	# Clear voxel characters and other tray content
	if content_container:
		for c in content_container.get_children():
			if is_instance_valid(c):
				c.queue_free()


func _update_ui() -> void:
	var total_pending := _pending_research
	for d in _dice:
		if is_instance_valid(d) and d.linear_velocity.length() > 0.01:
			total_pending += d.get_top_value()  # rough
	if research_label:
		research_label.text = "Research: %d" % (GameState.research + total_pending)
	if tube_count_label:
		tube_count_label.text = "Tubes: %d | Allies: %d" % [GameState.tubes.size(), GameState.allies.size()]
	if open_tube_btn:
		open_tube_btn.disabled = GameState.tubes.is_empty()
	# When all settled, apply research
	var all_settled := true
	for d in _dice:
		if is_instance_valid(d) and (d.linear_velocity.length() > 0.1 or d.angular_velocity.length() > 0.1):
			all_settled = false
			break
	if all_settled and _pending_research > 0:
		_apply_pending_research()


func _physics_process(_delta: float) -> void:
	_update_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_roll_pressed()
	if event.is_action_pressed("ui_cancel"):
		if shop_panel and shop_panel.visible:
			_close_shop()
		else:
			_reset_roll()


func _reset_roll() -> void:
	_apply_pending_research()
	_clear_dice()
	if dice_cup:
		dice_cup.reset()
	_spawn_dice_in_cup()
	_update_ui()


func _open_shop() -> void:
	if not shop_panel:
		return
	shop_panel.visible = true
	_populate_shop()


func _close_shop() -> void:
	if shop_panel:
		shop_panel.visible = false


func _populate_shop() -> void:
	if not shop_tubes_container:
		return
	for c in shop_tubes_container.get_children():
		c.queue_free()
	_shop_tube_buttons.clear()

	var rarities := ["common", "uncommon", "rare"]
	for r in rarities:
		var cost := GameState.TUBE_COSTS.get(r, 99)
		var can_afford := GameState.can_buy_tube(r)
		var btn := Button.new()
		btn.text = "%s Tube - %d" % [r.left(1).to_upper() + r.substr(1), cost]
		btn.disabled = not can_afford
		btn.pressed.connect(_on_buy_tube.bind(r))
		shop_tubes_container.add_child(btn)


func _on_buy_tube(rarity: String) -> void:
	if GameState.buy_tube(rarity):
		_populate_shop()
		_update_ui()


func _open_selected_tube() -> void:
	if GameState.tubes.is_empty():
		return
	var tube := GameState.open_tube(0)
	if tube.is_empty():
		return
	_spill_tube_contents(tube.get("contents", []))
	_update_ui()


func _spill_tube_contents(contents: Array) -> void:
	var container := content_container if content_container else dice_container
	if not container:
		return
	# Spawn dice from tube
	var dice_scn = dice_scene
	for item in contents:
		if item is Dictionary:
			if item.get("type") == "dice":
				var sides: int = int(item.get("sides", 6))
				var die: Dice = dice_scn.instantiate() as Dice
				if die:
					die.dice_type = sides
					die.dice_size = 0.05
					die.position = tray.position + Vector3(randf_range(-0.15, 0.15), 0.15, randf_range(-0.1, 0.1))
					container.add_child(die)
					die.roll(0.8, Vector3(randf_range(-0.2, 0.2), -0.5, randf_range(-0.2, 0.2)))
					_dice.append(die)
					die.dice_settled.connect(_on_dice_settled)
			elif item.get("type") == "character":
				var char_id := item.get("id", "")
				var voxel_path := item.get("voxel", "")
				var name_str := item.get("name", "Ally")
				if GameState.allies.size() < GameState.MAX_ALLIES:
					GameState.add_ally(char_id, name_str, voxel_path)
				# Spawn voxel on tray
				var vc = voxel_character_scene.instantiate()
				if vc:
					vc.set("voxel_mesh_path", voxel_path)
					vc.position = tray.position + Vector3(randf_range(-0.1, 0.1), 0.08, randf_range(-0.08, 0.08))
					vc.rotation.y = randf() * TAU
					container.add_child(vc)
