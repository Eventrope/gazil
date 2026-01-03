extends Control

@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var portfolio_label: Label = $MarginContainer/VBoxContainer/Header/PortfolioLabel

@onready var investment_options: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/OptionsPanel/VBoxContainer/ScrollContainer/InvestmentOptions
@onready var portfolio_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/PortfolioPanel/VBoxContainer/ScrollContainer/PortfolioList
@onready var message_label: Label = $MarginContainer/VBoxContainer/Footer/MessageLabel

var selected_type: Dictionary = {}
var amount_inputs: Dictionary = {}  # {type_id: SpinBox}

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var player := GameState.player

	credits_label.text = "Credits: %s" % _format_number(player.credits)

	# Calculate portfolio value
	var portfolio_value := 0
	for inv_data in player.investments:
		if inv_data is Dictionary:
			portfolio_value += inv_data.get("amount", 0)
		else:
			portfolio_value += inv_data.amount
	portfolio_label.text = "Invested: %s cr" % _format_number(portfolio_value)

	_build_investment_options()
	_build_portfolio_list()

func _build_investment_options() -> void:
	for child in investment_options.get_children():
		child.queue_free()
	amount_inputs.clear()

	var investment_types := DataRepo.get_all_investment_types()

	for type_data in investment_types:
		var row := _create_investment_option(type_data)
		investment_options.add_child(row)

func _create_investment_option(type_data: Dictionary) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)

	var type_id: String = type_data.get("id", "")
	var type_name: String = type_data.get("name", "Unknown")
	var description: String = type_data.get("description", "")
	var min_inv: int = type_data.get("min_investment", 100)
	var max_inv: int = type_data.get("max_investment", 10000)
	var duration: int = type_data.get("duration_days", 30)
	var base_return: float = type_data.get("base_return", 0.05)
	var risk: float = type_data.get("risk", 0.0)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = type_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", _get_category_color(type_data.get("category", "bonds")))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	# Return rate
	var return_label := Label.new()
	return_label.text = "+%d%%" % int(base_return * 100)
	return_label.add_theme_font_size_override("font_size", 16)
	return_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	header.add_child(return_label)

	# Risk
	var risk_label := Label.new()
	risk_label.text = "Risk: %s" % _get_risk_text(risk)
	risk_label.add_theme_font_size_override("font_size", 14)
	risk_label.add_theme_color_override("font_color", _get_risk_color(risk))
	header.add_child(risk_label)

	container.add_child(header)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	container.add_child(desc_label)

	# Details row
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation", 20)

	var range_label := Label.new()
	range_label.text = "%s - %s cr" % [_format_number(min_inv), _format_number(max_inv)]
	range_label.add_theme_font_size_override("font_size", 12)
	range_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	details.add_child(range_label)

	var duration_label := Label.new()
	duration_label.text = "%d days" % duration
	duration_label.add_theme_font_size_override("font_size", 12)
	duration_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	details.add_child(duration_label)

	container.add_child(details)

	# Investment row
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)

	var amount_input := SpinBox.new()
	amount_input.min_value = min_inv
	amount_input.max_value = max_inv
	amount_input.step = 100
	amount_input.value = min_inv
	amount_input.custom_minimum_size = Vector2(150, 35)
	amount_input.suffix = " cr"
	amount_inputs[type_id] = amount_input
	action_row.add_child(amount_input)

	var invest_btn := Button.new()
	invest_btn.text = "Invest"
	invest_btn.custom_minimum_size = Vector2(80, 35)
	invest_btn.add_theme_font_size_override("font_size", 14)
	invest_btn.pressed.connect(_on_invest_pressed.bind(type_id))
	action_row.add_child(invest_btn)

	container.add_child(action_row)

	# Separator
	var sep := HSeparator.new()
	container.add_child(sep)

	return container

func _build_portfolio_list() -> void:
	for child in portfolio_list.get_children():
		child.queue_free()

	var player := GameState.player

	if player.investments.is_empty():
		var no_inv := Label.new()
		no_inv.text = "No active investments"
		no_inv.add_theme_font_size_override("font_size", 14)
		no_inv.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		no_inv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		portfolio_list.add_child(no_inv)
		return

	for inv_data in player.investments:
		var row := _create_portfolio_row(inv_data)
		portfolio_list.add_child(row)

func _create_portfolio_row(inv_data) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var inv: Investment
	if inv_data is Dictionary:
		inv = Investment.from_dict(inv_data)
	else:
		inv = inv_data

	var type_data := DataRepo.get_investment_type(inv.type_id)
	var type_name: String = type_data.get("name", inv.type_id)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)

	var name_label := Label.new()
	name_label.text = type_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", _get_category_color(type_data.get("category", "bonds")))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var amount_label := Label.new()
	amount_label.text = "%s cr" % _format_number(inv.amount)
	amount_label.add_theme_font_size_override("font_size", 16)
	header.add_child(amount_label)

	container.add_child(header)

	# Status row
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 15)

	var days_left := inv.get_days_remaining(GameState.player.day)
	var maturity_label := Label.new()
	maturity_label.text = "Matures: Day %d (%d days)" % [inv.maturity_day, days_left]
	maturity_label.add_theme_font_size_override("font_size", 12)
	if days_left <= 3:
		maturity_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	else:
		maturity_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	status.add_child(maturity_label)

	# Expected return (hidden until maturity is close)
	var payout := inv.get_payout()
	var profit := inv.get_profit()
	var return_label := Label.new()
	if profit >= 0:
		return_label.text = "Expected: +%s cr" % _format_number(profit)
		return_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		return_label.text = "Expected: %s cr" % _format_number(profit)
		return_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	return_label.add_theme_font_size_override("font_size", 12)
	status.add_child(return_label)

	container.add_child(status)

	# Separator
	var sep := HSeparator.new()
	container.add_child(sep)

	return container

func _get_category_color(category: String) -> Color:
	match category:
		"bonds":
			return Color(0.4, 0.7, 0.9)
		"futures":
			return Color(0.9, 0.7, 0.3)
		"venture":
			return Color(0.9, 0.4, 0.6)
		_:
			return Color(0.7, 0.7, 0.7)

func _get_risk_text(risk: float) -> String:
	if risk <= 0.0:
		return "None"
	elif risk <= 0.15:
		return "Low"
	elif risk <= 0.35:
		return "Medium"
	elif risk <= 0.5:
		return "High"
	else:
		return "Very High"

func _get_risk_color(risk: float) -> Color:
	if risk <= 0.0:
		return Color(0.3, 0.9, 0.3)
	elif risk <= 0.15:
		return Color(0.6, 0.9, 0.3)
	elif risk <= 0.35:
		return Color(0.9, 0.8, 0.3)
	elif risk <= 0.5:
		return Color(0.9, 0.5, 0.3)
	else:
		return Color(0.9, 0.3, 0.3)

func _on_invest_pressed(type_id: String) -> void:
	var input: SpinBox = amount_inputs.get(type_id, null)
	if input == null:
		return

	var amount := int(input.value)
	var result := GameState.buy_investment(type_id, amount)

	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.9, 0.4))
		input.value = input.min_value
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
