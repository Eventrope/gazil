extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var cargo_label: Label = $MarginContainer/VBoxContainer/Header/CargoLabel
@onready var commodity_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/CommodityList
@onready var message_label: Label = $MarginContainer/VBoxContainer/Footer/MessageLabel

# Trade panel refs (created dynamically)
var trade_panel: PanelContainer = null
var selected_commodity: Commodity = null
var quantity_slider: HSlider = null
var quantity_label: Label = null
var total_label: Label = null
var trade_action_btn: Button = null
var is_buying := true

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
	for child in commodity_list.get_children():
		child.queue_free()

	var current_planet := GameState.player.current_planet

	for commodity in DataRepo.get_all_commodities():
		# Filter: only show commodities available at this planet
		if not commodity.is_available_at(current_planet):
			# Check if player owns some (still show for selling)
			if GameState.player.get_cargo_quantity(commodity.id) == 0:
				continue

		var row := _create_commodity_row(commodity)
		commodity_list.add_child(row)

func _create_commodity_row(commodity: Commodity) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var current_planet := GameState.player.current_planet
	var price := GameState.get_price_at(current_planet, commodity.id)
	var owned := GameState.player.get_cargo_quantity(commodity.id)
	var stock := GameState.get_stock_at(current_planet, commodity.id)
	var planet := DataRepo.get_planet(current_planet)
	var base_stock := planet.get_base_stock(commodity.id)
	var purchase_price := GameState.player.get_purchase_price(commodity.id)
	var is_available := commodity.is_available_at(current_planet)

	var price_range := DataRepo.get_commodity_price_range(commodity.id)
	var price_quality := DataRepo.get_price_quality(price, commodity.id)
	var quality: float = price_quality["quality"]

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# Name + Category column
	var name_col := VBoxContainer.new()
	name_col.custom_minimum_size.x = 140
	name_col.add_theme_constant_override("separation", 0)

	var name_label := Label.new()
	name_label.text = commodity.commodity_name
	name_label.add_theme_font_size_override("font_size", 15)
	if commodity.is_contraband():
		name_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	name_col.add_child(name_label)

	var cat_label := Label.new()
	cat_label.text = "(%s)" % commodity.category
	cat_label.add_theme_font_size_override("font_size", 11)
	cat_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	name_col.add_child(cat_label)

	row.add_child(name_col)

	# Price column with color and range
	var price_col := VBoxContainer.new()
	price_col.custom_minimum_size.x = 90
	price_col.add_theme_constant_override("separation", 0)

	var price_label := Label.new()
	if is_available:
		price_label.text = "%d cr" % price
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
	else:
		price_label.text = "N/A"
		price_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 15)
	price_col.add_child(price_label)

	var range_label := Label.new()
	range_label.text = "(%d-%d)" % [price_range["min_price"], price_range["max_price"]]
	range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	range_label.add_theme_font_size_override("font_size", 10)
	range_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	price_col.add_child(range_label)

	row.add_child(price_col)

	# Owned column with profit indicator
	var owned_col := VBoxContainer.new()
	owned_col.custom_minimum_size.x = 90
	owned_col.add_theme_constant_override("separation", 0)

	var owned_label := Label.new()
	owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owned_label.add_theme_font_size_override("font_size", 15)

	if owned > 0:
		owned_label.text = "%d" % owned
		owned_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))

		# Show profit/loss if selling now
		var profit_label := Label.new()
		var potential_profit := (price - purchase_price) * owned
		if potential_profit > 0:
			profit_label.text = "+%d" % potential_profit
			profit_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		elif potential_profit < 0:
			profit_label.text = "%d" % potential_profit
			profit_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			profit_label.text = "@%d" % purchase_price
			profit_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		profit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		profit_label.add_theme_font_size_override("font_size", 10)
		owned_col.add_child(owned_label)
		owned_col.add_child(profit_label)
	else:
		owned_label.text = "-"
		owned_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		owned_col.add_child(owned_label)

	row.add_child(owned_col)

	# Stock column
	var stock_label := Label.new()
	stock_label.custom_minimum_size.x = 55
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_label.add_theme_font_size_override("font_size", 15)

	if is_available:
		stock_label.text = str(stock)
		var stock_ratio: float = float(stock) / float(max(base_stock, 1))
		if stock_ratio > 0.7:
			stock_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		elif stock_ratio > 0.3:
			stock_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
		else:
			stock_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		stock_label.text = "-"
		stock_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	row.add_child(stock_label)

	# Weight column
	var weight_label := Label.new()
	weight_label.custom_minimum_size.x = 40
	weight_label.text = "%dt" % commodity.weight_per_unit
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 13)
	weight_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	row.add_child(weight_label)

	# Actions
	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 6)
	actions.alignment = BoxContainer.ALIGNMENT_END

	# Buy Max button
	if is_available and stock > 0:
		var buy_max_btn := Button.new()
		var max_buy := _calculate_max_buy(commodity, price, stock)
		buy_max_btn.text = "Buy Max (%d)" % max_buy if max_buy > 0 else "Buy Max"
		buy_max_btn.custom_minimum_size = Vector2(95, 30)
		buy_max_btn.disabled = max_buy < 1
		buy_max_btn.pressed.connect(_on_buy_pressed.bind(commodity.id, max_buy))
		actions.add_child(buy_max_btn)

		var buy_btn := Button.new()
		buy_btn.text = "Buy..."
		buy_btn.custom_minimum_size = Vector2(60, 30)
		buy_btn.pressed.connect(_on_open_trade_panel.bind(commodity, true))
		actions.add_child(buy_btn)

	# Sell buttons
	if owned > 0:
		var sell_btn := Button.new()
		sell_btn.text = "Sell..."
		sell_btn.custom_minimum_size = Vector2(60, 30)
		sell_btn.pressed.connect(_on_open_trade_panel.bind(commodity, false))
		actions.add_child(sell_btn)

		var sell_all_btn := Button.new()
		sell_all_btn.text = "Sell All"
		sell_all_btn.custom_minimum_size = Vector2(70, 30)
		sell_all_btn.pressed.connect(_on_sell_pressed.bind(commodity.id, owned))
		actions.add_child(sell_all_btn)

	row.add_child(actions)
	panel.add_child(row)

	return panel

