extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var cargo_label: Label = $MarginContainer/VBoxContainer/Header/CargoLabel
@onready var message_label: Label = $MarginContainer/VBoxContainer/Footer/MessageLabel

# Tab references
@onready var tab_container: TabContainer = $MarginContainer/VBoxContainer/TabContainer
@onready var corp_filter: OptionButton = $"MarginContainer/VBoxContainer/TabContainer/Available Contracts/CorpFilter/CorpFilterOption"
@onready var available_list: VBoxContainer = $"MarginContainer/VBoxContainer/TabContainer/Available Contracts/AvailableScroll/AvailableContractsList"
@onready var active_list: VBoxContainer = $"MarginContainer/VBoxContainer/TabContainer/Active Contracts/ActiveScroll/ActiveContractsList"
@onready var standings_list: VBoxContainer = $"MarginContainer/VBoxContainer/TabContainer/Corporation Standings/StandingsScroll/StandingsList"
@onready var sealed_list: VBoxContainer = $"MarginContainer/VBoxContainer/TabContainer/Sealed Cargo/SealedScroll/SealedCargoList"

var current_filter_corp: String = ""  # Empty = all corps

func _ready() -> void:
	var planet := DataRepo.get_planet(GameState.player.current_planet)
	title_label.text = "Corporation Office - %s" % planet.planet_name
	_update_header()
	_build_corp_filter()
	_build_available_contracts()
	_build_active_contracts()
	_build_standings()
	_build_sealed_cargo()

func _update_header() -> void:
	var player := GameState.player
	credits_label.text = "Credits: %s" % _format_number(player.credits)
	cargo_label.text = "Cargo: %d/%d t" % [player.get_cargo_space_used(), player.ship.cargo_tonnes]

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

func _build_corp_filter() -> void:
	corp_filter.clear()
	corp_filter.add_item("All Corporations", 0)

	var corps := CorporationManager.get_corporations_at_planet(GameState.player.current_planet)
	for i in range(corps.size()):
		var corp: Corporation = corps[i]
		corp_filter.add_item(corp.corp_name, i + 1)

func _on_corp_filter_changed(index: int) -> void:
	if index == 0:
		current_filter_corp = ""
	else:
		var corps := CorporationManager.get_corporations_at_planet(GameState.player.current_planet)
		if index - 1 < corps.size():
			current_filter_corp = corps[index - 1].id
	_build_available_contracts()

# --- Available Contracts Tab ---

func _build_available_contracts() -> void:
	for child in available_list.get_children():
		child.queue_free()

	var contracts := CorporationManager.get_available_contracts()
	if contracts.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No contracts available at this location."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		available_list.add_child(empty_label)
		return

	for contract in contracts:
		if current_filter_corp != "" and contract.corp_id != current_filter_corp:
			continue
		var row := _create_available_contract_row(contract)
		available_list.add_child(row)

func _create_available_contract_row(contract: Contract) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 1.0)
	if contract.is_express():
		style.bg_color = Color(0.16, 0.12, 0.12, 1.0)  # Slight red tint for express
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)

	var corp := CorporationManager.get_corporation(contract.corp_id)
	var player := GameState.player

	# Corp column
	var corp_label := Label.new()
	corp_label.custom_minimum_size.x = 120
	corp_label.text = corp.abbreviation if corp else "???"
	if corp:
		corp_label.add_theme_color_override("font_color", corp.color)
	corp_label.add_theme_font_size_override("font_size", 14)
	row.add_child(corp_label)

	# Type column
	var type_col := VBoxContainer.new()
	type_col.custom_minimum_size.x = 120
	var type_label := Label.new()
	type_label.text = contract.get_type_name()
	type_label.add_theme_font_size_override("font_size", 14)
	type_col.add_child(type_label)

	if contract.is_express():
		var tier_label := Label.new()
		tier_label.text = "[EXPRESS]"
		tier_label.add_theme_font_size_override("font_size", 10)
		tier_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		type_col.add_child(tier_label)

	row.add_child(type_col)

	# Description column
	var desc_label := Label.new()
	desc_label.custom_minimum_size.x = 280
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.text = contract.get_description()
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(desc_label)

	# Reward column
	var reward_label := Label.new()
	reward_label.custom_minimum_size.x = 80
	reward_label.text = "%d cr" % contract.reward
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 14)
	reward_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	row.add_child(reward_label)

	# Deadline column
	var deadline_label := Label.new()
	deadline_label.custom_minimum_size.x = 80
	var days_left := contract.get_days_remaining(player.day)
	deadline_label.text = "%d days" % days_left
	deadline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deadline_label.add_theme_font_size_override("font_size", 14)
	if days_left <= 3:
		deadline_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	elif days_left <= 7:
		deadline_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	row.add_child(deadline_label)

	# Action column
	var action_col := HBoxContainer.new()
	action_col.custom_minimum_size.x = 100
	action_col.alignment = BoxContainer.ALIGNMENT_END

	var standing: int = CorporationManager.get_standing(player, contract.corp_id)
	var can_accept: Dictionary = contract.can_accept(player.ship, standing)

	var accept_btn := Button.new()
	accept_btn.text = "Accept"
	accept_btn.custom_minimum_size = Vector2(80, 28)
	accept_btn.disabled = not can_accept["can_accept"]
	if can_accept["can_accept"]:
		accept_btn.pressed.connect(_on_accept_contract.bind(contract))
	else:
		accept_btn.tooltip_text = "\n".join(can_accept["reasons"])

	action_col.add_child(accept_btn)
	row.add_child(action_col)

	panel.add_child(row)
	return panel

