extends Control

@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var crew_label: Label = $MarginContainer/VBoxContainer/Header/CrewLabel
@onready var wages_label: Label = $MarginContainer/VBoxContainer/Header/WagesLabel

@onready var hiring_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/HiringPanel/VBoxContainer/ScrollContainer/HiringList
@onready var roster_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/RosterPanel/VBoxContainer/ScrollContainer/RosterList
@onready var message_label: Label = $MarginContainer/VBoxContainer/Footer/MessageLabel

var hiring_quality: Dictionary = {}  # {role_id: int}

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var player := GameState.player

	credits_label.text = "Credits: %s" % _format_number(player.credits)

	var max_crew := player.ship.min_crew + 3
	crew_label.text = "Crew: %d/%d (min: %d)" % [player.crew.size(), max_crew, player.ship.min_crew]
	if player.crew.size() < player.ship.min_crew:
		crew_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		crew_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))

	var daily_wages := player.get_daily_wages()
	wages_label.text = "Daily Wages: %d cr" % daily_wages

	_build_hiring_list()
	_build_roster_list()

func _build_hiring_list() -> void:
	for child in hiring_list.get_children():
		child.queue_free()

	var roles := DataRepo.get_all_crew_roles()

	for role_data in roles:
		var row := _create_hiring_row(role_data)
		hiring_list.add_child(row)

func _create_hiring_row(role_data: Dictionary) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)

	var role_id: String = role_data.get("id", "")
	var role_name: String = role_data.get("name", "Unknown")
	var description: String = role_data.get("description", "")
	var base_wage: int = role_data.get("base_wage", 20)

	# Initialize quality if not set
	if not hiring_quality.has(role_id):
		hiring_quality[role_id] = 3

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)

	var name_label := Label.new()
	name_label.text = role_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", _get_role_color(role_id))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	container.add_child(header)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	container.add_child(desc_label)

	# Quality selection
	var quality_row := HBoxContainer.new()
	quality_row.add_theme_constant_override("separation", 10)

	var quality_label := Label.new()
	quality_label.text = "Quality:"
	quality_label.add_theme_font_size_override("font_size", 14)
	quality_row.add_child(quality_label)

	for q in range(1, 6):
		var star_btn := Button.new()
		star_btn.text = "*".repeat(q)
		star_btn.custom_minimum_size = Vector2(50, 30)
		star_btn.add_theme_font_size_override("font_size", 12)
		if hiring_quality[role_id] == q:
			star_btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		star_btn.pressed.connect(_on_quality_selected.bind(role_id, q))
		quality_row.add_child(star_btn)

	container.add_child(quality_row)

	# Hire row
	var hire_row := HBoxContainer.new()
	hire_row.add_theme_constant_override("separation", 15)

	var quality: int = hiring_quality[role_id]
	var wage := int(base_wage * (0.8 + quality * 0.2))
	var cost := base_wage * quality * 5

	var wage_label := Label.new()
	wage_label.text = "Wage: %d cr/day" % wage
	wage_label.add_theme_font_size_override("font_size", 14)
	wage_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hire_row.add_child(wage_label)

	var cost_label := Label.new()
	cost_label.text = "Hiring: %d cr" % cost
	cost_label.add_theme_font_size_override("font_size", 14)
	if GameState.player.credits >= cost:
		cost_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		cost_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	hire_row.add_child(cost_label)

	var hire_btn := Button.new()
	hire_btn.text = "Hire"
	hire_btn.custom_minimum_size = Vector2(80, 35)
	hire_btn.add_theme_font_size_override("font_size", 14)
	hire_btn.pressed.connect(_on_hire_pressed.bind(role_id, quality))
	hire_row.add_child(hire_btn)

	container.add_child(hire_row)

	# Separator
	var sep := HSeparator.new()
	container.add_child(sep)

	return container

func _build_roster_list() -> void:
	for child in roster_list.get_children():
		child.queue_free()

	var player := GameState.player

	if player.crew.is_empty():
		var no_crew := Label.new()
		no_crew.text = "No crew members"
		no_crew.add_theme_font_size_override("font_size", 14)
		no_crew.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		no_crew.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roster_list.add_child(no_crew)
		return

	for i in range(player.crew.size()):
		var crew_data = player.crew[i]
		var row := _create_roster_row(crew_data, i)
		roster_list.add_child(row)

func _create_roster_row(crew_data, index: int) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var member: CrewMember
	if crew_data is Dictionary:
		member = CrewMember.from_dict(crew_data)
	else:
		member = crew_data

	var role_data := DataRepo.get_crew_role(member.role_id)
	var role_name: String = role_data.get("name", member.role_id)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)

	var name_label := Label.new()
	name_label.text = member.crew_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var role_label := Label.new()
	role_label.text = role_name
	role_label.add_theme_font_size_override("font_size", 14)
	role_label.add_theme_color_override("font_color", _get_role_color(member.role_id))
	header.add_child(role_label)

	var stars_label := Label.new()
	stars_label.text = member.get_quality_stars()
	stars_label.add_theme_font_size_override("font_size", 14)
	stars_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	header.add_child(stars_label)

	container.add_child(header)

	# Stats row
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 20)

	var wage_label := Label.new()
	wage_label.text = "Wage: %d cr/day" % member.wage
	wage_label.add_theme_font_size_override("font_size", 12)
	wage_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	stats.add_child(wage_label)

	var morale_label := Label.new()
	morale_label.text = "Morale: %d%%" % member.morale
	morale_label.add_theme_font_size_override("font_size", 12)
	if member.morale >= 70:
		morale_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif member.morale >= 40:
		morale_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	else:
		morale_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	stats.add_child(morale_label)

	var effectiveness_label := Label.new()
	var eff := int(member.get_effectiveness() * 100)
	effectiveness_label.text = "Effectiveness: %d%%" % eff
	effectiveness_label.add_theme_font_size_override("font_size", 12)
	effectiveness_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	stats.add_child(effectiveness_label)

	# Fire button
	var fire_btn := Button.new()
	fire_btn.text = "Release"
	fire_btn.custom_minimum_size = Vector2(70, 28)
	fire_btn.add_theme_font_size_override("font_size", 12)
	fire_btn.pressed.connect(_on_fire_pressed.bind(index))
	stats.add_child(fire_btn)

	container.add_child(stats)

	# Separator
	var sep := HSeparator.new()
	container.add_child(sep)

	return container

func _get_role_color(role_id: String) -> Color:
	match role_id:
		"pilot":
			return Color(0.4, 0.7, 0.9)
		"engineer":
			return Color(0.9, 0.6, 0.3)
		"navigator":
			return Color(0.5, 0.9, 0.5)
		"cargo_master":
			return Color(0.7, 0.5, 0.3)
		"steward":
			return Color(0.9, 0.5, 0.7)
		"medic":
			return Color(0.9, 0.3, 0.3)
		_:
			return Color(0.7, 0.7, 0.7)

func _on_quality_selected(role_id: String, quality: int) -> void:
	hiring_quality[role_id] = quality
	_update_display()

func _on_hire_pressed(role_id: String, quality: int) -> void:
	var result := GameState.hire_crew(role_id, quality)

	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.9, 0.4))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_display()

func _on_fire_pressed(index: int) -> void:
	var result := GameState.fire_crew(index)

	if result["success"]:
		_show_message(result["message"], Color(0.9, 0.7, 0.3))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
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
