class_name GameEvent
extends RefCounted

var id: String
var event_name: String
var description: String
var trigger: String  # "travel", "arrival", "departure"
var weight: float
var event_type: String  # "good", "bad", "neutral"
var conditions: Dictionary
var choices: Array

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	id = data.get("id", "")
	event_name = data.get("name", "")
	description = data.get("description", "")
	trigger = data.get("trigger", "travel")
	weight = data.get("weight", 1.0)
	event_type = data.get("type", "neutral")
	conditions = data.get("conditions", {})
	choices = data.get("choices", [])

func check_conditions(player: Player) -> bool:
	# Check if event can trigger based on player state
	if conditions.has("min_cargo_value"):
		var cargo_value := _estimate_cargo_value(player)
		if cargo_value < conditions["min_cargo_value"]:
			return false
	if conditions.has("min_credits"):
		if player.credits < conditions["min_credits"]:
			return false
	if conditions.has("min_fuel"):
		if player.fuel < conditions["min_fuel"]:
			return false
	return true

func _estimate_cargo_value(player: Player) -> int:
	# Rough estimate: sum of quantities * 50 (average price)
	var total := 0
	for commodity_id in player.cargo:
		total += player.cargo[commodity_id] * 50
	return total

func get_choice_count() -> int:
	return choices.size()

func get_choice_text(index: int) -> String:
	if index < 0 or index >= choices.size():
		return ""
	return choices[index].get("text", "")

func has_success_chance(choice_index: int) -> bool:
	if choice_index < 0 or choice_index >= choices.size():
		return false
	return choices[choice_index].has("success_chance")

func get_success_chance(choice_index: int) -> float:
	if choice_index < 0 or choice_index >= choices.size():
		return 1.0
	return choices[choice_index].get("success_chance", 1.0)
