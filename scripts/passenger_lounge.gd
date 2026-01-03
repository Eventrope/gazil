extends Control

@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var reputation_label: Label = $MarginContainer/VBoxContainer/Header/ReputationLabel
@onready var berths_label: Label = $MarginContainer/VBoxContainer/Header/BerthsLabel

@onready var available_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/AvailablePanel/VBoxContainer/ScrollContainer/AvailableList
@onready var accepted_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/AcceptedPanel/VBoxContainer/ScrollContainer/AcceptedList
@onready var message_label: Label = $MarginContainer/VBoxContainer/Footer/MessageLabel

func _ready() -> void:
	# Generate contracts if we haven't visited this planet yet
	var planet_id := GameState.player.current_planet
	var contracts := PassengerManager.get_contracts_at(planet_id)
	if contracts.is_empty():
		PassengerManager.generate_contracts_at(planet_id, GameState.player.passenger_reputation, GameState.player.day)
	_update_display()

func _update_display() -> void:
	var player := GameState.player

	credits_label.text = "Credits: %s" % _format_number(player.credits)
	reputation_label.text = "Reputation: %d" % player.passenger_reputation
	_color_reputation(reputation_label, player.passenger_reputation)

	var berths_used := player.get_passenger_count()
	var berths_total := player.ship.passenger_berths
	berths_label.text = "Berths: %d/%d" % [berths_used, berths_total]
	if berths_used >= berths_total:
		berths_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
	else:
		berths_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))

	_build_available_list()
	_build_accepted_list()

func _build_available_list() -> void:
	for child in available_list.get_children():
		child.queue_free()

	var planet_id := GameState.player.current_planet
	var contracts := PassengerManager.get_contracts_at(planet_id)

	if contracts.is_empty():
		var no_contracts := Label.new()
		no_contracts.text = "No passengers seeking transport"
		no_contracts.add_theme_font_size_override("font_size", 14)
		no_contracts.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		no_contracts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		available_list.add_child(no_contracts)
		return

	for contract in contracts:
		var row := _create_contract_row(contract, true)
		available_list.add_child(row)

func _build_accepted_list() -> void:
	for child in accepted_list.get_children():
		child.queue_free()

	var player := GameState.player

	if player.accepted_passengers.is_empty():
		var no_passengers := Label.new()
		no_passengers.text = "No passengers aboard"
		no_passengers.add_theme_font_size_override("font_size", 14)
		no_passengers.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		no_passengers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		accepted_list.add_child(no_passengers)
		return

	for i in range(player.accepted_passengers.size()):
		var contract = player.accepted_passengers[i]
		var row := _create_contract_row(contract, false, i)
		accepted_list.add_child(row)

