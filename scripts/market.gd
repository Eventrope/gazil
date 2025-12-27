extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var cargo_label: Label = $MarginContainer/VBoxContainer/Header/CargoLabel
@onready var commodity_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/CommodityList
@onready var message_label: Label = $MarginContainer/VBoxContainer/Footer/MessageLabel

func _ready() -> void:
	var planet := DataRepo.get_planet(GameState.player.current_planet)
	title_label.text = "Market - %s" % planet.planet_name
	_update_header()
	_build_commodity_rows()

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

func _build_commodity_rows() -> void:
	# Clear existing rows
	for child in commodity_list.get_children():
		child.queue_free()

	# Add a row for each commodity
	for commodity in DataRepo.get_all_commodities():
		var row := _create_commodity_row(commodity)
		commodity_list.add_child(row)

func _create_commodity_row(commodity: Commodity) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)

	var current_planet := GameState.player.current_planet
	var price := GameState.get_price_at(current_planet, commodity.id)
	var owned := GameState.player.get_cargo_quantity(commodity.id)
	var stock := GameState.get_stock_at(current_planet, commodity.id)
	var planet := DataRepo.get_planet(current_planet)
	var base_stock := planet.get_base_stock(commodity.id)

	# Name
	var name_label := Label.new()
	name_label.custom_minimum_size.x = 200
	name_label.text = commodity.commodity_name
	name_label.add_theme_font_size_override("font_size", 16)
	row.add_child(name_label)

	# Price with news indicator
	var price_label := Label.new()
	price_label.custom_minimum_size.x = 100
	var news_effects := NewsManager.get_combined_effects(
		GameState.get_active_news_events(), current_planet, commodity.id
	)
	var price_text := "%d cr" % price
	if news_effects["price_modifier"] > 1.0:
		price_text += " ^"
		price_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
	elif news_effects["price_modifier"] < 1.0:
		price_text += " v"
		price_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	price_label.text = price_text
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 16)
	row.add_child(price_label)

	# Owned
	var owned_label := Label.new()
	owned_label.custom_minimum_size.x = 80
	owned_label.text = str(owned)
	owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owned_label.add_theme_font_size_override("font_size", 16)
	if owned > 0:
		owned_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	row.add_child(owned_label)

	# Stock with color coding
	var stock_label := Label.new()
	stock_label.custom_minimum_size.x = 80
	stock_label.text = str(stock)
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_label.add_theme_font_size_override("font_size", 16)
	# Color based on stock level relative to base
	var stock_ratio: float = float(stock) / float(max(base_stock, 1))
	if stock_ratio > 0.7:
		stock_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))  # Green - plenty
	elif stock_ratio > 0.3:
		stock_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))  # Yellow - moderate
	else:
		stock_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))  # Red - scarce
	row.add_child(stock_label)

	# Weight
	var weight_label := Label.new()
	weight_label.custom_minimum_size.x = 80
	weight_label.text = "%d/unit" % commodity.weight_per_unit
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 16)
	weight_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	row.add_child(weight_label)

	# Actions container
	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 10)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER

	# Buy button - disabled if no stock
	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(60, 30)
	buy_btn.disabled = stock < 1
	buy_btn.pressed.connect(_on_buy_pressed.bind(commodity.id, 1))
	actions.add_child(buy_btn)

	# Buy 5 - disabled if not enough stock
	var buy5_btn := Button.new()
	buy5_btn.text = "+5"
	buy5_btn.custom_minimum_size = Vector2(50, 30)
	buy5_btn.disabled = stock < 5
	buy5_btn.pressed.connect(_on_buy_pressed.bind(commodity.id, mini(5, stock)))
	actions.add_child(buy5_btn)

	# Sell button
	var sell_btn := Button.new()
	sell_btn.text = "Sell"
	sell_btn.custom_minimum_size = Vector2(60, 30)
	sell_btn.disabled = owned == 0
	sell_btn.pressed.connect(_on_sell_pressed.bind(commodity.id, 1))
	actions.add_child(sell_btn)

	# Sell 5
	var sell5_btn := Button.new()
	sell5_btn.text = "-5"
	sell5_btn.custom_minimum_size = Vector2(50, 30)
	sell5_btn.disabled = owned < 5
	sell5_btn.pressed.connect(_on_sell_pressed.bind(commodity.id, mini(5, owned)))
	actions.add_child(sell5_btn)

	# Sell All
	var sell_all_btn := Button.new()
	sell_all_btn.text = "All"
	sell_all_btn.custom_minimum_size = Vector2(50, 30)
	sell_all_btn.disabled = owned == 0
	sell_all_btn.pressed.connect(_on_sell_pressed.bind(commodity.id, owned))
	actions.add_child(sell_all_btn)

	row.add_child(actions)

	return row

func _on_buy_pressed(commodity_id: String, quantity: int) -> void:
	var result := GameState.buy_commodity(commodity_id, quantity)
	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.8, 0.4))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_header()
	_build_commodity_rows()

func _on_sell_pressed(commodity_id: String, quantity: int) -> void:
	var result := GameState.sell_commodity(commodity_id, quantity)
	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.8, 0.4))

		# Check win condition
		var game_over := GameState.check_game_over()
		if game_over["game_over"]:
			get_tree().change_scene_to_file("res://scenes/game_over.tscn")
			return
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_header()
	_build_commodity_rows()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")

func _show_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
