extends Node

# GameState - Manages current game session and persistence

const SAVE_PATH := "user://savegame.json"

var player: Player = null
var price_drifts: Dictionary = {}  # {planet_id: {commodity_id: float}}
var is_game_active := false

signal game_started()
signal game_ended(won: bool)
signal day_advanced(new_day: int)
signal player_traveled(from_planet: String, to_planet: String)

func _ready() -> void:
	pass

func new_game() -> void:
	player = Player.new()
	player.ship = DataRepo.get_starting_ship()
	player.fuel = player.ship.fuel_capacity
	_init_price_drifts()
	is_game_active = true
	game_started.emit()
	print("GameState: New game started")

func _init_price_drifts() -> void:
	price_drifts.clear()
	for planet_id in DataRepo.get_all_planet_ids():
		price_drifts[planet_id] = {}
		for commodity_id in DataRepo.get_all_commodity_ids():
			price_drifts[planet_id][commodity_id] = 0.0

func get_price_at(planet_id: String, commodity_id: String) -> int:
	var planet := DataRepo.get_planet(planet_id)
	var commodity := DataRepo.get_commodity(commodity_id)
	if planet == null or commodity == null:
		return 0
	var drift: float = price_drifts.get(planet_id, {}).get(commodity_id, 0.0)
	return commodity.get_price_at(planet, drift)

func advance_day(days: int = 1) -> void:
	if player == null:
		return
	player.day += days
	_drift_prices()
	day_advanced.emit(player.day)

func _drift_prices() -> void:
	# Prices drift slightly each day based on volatility
	for planet_id in price_drifts:
		var planet := DataRepo.get_planet(planet_id)
		if planet == null:
			continue
		for commodity_id in price_drifts[planet_id]:
			var current_drift: float = price_drifts[planet_id][commodity_id]
			var volatility: float = planet.supply_volatility
			# Random walk with mean reversion
			var change := randf_range(-volatility, volatility)
			var new_drift: float = current_drift + change
			# Mean reversion - pull back toward 0
			new_drift *= 0.95
			# Clamp to reasonable bounds
			new_drift = clampf(new_drift, -0.5, 0.5)
			price_drifts[planet_id][commodity_id] = new_drift

func travel_to(planet_id: String) -> Dictionary:
	# Returns {success: bool, message: String, event: GameEvent or null}
	if player == null:
		return {"success": false, "message": "No active game", "event": null}

	var current := DataRepo.get_planet(player.current_planet)
	var destination := DataRepo.get_planet(planet_id)

	if current == null or destination == null:
		return {"success": false, "message": "Invalid planet", "event": null}

	if player.current_planet == planet_id:
		return {"success": false, "message": "Already at this planet", "event": null}

	var distance := current.get_distance_to(planet_id)
	var fuel_cost := player.ship.get_fuel_cost(distance)

	if player.fuel < fuel_cost:
		return {"success": false, "message": "Not enough fuel (need %d)" % fuel_cost, "event": null}

	# Consume fuel
	player.use_fuel(fuel_cost)

	# Move player
	var from_planet := player.current_planet
	player.travel_to(planet_id, distance)

	# Advance time
	_drift_prices()

	player_traveled.emit(from_planet, planet_id)

	# Check for random event
	var event := EventManager.roll_event("travel")

	return {
		"success": true,
		"message": "Traveled to %s (-%d fuel, %d days)" % [destination.planet_name, fuel_cost, distance],
		"event": event
	}

func buy_commodity(commodity_id: String, quantity: int) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active game"}

	var commodity := DataRepo.get_commodity(commodity_id)
	if commodity == null:
		return {"success": false, "message": "Unknown commodity"}

	var price := get_price_at(player.current_planet, commodity_id)
	var total_cost := price * quantity
	var weight := commodity.weight_per_unit * quantity

	if player.credits < total_cost:
		return {"success": false, "message": "Not enough credits (need %d)" % total_cost}

	if player.get_cargo_space_free() < weight:
		return {"success": false, "message": "Not enough cargo space (need %d)" % weight}

	player.spend_credits(total_cost)
	player.add_cargo(commodity_id, quantity)
	player.statistics["trades_made"] += 1

	return {"success": true, "message": "Bought %d %s for %d credits" % [quantity, commodity.commodity_name, total_cost]}

func sell_commodity(commodity_id: String, quantity: int) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active game"}

	var commodity := DataRepo.get_commodity(commodity_id)
	if commodity == null:
		return {"success": false, "message": "Unknown commodity"}

	if player.get_cargo_quantity(commodity_id) < quantity:
		return {"success": false, "message": "Not enough cargo"}

	var price := get_price_at(player.current_planet, commodity_id)
	var total_value := price * quantity

	player.remove_cargo(commodity_id, quantity)
	player.add_credits(total_value)
	player.statistics["trades_made"] += 1

	return {"success": true, "message": "Sold %d %s for %d credits" % [quantity, commodity.commodity_name, total_value]}

func buy_upgrade(upgrade_id: String) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active game"}

	var upgrade := DataRepo.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return {"success": false, "message": "Unknown upgrade"}

	if player.ship.has_upgrade(upgrade_id):
		return {"success": false, "message": "Already installed"}

	var cost: int = upgrade.get("cost", 0)
	if player.credits < cost:
		return {"success": false, "message": "Not enough credits (need %d)" % cost}

	# Check prerequisites
	var prereqs: Array = upgrade.get("requires", [])
	for prereq in prereqs:
		if not player.ship.has_upgrade(prereq):
			var prereq_upgrade := DataRepo.get_upgrade(prereq)
			var prereq_name: String = prereq_upgrade.get("name", prereq)
			return {"success": false, "message": "Requires: %s" % prereq_name}

	player.spend_credits(cost)
	player.ship.apply_upgrade(upgrade)

	return {"success": true, "message": "Installed %s" % upgrade.get("name", upgrade_id)}

func check_game_over() -> Dictionary:
	# Returns {game_over: bool, won: bool, reason: String}
	if player == null:
		return {"game_over": false, "won": false, "reason": ""}

	if player.has_won():
		is_game_active = false
		game_ended.emit(true)
		return {"game_over": true, "won": true, "reason": "You reached 100,000 credits!"}

	if player.is_stranded():
		is_game_active = false
		game_ended.emit(false)
		return {"game_over": true, "won": false, "reason": "You ran out of fuel and are stranded in space!"}

	if player.is_bankrupt():
		is_game_active = false
		game_ended.emit(false)
		return {"game_over": true, "won": false, "reason": "You went bankrupt!"}

	return {"game_over": false, "won": false, "reason": ""}

func save_game() -> bool:
	if player == null:
		return false

	var save_data := {
		"version": 1,
		"player": player.to_dict(),
		"price_drifts": price_drifts
	}

	var json_string := JSON.stringify(save_data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: Cannot save game")
		return false

	file.store_string(json_string)
	file.close()
	print("GameState: Game saved")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("GameState: Cannot parse save file")
		return false

	var save_data: Dictionary = json.data

	if save_data.get("version", 0) != 1:
		push_error("GameState: Incompatible save version")
		return false

	player = Player.from_dict(save_data.get("player", {}))
	price_drifts = save_data.get("price_drifts", {})
	is_game_active = true

	print("GameState: Game loaded")
	game_started.emit()
	return true

func has_save_game() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
