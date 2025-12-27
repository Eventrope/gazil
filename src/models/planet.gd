class_name Planet
extends RefCounted

var id: String
var planet_name: String
var description: String
var distance_from: Dictionary  # {planet_id: int}
var price_modifiers: Dictionary  # {commodity_id: float}
var supply_volatility: float
var unlock_day: int
var category: String  # "inner_system", "outer_system", "belt", "station"
var base_stock: Dictionary  # {commodity_id: int}
var stock_regen_rate: Dictionary  # {commodity_id: float}
var fuel_price_modifier: float

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	id = data.get("id", "")
	planet_name = data.get("name", "")
	description = data.get("description", "")
	distance_from = data.get("distance_from", {})
	price_modifiers = data.get("price_modifiers", {})
	supply_volatility = data.get("supply_volatility", 0.1)
	unlock_day = data.get("unlock_day", 0)
	category = data.get("category", "inner_system")
	base_stock = data.get("base_stock", {})
	stock_regen_rate = data.get("stock_regen_rate", {})
	fuel_price_modifier = data.get("fuel_price_modifier", 1.0)

func get_distance_to(planet_id: String) -> int:
	return distance_from.get(planet_id, 999)

func get_price_modifier(commodity_id: String) -> float:
	return price_modifiers.get(commodity_id, 1.0)

func is_unlocked(current_day: int) -> bool:
	return current_day >= unlock_day

func get_base_stock(commodity_id: String) -> int:
	return base_stock.get(commodity_id, 100)

func get_stock_regen(commodity_id: String) -> float:
	return stock_regen_rate.get(commodity_id, 10.0)
