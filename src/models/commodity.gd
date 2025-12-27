class_name Commodity
extends RefCounted

var id: String
var commodity_name: String
var base_price: int
var weight_per_unit: int
var legality: String
var description: String

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	id = data.get("id", "")
	commodity_name = data.get("name", "")
	base_price = data.get("base_price", 100)
	weight_per_unit = data.get("weight_per_unit", 1)
	legality = data.get("legality", "legal")
	description = data.get("description", "")

func get_price_at(planet: Planet, price_drift: float = 0.0) -> int:
	var modifier := planet.get_price_modifier(id)
	var price := base_price * modifier * (1.0 + price_drift)
	return int(max(1, round(price)))
