class_name Planet
extends RefCounted

var id: String
var planet_name: String
var description: String
var distance_from: Dictionary  # {planet_id: int}
var price_modifiers: Dictionary  # {commodity_id: float}
var supply_volatility: float

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	id = data.get("id", "")
	planet_name = data.get("name", "")
	description = data.get("description", "")
	distance_from = data.get("distance_from", {})
	price_modifiers = data.get("price_modifiers", {})
	supply_volatility = data.get("supply_volatility", 0.1)

func get_distance_to(planet_id: String) -> int:
	return distance_from.get(planet_id, 999)

func get_price_modifier(commodity_id: String) -> float:
	return price_modifiers.get(commodity_id, 1.0)
