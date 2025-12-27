extends Node

# EventManager - Handles random event selection and resolution

const EVENT_CHANCE := 0.35  # 35% chance of event during travel

var rng := RandomNumberGenerator.new()
var current_event: GameEvent = null

signal event_triggered(event: GameEvent)
signal event_resolved(outcome: Dictionary)

func _ready() -> void:
	rng.randomize()

func set_seed(seed_value: int) -> void:
	rng.seed = seed_value

func roll_event(trigger: String) -> GameEvent:
	# Check if event triggers at all
	if rng.randf() > EVENT_CHANCE:
		return null

	var possible_events := DataRepo.get_events_for_trigger(trigger)
	if possible_events.is_empty():
		return null

	# Filter events by conditions
	var valid_events: Array[GameEvent] = []
	var total_weight := 0.0

	for event in possible_events:
		if event.check_conditions(GameState.player):
			valid_events.append(event)
			total_weight += event.weight

	if valid_events.is_empty():
		return null

	# Weighted random selection
	var roll := rng.randf() * total_weight
	var cumulative := 0.0

	for event in valid_events:
		cumulative += event.weight
		if roll <= cumulative:
			current_event = event
			event_triggered.emit(event)
			return event

	return null

func execute_choice(choice_index: int) -> Dictionary:
	# Returns {success: bool, message: String, effects: Dictionary}
	if current_event == null:
		return {"success": false, "message": "No active event", "effects": {}}

	if choice_index < 0 or choice_index >= current_event.choices.size():
		return {"success": false, "message": "Invalid choice", "effects": {}}

	var choice: Dictionary = current_event.choices[choice_index]
	var outcome: Dictionary

	# Check if this choice has a success chance
	if choice.has("success_chance"):
		var chance: float = choice["success_chance"]
		var roll := rng.randf()
		if roll <= chance:
			outcome = choice.get("outcome_success", {})
		else:
			outcome = choice.get("outcome_failure", {})
	else:
		outcome = choice.get("outcome", {})

	# Apply outcome effects
	var effects := _apply_outcome(outcome)

	var result := {
		"success": true,
		"message": outcome.get("message", ""),
		"effects": effects
	}

	GameState.player.statistics["events_survived"] += 1
	current_event = null
	event_resolved.emit(result)

	return result

func _apply_outcome(outcome: Dictionary) -> Dictionary:
	var effects := {}
	var player := GameState.player

	# Direct credit change
	if outcome.has("credits"):
		var amount: int = outcome["credits"]
		if amount > 0:
			player.add_credits(amount)
		else:
			player.spend_credits(-amount)
		effects["credits"] = amount

	# Percentage credit change
	if outcome.has("credits_percent"):
		var percent: float = outcome["credits_percent"]
		var amount := int(player.credits * abs(percent))
		if percent > 0:
			player.add_credits(amount)
		else:
			player.spend_credits(amount)
		effects["credits"] = amount * sign(percent)

	# Fuel change
	if outcome.has("fuel"):
		var amount: int = outcome["fuel"]
		if amount > 0:
			player.add_fuel(amount)
		else:
			player.use_fuel(-amount)
		effects["fuel"] = amount

	# Cargo loss (percentage)
	if outcome.has("cargo_percent"):
		var percent: float = abs(outcome["cargo_percent"])
		var lost_items := {}
		for commodity_id in player.cargo.keys():
			var qty: int = player.cargo[commodity_id]
			var loss := int(ceil(qty * percent))
			if loss > 0:
				player.remove_cargo(commodity_id, loss)
				lost_items[commodity_id] = loss
		effects["cargo_lost"] = lost_items

	# Random cargo gain
	if outcome.has("random_cargo"):
		var cargo_range: Dictionary = outcome["random_cargo"]
		var min_qty: int = cargo_range.get("min", 1)
		var max_qty: int = cargo_range.get("max", 5)
		var qty := rng.randi_range(min_qty, max_qty)

		# Pick a random commodity
		var commodities := DataRepo.get_all_commodity_ids()
		if not commodities.is_empty():
			var commodity_id: String = commodities[rng.randi() % commodities.size()]
			# Check if player has space
			var commodity := DataRepo.get_commodity(commodity_id)
			var weight := commodity.weight_per_unit * qty
			if player.get_cargo_space_free() >= weight:
				player.add_cargo(commodity_id, qty)
				effects["cargo_gained"] = {commodity_id: qty}

	# Sell bonus (temporary flag for next sale)
	if outcome.has("sell_bonus"):
		effects["sell_bonus"] = outcome["sell_bonus"]
		# This would need to be handled by the market screen

	return effects

func get_current_event() -> GameEvent:
	return current_event

func has_active_event() -> bool:
	return current_event != null

func skip_event() -> void:
	current_event = null
