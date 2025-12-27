extends Control

@onready var credits_label: Label = $MarginContainer/VBoxContainer/HUD/CreditsLabel
@onready var fuel_label: Label = $MarginContainer/VBoxContainer/HUD/FuelLabel
@onready var cargo_label: Label = $MarginContainer/VBoxContainer/HUD/CargoLabel
@onready var day_label: Label = $MarginContainer/VBoxContainer/HUD/DayLabel
@onready var location_label: Label = $MarginContainer/VBoxContainer/HUD/LocationLabel

@onready var planet_list: ItemList = $MarginContainer/VBoxContainer/MainContent/LeftPanel/PlanetList
@onready var planet_name: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/PlanetName
@onready var planet_description: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/PlanetDescription
@onready var distance_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/TravelInfo/DistanceLabel
@onready var fuel_cost_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/TravelInfo/FuelCostLabel
@onready var travel_time_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/TravelInfo/TravelTimeLabel
@onready var travel_button: Button = $MarginContainer/VBoxContainer/MainContent/RightPanel/ButtonRow/TravelButton
@onready var message_label: Label = $MarginContainer/VBoxContainer/MessageLabel

var selected_planet_id: String = ""
var planet_ids: Array = []

func _ready() -> void:
	_populate_planet_list()
	_update_hud()
	_clear_selection()

func _populate_planet_list() -> void:
	planet_list.clear()
	planet_ids.clear()

	var current_planet := DataRepo.get_planet(GameState.player.current_planet)

	for planet in DataRepo.get_all_planets():
		var display_text: String = planet.planet_name
		if planet.id == GameState.player.current_planet:
			display_text += " (Current)"
		else:
			var distance := current_planet.get_distance_to(planet.id)
			display_text += " [%d days]" % distance

		planet_list.add_item(display_text)
		planet_ids.append(planet.id)

func _update_hud() -> void:
	var player := GameState.player
	var current := DataRepo.get_planet(player.current_planet)

	credits_label.text = "Credits: %s" % _format_number(player.credits)
	fuel_label.text = "Fuel: %d/%d" % [player.fuel, player.ship.fuel_capacity]
	cargo_label.text = "Cargo: %d/%d" % [player.get_cargo_space_used(), player.ship.cargo_capacity]
	day_label.text = "Day: %d" % player.day
	location_label.text = "Location: %s" % current.planet_name

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
"MEEROPA"
func _clear_selection() -> void:
	selected_planet_id = ""
	planet_name.text = "Select a Destination"
	planet_description.text = "Choose a planet from the list to see details."
	distance_label.text = "Distance: --"
	fuel_cost_label.text = "Fuel Cost: --"
	travel_time_label.text = "Travel Time: -- days"
	travel_button.disabled = true

func _on_planet_selected(index: int) -> void:
	if index < 0 or index >= planet_ids.size():
		_clear_selection()
		return

	selected_planet_id = planet_ids[index]
	var planet := DataRepo.get_planet(selected_planet_id)
	var current := DataRepo.get_planet(GameState.player.current_planet)

	planet_name.text = planet.planet_name
	planet_description.text = planet.description

	if selected_planet_id == GameState.player.current_planet:
		distance_label.text = "Distance: You are here"
		fuel_cost_label.text = "Fuel Cost: --"
		travel_time_label.text = "Travel Time: --"
		travel_button.disabled = true
	else:
		var distance := current.get_distance_to(selected_planet_id)
		var fuel_cost := GameState.player.ship.get_fuel_cost(distance)

		distance_label.text = "Distance: %d light years" % distance
		fuel_cost_label.text = "Fuel Cost: %d fuel" % fuel_cost
		travel_time_label.text = "Travel Time: %d days" % distance

		# Check if player can afford the trip
		if GameState.player.fuel >= fuel_cost:
			travel_button.disabled = false
			fuel_cost_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		else:
			travel_button.disabled = true
			fuel_cost_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

func _on_travel_pressed() -> void:
	if selected_planet_id.is_empty():
		return

	var result := GameState.travel_to(selected_planet_id)

	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.8, 0.4))

		# Check for event
		if result["event"] != null:
			get_tree().change_scene_to_file("res://scenes/travel_event.tscn")
			return

		# Check game over conditions
		var game_over := GameState.check_game_over()
		if game_over["game_over"]:
			get_tree().change_scene_to_file("res://scenes/game_over.tscn")
			return

		# Refresh UI
		_populate_planet_list()
		_update_hud()
		_clear_selection()
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))

func _on_market_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/market.tscn")

func _on_shipyard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/shipyard.tscn")

func _on_save_pressed() -> void:
	if GameState.save_game():
		_show_message("Game saved!", Color(0.4, 0.8, 0.4))
	else:
		_show_message("Failed to save game", Color(0.9, 0.3, 0.3))

func _show_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)

	# Auto-clear message after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if message_label.text == text:
		message_label.text = ""
