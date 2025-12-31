class_name Bot
extends RefCounted

# Bot opponent for competition mode
# Based on Player but with AI-specific fields

enum Personality { VULTURE, SPEEDRUNNER, GAMBLER, STEADY }

var id: String
var bot_name: String
var personality: Personality
var color: Color
var backstory: String

# State (similar to Player)
var credits: int
var cargo: Dictionary  # {commodity_id: quantity}
var fuel: int
var current_planet: String
var destination_planet: String  # null if not traveling
var days_until_arrival: int
var is_eliminated: bool

# Ship (simplified - bots start with basic ship)
var cargo_capacity: int
var fuel_capacity: int
var fuel_efficiency: float  # fuel per distance unit

# AI Memory
var price_memory: Dictionary  # {planet_id: {commodity_id: {price: int, day: int}}}
var price_memory_duration: int  # How many days bot remembers prices

# Statistics
var statistics: Dictionary

signal credits_changed(new_amount: int)
signal location_changed(new_planet: String)
signal eliminated()

func _init() -> void:
	id = ""
	bot_name = ""
	personality = Personality.STEADY
	color = Color.WHITE
	backstory = ""
	credits = 1000
	cargo = {}
	fuel = 50
	current_planet = "earth"
	destination_planet = ""
	days_until_arrival = 0
	is_eliminated = false
	cargo_capacity = 100
	fuel_capacity = 100
	fuel_efficiency = 1.0
	price_memory = {}
	price_memory_duration = 15  # Medium difficulty default
	statistics = {
		"trades_made": 0,
		"distance_traveled": 0,
		"events_survived": 0,
		"credits_earned": 0,
		"credits_spent": 0,
		"biggest_trade_profit": 0
	}

static func create(bot_data: Dictionary, difficulty: String) -> Bot:
	var bot: Bot = Bot.new()
	bot.id = bot_data.get("id", "bot_%d" % randi())
	bot.bot_name = bot_data.get("name", "Unknown Trader")
	bot.backstory = bot_data.get("backstory", "")

	# Parse personality
	var personality_str: String = bot_data.get("personality", "steady")
	match personality_str.to_lower():
		"vulture":
			bot.personality = Personality.VULTURE
		"speedrunner":
			bot.personality = Personality.SPEEDRUNNER
		"gambler":
			bot.personality = Personality.GAMBLER
		_:
			bot.personality = Personality.STEADY

	# Parse color
	var color_str: String = bot_data.get("color", "#ffffff")
	bot.color = Color.html(color_str)

	# Set difficulty-based parameters
	match difficulty:
		"easy":
			bot.credits = 500
			bot.price_memory_duration = 5
		"medium":
			bot.credits = 1000
			bot.price_memory_duration = 15
		"hard":
			bot.credits = 2000
			bot.price_memory_duration = 30

	# Standard bot ship stats
	bot.cargo_capacity = 100
	bot.fuel_capacity = 100
	bot.fuel = bot.fuel_capacity
	bot.fuel_efficiency = 1.0

	# Random starting planet (not all on Earth)
	var starting_planets := ["earth", "mars", "venus", "mercury"]
	bot.current_planet = starting_planets[randi() % starting_planets.size()]

	return bot

func is_traveling() -> bool:
	return destination_planet != "" and days_until_arrival > 0

func get_cargo_weight() -> int:
	var total := 0
	for commodity_id in cargo:
		var qty: int = cargo[commodity_id]
		total += qty * 2  # Assume avg weight 2 per unit
	return total

func get_cargo_space_free() -> int:
	return cargo_capacity - get_cargo_weight()

func add_cargo(commodity_id: String, quantity: int) -> void:
	if cargo.has(commodity_id):
		cargo[commodity_id] += quantity
	else:
		cargo[commodity_id] = quantity

func remove_cargo(commodity_id: String, quantity: int) -> bool:
	if not cargo.has(commodity_id):
		return false
	if cargo[commodity_id] < quantity:
		return false
	cargo[commodity_id] -= quantity
	if cargo[commodity_id] <= 0:
		cargo.erase(commodity_id)
	return true

func get_cargo_quantity(commodity_id: String) -> int:
	return cargo.get(commodity_id, 0)

func get_total_cargo_value_at(planet_id: String, game_state) -> int:
	var total := 0
	for commodity_id in cargo:
		var qty: int = cargo[commodity_id]
		var price: int = game_state.get_price_at(planet_id, commodity_id)
		total += price * qty
	return total

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
	return true

func add_fuel(amount: int) -> void:
	fuel = mini(fuel + amount, fuel_capacity)

func get_fuel_cost(distance: int) -> int:
	return int(ceil(distance * fuel_efficiency))