func _create_contract_row(contract, is_available: bool, index: int = -1) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	# Handle both Dictionary and PassengerContract
	var passenger_type: String
	var passenger_name: String
	var destination: String
	var deadline: int
	var base_payment: int
	var count: int
	var mood: int = 100

	if contract is Dictionary:
		passenger_type = contract.get("passenger_type", "tourist")
		passenger_name = contract.get("passenger_name", "Unknown")
		destination = contract.get("destination", "")
		deadline = contract.get("deadline", 0)
		base_payment = contract.get("base_payment", 100)
		count = contract.get("count", 1)
		mood = contract.get("mood", 100)
	else:
		passenger_type = contract.passenger_type
		passenger_name = contract.passenger_name
		destination = contract.destination
		deadline = contract.deadline
		base_payment = contract.base_payment
		count = contract.count
		mood = contract.mood

	var type_data := PassengerManager.get_passenger_type(passenger_type)
	var dest_planet := DataRepo.get_planet(destination)
	var dest_name := dest_planet.planet_name if dest_planet else destination

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)

	# Type icon
	var type_label := Label.new()
	type_label.text = "[%s]" % type_data.get("name", "Tourist").substr(0, 3).to_upper()
	type_label.add_theme_font_size_override("font_size", 14)
	type_label.add_theme_color_override("font_color", _get_type_color(passenger_type))
	header.add_child(type_label)

	# Name and count
	var name_label := Label.new()
	if count > 1:
		name_label.text = "%s (+%d)" % [passenger_name, count - 1]
	else:
		name_label.text = passenger_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	# Payment
	var payment_label := Label.new()
	payment_label.text = "%s cr" % _format_number(base_payment * count)
	payment_label.add_theme_font_size_override("font_size", 16)
	payment_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	header.add_child(payment_label)

	container.add_child(header)

	# Details row
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation", 15)

	# Destination
	var dest_label := Label.new()
	dest_label.text = "To: %s" % dest_name
	dest_label.add_theme_font_size_override("font_size", 14)
	dest_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	details.add_child(dest_label)

	# Deadline
	var days_left := deadline - GameState.player.day
	var deadline_label := Label.new()
	if days_left > 0:
		deadline_label.text = "Due: Day %d (%d days)" % [deadline, days_left]
		if days_left <= 2:
			deadline_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
		else:
			deadline_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	else:
		deadline_label.text = "OVERDUE!"
		deadline_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	deadline_label.add_theme_font_size_override("font_size", 14)
	details.add_child(deadline_label)

	# Mood (only for accepted passengers)
	if not is_available:
		var mood_label := Label.new()
		mood_label.text = "Mood: %d%%" % mood
		mood_label.add_theme_font_size_override("font_size", 14)
		if mood >= 70:
			mood_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		elif mood >= 40:
			mood_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
		else:
			mood_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		details.add_child(mood_label)

	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(details)

	# Action button
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_END

	if is_available:
		var accept_btn := Button.new()
		accept_btn.text = "Accept"
		accept_btn.custom_minimum_size = Vector2(80, 32)
		accept_btn.add_theme_font_size_override("font_size", 14)

		# Check if we have room
		var player := GameState.player
		var berths_free := player.get_passenger_berths_free()
		accept_btn.disabled = berths_free < count

		accept_btn.pressed.connect(_on_accept_pressed.bind(contract))
		action_row.add_child(accept_btn)
	else:
		var abandon_btn := Button.new()
		abandon_btn.text = "Abandon"
		abandon_btn.custom_minimum_size = Vector2(80, 32)
		abandon_btn.add_theme_font_size_override("font_size", 14)
		abandon_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		abandon_btn.pressed.connect(_on_abandon_pressed.bind(index))
		action_row.add_child(abandon_btn)

	container.add_child(action_row)

	# Separator
	var sep := HSeparator.new()
	container.add_child(sep)

	return container

func _get_type_color(type_id: String) -> Color:
	match type_id:
		"tourist":
			return Color(0.4, 0.8, 0.4)
		"businessman":
			return Color(0.4, 0.6, 0.9)
		"colonist":
			return Color(0.7, 0.6, 0.4)
		"scientist":
			return Color(0.6, 0.4, 0.9)
		"vip":
			return Color(0.9, 0.7, 0.2)
		_:
			return Color(0.7, 0.7, 0.7)

func _color_reputation(label: Label, rep: int) -> void:
	if rep >= 80:
		label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif rep >= 50:
		label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	else:
		label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

func _on_accept_pressed(contract) -> void:
	var player := GameState.player

	# Get count from contract
	var count: int
	if contract is Dictionary:
		count = contract.get("count", 1)
	else:
		count = contract.count

	# Check berths
	if player.get_passenger_berths_free() < count:
		_show_message("Not enough passenger berths!", Color(0.9, 0.3, 0.3))
		return

	# Accept the contract
	PassengerManager.accept_contract(contract)

	# Add to player's accepted passengers
	if contract is Dictionary:
		player.accepted_passengers.append(contract)
	else:
		player.accepted_passengers.append(contract.to_dict())

	_show_message("Passengers accepted!", Color(0.4, 0.9, 0.4))
	_update_display()

func _on_abandon_pressed(index: int) -> void:
	if PassengerManager.abandon_contract(GameState.player, index):
		_show_message("Passengers abandoned (reputation -10)", Color(0.9, 0.5, 0.3))
	else:
		_show_message("Failed to abandon passengers", Color(0.9, 0.3, 0.3))
	_update_display()

func _on_refresh_pressed() -> void:
	var player := GameState.player
	PassengerManager.refresh_contracts_at(player.current_planet, player.passenger_reputation, player.day)
	_show_message("Checked for new passengers", Color(0.4, 0.8, 0.9))
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