func _calculate_max_buy(commodity: Commodity, price: int, stock: int) -> int:
	var player := GameState.player
	var affordable: int = player.credits / max(price, 1)
	var space: int = player.get_cargo_space_free() / max(commodity.weight_per_unit, 1)
	return mini(mini(affordable, space), stock)

func _get_quality_color(quality: float) -> Color:
	if quality <= 0.15:
		return Color(0.2, 0.95, 0.3)  # Bright green
	elif quality <= 0.35:
		return Color(0.5, 0.85, 0.3)  # Yellow-green
	elif quality <= 0.65:
		return Color(0.85, 0.85, 0.3)  # Yellow
	elif quality <= 0.85:
		return Color(0.95, 0.55, 0.3)  # Orange
	else:
		return Color(0.95, 0.3, 0.3)  # Red

func _on_open_trade_panel(commodity: Commodity, buying: bool) -> void:
	selected_commodity = commodity
	is_buying = buying
	_show_trade_panel()

func _show_trade_panel() -> void:
	if trade_panel != null:
		trade_panel.queue_free()

	var current_planet := GameState.player.current_planet
	var price := GameState.get_price_at(current_planet, selected_commodity.id)
	var owned := GameState.player.get_cargo_quantity(selected_commodity.id)
	var stock := GameState.get_stock_at(current_planet, selected_commodity.id)

	var max_qty: int
	if is_buying:
		max_qty = _calculate_max_buy(selected_commodity, price, stock)
	else:
		max_qty = owned

	if max_qty < 1:
		_show_message("Cannot trade - check credits/cargo/stock", Color(0.9, 0.3, 0.3))
		return

	# Create trade panel
	trade_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	style.border_color = Color(0.3, 0.5, 0.8)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	trade_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)

	# Title
	var title := Label.new()
	title.text = "%s %s" % ["Buy" if is_buying else "Sell", selected_commodity.commodity_name]
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Quantity row
	var qty_row := HBoxContainer.new()
	qty_row.add_theme_constant_override("separation", 10)

	var qty_title := Label.new()
	qty_title.text = "Quantity:"
	qty_title.add_theme_font_size_override("font_size", 14)
	qty_row.add_child(qty_title)

	quantity_slider = HSlider.new()
	quantity_slider.min_value = 1
	quantity_slider.max_value = max_qty
	quantity_slider.value = max_qty
	quantity_slider.step = 1
	quantity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_slider.value_changed.connect(_on_quantity_changed.bind(price))
	qty_row.add_child(quantity_slider)

	quantity_label = Label.new()
	quantity_label.text = str(max_qty)
	quantity_label.custom_minimum_size.x = 50
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.add_theme_font_size_override("font_size", 16)
	qty_row.add_child(quantity_label)

	vbox.add_child(qty_row)

	# Total row
	total_label = Label.new()
	var total := max_qty * price
	total_label.text = "Total: %s cr" % _format_number(total)
	total_label.add_theme_font_size_override("font_size", 16)
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not is_buying:
		var purchase_price := GameState.player.get_purchase_price(selected_commodity.id)
		var profit := (price - purchase_price) * max_qty
		if profit > 0:
			total_label.text += " (+%d profit)" % profit
			total_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		elif profit < 0:
			total_label.text += " (%d loss)" % profit
			total_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	vbox.add_child(total_label)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(80, 35)
	cancel_btn.pressed.connect(_on_close_trade_panel)
	btn_row.add_child(cancel_btn)

	trade_action_btn = Button.new()
	trade_action_btn.text = "Buy" if is_buying else "Sell"
	trade_action_btn.custom_minimum_size = Vector2(80, 35)
	trade_action_btn.pressed.connect(_on_execute_trade)
	btn_row.add_child(trade_action_btn)

	vbox.add_child(btn_row)

	trade_panel.add_child(vbox)

	# Position panel
	trade_panel.position = Vector2(400, 250)
	add_child(trade_panel)

