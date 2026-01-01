extends Control

# Left panel refs
@onready var title_label: Label = $MarginContainer/MainLayout/LeftPanel/Header/TitleLabel
@onready var day_label: Label = $MarginContainer/MainLayout/LeftPanel/Header/DayLabel
@onready var commodity_list: VBoxContainer = $MarginContainer/MainLayout/LeftPanel/ScrollContainer/CommodityList

# Right panel - Player info
@onready var credits_label: Label = $MarginContainer/MainLayout/RightPanel/PlayerInfo/PlayerInfoContent/CreditsRow/CreditsLabel
@onready var cargo_label: Label = $MarginContainer/MainLayout/RightPanel/PlayerInfo/PlayerInfoContent/CargoRow/CargoLabel

# Right panel - Trade panel
@onready var selected_name: Label = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/SelectedName
@onready var selected_category: Label = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/SelectedCategory
@onready var price_label: Label = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/PriceInfo/CurrentPriceRow/PriceLabel
@onready var range_label: Label = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/PriceInfo/RangeRow/RangeLabel
@onready var quantity_label: Label = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/QuantitySection/QuantityRow/QuantityLabel
@onready var quantity_slider: HSlider = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/QuantitySection/QuantitySlider
@onready var total_label: Label = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/QuantitySection/TotalRow/TotalLabel
@onready var buy_btn: Button = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/TradeButtons/BuyRow/BuyButton
@onready var buy_max_btn: Button = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/TradeButtons/BuyRow/BuyMaxButton
@onready var sell_btn: Button = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/TradeButtons/SellRow/SellButton
@onready var sell_all_btn: Button = $MarginContainer/MainLayout/RightPanel/TradePanel/TradePanelContent/TradeButtons/SellRow/SellAllButton
@onready var message_label: Label = $MarginContainer/MainLayout/RightPanel/MessageLabel

# State
var selected_commodity: Commodity = null
var selected_row: PanelContainer = null
var commodity_rows: Dictionary = {}  # commodity_id -> PanelContainer

# Colors
const COLOR_ROW_NORMAL := Color(0.1, 0.11, 0.14, 1.0)
const COLOR_ROW_HOVER := Color(0.14, 0.15, 0.19, 1.0)
const COLOR_ROW_SELECTED := Color(0.18, 0.22, 0.32, 1.0)
const COLOR_BORDER_SELECTED := Color(0.35, 0.5, 0.8, 1.0)
const COLOR_TEXT_DIM := Color(0.5, 0.52, 0.58, 1.0)
const COLOR_TEXT_NORMAL := Color(0.85, 0.87, 0.9, 1.0)
const COLOR_PROFIT := Color(0.3, 0.9, 0.3, 1.0)
const COLOR_LOSS := Color(0.9, 0.35, 0.35, 1.0)

func _ready() -> void:
	print("Market._ready() called")
	
	if GameState.player == null:
		push_error("Market: GameState.player is null!")
		return
	
	var planet := DataRepo.get_planet(GameState.player.current_planet)
	if planet == null:
		push_error("Market: Could not find planet: " + GameState.player.current_planet)
		return
	
	title_label.text = "Market - %s" % planet.planet_name
	day_label.text = "Day %d" % GameState.player.day
	
	_style_panels()
	_update_player_info()
	_build_commodity_rows()
	_update_trade_panel()
	
	print("Market._ready() completed")

