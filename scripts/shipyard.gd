extends Control

# Upgrade categories with their upgrade chains
const UPGRADE_TREES := {
	"cargo": {
		"title": "CARGO BAY",
		"icon": "[C]",
		"color": Color(0.4, 0.7, 0.9),
		"upgrades": ["cargo_expansion_1", "cargo_expansion_2"]
	},
	"fuel": {
		"title": "FUEL SYSTEM",
		"icon": "[F]",
		"color": Color(0.9, 0.7, 0.3),
		"upgrades": ["fuel_tank_1", "fuel_tank_2"]
	},
	"engine": {
		"title": "ENGINE",
		"icon": "[E]",
		"color": Color(0.5, 0.9, 0.5),
		"upgrades": ["efficient_engine"]
	}
}

@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var ship_name_label: Label = $MarginContainer/VBoxContainer/Header/ShipNameLabel
@onready var cargo_stat: Label = $MarginContainer/VBoxContainer/StatsBar/CargoStat
@onready var fuel_stat: Label = $MarginContainer/VBoxContainer/StatsBar/FuelStat
@onready var burn_stat: Label = $MarginContainer/VBoxContainer/StatsBar/BurnStat
@onready var reliability_stat: Label = $MarginContainer/VBoxContainer/StatsBar/ReliabilityStat
@onready var repair_button: Button = $MarginContainer/VBoxContainer/StatsBar/RepairButton
@onready var refuel_button: Button = $MarginContainer/VBoxContainer/StatsBar/RefuelButton
@onready var cargo_tree: VBoxContainer = $MarginContainer/VBoxContainer/UpgradeTreeContainer/CargoPanel/CargoTree
@onready var fuel_tree: VBoxContainer = $MarginContainer/VBoxContainer/UpgradeTreeContainer/FuelPanel/FuelTree
@onready var engine_tree: VBoxContainer = $MarginContainer/VBoxContainer/UpgradeTreeContainer/EnginePanel/EngineTree
@onready var message_label: Label = $MarginContainer/VBoxContainer/Footer/MessageLabel

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var player := GameState.player
	var ship := player.ship

	credits_label.text = "Credits: %s" % _format_number(player.credits)
	ship_name_label.text = ship.ship_name

	cargo_stat.text = "Cargo: %dt" % ship.cargo_tonnes
	fuel_stat.text = "Fuel: %d/%d" % [player.fuel, ship.fuel_tank]
	burn_stat.text = "Burn: %.1f/ly" % ship.fuel_burn_per_distance

	# Update reliability display
	var reliability_pct := int(float(ship.current_reliability) / float(ship.reliability) * 100)
	reliability_stat.text = "Reliability: %d%%" % reliability_pct
	if reliability_pct >= 70:
		reliability_stat.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif reliability_pct >= 40:
		reliability_stat.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	else:
		reliability_stat.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	_build_upgrade_tree(cargo_tree, UPGRADE_TREES["cargo"])
	_build_upgrade_tree(fuel_tree, UPGRADE_TREES["fuel"])
	_build_upgrade_tree(engine_tree, UPGRADE_TREES["engine"])
	_update_repair_button()
	_update_refuel_button()

func _build_upgrade_tree(container: VBoxContainer, tree_data: Dictionary) -> void:
	for child in container.get_children():
		child.queue_free()

	var ship := GameState.player.ship
	var player := GameState.player

	# Header
	var header := Label.new()
	header.text = tree_data["title"]
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", tree_data["color"])
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(header)

	var sep := HSeparator.new()
	container.add_child(sep)

	# Base level (always owned)
	var base_node := _create_upgrade_node("Stock", "Base equipment", 0, "installed", tree_data["color"])
	container.add_child(base_node)

	# Upgrade chain
	var upgrade_ids: Array = tree_data["upgrades"]
	for i in range(upgrade_ids.size()):
		var upgrade_id: String = upgrade_ids[i]
		var upgrade := DataRepo.get_upgrade(upgrade_id)
		if upgrade.is_empty():
			continue

		# Arrow connector
		var arrow := Label.new()
		arrow.text = "|"
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		container.add_child(arrow)

		# Determine state
		var state := "locked"
		if ship.has_upgrade(upgrade_id):
			state = "installed"
		else:
			# Check if available (prereqs met)
			var prereqs: Array = upgrade.get("requires", [])
			var has_prereqs := true
			for prereq in prereqs:
				if not ship.has_upgrade(prereq):
					has_prereqs = false
					break
			if has_prereqs:
				if player.credits >= upgrade.get("cost", 0):
					state = "available"
				else:
					state = "too_expensive"

		var effect_text := _get_effect_text(upgrade)
		var node := _create_upgrade_node(
			upgrade.get("name", "Unknown"),
			effect_text,
			upgrade.get("cost", 0),
			state,
			tree_data["color"],
			upgrade_id
		)
		container.add_child(node)

