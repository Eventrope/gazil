class_name Contract
extends RefCounted

enum Type {
	CARGO_HAUL,
	SUPPLY_RUN,
	EMBARGO,
	MANIPULATION,
	VIP_TRANSPORT
}

enum Tier {
	STANDARD,
	EXPRESS
}

enum Status {
	AVAILABLE,
	ACCEPTED,
	COMPLETED,
	FAILED,
	EXPIRED
}

var id: String
var template_id: String
var corp_id: String
var type: Type
var tier: Tier
var status: Status

# Cargo details
var commodity: String
var quantity: int
var cargo_provided: bool  # If true, corp provides sealed cargo
var sealed_cargo_id: String  # Reference to SealedCargo if provided

# Route details
var origin: String
var destination: String

# Timing
var created_day: int
var accepted_day: int
var deadline_day: int

# Rewards and penalties
var reward: int
var penalty: int
var standing_gain: int
var standing_loss: int

# Requirements
var min_cargo: int
var min_speed: int
var min_fuel_range: int
var min_standing: int
var required_upgrades: Array

# Embargo-specific
var embargo_commodities: Array
var embargo_planets: Array
var embargo_duration: int

# Manipulation-specific
var target_planet: String
var target_commodity: String
var target_price: int  # Price to reach (above or below)
var target_stock: int  # Stock level to reach
var manipulation_direction: String  # "increase" or "decrease"

func _init() -> void:
	id = ""
	template_id = ""
	corp_id = ""
	type = Type.CARGO_HAUL
	tier = Tier.STANDARD
	status = Status.AVAILABLE
	commodity = ""
	quantity = 0
	cargo_provided = false
	sealed_cargo_id = ""
	origin = ""
	destination = ""
	created_day = 0
	accepted_day = 0
	deadline_day = 0
	reward = 0
	penalty = 0
	standing_gain = 0
	standing_loss = 0
	min_cargo = 0
	min_speed = 0
	min_fuel_range = 0
	min_standing = 0
	required_upgrades = []
	embargo_commodities = []
	embargo_planets = []
	embargo_duration = 0
	target_planet = ""
	target_commodity = ""
	target_price = 0
	target_stock = 0
	manipulation_direction = ""

static func generate_id() -> String:
	return "contract_%d_%d" % [Time.get_unix_time_from_system(), randi() % 10000]

func get_type_name() -> String:
	match type:
		Type.CARGO_HAUL:
			return "Cargo Hauling"
		Type.SUPPLY_RUN:
			return "Supply Run"
		Type.EMBARGO:
			return "Trade Embargo"
		Type.MANIPULATION:
			return "Market Manipulation"
		Type.VIP_TRANSPORT:
			return "VIP Transport"
	return "Unknown"

func get_tier_name() -> String:
	match tier:
		Tier.EXPRESS:
			return "Express"
		Tier.STANDARD:
			return "Standard"
	return "Unknown"

func get_status_name() -> String:
	match status:
		Status.AVAILABLE:
			return "Available"
		Status.ACCEPTED:
			return "Accepted"
		Status.COMPLETED:
			return "Completed"
		Status.FAILED:
			return "Failed"
		Status.EXPIRED:
			return "Expired"
	return "Unknown"

func get_days_remaining(current_day: int) -> int:
	return deadline_day - current_day

func is_expired(current_day: int) -> bool:
	return current_day > deadline_day and status == Status.ACCEPTED

func is_express() -> bool:
	return tier == Tier.EXPRESS

func can_accept(player_ship, player_standing: int) -> Dictionary:
	# Returns {can_accept: bool, reasons: Array[String]}
	var reasons: Array = []

	if player_standing < min_standing:
		reasons.append("Requires %d standing (you have %d)" % [min_standing, player_standing])

	if player_ship != null:
		if player_ship.cargo_tonnes < min_cargo:
			reasons.append("Requires %d cargo capacity (ship has %d)" % [min_cargo, player_ship.cargo_tonnes])
		if min_speed > 0 and player_ship.speed < min_speed:
			reasons.append("Requires speed %d (ship has %d)" % [min_speed, player_ship.speed])
		if min_fuel_range > 0 and player_ship.fuel_tank < min_fuel_range:
			reasons.append("Requires %d fuel range (ship has %d)" % [min_fuel_range, player_ship.fuel_tank])
		for upgrade_id in required_upgrades:
			if not player_ship.has_upgrade(upgrade_id):
				reasons.append("Requires upgrade: %s" % upgrade_id)

	return {
		"can_accept": reasons.is_empty(),
		"reasons": reasons
	}

