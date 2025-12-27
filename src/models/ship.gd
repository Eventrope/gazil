class_name Ship
extends RefCounted

var id: String
var ship_name: String
var description: String
var cargo_capacity: int
var fuel_capacity: int
var fuel_efficiency: float
var upgrades_installed: Array[String]

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	id = data.get("id", "rustbucket")
	ship_name = data.get("name", "Unknown Ship")
	description = data.get("description", "")
	cargo_capacity = data.get("cargo_capacity", 100)
	fuel_capacity = data.get("fuel_capacity", 50)
	fuel_efficiency = data.get("fuel_efficiency", 1.0)
	upgrades_installed = []

func apply_upgrade(upgrade_data: Dictionary) -> void:
	var effects: Dictionary = upgrade_data.get("effects", {})
	if effects.has("cargo_capacity"):
		cargo_capacity += int(effects["cargo_capacity"])
	if effects.has("fuel_capacity"):
		fuel_capacity += int(effects["fuel_capacity"])
	if effects.has("fuel_efficiency"):
		fuel_efficiency *= float(effects["fuel_efficiency"])
	upgrades_installed.append(upgrade_data["id"])

func has_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in upgrades_installed

func get_fuel_cost(distance: int) -> int:
	return int(ceil(distance * 5 * fuel_efficiency))

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": ship_name,
		"description": description,
		"cargo_capacity": cargo_capacity,
		"fuel_capacity": fuel_capacity,
		"fuel_efficiency": fuel_efficiency,
		"upgrades_installed": upgrades_installed
	}

static func from_dict(data: Dictionary) -> Ship:
	var ship := Ship.new(data)
	ship.upgrades_installed.assign(data.get("upgrades_installed", []))
	return ship
