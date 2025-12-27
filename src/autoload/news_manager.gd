extends Node

# NewsManager - Handles spawning and processing of galactic news events

const MAX_ACTIVE_EVENTS := 3
const NEW_EVENT_CHANCE := 0.25  # 25% chance per day

var rng := RandomNumberGenerator.new()

signal news_event_started(event: NewsEvent)
signal news_event_ended(event: NewsEvent)

func _ready() -> void:
	rng.randomize()

func process_day(current_day: int, active_events: Array) -> Dictionary:
	# Returns {expired: Array, new_event: NewsEvent or null}
	var result := {"expired": [], "new_event": null}

	# Check for expired events
	for event in active_events:
		if event.is_expired(current_day):
			result["expired"].append(event)
			news_event_ended.emit(event)

	# Possibly spawn new event
	var expired_count: int = result["expired"].size()
	var remaining_count: int = active_events.size() - expired_count
	if remaining_count < MAX_ACTIVE_EVENTS and rng.randf() < NEW_EVENT_CHANCE:
		result["new_event"] = _roll_new_event(current_day, active_events)
		if result["new_event"]:
			news_event_started.emit(result["new_event"])

	return result

func _roll_new_event(current_day: int, active_events: Array) -> NewsEvent:
	var templates := DataRepo.get_news_event_templates()
	var valid_templates: Array = []
	var total_weight := 0.0

	# Get IDs of currently active events
	var active_ids: Array = []
	for event in active_events:
		active_ids.append(event.id)

	for template in templates:
		# Check conditions
		var conditions: Dictionary = template.get("conditions", {})
		var min_day: int = conditions.get("min_day", 0)
		if current_day < min_day:
			continue

		# Check max concurrent
		var max_concurrent: int = conditions.get("max_concurrent", 1)
		var concurrent_count := active_ids.count(template["id"])
		if concurrent_count >= max_concurrent:
			continue

		valid_templates.append(template)
		total_weight += template.get("weight", 1.0)

	if valid_templates.is_empty():
		return null

	# Weighted random selection
	var roll := rng.randf() * total_weight
	var cumulative := 0.0

	for template in valid_templates:
		cumulative += template.get("weight", 1.0)
		if roll <= cumulative:
			return NewsEvent.new(template, current_day)

	return null

func get_combined_effects(active_events: Array, planet_id: String, commodity_id: String) -> Dictionary:
	var effects := {
		"price_modifier": 1.0,
		"stock_modifier": 1.0,
		"travel_time_modifier": 1.0,
		"access_blocked": false,
		"event_chance_modifier": 1.0
	}

	for event in active_events:
		if event.affects_planet(planet_id):
			if event.affects_commodity(commodity_id):
				effects["price_modifier"] *= event.get_price_modifier()
				effects["stock_modifier"] *= event.get_stock_modifier()
			effects["travel_time_modifier"] = maxf(effects["travel_time_modifier"], event.get_travel_time_modifier())
			effects["event_chance_modifier"] = maxf(effects["event_chance_modifier"], event.get_event_chance_modifier())
			if event.blocks_access():
				effects["access_blocked"] = true

	return effects

func is_planet_accessible(active_events: Array, planet_id: String) -> bool:
	for event in active_events:
		if event.affects_planet(planet_id) and event.blocks_access():
			return false
	return true

func get_travel_time_modifier(active_events: Array, from_planet_id: String, to_planet_id: String) -> float:
	var modifier := 1.0
	for event in active_events:
		if event.affects_planet(from_planet_id) or event.affects_planet(to_planet_id):
			modifier = maxf(modifier, event.get_travel_time_modifier())
	return modifier

func get_event_chance_modifier(active_events: Array, from_planet_id: String, to_planet_id: String) -> float:
	var modifier := 1.0
	for event in active_events:
		if event.affects_planet(from_planet_id) or event.affects_planet(to_planet_id):
			modifier = maxf(modifier, event.get_event_chance_modifier())
	return modifier
