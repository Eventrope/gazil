extends Control

const BASE_FUEL_PRICE := 5

@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var ship_title: Label = $MarginContainer/VBoxContainer/ContentContainer/ShipStats/ShipTitle
@onready var cargo_stat: Label = $MarginContainer/VBoxContainer/ContentContainer/ShipStats/StatsContainer/CargoStat
@onready var fuel_cap_stat: Label = $MarginContainer/VBoxContainer/ContentContainer/ShipStats/StatsContainer/FuelCapStat
@onready var efficiency_stat: Label = $MarginContainer/VBoxContainer/ContentContainer/ShipStats/StatsContainer/EfficiencyStat
@onready var installed_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/ShipStats/InstalledList
@onready var upgrade_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/UpgradesPanel/ScrollContainer/UpgradeList
@onready var message_label: Label = $MarginContainer/VBoxContainer/Footer/MessageLabel
@onready var refuel_button: Button = $MarginContainer/VBoxContainer/Footer/RefuelButton

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var player := GameState.player
	var ship := player.ship

	credits_label.text = "Credits: %s" % _format_number(player.credits)

	ship_title.text = "Your Ship: %s" % ship.ship_name
	cargo_stat.text = "Cargo Capacity: %d tonnes" % ship.cargo_tonnes
	fuel_cap_stat.text = "Fuel Tank: %d (Current: %d)" % [ship.fuel_tank, player.fuel]
	efficiency_stat.text = "Fuel Burn: %.1f per distance" % ship.fuel_burn_per_distance

	_update_installed_list()
	_update_upgrade_list()
	_update_refuel_button()

func _update_installed_list() -> void:
	for child in installed_list.get_children():
		child.queue_free()

	var ship := GameState.player.ship
	if ship.upgrades_installed.is_empty():
		var none_label := Label.new()
		none_label.text = "  (None)"
		none_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		installed_list.add_child(none_label)
	else:
		for upgrade_id in ship.upgrades_installed:
			var upgrade := DataRepo.get_upgrade(upgrade_id)
			var label := Label.new()
			label.text = "  - %s" % upgrade.get("name", upgrade_id)
			label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
			installed_list.add_child(label)

func _update_upgrade_list() -> void:
	for child in upgrade_list.get_children():
		child.queue_free()

	var available := DataRepo.get_available_upgrades(GameState.player)

	if available.is_empty():
		var none_label := Label.new()
		none_label.text = "No upgrades available"
		none_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		upgrade_list.add_child(none_label)
	else:
		for upgrade in available:
			var row := _create_upgrade_row(upgrade)
			upgrade_list.add_child(row)

func _create_upgrade_row(upgrade: Dictionary) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)

	var name_label := Label.new()
	name_label.text = upgrade.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var cost: int = upgrade.get("cost", 0)
	var cost_label := Label.new()
	cost_label.text = "%s cr" % _format_number(cost)
	cost_label.add_theme_font_size_override("font_size", 18)
	if GameState.player.credits >= cost:
		cost_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	else:
		cost_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	header.add_child(cost_label)

	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(80, 35)
	buy_btn.disabled = GameState.player.credits < cost
	buy_btn.pressed.connect(_on_upgrade_pressed.bind(upgrade["id"]))
	header.add_child(buy_btn)

	container.add_child(header)

	var desc_label := Label.new()
	desc_label.text = upgrade.get("description", "")
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	container.add_child(desc_label)

	var separator := HSeparator.new()
	container.add_child(separator)

	return container

func _get_fuel_price() -> int:
	return GameState.get_fuel_price_at(GameState.player.current_planet)

func _update_refuel_button() -> void:
	var player := GameState.player
	var needed := player.ship.fuel_tank - player.fuel
	var fuel_price := _get_fuel_price()
	if needed <= 0:
		refuel_button.text = "Tank Full"
		refuel_button.disabled = true
	else:
		var cost := needed * fuel_price
		refuel_button.text = "Refuel +%d (%d cr @ %d cr/unit)" % [needed, cost, fuel_price]
		refuel_button.disabled = player.credits < fuel_price

func _on_upgrade_pressed(upgrade_id: String) -> void:
	var result := GameState.buy_upgrade(upgrade_id)
	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.8, 0.4))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_display()

func _on_refuel_pressed() -> void:
	var player := GameState.player
	var needed := player.ship.fuel_tank - player.fuel
	var fuel_price := _get_fuel_price()

	if needed <= 0:
		_show_message("Tank is already full!", Color(0.9, 0.7, 0.2))
		return

	# Calculate how much fuel we can afford
	var affordable: int = player.credits / fuel_price
	var to_buy: int = min(needed, affordable)

	if to_buy <= 0:
		_show_message("Not enough credits!", Color(0.9, 0.3, 0.3))
		return

	var cost: int = to_buy * fuel_price
	player.spend_credits(cost)
	player.add_fuel(to_buy)

	_show_message("Bought %d fuel for %d credits" % [to_buy, cost], Color(0.4, 0.8, 0.4))
	_update_display()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")

func _show_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)

func _format_number(num: int) -> String:
	var str_num := str(num)
	var result := ""
	var count := 0
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	return result
