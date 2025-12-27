extends Control

@onready var ship_button_container: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/ShipListPanel/ScrollContainer/ShipButtonContainer
@onready var ship_name_label: Label = $MarginContainer/VBoxContainer/ContentContainer/ShipDetailsPanel/ShipNameLabel
@onready var ship_description_label: Label = $MarginContainer/VBoxContainer/ContentContainer/ShipDetailsPanel/ShipDescriptionLabel
@onready var stats_grid: GridContainer = $MarginContainer/VBoxContainer/ContentContainer/ShipDetailsPanel/StatsGrid
@onready var trait_name_label: Label = $MarginContainer/VBoxContainer/ContentContainer/ShipDetailsPanel/TraitContainer/TraitNameLabel
@onready var trait_desc_label: Label = $MarginContainer/VBoxContainer/ContentContainer/ShipDetailsPanel/TraitContainer/TraitDescLabel
@onready var select_button: Button = $MarginContainer/VBoxContainer/Footer/SelectButton

var starter_ships: Array[Ship] = []
var selected_ship: Ship = null
var ship_buttons: Array[Button] = []

func _ready() -> void:
	starter_ships = DataRepo.get_starter_ships()
	_populate_ship_list()
	_clear_selection()

func _populate_ship_list() -> void:
	for child in ship_button_container.get_children():
		child.queue_free()
	ship_buttons.clear()

	for ship in starter_ships:
		var btn := Button.new()
		btn.text = ship.ship_name
		btn.custom_minimum_size = Vector2(240, 50)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_ship_button_pressed.bind(ship))
		ship_button_container.add_child(btn)
		ship_buttons.append(btn)

func _clear_selection() -> void:
	selected_ship = null
	ship_name_label.text = "Select a Ship"
	ship_description_label.text = "Click on a ship to see its details."
	trait_name_label.text = ""
	trait_desc_label.text = ""
	select_button.disabled = true

	# Clear stats grid
	for child in stats_grid.get_children():
		child.queue_free()

	# Reset button styles
	for btn in ship_buttons:
		btn.remove_theme_color_override("font_color")

func _on_ship_button_pressed(ship: Ship) -> void:
	selected_ship = ship
	_display_ship_details(ship)
	select_button.disabled = false

	# Highlight selected button
	for i in range(ship_buttons.size()):
		if starter_ships[i].id == ship.id:
			ship_buttons[i].add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		else:
			ship_buttons[i].remove_theme_color_override("font_color")

func _display_ship_details(ship: Ship) -> void:
	ship_name_label.text = ship.ship_name
	ship_description_label.text = ship.description

	# Clear and populate stats grid
	for child in stats_grid.get_children():
		child.queue_free()

	_add_stat("Cargo Capacity", "%d tonnes" % ship.cargo_tonnes)
	if ship.passenger_berths > 0:
		_add_stat("Passenger Berths", str(ship.passenger_berths))
	_add_stat("Speed", "%d units/day" % ship.speed)
	_add_stat("Fuel Tank", str(ship.fuel_tank))
	_add_stat("Fuel Burn", "%.1f per distance" % ship.fuel_burn_per_distance)
	_add_stat("Min Crew", str(ship.min_crew))
	_add_stat("Crew Quality", "%d / 5" % ship.crew_quality)
	_add_stat("Reliability", "%d%%" % ship.reliability)
	if ship.automation_level > 0:
		_add_stat("Automation", "Level %d" % ship.automation_level)
	_add_stat("Module Slots", str(ship.module_slots_total))

	# Display trait
	var trait_data := DataRepo.get_ship_trait(ship.trait_id)
	if not trait_data.is_empty():
		trait_name_label.text = "Trait: %s" % trait_data.get("name", ship.trait_id)
		trait_desc_label.text = trait_data.get("description", "")
	else:
		trait_name_label.text = ""
		trait_desc_label.text = ""

func _add_stat(stat_name: String, value: String) -> void:
	var name_label := Label.new()
	name_label.text = stat_name + ":"
	name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	name_label.add_theme_font_size_override("font_size", 16)
	stats_grid.add_child(name_label)

	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 16)
	stats_grid.add_child(value_label)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_select_pressed() -> void:
	if selected_ship == null:
		return
	GameState.finalize_new_game(selected_ship.id)
	get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")