func _on_quantity_changed(value: float, price: int) -> void:
	var qty := int(value)
	quantity_label.text = str(qty)
	var total := qty * price
	total_label.text = "Total: %s cr" % _format_number(total)

	if not is_buying:
		var purchase_price := GameState.player.get_purchase_price(selected_commodity.id)
		var profit := (price - purchase_price) * qty
		if profit > 0:
			total_label.text += " (+%d profit)" % profit
			total_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		elif profit < 0:
			total_label.text += " (%d loss)" % profit
			total_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			total_label.add_theme_color_override("font_color", Color(1, 1, 1))

func _on_close_trade_panel() -> void:
	if trade_panel != null:
		trade_panel.queue_free()
		trade_panel = null
	selected_commodity = null

func _on_execute_trade() -> void:
	if selected_commodity == null or quantity_slider == null:
		return

	var qty := int(quantity_slider.value)
	if is_buying:
		_on_buy_pressed(selected_commodity.id, qty)
	else:
		_on_sell_pressed(selected_commodity.id, qty)

	_on_close_trade_panel()

func _on_buy_pressed(commodity_id: String, quantity: int) -> void:
	if quantity < 1:
		return
	var result := GameState.buy_commodity(commodity_id, quantity)
	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.8, 0.4))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_header()
	_build_commodity_rows()

func _on_sell_pressed(commodity_id: String, quantity: int) -> void:
	if quantity < 1:
		return
	var result := GameState.sell_commodity(commodity_id, quantity)
	if result["success"]:
		var color := Color(0.4, 0.8, 0.4)
		if result.has("profit"):
			if result["profit"] > 0:
				color = Color(0.3, 0.95, 0.3)
			elif result["profit"] < 0:
				color = Color(0.95, 0.7, 0.3)
		_show_message(result["message"], color)

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
