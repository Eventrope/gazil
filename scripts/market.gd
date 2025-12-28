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

func _create_commodity_row(commodity: Commodity) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var current_planet := GameState.player.current_planet
	var price := GameState.get_price_at(current_planet, commodity.id)
	var owned := GameState.player.get_cargo_quantity(commodity.id)
	var stock := GameState.get_stock_at(current_planet, commodity.id)
	var planet := DataRepo.get_planet(current_planet)
	var base_stock := planet.get_base_stock(commodity.id)

	# Get price range and quality info
	var price_range := DataRepo.get_commodity_price_range(commodity.id)
	var price_quality := DataRepo.get_price_quality(price, commodity.id)
	var quality: float = price_quality["quality"]
	var rating: String = price_quality["rating"]

	# Main row
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)

	# Name
	var name_label := Label.new()
	name_label.custom_minimum_size.x = 160
	name_label.text = commodity.commodity_name
	name_label.add_theme_font_size_override("font_size", 16)
	row.add_child(name_label)

	# Price with quality color
	var price_container := VBoxContainer.new()
	price_container.custom_minimum_size.x = 120
	price_container.add_theme_constant_override("separation", 0)

	var price_label := Label.new()
	price_label.text = "%d cr" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 16)

	# Color based on buy quality (low = green/good, high = red/bad)
	var price_color := _get_quality_color(quality)
	price_label.add_theme_color_override("font_color", price_color)

	# Add news indicator
	var news_effects := NewsManager.get_combined_effects(
		GameState.get_active_news_events(), current_planet, commodity.id
	)
	if news_effects["price_modifier"] > 1.0:
		price_label.text += " ^"
	elif news_effects["price_modifier"] < 1.0:
		price_label.text += " v"

	price_container.add_child(price_label)

	# Price range subtitle
	var range_label := Label.new()
	range_label.text = "(%d-%d)" % [price_range["min_price"], price_range["max_price"]]
	range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	range_label.add_theme_font_size_override("font_size", 11)
	range_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	price_container.add_child(range_label)

	row.add_child(price_container)

	# Rating badge
	var rating_label := Label.new()
	rating_label.custom_minimum_size.x = 70
	rating_label.text = _get_rating_text(rating)
	rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rating_label.add_theme_font_size_override("font_size", 12)
	rating_label.add_theme_color_override("font_color", price_color)
	row.add_child(rating_label)

	# Owned
	var owned_label := Label.new()
	owned_label.custom_minimum_size.x = 60
	owned_label.text = str(owned)
	owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owned_label.add_theme_font_size_override("font_size", 16)
	if owned > 0:
		owned_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	row.add_child(owned_label)

	# Stock with color coding
	var stock_label := Label.new()
	stock_label.custom_minimum_size.x = 60
	stock_label.text = str(stock)
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_label.add_theme_font_size_override("font_size", 16)
	var stock_ratio: float = float(stock) / float(max(base_stock, 1))
	if stock_ratio > 0.7:
		stock_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	elif stock_ratio > 0.3:
		stock_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	else:
		stock_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	row.add_child(stock_label)

	# Weight
	var weight_label := Label.new()
	weight_label.custom_minimum_size.x = 50
	weight_label.text = "%dt" % commodity.weight_per_unit
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 14)
	weight_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	row.add_child(weight_label)

	# Actions container
	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	actions.alignment = BoxContainer.ALIGNMENT_END

	# Buy button
	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(55, 28)
	buy_btn.disabled = stock < 1
	buy_btn.pressed.connect(_on_buy_pressed.bind(commodity.id, 1))
	actions.add_child(buy_btn)

	# Buy 5
	var buy5_btn := Button.new()
	buy5_btn.text = "+5"
	buy5_btn.custom_minimum_size = Vector2(45, 28)
	buy5_btn.disabled = stock < 5
	buy5_btn.pressed.connect(_on_buy_pressed.bind(commodity.id, mini(5, stock)))
	actions.add_child(buy5_btn)

	# Sell button
	var sell_btn := Button.new()
	sell_btn.text = "Sell"
	sell_btn.custom_minimum_size = Vector2(55, 28)
	sell_btn.disabled = owned == 0
	sell_btn.pressed.connect(_on_sell_pressed.bind(commodity.id, 1))
	actions.add_child(sell_btn)

	# Sell 5
	var sell5_btn := Button.new()
	sell5_btn.text = "-5"
	sell5_btn.custom_minimum_size = Vector2(45, 28)
	sell5_btn.disabled = owned < 5
	sell5_btn.pressed.connect(_on_sell_pressed.bind(commodity.id, mini(5, owned)))
	actions.add_child(sell5_btn)

	# Sell All
	var sell_all_btn := Button.new()
	sell_all_btn.text = "All"
	sell_all_btn.custom_minimum_size = Vector2(45, 28)
	sell_all_btn.disabled = owned == 0
	sell_all_btn.pressed.connect(_on_sell_pressed.bind(commodity.id, owned))
	actions.add_child(sell_all_btn)

	row.add_child(actions)
	container.add_child(row)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	container.add_child(sep)

	return container

func _get_quality_color(quality: float) -> Color:
	# quality 0.0 = excellent (green), 1.0 = terrible (red)
	if quality <= 0.15:
		return Color(0.2, 0.9, 0.3)  # Bright green - excellent buy
	elif quality <= 0.35:
		return Color(0.5, 0.8, 0.3)  # Yellow-green - good buy
	elif quality <= 0.65:
		return Color(0.8, 0.8, 0.3)  # Yellow - fair
	elif quality <= 0.85:
		return Color(0.9, 0.5, 0.3)  # Orange - poor buy
	else:
		return Color(0.9, 0.3, 0.3)  # Red - terrible buy

func _get_rating_text(rating: String) -> String:
	match rating:
		"excellent":
			return "BUY!"
		"good":
			return "Good"
		"fair":
			return "Fair"
		"poor":
			return "High"
		"terrible":
			return "SELL!"
		_:
			return ""

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

func _on_main_menu_pressed() -> void:
	GameState.return_to_main_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _show_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
