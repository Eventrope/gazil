class_name Corporation
extends RefCounted

var id: String
var corp_name: String
var abbreviation: String
var archetype: String  # "mining", "research", "leisure", "gas_giant", "agricultural", "crossroads", "smuggler"
var home_planet: String
var secondary_planets: Array
var specialty_commodities: Array
var color: Color
var description: String
var is_underground: bool  # True for smuggler-type corps

# Economic influence modifiers
var price_discount: float  # Discount for high-standing players at corp planets
var price_penalty: float   # Penalty for low-standing players

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	id = data.get("id", "")
	corp_name = data.get("name", "")
	abbreviation = data.get("abbreviation", "")
	archetype = data.get("archetype", "crossroads")
	home_planet = data.get("home_planet", "")
	secondary_planets = data.get("secondary_planets", [])
	specialty_commodities = data.get("specialty_commodities", [])
	description = data.get("description", "")
	is_underground = data.get("is_underground", false)
	price_discount = data.get("price_discount", 0.1)  # 10% default
	price_penalty = data.get("price_penalty", 0.1)    # 10% default

	# Parse color from hex string
	var color_str: String = data.get("color", "#FFFFFF")
	color = Color.from_string(color_str, Color.WHITE)

func has_presence_at(planet_id: String) -> bool:
	return planet_id == home_planet or planet_id in secondary_planets

func is_home_planet(planet_id: String) -> bool:
	return planet_id == home_planet

func get_presence_level(planet_id: String) -> String:
	if planet_id == home_planet:
		return "primary"
	elif planet_id in secondary_planets:
		return "secondary"
	return "none"

func get_all_planets() -> Array:
	var planets := [home_planet]
	planets.append_array(secondary_planets)
	return planets

func is_specialty_commodity(commodity_id: String) -> bool:
	return commodity_id in specialty_commodities

func get_price_modifier_for_standing(standing: int) -> float:
	# Returns a multiplier: < 1.0 is discount, > 1.0 is penalty
	if standing >= 80:
		return 1.0 - price_discount  # e.g., 0.9 for 10% discount
	elif standing < 20:
		return 1.0 + price_penalty   # e.g., 1.1 for 10% penalty
	return 1.0

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": corp_name,
		"abbreviation": abbreviation,
		"archetype": archetype,
		"home_planet": home_planet,
		"secondary_planets": secondary_planets,
		"specialty_commodities": specialty_commodities,
		"color": "#" + color.to_html(false),
		"description": description,
		"is_underground": is_underground,
		"price_discount": price_discount,
		"price_penalty": price_penalty
	}

static func from_dict(data: Dictionary) -> Corporation:
	return Corporation.new(data)