func start_travel(planet_id: String, distance: int) -> void:
	destination_planet = planet_id
	days_until_arrival = distance
	var fuel_cost: int = get_fuel_cost(distance)
	use_fuel(fuel_cost)
	statistics["distance_traveled"] += distance

func advance_travel(days: int) -> bool:
	# Returns true if arrived at destination
	if not is_traveling():
		return false

	days_until_arrival -= days
	if days_until_arrival <= 0:
		current_planet = destination_planet
		destination_planet = ""
		days_until_arrival = 0
		location_changed.emit(current_planet)
		return true
	return false

# Memory functions for AI
func remember_price(planet_id: String, commodity_id: String, price: int, day: int) -> void:
	if not price_memory.has(planet_id):
		price_memory[planet_id] = {}
	price_memory[planet_id][commodity_id] = {"price": price, "day": day}

func recall_price(planet_id: String, commodity_id: String, current_day: int) -> int:
	# Returns remembered price or -1 if forgotten/unknown
	if not price_memory.has(planet_id):
		return -1
	if not price_memory[planet_id].has(commodity_id):
		return -1

	var memory: Dictionary = price_memory[planet_id][commodity_id]
	var age: int = current_day - memory["day"]

	if age > price_memory_duration:
		return -1  # Memory expired

	return memory["price"]

func forget_old_prices(current_day: int) -> void:
	for planet_id in price_memory:
		var to_forget: Array = []
		for commodity_id in price_memory[planet_id]:
			var memory: Dictionary = price_memory[planet_id][commodity_id]
			var age: int = current_day - memory["day"]
			if age > price_memory_duration:
				to_forget.append(commodity_id)
		for commodity_id in to_forget:
			price_memory[planet_id].erase(commodity_id)

func is_bankrupt() -> bool:
	if credits >= 0:
		return false
	# Check if bot has any cargo to sell
	for commodity_id in cargo:
		if cargo[commodity_id] > 0:
			return false
	return true

func eliminate() -> void:
	is_eliminated = true
	eliminated.emit()

func get_net_worth() -> int:
	return credits  # Bots don't use banking

func get_personality_name() -> String:
	match personality:
		Personality.VULTURE:
			return "Vulture"
		Personality.SPEEDRUNNER:
			return "Speedrunner"
		Personality.GAMBLER:
			return "Gambler"
		Personality.STEADY:
			return "Steady"
	return "Unknown"

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": bot_name,
		"personality": get_personality_name().to_lower(),
		"color": color.to_html(),
		"backstory": backstory,
		"credits": credits,
		"cargo": cargo.duplicate(),
		"fuel": fuel,
		"current_planet": current_planet,
		"destination_planet": destination_planet,
		"days_until_arrival": days_until_arrival,
		"is_eliminated": is_eliminated,
		"cargo_capacity": cargo_capacity,
		"fuel_capacity": fuel_capacity,
		"fuel_efficiency": fuel_efficiency,
		"price_memory": price_memory.duplicate(true),
		"price_memory_duration": price_memory_duration,
		"statistics": statistics.duplicate()
	}

static func from_dict(data: Dictionary) -> Bot:
	var bot: Bot = Bot.new()
	bot.id = data.get("id", "")
	bot.bot_name = data.get("name", "Unknown")
	bot.backstory = data.get("backstory", "")
	bot.credits = data.get("credits", 1000)
	bot.cargo = data.get("cargo", {})
	bot.fuel = data.get("fuel", 50)
	bot.current_planet = data.get("current_planet", "earth")
	bot.destination_planet = data.get("destination_planet", "")
	bot.days_until_arrival = data.get("days_until_arrival", 0)
	bot.is_eliminated = data.get("is_eliminated", false)
	bot.cargo_capacity = data.get("cargo_capacity", 100)
	bot.fuel_capacity = data.get("fuel_capacity", 100)
	bot.fuel_efficiency = data.get("fuel_efficiency", 1.0)
	bot.price_memory = data.get("price_memory", {})
	bot.price_memory_duration = data.get("price_memory_duration", 15)
	bot.statistics = data.get("statistics", bot.statistics)

	# Parse personality
	var personality_str: String = data.get("personality", "steady")
	match personality_str.to_lower():
		"vulture":
			bot.personality = Bot.Personality.VULTURE
		"speedrunner":
			bot.personality = Bot.Personality.SPEEDRUNNER
		"gambler":
			bot.personality = Bot.Personality.GAMBLER
		_:
			bot.personality = Bot.Personality.STEADY

	# Parse color
	var color_str: String = data.get("color", "#ffffff")
	bot.color = Color.html(color_str)

	return bot