func _create_upgrade_node(title: String, effect: String, cost: int, state: String, accent_color: Color, upgrade_id: String = "") -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", 4)

	# Status indicator + Title row
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)

	var status := Label.new()
	status.add_theme_font_size_override("font_size", 16)

	match state:
		"installed":
			status.text = "[OK]"
			status.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		"available":
			status.text = "[+]"
			status.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
		"too_expensive":
			status.text = "[$]"
			status.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3))
		"locked":
			status.text = "[X]"
			status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	title_row.add_child(status)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	match state:
		"installed":
			title_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		"available":
			title_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		"too_expensive":
			title_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		"locked":
			title_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	title_row.add_child(title_label)
	node.add_child(title_row)

	# Effect text
	var effect_label := Label.new()
	effect_label.text = effect
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.add_theme_color_override("font_color", accent_color.lerp(Color.WHITE, 0.3))
	node.add_child(effect_label)

	# Cost / Status row
	if state == "installed":
		var installed_label := Label.new()
		installed_label.text = "INSTALLED"
		installed_label.add_theme_font_size_override("font_size", 12)
		installed_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		node.add_child(installed_label)
	elif state != "locked" or cost > 0:
		var action_row := HBoxContainer.new()
		action_row.add_theme_constant_override("separation", 10)

		if cost > 0:
			var cost_label := Label.new()
			cost_label.text = "%s cr" % _format_number(cost)
			cost_label.add_theme_font_size_override("font_size", 14)
			if state == "too_expensive":
				cost_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			elif state == "available":
				cost_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			else:
				cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			action_row.add_child(cost_label)

		if state == "available" and upgrade_id != "":
			var buy_btn := Button.new()
			buy_btn.text = "BUY"
			buy_btn.custom_minimum_size = Vector2(60, 28)
			buy_btn.add_theme_font_size_override("font_size", 12)
			buy_btn.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
			action_row.add_child(buy_btn)
		elif state == "locked":
			var locked_label := Label.new()
			locked_label.text = "(Requires previous)"
			locked_label.add_theme_font_size_override("font_size", 12)
			locked_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			action_row.add_child(locked_label)

		node.add_child(action_row)

	return node

func _get_effect_text(upgrade: Dictionary) -> String:
	var effects: Dictionary = upgrade.get("effects", {})
	var parts: Array[String] = []

	if effects.has("cargo_tonnes"):
		parts.append("+%d tonnes" % int(effects["cargo_tonnes"]))
	if effects.has("fuel_tank"):
		parts.append("+%d fuel" % int(effects["fuel_tank"]))
	if effects.has("fuel_burn_modifier"):
		var reduction := int((1.0 - float(effects["fuel_burn_modifier"])) * 100)
		parts.append("-%d%% fuel use" % reduction)

	if parts.is_empty():
		return upgrade.get("description", "")
	return ", ".join(parts)

func _get_fuel_price() -> int:
	return GameState.get_fuel_price_at(GameState.player.current_planet)

func _update_repair_button() -> void:
	var player := GameState.player
	var ship := player.ship
	var damage := ship.reliability - ship.current_reliability
	var cost_per_point := ship.get_repair_cost_per_point()

	if damage <= 0:
		repair_button.text = "Fully Repaired"
		repair_button.disabled = true
	else:
		var cost := damage * cost_per_point
		repair_button.text = "Repair %d pts (%d cr)" % [damage, cost]
		repair_button.disabled = player.credits < cost_per_point

func _update_refuel_button() -> void:
	var player := GameState.player
	var needed := player.ship.fuel_tank - player.fuel
	var fuel_price := _get_fuel_price()

	if needed <= 0:
		refuel_button.text = "Tank Full"
		refuel_button.disabled = true
	else:
		var cost := needed * fuel_price
		refuel_button.text = "Refuel +%d (%d cr)" % [needed, cost]
		refuel_button.disabled = player.credits < fuel_price

func _on_upgrade_pressed(upgrade_id: String) -> void:
	var result := GameState.buy_upgrade(upgrade_id)
	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.9, 0.4))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_display()

func _on_repair_pressed() -> void:
	var player := GameState.player
	var ship := player.ship
	var damage := ship.reliability - ship.current_reliability

	if damage <= 0:
		_show_message("Ship is already fully repaired!", Color(0.9, 0.7, 0.2))
		return

	var result := GameState.repair_ship(damage)
	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.9, 0.4))
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

	var affordable: int = player.credits / fuel_price
	var to_buy: int = min(needed, affordable)

	if to_buy <= 0:
		_show_message("Not enough credits!", Color(0.9, 0.3, 0.3))
		return

	var cost: int = to_buy * fuel_price
	player.spend_credits(cost)
	player.add_fuel(to_buy)

	_show_message("Refueled +%d for %d credits" % [to_buy, cost], Color(0.4, 0.9, 0.4))
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
