class_name Commodity
extends RefCounted

var id: String
var commodity_name: String
var category: String
var base_price: int
var weight_per_unit: int
var volatility: String  # "low", "medium", "high", "very_high", "extreme"
var legality: String
var exclusive_to: Array  # Planet IDs where this can be bought, empty = everywhere
var description: String

# Volatility ranges: how much prices can swing from base
const VOLATILITY_RANGES: Dictionary = {
	"low": {"min": 0.7, "max": 1.3},
	"medium": {"min": 0.5, "max": 1.5},
	"high": {"min": 0.3, "max": 2.0},
	"very_high": {"min": 0.2, "max": 3.0},
	"extreme": {"min": 0.1, "max": 5.0}
}

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	id = data.get("id", "")
	commodity_name = data.get("name", "")
	category = data.get("category", "")
	base_price = data.get("base_price", 100)
	weight_per_unit = data.get("weight_per_unit", 1)
	volatility = data.get("volatility", "medium")
	legality = data.get("legality", "legal")
	exclusive_to = data.get("exclusive_to", [])
	description = data.get("description", "")

func is_available_at(planet_id: String) -> bool:
	if exclusive_to.is_empty():
		return true
	return planet_id in exclusive_to

func get_volatility_range() -> Dictionary:
	return VOLATILITY_RANGES.get(volatility, VOLATILITY_RANGES["medium"])

func is_contraband() -> bool:
	return legality == "contraband"

func get_price_at(planet: Planet, price_drift: float = 0.0) -> int:
	var modifier := planet.get_price_modifier(id)

	# Apply volatility-based price swing
	# price_drift is in range [-0.5, 0.5], map it to volatility range
	var vol_range := get_volatility_range()
	var vol_min: float = vol_range["min"]
	var vol_max: float = vol_range["max"]

	# Map drift [-0.5, 0.5] to volatility multiplier [min, max]
	# drift of -0.5 -> min, drift of 0 -> 1.0, drift of 0.5 -> max
	var volatility_multiplier: float
	if price_drift < 0:
		# Negative drift: interpolate from min to 1.0
		volatility_multiplier = lerpf(1.0, vol_min, absf(price_drift) * 2.0)
	else:
		# Positive drift: interpolate from 1.0 to max
		volatility_multiplier = lerpf(1.0, vol_max, price_drift * 2.0)

	var price := base_price * modifier * volatility_multiplier
	return int(max(1, round(price)))
