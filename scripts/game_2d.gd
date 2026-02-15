extends Control
## Game with 3D viewport - dice roll, cup tilt, tube opening with voxel characters.

@onready var roll_btn: Button = $MainVBox/Margin/VBox/ButtonRow/RollButton
@onready var research_label: Label = $MainVBox/Margin/VBox/ResearchLabel
@onready var tube_shop_btn: Button = $MainVBox/Margin/VBox/ButtonRow/TubeShopBtn
@onready var open_tube_btn: Button = $MainVBox/Margin/VBox/TubeRow/OpenTubeBtn
@onready var tube_count_label: Label = $MainVBox/Margin/VBox/TubeRow/TubeCountLabel

var _game_3d: Node3D = null

func _ready() -> void:
	GameState.research = 20
	_game_3d = $MainVBox/ViewportContainer/SubViewport/Game3DContent as Node3D
	if roll_btn:
		roll_btn.pressed.connect(_on_roll)
	var reset_btn := $MainVBox/Margin/VBox/ButtonRow/ResetButton as Button
	if reset_btn:
		reset_btn.pressed.connect(_on_reset)
	if tube_shop_btn:
		tube_shop_btn.pressed.connect(_open_shop)
	if open_tube_btn:
		open_tube_btn.pressed.connect(_open_tube)
	_update_ui()

func _process(_delta: float) -> void:
	_update_ui()

func _on_roll() -> void:
	roll_btn.disabled = true
	roll_btn.text = "Rolling..."
	if _game_3d and _game_3d.has_method("roll_dice"):
		await _game_3d.roll_dice()
	roll_btn.disabled = false
	roll_btn.text = "Roll Dice"
	_update_ui()

func _on_reset() -> void:
	if _game_3d and _game_3d.has_method("reset_roll"):
		_game_3d.reset_roll()
	roll_btn.text = "Roll Dice"
	_update_ui()

func _update_ui() -> void:
	if research_label:
		research_label.text = "Research: %d" % GameState.research
	if tube_count_label:
		tube_count_label.text = "Tubes: %d | Allies: %d" % [GameState.tubes.size(), GameState.allies.size()]
	if open_tube_btn:
		open_tube_btn.disabled = GameState.tubes.is_empty()

func _open_shop() -> void:
	$MainVBox/Margin.visible = false
	var shop := _make_shop_panel()
	add_child(shop)

func _make_shop_panel() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.set_meta("shop_panel", true)
	
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.65)
	overlay.add_child(backdrop)
	
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 260)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	
	var title := Label.new()
	title.text = "Tube Shop"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	for r in ["common", "uncommon", "rare"]:
		var cost: int = int(GameState.TUBE_COSTS.get(r, 99))
		var btn := Button.new()
		btn.text = "%s Tube - %d research" % [r.capitalize(), cost]
		btn.disabled = not GameState.can_buy_tube(r)
		btn.set_meta("rarity", r)
		btn.pressed.connect(_on_buy_tube_clicked.bind(btn, overlay))
		vbox.add_child(btn)
	
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func():
		overlay.queue_free()
		$MainVBox/Margin.visible = true
	)
	vbox.add_child(close_btn)
	
	margin.add_child(vbox)
	panel.add_child(margin)
	center.add_child(panel)
	overlay.add_child(center)
	
	return overlay

func _on_buy_tube_clicked(btn: Button, overlay: Control) -> void:
	var rarity: String = str(btn.get_meta("rarity", "common"))
	if GameState.buy_tube(rarity):
		_update_ui()
		var vbox: VBoxContainer = overlay.get_child(1).get_child(0).get_child(0).get_child(0) as VBoxContainer
		if vbox:
			for c in vbox.get_children():
				if c is Button and c.has_meta("rarity"):
					var r: String = str(c.get_meta("rarity"))
					c.disabled = not GameState.can_buy_tube(r)

func _open_tube() -> void:
	if GameState.tubes.is_empty():
		return
	var tube := GameState.open_tube(0)
	var contents: Array = tube.get("contents", [])
	if _game_3d and _game_3d.has_method("spill_tube"):
		_game_3d.spill_tube(contents)
	_update_ui()