func _style_panels() -> void:
	# Style the player info panel
	var player_panel: PanelContainer = $MarginContainer/MainLayout/RightPanel/PlayerInfo
	var player_style := StyleBoxFlat.new()
	player_style.bg_color = Color(0.1, 0.11, 0.14, 1.0)
	player_style.corner_radius_top_left = 6
	player_style.corner_radius_top_right = 6
	player_style.corner_radius_bottom_left = 6
	player_style.corner_radius_bottom_right = 6
	player_style.content_margin_left = 14
	player_style.content_margin_right = 14
	player_style.content_margin_top = 12
	player_style.content_margin_bottom = 12
	player_panel.add_theme_stylebox_override("panel", player_style)
	
	# Style the trade panel
	var trade_panel: PanelContainer = $MarginContainer/MainLayout/RightPanel/TradePanel
	var trade_style := StyleBoxFlat.new()
	trade_style.bg_color = Color(0.1, 0.11, 0.14, 1.0)
	trade_style.corner_radius_top_left = 6
	trade_style.corner_radius_top_right = 6
	trade_style.corner_radius_bottom_left = 6
	trade_style.corner_radius_bottom_right = 6
	trade_style.content_margin_left = 14
	trade_style.content_margin_right = 14
	trade_style.content_margin_top = 12
	trade_style.content_margin_bottom = 12
	trade_panel.add_theme_stylebox_override("panel", trade_style)

func _update_player_info() -> void:
	var player := GameState.player
	credits_label.text = "%s" % _format_number(player.credits)
	cargo_label.text = "%d/%d t" % [player.get_cargo_space_used(), player.ship.cargo_tonnes]

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
	print("_build_commodity_rows() called")
	
	# Clear existing rows - use get_children() snapshot to avoid issues
	var children := commodity_list.get_children()
	for child in children:
		commodity_list.remove_child(child)
		child.queue_free()
	commodity_rows.clear()
	
	var current_planet := GameState.player.current_planet
	var all_commodities := DataRepo.get_all_commodities()
	print("Found %d commodities, current planet: %s" % [all_commodities.size(), current_planet])
	
	var added_count: int = 0
	for commodity in all_commodities:
		# Filter: only show commodities available at this planet or owned by player
		var is_available: bool = commodity.is_available_at(current_planet)
		var owned: int = GameState.player.get_cargo_quantity(commodity.id)
		
		if not is_available and owned == 0:
			continue
		
		var row := _create_commodity_row(commodity)
		commodity_list.add_child(row)
		commodity_rows[commodity.id] = row
		added_count += 1
	
	print("Added %d commodity rows to list (children count: %d)" % [added_count, commodity_list.get_child_count()])

