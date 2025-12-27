class_name Ship
extends RefCounted

# Identity
var id: String
var ship_name: String
var description: String
var price: int

# Cargo and Passengers
var cargo_tonnes: int
var passenger_berths: int

# Movement
var speed: int  # units per day

# Fuel
var fuel_tank: int
var fuel_burn_per_distance: float

# Crew
var min_crew: int
var crew_quality: int  # 1-5 scale

# Reliability and Automation
var reliability: int  # 0-100 percentage
var automation_level: int  # 0-3

# Modules and Traits
var module_slots_total: int
var trait_id: String

# Runtime State (modified during gameplay)
var upgrades_installed: Array[String]
var modules_installed: Array[String]

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return

	# Identity
	id = data.get("id", "unknown")
	ship_name = data.get("name", "Unknown Ship")
	description = data.get("description", "")
	price = data.get("price", 0)

	# Cargo and Passengers
	cargo_tonnes = data.get("cargo_tonnes", 20)
	passenger_berths = data.get("passenger_berths", 0)

	# Movement
	speed = data.get("speed", 4)

	# Fuel
	fuel_tank = data.get("fuel_tank", 100)
	fuel_burn_per_distance = data.get("fuel_burn_per_distance", 2.0)

	# Crew
	min_crew = data.get("min_crew", 1)
	crew_quality = data.get("crew_quality", 1)

	# Reliability and Automation
	reliability = data.get("reliability", 100)
	automation_level = data.get("automation_level", 0)

	# Modules and Traits
	module_slots_total = data.get("module_slots_total", 0)
	trait_id = data.get("trait_id", "")

	# Runtime state
	upgrades_installed = []
	modules_installed = []

func apply_upgrade(upgrade_data: Dictionary) -> void:
	var effects: Dictionary = upgrade_data.get("effects", {})

	# Cargo upgrades
	if effects.has("cargo_tonnes"):
		cargo_tonnes += int(effects["cargo_tonnes"])

	# Fuel upgrades
	if effects.has("fuel_tank"):
		fuel_tank += int(effects["fuel_tank"])
	if effects.has("fuel_burn_modifier"):
		fuel_burn_per_distance *= float(effects["fuel_burn_modifier"])

	upgrades_installed.append(upgrade_data["id"])

func has_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in upgrades_installed

func get_fuel_cost(distance: int) -> int:
	return int(ceil(distance * fuel_burn_per_distance))

func get_module_slots_free() -> int:
	return module_slots_total - modules_installed.size()

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": ship_name,
		"description": description,
		"price": price,
		"cargo_tonnes": cargo_tonnes,
		"passenger_berths": passenger_berths,
		"speed": speed,
		"fuel_tank": fuel_tank,
		"fuel_burn_per_distance": fuel_burn_per_distance,
		"min_crew": min_crew,
		"crew_quality": crew_quality,
		"reliability": reliability,
		"automation_level": automation_level,
		"module_slots_total": module_slots_total,
		"trait_id": trait_id,
		"upgrades_installed": upgrades_installed,
		"modules_installed": modules_installed
	}

static func from_dict(data: Dictionary) -> Ship:
	var ship := Ship.new(data)
	ship.upgrades_installed.assign(data.get("upgrades_installed", []))
	ship.modules_installed.assign(data.get("modules_installed", []))
	return ship
