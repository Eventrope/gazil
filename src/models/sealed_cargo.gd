class_name SealedCargo
extends RefCounted

var id: String
var contract_id: String
var weight: int  # Cargo space used

# Hidden from player - revealed only on inspection or contract expiry
var is_contraband: bool
var actual_commodity: String
var actual_quantity: int
var actual_value: int  # Estimated value if sold

# State
var is_expired: bool  # True if contract deadline passed - cargo becomes worthless
var was_inspected: bool  # True if inspected during travel

func _init() -> void:
	id = ""
	contract_id = ""
	weight = 0
	is_contraband = false
	actual_commodity = ""
	actual_quantity = 0
	actual_value = 0
	is_expired = false
	was_inspected = false

static func generate_id() -> String:
	return "sealed_%d_%d" % [Time.get_unix_time_from_system(), randi() % 10000]

static func create_for_contract(contract: Contract, contraband_chance: float = 0.1) -> SealedCargo:
	var cargo := SealedCargo.new()
	cargo.id = generate_id()
	cargo.contract_id = contract.id

	# Determine if this is contraband
	# Smuggler corp contracts have higher contraband chance
	cargo.is_contraband = randf() < contraband_chance

	if cargo.is_contraband:
		cargo.actual_commodity = "contraband"
		cargo.actual_quantity = randi_range(5, 20)
		cargo.weight = cargo.actual_quantity  # 1 weight per unit
		cargo.actual_value = cargo.actual_quantity * 400  # Base contraband price
	else:
		# Random legal commodity
		var legal_commodities := ["ore", "grain", "fuel", "parts", "medicine", "tech", "entertainment", "luxury"]
		cargo.actual_commodity = legal_commodities[randi() % legal_commodities.size()]
		cargo.actual_quantity = randi_range(10, 50)
		# Weight varies by commodity (simplified)
		var weight_map := {
			"ore": 5, "grain": 4, "fuel": 3, "parts": 2,
			"medicine": 1, "tech": 1, "entertainment": 1, "luxury": 1
		}
		cargo.weight = cargo.actual_quantity * weight_map.get(cargo.actual_commodity, 2)
		# Value based on commodity base price
		var price_map := {
			"ore": 25, "grain": 30, "fuel": 50, "parts": 75,
			"medicine": 100, "tech": 120, "entertainment": 180, "luxury": 300
		}
		cargo.actual_value = cargo.actual_quantity * price_map.get(cargo.actual_commodity, 50)

	return cargo

func get_display_name() -> String:
	if is_expired:
		return "Expired Sealed Container"
	return "Sealed Container (%d cargo)" % weight

func get_description() -> String:
	if is_expired:
		return "This sealed container's contract has expired. The contents are now worthless corporate property. Discard to free cargo space."
	return "A sealed container from a corporation contract. Contents unknown. Must be delivered to complete the contract."

func mark_expired() -> void:
	is_expired = true

func reveal_contents() -> Dictionary:
	# Called when inspected - returns what authorities found
	return {
		"commodity": actual_commodity,
		"quantity": actual_quantity,
		"is_contraband": is_contraband,
		"value": actual_value
	}

func to_dict() -> Dictionary:
	return {
		"id": id,
		"contract_id": contract_id,
		"weight": weight,
		"is_contraband": is_contraband,
		"actual_commodity": actual_commodity,
		"actual_quantity": actual_quantity,
		"actual_value": actual_value,
		"is_expired": is_expired,
		"was_inspected": was_inspected
	}

static func from_dict(data: Dictionary) -> SealedCargo:
	var cargo := SealedCargo.new()
	cargo.id = data.get("id", "")
	cargo.contract_id = data.get("contract_id", "")
	cargo.weight = data.get("weight", 0)
	cargo.is_contraband = data.get("is_contraband", false)
	cargo.actual_commodity = data.get("actual_commodity", "")
	cargo.actual_quantity = data.get("actual_quantity", 0)
	cargo.actual_value = data.get("actual_value", 0)
	cargo.is_expired = data.get("is_expired", false)
	cargo.was_inspected = data.get("was_inspected", false)
	return cargo