func _create_commodity_row(commodity: Commodity) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	
	# Check for active embargo on this commodity at this planet
	var has_embargo: bool = _check_embargo_warning(commodity.id)
	
	if has_embargo:
		style.bg_color = Color(0.18, 0.10, 0.10, 1.0)  # Red tint for embargoed
	else:
		style.bg_color = COLOR_ROW_NORMAL
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("commodity_id", commodity.id)
	
	# Connect mouse events
	panel.gui_input.connect(_on_row_input.bind(panel, commodity))
	panel.mouse_entered.connect(_on_row_hover.bind(panel, true))
	panel.mouse_exited.connect(_on_row_hover.bind(panel, false))
	
	var current_planet: String = GameState.player.current_planet
	var price: int = GameState.get_price_at(current_planet, commodity.id)
	var sell_price: int = GameState.get_sell_price_at(current_planet, commodity.id)
	var owned: int = GameState.player.get_cargo_quantity(commodity.id)
	var stock: int = GameState.get_stock_at(current_planet, commodity.id)
	var planet: Planet = DataRepo.get_planet(current_planet)
	var base_stock: int = planet.get_base_stock(commodity.id)
	var purchase_price: int = GameState.player.get_purchase_price(commodity.id)
	var is_available: bool = commodity.is_available_at(current_planet)
	
	var price_range: Dictionary = DataRepo.get_commodity_price_range(commodity.id)
	var price_quality: Dictionary = DataRepo.get_price_quality(price, commodity.id)
	var quality: float = price_quality["quality"]
	
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Name column
	var name_col := VBoxContainer.new()
	name_col.custom_minimum_size.x = 160
	name_col.add_theme_constant_override("separation", 1)
	name_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var name_label := Label.new()
	name_label.text = commodity.commodity_name
	if has_embargo:
		name_label.text += " [EMBARGO]"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if commodity.is_contraband():
		name_label.add_theme_color_override("font_color", Color(0.9, 0.45, 0.45))
	elif has_embargo:
		name_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
	else:
		name_label.add_theme_color_override("font_color", COLOR_TEXT_NORMAL)
	name_col.add_child(name_label)
	
	var cat_label := Label.new()
	cat_label.text = commodity.category
	cat_label.add_theme_font_size_override("font_size", 11)
	cat_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	cat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_col.add_child(cat_label)
	
	row.add_child(name_col)
	
	# Price column
	var price_col := VBoxContainer.new()
	price_col.custom_minimum_size.x = 100
	price_col.add_theme_constant_override("separation", 1)
	price_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var price_label := Label.new()
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if is_available:
		# Show buy price with sell price in smaller text
		price_label.text = "%d cr" % price
		var price_color: Color = _get_quality_color(quality)
		price_label.add_theme_color_override("font_color", price_color)

		# News indicator
		var news_effects: Dictionary = NewsManager.get_combined_effects(
			GameState.get_active_news_events(), current_planet, commodity.id
		)
		if news_effects["price_modifier"] > 1.0:
			price_label.text += " ↑"
		elif news_effects["price_modifier"] < 1.0:
			price_label.text += " ↓"
	else:
		price_label.text = "N/A"
		price_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)

	price_col.add_child(price_label)

	# Show sell price (95% of buy) below
	var sell_lbl := Label.new()
	sell_lbl.text = "sell: %d" % sell_price
	sell_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sell_lbl.add_theme_font_size_override("font_size", 10)
	sell_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	sell_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_col.add_child(sell_lbl)
	
	row.add_child(price_col)
	
	# Owned column
	var owned_col := VBoxContainer.new()
	owned_col.custom_minimum_size.x = 100
	owned_col.add_theme_constant_override("separation", 1)
	owned_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var owned_label := Label.new()
	owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owned_label.add_theme_font_size_override("font_size", 14)
	owned_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if owned > 0:
		owned_label.text = "%d" % owned
		owned_label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5))
		owned_col.add_child(owned_label)

		# Profit/loss indicator (uses sell price, not buy price)
		var profit_label := Label.new()
		var potential_profit: int = (sell_price - purchase_price) * owned
		if potential_profit > 0:
			profit_label.text = "+%d" % potential_profit
			profit_label.add_theme_color_override("font_color", COLOR_PROFIT)
		elif potential_profit < 0:
			profit_label.text = "%d" % potential_profit
			profit_label.add_theme_color_override("font_color", COLOR_LOSS)
		else:
			profit_label.text = "@%d" % purchase_price
			profit_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		profit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		profit_label.add_theme_font_size_override("font_size", 10)
		profit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		owned_col.add_child(profit_label)
	else:
		owned_label.text = "—"
		owned_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		owned_col.add_child(owned_label)
	
	row.add_child(owned_col)
	
	# Stock column
	var stock_label := Label.new()
	stock_label.custom_minimum_size.x = 70
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_label.add_theme_font_size_override("font_size", 14)
	stock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if is_available:
		stock_label.text = str(stock)
		var base_stock_float: float = float(base_stock)
		var stock_ratio: float = float(stock) / max(base_stock_float, 1.0)
		if stock_ratio > 0.7:
			stock_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		elif stock_ratio > 0.3:
			stock_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.35))
		else:
			stock_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	else:
		stock_label.text = "—"
		stock_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	
	row.add_child(stock_label)
	
	# Weight column
	var weight_label := Label.new()
	weight_label.custom_minimum_size.x = 50
	weight_label.text = "%dt" % commodity.weight_per_unit
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 13)
	weight_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	weight_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(weight_label)
	
	panel.add_child(row)
	return panel

func _on_row_hover(panel: PanelContainer, is_hovering: bool) -> void:
	if panel == selected_row:
		return  # Don't change selected row style
	
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.bg_color = COLOR_ROW_HOVER if is_hovering else COLOR_ROW_NORMAL

func _on_row_input(event: InputEvent, panel: PanelContainer, commodity: Commodity) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_select_commodity(panel, commodity)