func _on_accept_contract(contract: Contract) -> void:
	var result := CorporationManager.accept_contract(GameState.player, contract)
	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.8, 0.4))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_header()
	_build_available_contracts()
	_build_active_contracts()
	_build_sealed_cargo()

# --- Active Contracts Tab ---

func _build_active_contracts() -> void:
	for child in active_list.get_children():
		child.queue_free()

	var contracts := CorporationManager.get_active_contracts(GameState.player)
	if contracts.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active contracts."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		active_list.add_child(empty_label)
		return

	for contract in contracts:
		var row := _create_active_contract_row(contract)
		active_list.add_child(row)

func _create_active_contract_row(contract: Contract) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.12, 1.0)  # Green tint for active
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)

	var corp := CorporationManager.get_corporation(contract.corp_id)
	var player := GameState.player

	# Corp column
	var corp_label := Label.new()
	corp_label.custom_minimum_size.x = 120
	corp_label.text = corp.abbreviation if corp else "???"
	if corp:
		corp_label.add_theme_color_override("font_color", corp.color)
	corp_label.add_theme_font_size_override("font_size", 14)
	row.add_child(corp_label)

	# Type column
	var type_label := Label.new()
	type_label.custom_minimum_size.x = 120
	type_label.text = contract.get_type_name()
	type_label.add_theme_font_size_override("font_size", 14)
	row.add_child(type_label)

	# Description column
	var desc_label := Label.new()
	desc_label.custom_minimum_size.x = 280
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.text = contract.get_description()
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(desc_label)

	# Reward column
	var reward_label := Label.new()
	reward_label.custom_minimum_size.x = 80
	reward_label.text = "%d cr" % contract.reward
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 14)
	reward_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	row.add_child(reward_label)

	# Days left column
	var days_label := Label.new()
	days_label.custom_minimum_size.x = 80
	var days_left := contract.get_days_remaining(player.day)
	days_label.text = "%d days" % days_left
	days_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	days_label.add_theme_font_size_override("font_size", 14)
	if days_left <= 3:
		days_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	elif days_left <= 7:
		days_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	else:
		days_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	row.add_child(days_label)

	# Action column
	var action_col := HBoxContainer.new()
	action_col.custom_minimum_size.x = 100
	action_col.alignment = BoxContainer.ALIGNMENT_END

	var abandon_btn := Button.new()
	abandon_btn.text = "Abandon"
	abandon_btn.custom_minimum_size = Vector2(80, 28)
	abandon_btn.pressed.connect(_on_abandon_contract.bind(contract))
	action_col.add_child(abandon_btn)

	row.add_child(action_col)

	panel.add_child(row)
	return panel

func _on_abandon_contract(contract: Contract) -> void:
	var result := CorporationManager.abandon_contract(GameState.player, contract)
	if result["success"]:
		_show_message(result["message"], Color(0.9, 0.6, 0.3))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_header()
	_build_active_contracts()
	_build_sealed_cargo()

# --- Standings Tab ---

func _build_standings() -> void:
	for child in standings_list.get_children():
		child.queue_free()

	var corps := CorporationManager.get_all_corporations()
	for corp in corps:
		var row := _create_standing_row(corp)
		standings_list.add_child(row)

