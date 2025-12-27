extends Node

# Data Repository - Loads and provides access to all game data

var planets: Dictionary = {}  # {id: Planet}
var commodities: Dictionary = {}  # {id: Commodity}
var events: Array[GameEvent] = []
var news_event_templates: Array = []  # Raw template data for news events
var upgrades: Dictionary = {}  # {id: Dictionary}
var ships: Dictionary = {}  # {id: Dictionary}
var ship_traits: Dictionary = {}  # {id: Dictionary}

var _loaded := false

func _ready() -> void:
	_load_all_data()

func _load_all_data() -> void:
	_load_planets()
	_load_commodities()
	_load_events()
	_load_news_events()
	_load_upgrades()
	_load_ships()
	_load_ship_traits()
	_loaded = true
	print("DataRepo: Loaded %d planets, %d commodities, %d events, %d news events, %d upgrades, %d ships, %d traits" % [
		planets.size(), commodities.size(), events.size(), news_event_templates.size(),
		upgrades.size(), ships.size(), ship_traits.size()
	])

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("DataRepo: File not found: " + path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataRepo: Cannot open file: " + path)
		return null
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("DataRepo: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return null
	return json.data

func _load_planets() -> void:
	var data = _load_json("res://data/planets.json")
	if data == null or not data.has("planets"):
		return
	for planet_data in data["planets"]:
		var planet := Planet.new(planet_data)
		planets[planet.id] = planet

func _load_commodities() -> void:
	var data = _load_json("res://data/commodities.json")
	if data == null or not data.has("commodities"):
		return
	for commodity_data in data["commodities"]:
		var commodity := Commodity.new(commodity_data)
		commodities[commodity.id] = commodity

func _load_events() -> void:
	var data = _load_json("res://data/events.json")
	if data == null or not data.has("events"):
		return
	for event_data in data["events"]:
		var game_event := GameEvent.new(event_data)
		events.append(game_event)

func _load_news_events() -> void:
	var data = _load_json("res://data/news_events.json")
	if data == null or not data.has("news_events"):
		return
	news_event_templates = data["news_events"]

func _load_upgrades() -> void:
	var data = _load_json("res://data/upgrades.json")
	if data == null or not data.has("upgrades"):
		return
	for upgrade_data in data["upgrades"]:
		upgrades[upgrade_data["id"]] = upgrade_data

func _load_ships() -> void:
	var data = _load_json("res://data/ships.json")
	if data == null or not data.has("ships"):
		return
	for ship_data in data["ships"]:
		ships[ship_data["id"]] = ship_data

func _load_ship_traits() -> void:
	var data = _load_json("res://data/ship_traits.json")
	if data == null or not data.has("ship_traits"):
		return
	for trait_data in data["ship_traits"]:
		ship_traits[trait_data["id"]] = trait_data

# --- Public API ---

func get_planet(id: String) -> Planet:
	return planets.get(id, null)

func get_all_planets() -> Array:
	return planets.values()

func get_all_planet_ids() -> Array:
	return planets.keys()

func get_commodity(id: String) -> Commodity:
	return commodities.get(id, null)

func get_all_commodities() -> Array:
	return commodities.values()

func get_all_commodity_ids() -> Array:
	return commodities.keys()

func get_events_for_trigger(trigger: String) -> Array[GameEvent]:
	var result: Array[GameEvent] = []
	for event in events:
		if event.trigger == trigger:
			result.append(event)
	return result

func get_upgrade(id: String) -> Dictionary:
	return upgrades.get(id, {})

func get_all_upgrades() -> Array:
	return upgrades.values()

func get_available_upgrades(player: Player) -> Array:
	var available: Array = []
	for upgrade_id in upgrades:
		var upgrade: Dictionary = upgrades[upgrade_id]
		# Skip if already installed
		if player.ship.has_upgrade(upgrade_id):
			continue
		# Check prerequisites
		var prereqs: Array = upgrade.get("requires", [])
		var has_prereqs := true
		for prereq in prereqs:
			if not player.ship.has_upgrade(prereq):
				has_prereqs = false
				break
		if has_prereqs:
			available.append(upgrade)
	return available

func get_ship_template(id: String) -> Dictionary:
	return ships.get(id, {})

func get_all_ships() -> Array:
	return ships.values()

func get_all_ship_ids() -> Array:
	return ships.keys()

func get_starter_ships() -> Array[Ship]:
	var starters: Array[Ship] = []
	for ship_data in ships.values():
		if ship_data.get("is_starter", false):
			starters.append(Ship.new(ship_data))
	return starters

func create_ship(ship_id: String) -> Ship:
	var template: Dictionary = ships.get(ship_id, {})
	if template.is_empty():
		push_error("DataRepo: Unknown ship id: " + ship_id)
		return null
	return Ship.new(template)

func get_ship_trait(trait_id: String) -> Dictionary:
	return ship_traits.get(trait_id, {})

func get_commodity_weight(commodity_id: String) -> int:
	var commodity := get_commodity(commodity_id)
	if commodity:
		return commodity.weight_per_unit
	return 2  # Default weight

func get_news_event_templates() -> Array:
	return news_event_templates

func get_unlocked_planets(current_day: int) -> Array:
	var unlocked: Array = []
	for planet in planets.values():
		if planet.is_unlocked(current_day):
			unlocked.append(planet)
	return unlocked

func get_locked_planets(current_day: int) -> Array:
	var locked: Array = []
	for planet in planets.values():
		if not planet.is_unlocked(current_day):
			locked.append(planet)
	return locked