func get_description() -> String:
	var desc := ""
	match type:
		Type.CARGO_HAUL:
			if cargo_provided:
				desc = "Transport sealed cargo from %s to %s" % [origin, destination]
			else:
				desc = "Deliver %d units of %s from %s to %s" % [quantity, commodity, origin, destination]
		Type.SUPPLY_RUN:
			desc = "Supply %d units of %s to %s" % [quantity, commodity, destination]
		Type.EMBARGO:
			desc = "Avoid selling %s to %s for %d days" % [", ".join(embargo_commodities), ", ".join(embargo_planets), embargo_duration]
		Type.MANIPULATION:
			desc = "%s %s prices at %s" % [manipulation_direction.capitalize(), target_commodity, target_planet]
		Type.VIP_TRANSPORT:
			desc = "Transport VIP executive from %s to %s" % [origin, destination]
	return desc

func to_dict() -> Dictionary:
	return {
		"id": id,
		"template_id": template_id,
		"corp_id": corp_id,
		"type": type,
		"tier": tier,
		"status": status,
		"commodity": commodity,
		"quantity": quantity,
		"cargo_provided": cargo_provided,
		"sealed_cargo_id": sealed_cargo_id,
		"origin": origin,
		"destination": destination,
		"created_day": created_day,
		"accepted_day": accepted_day,
		"deadline_day": deadline_day,
		"reward": reward,
		"penalty": penalty,
		"standing_gain": standing_gain,
		"standing_loss": standing_loss,
		"min_cargo": min_cargo,
		"min_speed": min_speed,
		"min_fuel_range": min_fuel_range,
		"min_standing": min_standing,
		"required_upgrades": required_upgrades,
		"embargo_commodities": embargo_commodities,
		"embargo_planets": embargo_planets,
		"embargo_duration": embargo_duration,
		"target_planet": target_planet,
		"target_commodity": target_commodity,
		"target_price": target_price,
		"target_stock": target_stock,
		"manipulation_direction": manipulation_direction
	}

static func from_dict(data: Dictionary) -> Contract:
	var contract := Contract.new()
	contract.id = data.get("id", "")
	contract.template_id = data.get("template_id", "")
	contract.corp_id = data.get("corp_id", "")
	contract.type = data.get("type", Type.CARGO_HAUL)
	contract.tier = data.get("tier", Tier.STANDARD)
	contract.status = data.get("status", Status.AVAILABLE)
	contract.commodity = data.get("commodity", "")
	contract.quantity = data.get("quantity", 0)
	contract.cargo_provided = data.get("cargo_provided", false)
	contract.sealed_cargo_id = data.get("sealed_cargo_id", "")
	contract.origin = data.get("origin", "")
	contract.destination = data.get("destination", "")
	contract.created_day = data.get("created_day", 0)
	contract.accepted_day = data.get("accepted_day", 0)
	contract.deadline_day = data.get("deadline_day", 0)
	contract.reward = data.get("reward", 0)
	contract.penalty = data.get("penalty", 0)
	contract.standing_gain = data.get("standing_gain", 0)
	contract.standing_loss = data.get("standing_loss", 0)
	contract.min_cargo = data.get("min_cargo", 0)
	contract.min_speed = data.get("min_speed", 0)
	contract.min_fuel_range = data.get("min_fuel_range", 0)
	contract.min_standing = data.get("min_standing", 0)
	contract.required_upgrades = data.get("required_upgrades", [])
	contract.embargo_commodities = data.get("embargo_commodities", [])
	contract.embargo_planets = data.get("embargo_planets", [])
	contract.embargo_duration = data.get("embargo_duration", 0)
	contract.target_planet = data.get("target_planet", "")
	contract.target_commodity = data.get("target_commodity", "")
	contract.target_price = data.get("target_price", 0)
	contract.target_stock = data.get("target_stock", 0)
	contract.manipulation_direction = data.get("manipulation_direction", "")
	return contract
