class_name NewsEvent
extends RefCounted

var id: String
var headline: String
var description: String
var category: String  # "economic", "political", "natural"
var start_day: int
var end_day: int
var effects: Dictionary

func _init(template: Dictionary = {}, current_day: int = 1) -> void:
	if template.is_empty():
		return
	id = template.get("id", "")
	headline = template.get("headline", "")
	description = template.get("description", "")
	category = template.get("category", "economic")
	start_day = current_day
	var duration_min: int = template.get("duration_min", 3)
	var duration_max: int = template.get("duration_max", 7)
	var duration := randi_range(duration_min, duration_max)
	end_day = current_day + duration
	effects = template.get("effects", {})

func is_expired(current_day: int) -> bool:
	return current_day > end_day

func affects_planet(planet_id: String) -> bool:
	var planets = effects.get("planets", [])
	if planets is String and planets == "*":
		return true
	return planet_id in planets

func affects_commodity(commodity_id: String) -> bool:
	var commodities = effects.get("commodities", [])
	if commodities is String and commodities == "*":
		return true
	return commodity_id in commodities

func get_price_modifier() -> float:
	return effects.get("price_modifier", 1.0)

func get_stock_modifier() -> float:
	return effects.get("stock_modifier", 1.0)

func get_travel_time_modifier() -> float:
	return effects.get("travel_time_modifier", 1.0)

func blocks_access() -> bool:
	return effects.get("access_blocked", false)

func get_event_chance_modifier() -> float:
	return effects.get("event_chance_modifier", 1.0)

func days_remaining(current_day: int) -> int:
	return max(0, end_day - current_day)

func get_affected_planets_list() -> Array:
	var planets = effects.get("planets", [])
	if planets is String and planets == "*":
		return ["All Locations"]
	return planets

func get_affected_commodities_list() -> Array:
	var commodities = effects.get("commodities", [])
	if commodities is String and commodities == "*":
		return ["All Goods"]
	return commodities

func to_dict() -> Dictionary:
	return {
		"id": id,
		"headline": headline,
		"description": description,
		"category": category,
		"start_day": start_day,
		"end_day": end_day,
		"effects": effects
	}

static func from_dict(data: Dictionary) -> NewsEvent:
	var event := NewsEvent.new({}, 0)
	event.id = data.get("id", "")
	event.headline = data.get("headline", "")
	event.description = data.get("description", "")
	event.category = data.get("category", "economic")
	event.start_day = data.get("start_day", 1)
	event.end_day = data.get("end_day", 1)
	event.effects = data.get("effects", {})
	return event