func _select_commodity(panel: PanelContainer, commodity: Commodity) -> void:
	# Deselect previous
	if selected_row != null and selected_row != panel:
		var old_style := selected_row.get_theme_stylebox("panel") as StyleBoxFlat
		if old_style:
			old_style.bg_color = COLOR_ROW_NORMAL
			old_style.border_width_left = 0
			old_style.border_width_right = 0
			old_style.border_width_top = 0
			old_style.border_width_bottom = 0
	
	# Select new
	selected_row = panel
	selected_commodity = commodity
	
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.bg_color = COLOR_ROW_SELECTED
		style.border_color = COLOR_BORDER_SELECTED
		style.border_width_left = 2
		style.border_width_right = 0
		style.border_width_top = 0
		style.border_width_bottom = 0
	
	_update_trade_panel()

func _update_trade_panel() -> void:
	if selected_commodity == null:
		selected_name.text = "Select a commodity"
		selected_category.text = ""
		price_label.text = "— cr"
		range_label.text = "—"
		quantity_label.text = "0"
		total_label.text = "— cr"
		quantity_slider.editable = false
		buy_btn.disabled = true
		buy_max_btn.disabled = true
		sell_btn.disabled = true
		sell_all_btn.disabled = true
		return
	
	var current_planet: String = GameState.player.current_planet
	var price: int = GameState.get_price_at(current_planet, selected_commodity.id)
	var owned: int = GameState.player.get_cargo_quantity(selected_commodity.id)
	var stock: int = GameState.get_stock_at(current_planet, selected_commodity.id)
	var is_available: bool = selected_commodity.is_available_at(current_planet)
	var price_range: Dictionary = DataRepo.get_commodity_price_range(selected_commodity.id)
	var price_quality: Dictionary = DataRepo.get_price_quality(price, selected_commodity.id)
	var quality: float = price_quality["quality"]
	
	# Update labels
	selected_name.text = selected_commodity.commodity_name
	selected_category.text = selected_commodity.category
	
	if is_available:
		price_label.text = "%d cr" % price
		price_label.add_theme_color_override("font_color", _get_quality_color(quality))
	else:
		price_label.text = "N/A"
		price_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	
	var range_min: int = price_range["min_price"]
	var range_max: int = price_range["max_price"]
	range_label.text = "%d – %d" % [range_min, range_max]
	
	# Calculate max buy
	var max_buy: int = _calculate_max_buy(selected_commodity, price, stock) if is_available else 0
	
	# Setup slider for buying (default mode)
	if max_buy > 0:
		quantity_slider.min_value = 1
		quantity_slider.max_value = max_buy
		quantity_slider.value = max_buy
		quantity_slider.editable = true
		quantity_label.text = str(max_buy)
		total_label.text = "%s cr" % _format_number(max_buy * price)
	else:
		quantity_slider.min_value = 1
		quantity_slider.max_value = 1
		quantity_slider.value = 1
		quantity_slider.editable = false
		quantity_label.text = "0"
		total_label.text = "— cr"
	
	# Enable/disable buttons
	buy_btn.disabled = max_buy < 1
	buy_max_btn.disabled = max_buy < 1
	buy_max_btn.text = "Buy Max" if max_buy < 1 else "Max (%d)" % max_buy
	sell_btn.disabled = owned < 1
	sell_all_btn.disabled = owned < 1
	sell_all_btn.text = "Sell All" if owned < 1 else "All (%d)" % owned

func _calculate_max_buy(commodity: Commodity, price: int, stock: int) -> int:
	var player := GameState.player
	var affordable: int = player.credits / max(price, 1)
	var space: int = player.get_cargo_space_free() / max(commodity.weight_per_unit, 1)
	return mini(mini(affordable, space), stock)