func _create_standing_row(corp: Corporation) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)

	var player := GameState.player
	var standing: int = CorporationManager.get_standing(player, corp.id)
	var level: String = CorporationManager.get_standing_level_name(standing)
	var presence: String = corp.get_presence_level(player.current_planet)

	# Corp name column
	var name_col := VBoxContainer.new()
	name_col.custom_minimum_size.x = 200

	var name_label := Label.new()
	name_label.text = corp.corp_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", corp.color)
	name_col.add_child(name_label)

	var abbrev_label := Label.new()
	abbrev_label.text = "(%s)" % corp.abbreviation
	abbrev_label.add_theme_font_size_override("font_size", 11)
	abbrev_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	name_col.add_child(abbrev_label)

	row.add_child(name_col)

	# Standing value column
	var standing_label := Label.new()
	standing_label.custom_minimum_size.x = 100
	standing_label.text = str(standing)
	standing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	standing_label.add_theme_font_size_override("font_size", 16)

	if standing >= 80:
		standing_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif standing >= 50:
		standing_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
	elif standing >= 20:
		standing_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
	else:
		standing_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	row.add_child(standing_label)

	# Level column
	var level_label := Label.new()
	level_label.custom_minimum_size.x = 100
	level_label.text = level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 14)
	row.add_child(level_label)

	# Presence column
	var presence_label := Label.new()
	presence_label.custom_minimum_size.x = 120
	presence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	presence_label.add_theme_font_size_override("font_size", 14)

	match presence:
		"primary":
			presence_label.text = "HQ"
			presence_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		"secondary":
			presence_label.text = "Office"
			presence_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.4))
		_:
			presence_label.text = "-"
			presence_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	row.add_child(presence_label)

	# Specialty column
	var specialty_label := Label.new()
	specialty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var specialties: Array = []
	for commodity_id in corp.specialty_commodities:
		var commodity := DataRepo.get_commodity(commodity_id)
		if commodity:
			specialties.append(commodity.commodity_name)
	specialty_label.text = ", ".join(specialties)
	specialty_label.add_theme_font_size_override("font_size", 13)
	specialty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	row.add_child(specialty_label)

	panel.add_child(row)
	return panel

# --- Sealed Cargo Tab ---

func _build_sealed_cargo() -> void:
	for child in sealed_list.get_children():
		child.queue_free()

	var player := GameState.player
	if player.sealed_cargo.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No sealed cargo containers."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		sealed_list.add_child(empty_label)
		return

	for cargo_data in player.sealed_cargo:
		var cargo := SealedCargo.from_dict(cargo_data)
		var row := _create_sealed_cargo_row(cargo)
		sealed_list.add_child(row)

func _create_sealed_cargo_row(cargo: SealedCargo) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()

	if cargo.is_expired:
		style.bg_color = Color(0.16, 0.12, 0.12, 1.0)  # Red tint for expired
	else:
		style.bg_color = Color(0.12, 0.12, 0.16, 1.0)

	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)

	# Contract column - find associated contract
	var contract_label := Label.new()
	contract_label.custom_minimum_size.x = 200
	contract_label.text = "Sealed Container"
	contract_label.add_theme_font_size_override("font_size", 14)

	# Try to find the contract
	for contract_data in GameState.player.active_contracts:
		if contract_data.get("sealed_cargo_id", "") == cargo.id:
			var corp_id_str: String = contract_data.get("corp_id", "")
			var corp := CorporationManager.get_corporation(corp_id_str)
			if corp:
				contract_label.text = "%s Contract" % corp.abbreviation
				contract_label.add_theme_color_override("font_color", corp.color)
			break

	row.add_child(contract_label)

	# Weight column
	var weight_label := Label.new()
	weight_label.custom_minimum_size.x = 80
	weight_label.text = "%d t" % cargo.weight
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 14)
	row.add_child(weight_label)

	# Status column
	var status_label := Label.new()
	status_label.custom_minimum_size.x = 120
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)

	if cargo.is_expired:
		status_label.text = "EXPIRED"
		status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		status_label.text = "In Transit"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))

	row.add_child(status_label)

	# Action column
	var action_col := HBoxContainer.new()
	action_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if cargo.is_expired:
		var discard_btn := Button.new()
		discard_btn.text = "Discard"
		discard_btn.custom_minimum_size = Vector2(80, 28)
		discard_btn.pressed.connect(_on_discard_cargo.bind(cargo.id))
		action_col.add_child(discard_btn)

	row.add_child(action_col)

	panel.add_child(row)
	return panel

func _on_discard_cargo(cargo_id: String) -> void:
	var result := CorporationManager.discard_expired_sealed_cargo(GameState.player, cargo_id)
	if result["success"]:
		_show_message(result["message"], Color(0.6, 0.6, 0.4))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_header()
	_build_sealed_cargo()

# --- Navigation ---

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")

func _show_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
