class_name Player
extends RefCounted

var credits: int
var current_planet: String
var ship: Ship
var cargo: Dictionary  # {commodity_id: quantity}
var fuel: int
var day: int
var statistics: Dictionary

signal credits_changed(new_amount: int)
signal fuel_changed(new_amount: int)
signal cargo_changed()
signal location_changed(new_planet: String)

func _init() -> void:
	credits = 1000
	current_planet = "earth"
	ship = null
	cargo = {}
	fuel = 50
	day = 1
	statistics = {
		"trades_made": 0,
		"distance_traveled": 0,
		"events_survived": 0,
		"credits_earned": 0,
		"credits_spent": 0
	}

func get_cargo_weight() -> int:
	var total := 0
	for commodity_id in cargo:
		var qty: int = cargo[commodity_id]
		# Will need DataRepo to get weight - for now assume 2 per unit avg
		total += qty * 2
	return total

func get_cargo_space_used() -> int:
	return get_cargo_weight()

func get_cargo_space_free() -> int:
	if ship == null:
		return 0
	return ship.cargo_capacity - get_cargo_space_used()

func add_cargo(commodity_id: String, quantity: int) -> void:
	if cargo.has(commodity_id):
		cargo[commodity_id] += quantity
	else:
		cargo[commodity_id] = quantity
	cargo_changed.emit()

func remove_cargo(commodity_id: String, quantity: int) -> bool:
	if not cargo.has(commodity_id):
		return false
	if cargo[commodity_id] < quantity:
		return false
	cargo[commodity_id] -= quantity
	if cargo[commodity_id] <= 0:
		cargo.erase(commodity_id)
	cargo_changed.emit()
	return true

func get_cargo_quantity(commodity_id: String) -> int:
	return cargo.get(commodity_id, 0)

func add_credits(amount: int) -> void:
	credits += amount
	if amount > 0:
		statistics["credits_earned"] += amount
	credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	statistics["credits_spent"] += amount
	credits_changed.emit(credits)
	return true

func use_fuel(amount: int) -> bool:
	if fuel < amount:
		return false
	fuel -= amount
	fuel_changed.emit(fuel)
	return true

func add_fuel(amount: int) -> void:
	if ship:
		fuel = min(fuel + amount, ship.fuel_capacity)
	else:
		fuel += amount
	fuel_changed.emit(fuel)

func travel_to(planet_id: String, distance: int) -> void:
	current_planet = planet_id
	day += distance
	statistics["distance_traveled"] += distance
	location_changed.emit(planet_id)

func is_bankrupt() -> bool:
	if credits >= 0:
		return false
	# Check if player has any cargo to sell
	for commodity_id in cargo:
		if cargo[commodity_id] > 0:
			return false
	return true

func is_stranded() -> bool:
	return fuel <= 0

func has_won() -> bool:
	return credits >= 100000

func to_dict() -> Dictionary:
	return {
		"credits": credits,
		"current_planet": current_planet,
		"ship": ship.to_dict() if ship else {},
		"cargo": cargo.duplicate(),
		"fuel": fuel,
		"day": day,
		"statistics": statistics.duplicate()
	}

static func from_dict(data: Dictionary) -> Player:
	var player := Player.new()
	player.credits = data.get("credits", 1000)
	player.current_planet = data.get("current_planet", "earth")
	player.cargo = data.get("cargo", {})
	player.fuel = data.get("fuel", 50)
	player.day = data.get("day", 1)
	player.statistics = data.get("statistics", player.statistics)
	if data.has("ship") and not data["ship"].is_empty():
		player.ship = Ship.from_dict(data["ship"])
	return player