func _get_quality_color(quality: float) -> Color:
	if quality <= 0.15:
		return Color(0.25, 0.95, 0.35)  # Bright green - excellent
	elif quality <= 0.35:
		return Color(0.55, 0.9, 0.35)   # Yellow-green - good
	elif quality <= 0.65:
		return Color(0.9, 0.85, 0.35)   # Yellow - fair
	elif quality <= 0.85:
		return Color(0.95, 0.6, 0.35)   # Orange - poor
	else:
		return Color(0.95, 0.35, 0.35)  # Red - bad

func _on_quantity_changed(value: float) -> void:
	if selected_commodity == null:
		return
	
	var qty: int = int(value)
	var current_planet: String = GameState.player.current_planet
	var price: int = GameState.get_price_at(current_planet, selected_commodity.id)
	
	quantity_label.text = str(qty)
	total_label.text = "%s cr" % _format_number(qty * price)

func _on_buy_pressed() -> void:
	if selected_commodity == null:
		return
	var qty: int = int(quantity_slider.value)
	_execute_buy(selected_commodity.id, qty)

func _on_buy_max_pressed() -> void:
	if selected_commodity == null:
		return
	var current_planet: String = GameState.player.current_planet
	var price: int = GameState.get_price_at(current_planet, selected_commodity.id)
	var stock: int = GameState.get_stock_at(current_planet, selected_commodity.id)
	var max_buy: int = _calculate_max_buy(selected_commodity, price, stock)
	if max_buy > 0:
		_execute_buy(selected_commodity.id, max_buy)

func _on_sell_pressed() -> void:
	if selected_commodity == null:
		return
	var qty: int = int(quantity_slider.value)
	var owned: int = GameState.player.get_cargo_quantity(selected_commodity.id)
	# Clamp to owned amount
	qty = mini(qty, owned)
	if qty > 0:
		_execute_sell(selected_commodity.id, qty)

func _on_sell_all_pressed() -> void:
	if selected_commodity == null:
		return
	var owned: int = GameState.player.get_cargo_quantity(selected_commodity.id)
	if owned > 0:
		_execute_sell(selected_commodity.id, owned)

func _execute_buy(commodity_id: String, quantity: int) -> void:
	if quantity < 1:
		return
	var result: Dictionary = GameState.buy_commodity(commodity_id, quantity)
	if result["success"]:
		_show_message(result["message"], COLOR_PROFIT)
	else:
		_show_message(result["message"], COLOR_LOSS)
	_refresh_ui()

func _execute_sell(commodity_id: String, quantity: int) -> void:
	if quantity < 1:
		return
	var result: Dictionary = GameState.sell_commodity(commodity_id, quantity)
	if result["success"]:
		var color: Color = COLOR_PROFIT
		if result.has("profit"):
			var profit: int = result["profit"]
			if profit < 0:
				color = Color(0.95, 0.7, 0.35)  # Orange for loss
		_show_message(result["message"], color)
		
		var game_over: Dictionary = GameState.check_game_over()
		if game_over["game_over"]:
			get_tree().change_scene_to_file("res://scenes/game_over.tscn")
			return
	else:
		_show_message(result["message"], COLOR_LOSS)
	_refresh_ui()

func _refresh_ui() -> void:
	_update_player_info()
	_build_commodity_rows()
	
	# Re-select the commodity if it still exists
	if selected_commodity != null:
		if commodity_rows.has(selected_commodity.id):
			var panel: PanelContainer = commodity_rows[selected_commodity.id]
			_select_commodity(panel, selected_commodity)
		else:
			selected_commodity = null
			selected_row = null
			_update_trade_panel()

func _show_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")

func _on_main_menu_pressed() -> void:
	GameState.return_to_main_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _check_embargo_warning(commodity_id: String) -> bool:
	# Check if selling this commodity at this planet would violate an active embargo
	var player := GameState.player
	if player == null:
		return false

	for contract_data in player.active_contracts:
		var contract := Contract.from_dict(contract_data)
		if contract.type != Contract.Type.EMBARGO:
			continue
		if contract.status != Contract.Status.ACCEPTED:
			continue

		if commodity_id in contract.embargo_commodities and player.current_planet in contract.embargo_planets:
			return true

	return false
