extends Node

# CorporationManager - Manages corporations, contracts, and player standings

const INITIAL_STANDING := 50
const MAX_STANDING := 100
const MIN_STANDING := 0
const HIGH_STANDING_THRESHOLD := 80
const LOW_STANDING_THRESHOLD := 20

var corporations: Dictionary = {}  # {corp_id: Corporation}
var contract_templates: Array = []
var available_contracts: Array = []  # Contracts available at current location

signal contract_available(contract: Contract)
signal contract_taken(contract: Contract, taker_name: String)
signal contract_accepted(contract: Contract)
signal contract_completed(contract: Contract)
signal contract_failed(contract: Contract, reason: String)
signal standing_changed(corp_id: String, old_standing: int, new_standing: int)
signal sealed_cargo_inspected(cargo: SealedCargo, was_contraband: bool)

func _ready() -> void:
	_load_corporations()

func _load_corporations() -> void:
	var file := FileAccess.open("res://data/corporations.json", FileAccess.READ)
	if file == null:
		push_error("CorporationManager: Cannot open corporations.json")
		return

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("CorporationManager: Cannot parse corporations.json")
		return

	var data: Dictionary = json.data

	# Load corporations
	corporations.clear()
	var corps_data: Array = data.get("corporations", [])
	for corp_data in corps_data:
		var corp := Corporation.new(corp_data)
		corporations[corp.id] = corp
	print("CorporationManager: Loaded %d corporations" % corporations.size())

	# Load contract templates
	contract_templates.clear()
	var templates_data: Array = data.get("contract_templates", [])
	for template in templates_data:
		contract_templates.append(template)
	print("CorporationManager: Loaded %d contract templates" % contract_templates.size())

# --- Corporation Access ---

func get_corporation(corp_id: String) -> Corporation:
	return corporations.get(corp_id, null)

func get_all_corporations() -> Array:
	return corporations.values()

func get_corporations_at_planet(planet_id: String) -> Array:
	var result: Array = []
	for corp in corporations.values():
		if corp.has_presence_at(planet_id):
			result.append(corp)
	return result

func get_corporation_presence_level(corp_id: String, planet_id: String) -> String:
	var corp := get_corporation(corp_id)
	if corp == null:
		return "none"
	return corp.get_presence_level(planet_id)

# --- Standing Management ---

func get_standing(player: Player, corp_id: String) -> int:
	if player == null:
		return INITIAL_STANDING
	return player.corp_standings.get(corp_id, INITIAL_STANDING)

func set_standing(player: Player, corp_id: String, value: int) -> void:
	if player == null:
		return
	var old_standing: int = get_standing(player, corp_id)
	var new_standing: int = clampi(value, MIN_STANDING, MAX_STANDING)
	player.corp_standings[corp_id] = new_standing
	if old_standing != new_standing:
		standing_changed.emit(corp_id, old_standing, new_standing)

func modify_standing(player: Player, corp_id: String, delta: int) -> void:
	var current: int = get_standing(player, corp_id)
	set_standing(player, corp_id, current + delta)

func has_high_standing(player: Player, corp_id: String) -> bool:
	return get_standing(player, corp_id) >= HIGH_STANDING_THRESHOLD

func has_low_standing(player: Player, corp_id: String) -> bool:
	return get_standing(player, corp_id) < LOW_STANDING_THRESHOLD

func get_standing_level_name(standing: int) -> String:
	if standing >= HIGH_STANDING_THRESHOLD:
		return "Trusted"
	elif standing >= 50:
		return "Neutral"
	elif standing >= LOW_STANDING_THRESHOLD:
		return "Low"
	else:
		return "Hostile"

# --- Contract Generation ---

func generate_contracts_for_planet(planet_id: String, current_day: int, player: Player) -> Array:
	available_contracts.clear()

	var corps_at_planet := get_corporations_at_planet(planet_id)
	if corps_at_planet.is_empty():
		return []

	for corp in corps_at_planet:
		var corp_templates := _get_templates_for_corp(corp.id)
		var presence_level: String = corp.get_presence_level(planet_id)

		# Primary presence: more contracts available
		var max_contracts := 3 if presence_level == "primary" else 1

		var generated := 0
		var shuffled_templates := corp_templates.duplicate()
		shuffled_templates.shuffle()

		for template in shuffled_templates:
			if generated >= max_contracts:
				break

			# Check if template can generate from this planet
			var origin_options: Array = template.get("origin_options", [])
			if not origin_options.is_empty() and planet_id not in origin_options:
				continue

			var contract := _generate_contract_from_template(template, planet_id, current_day, player)
			if contract != null:
				available_contracts.append(contract)
				contract_available.emit(contract)
				generated += 1

	return available_contracts

func _get_templates_for_corp(corp_id: String) -> Array:
	var result: Array = []
	for template in contract_templates:
		if template.get("corp_id", "") == corp_id:
			result.append(template)
	return result

func _generate_contract_from_template(template: Dictionary, current_planet: String, current_day: int, player: Player) -> Contract:
	var contract := Contract.new()
	contract.id = Contract.generate_id()
	contract.template_id = template.get("id", "")
	contract.corp_id = template.get("corp_id", "")
	contract.created_day = current_day
	contract.status = Contract.Status.AVAILABLE

	# Type
	var type_str: String = template.get("type", "cargo_haul")
	match type_str:
		"cargo_haul":
			contract.type = Contract.Type.CARGO_HAUL
		"supply_run":
			contract.type = Contract.Type.SUPPLY_RUN
		"embargo":
			contract.type = Contract.Type.EMBARGO
		"manipulation":
			contract.type = Contract.Type.MANIPULATION
		"vip_transport":
			contract.type = Contract.Type.VIP_TRANSPORT

	# Tier
	var tier_str: String = template.get("tier", "standard")
	contract.tier = Contract.Tier.EXPRESS if tier_str == "express" else Contract.Tier.STANDARD

	# Cargo details
	var commodity_options: Array = template.get("commodity_options", [])
	if not commodity_options.is_empty():
		contract.commodity = commodity_options[randi() % commodity_options.size()]

	var qty_range: Array = template.get("quantity_range", [0, 0])
	if qty_range[1] > qty_range[0]:
		contract.quantity = randi_range(qty_range[0], qty_range[1])

	contract.cargo_provided = template.get("cargo_provided", false)

	# Origin
	var origin_options: Array = template.get("origin_options", [])
	if origin_options.is_empty():
		contract.origin = current_planet
	else:
		contract.origin = origin_options[randi() % origin_options.size()]

	# Destination - make sure it's different from origin
	var dest_options: Array = template.get("destination_options", [])
	if not dest_options.is_empty():
		var valid_destinations: Array = []
		for dest in dest_options:
			if dest != contract.origin:
				valid_destinations.append(dest)
		if valid_destinations.is_empty():
			return null  # Can't generate valid contract
		contract.destination = valid_destinations[randi() % valid_destinations.size()]

	# Deadline
	var deadline_base: int = template.get("deadline_base", 10)
	contract.deadline_day = current_day + deadline_base

	# Rewards
	var reward_per_unit: int = template.get("reward_per_unit", 0)
	var reward_flat: int = template.get("reward_flat", 0)
	if reward_per_unit > 0:
		contract.reward = reward_per_unit * contract.quantity
	else:
		contract.reward = reward_flat

	# Express tier bonus
	if contract.tier == Contract.Tier.EXPRESS:
		contract.reward = int(contract.reward * 1.5)

	# Penalty
	var penalty_ratio: float = template.get("penalty_ratio", 0.5)
	contract.penalty = int(contract.reward * penalty_ratio)

	# Standing changes
	contract.standing_gain = template.get("standing_gain", 3)
	contract.standing_loss = template.get("standing_loss", 5)

	# Requirements
	var requirements: Dictionary = template.get("requirements", {})
	contract.min_standing = requirements.get("min_standing", 0)
	contract.min_cargo = requirements.get("min_cargo", 0)
	contract.min_speed = requirements.get("min_speed", 0)
	contract.min_fuel_range = requirements.get("min_fuel_range", 0)
	contract.required_upgrades = requirements.get("required_upgrades", [])

	# Check if player meets standing requirement
	if player != null:
		var standing: int = get_standing(player, contract.corp_id)
		if standing < contract.min_standing:
			return null  # Player doesn't meet standing requirement

	# Embargo specific
	if contract.type == Contract.Type.EMBARGO:
		contract.embargo_commodities = template.get("embargo_commodities", [])
		contract.embargo_planets = template.get("embargo_planets", [])
		contract.embargo_duration = template.get("embargo_duration", 10)
		contract.deadline_day = current_day + contract.embargo_duration

	# Manipulation specific
	if contract.type == Contract.Type.MANIPULATION:
		var manip_targets: Array = template.get("manipulation_targets", [])
		var manip_planets: Array = template.get("manipulation_planets", [])
		if not manip_targets.is_empty():
			contract.target_commodity = manip_targets[randi() % manip_targets.size()]
		if not manip_planets.is_empty():
			contract.target_planet = manip_planets[randi() % manip_planets.size()]
		contract.target_stock = template.get("manipulation_stock_change", -50)
		contract.manipulation_direction = "decrease" if contract.target_stock < 0 else "increase"
		contract.deadline_day = current_day + template.get("manipulation_duration", 15)

	return contract

# --- Contract Actions ---

func accept_contract(player: Player, contract: Contract) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active player"}

	if contract.status != Contract.Status.AVAILABLE:
		return {"success": false, "message": "Contract not available"}

	# Check requirements
	var can_accept: Dictionary = contract.can_accept(player.ship, get_standing(player, contract.corp_id))
	if not can_accept["can_accept"]:
		var reasons: Array = can_accept["reasons"]
		return {"success": false, "message": reasons[0] if not reasons.is_empty() else "Cannot accept"}

	# Check cargo space for sealed cargo
	if contract.cargo_provided:
		var template := _get_template_by_id(contract.template_id)
		var weight_range: Array = template.get("sealed_weight_range", [50, 100])
		var weight: int = randi_range(weight_range[0], weight_range[1])
		if player.get_cargo_space_free() < weight:
			return {"success": false, "message": "Not enough cargo space for sealed container (%d needed)" % weight}

		# Create sealed cargo
		var contraband_chance: float = template.get("contraband_chance", 0.1)
		var sealed := SealedCargo.new()
		sealed.id = SealedCargo.generate_id()
		sealed.contract_id = contract.id
		sealed.weight = weight
		sealed.is_contraband = randf() < contraband_chance
		if sealed.is_contraband:
			sealed.actual_commodity = "contraband"
			sealed.actual_quantity = randi_range(5, 20)
			sealed.actual_value = sealed.actual_quantity * 400
		else:
			var commodities := ["ore", "parts", "tech", "medicine", "grain"]
			sealed.actual_commodity = commodities[randi() % commodities.size()]
			sealed.actual_quantity = randi_range(10, 30)
			sealed.actual_value = sealed.actual_quantity * 50

		player.sealed_cargo.append(sealed.to_dict())
		contract.sealed_cargo_id = sealed.id

	contract.status = Contract.Status.ACCEPTED
	contract.accepted_day = GameState.player.day if GameState.player else 0
	player.active_contracts.append(contract.to_dict())

	# Remove from available
	available_contracts.erase(contract)

	contract_accepted.emit(contract)

	var corp := get_corporation(contract.corp_id)
	var corp_name: String = corp.corp_name if corp else "Unknown"
	return {"success": true, "message": "Contract accepted from %s" % corp_name}

func _get_template_by_id(template_id: String) -> Dictionary:
	for template in contract_templates:
		if template.get("id", "") == template_id:
			return template
	return {}

func complete_contract(player: Player, contract: Contract) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active player"}

	if contract.status != Contract.Status.ACCEPTED:
		return {"success": false, "message": "Contract not active"}

	# Mark completed
	contract.status = Contract.Status.COMPLETED

	# Award reward
	player.add_credits(contract.reward)

	# Increase standing
	modify_standing(player, contract.corp_id, contract.standing_gain)

	# Remove sealed cargo if present
	if not contract.sealed_cargo_id.is_empty():
		_remove_sealed_cargo(player, contract.sealed_cargo_id)

	# Update player's contract list
	_update_player_contract(player, contract)

	contract_completed.emit(contract)

	var corp := get_corporation(contract.corp_id)
	var corp_name: String = corp.corp_name if corp else "Unknown"
	return {
		"success": true,
		"message": "Contract completed! +%d credits, +%d standing with %s" % [contract.reward, contract.standing_gain, corp_name],
		"reward": contract.reward,
		"standing_gain": contract.standing_gain
	}

func fail_contract(player: Player, contract: Contract, reason: String = "Failed") -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active player"}

	if contract.status != Contract.Status.ACCEPTED:
		return {"success": false, "message": "Contract not active"}

	# Mark failed
	contract.status = Contract.Status.FAILED

	# Apply penalty
	if player.credits >= contract.penalty:
		player.spend_credits(contract.penalty)
	else:
		player.spend_credits(player.credits)  # Take what they have

	# Decrease standing
	modify_standing(player, contract.corp_id, -contract.standing_loss)

	# Mark sealed cargo as expired if present
	if not contract.sealed_cargo_id.is_empty():
		_mark_sealed_cargo_expired(player, contract.sealed_cargo_id)

	# Update player's contract list
	_update_player_contract(player, contract)

	contract_failed.emit(contract, reason)

	var corp := get_corporation(contract.corp_id)
	var corp_name: String = corp.corp_name if corp else "Unknown"
	return {
		"success": true,
		"message": "Contract failed: %s. -%d credits, -%d standing with %s" % [reason, contract.penalty, contract.standing_loss, corp_name],
		"penalty": contract.penalty,
		"standing_loss": contract.standing_loss
	}

func abandon_contract(player: Player, contract: Contract) -> Dictionary:
	return fail_contract(player, contract, "Abandoned")

func _update_player_contract(player: Player, contract: Contract) -> void:
	for i in range(player.active_contracts.size()):
		var c: Dictionary = player.active_contracts[i]
		if c.get("id", "") == contract.id:
			player.active_contracts[i] = contract.to_dict()
			return

func _remove_sealed_cargo(player: Player, cargo_id: String) -> void:
	for i in range(player.sealed_cargo.size() - 1, -1, -1):
		var c: Dictionary = player.sealed_cargo[i]
		if c.get("id", "") == cargo_id:
			player.sealed_cargo.remove_at(i)
			return

func _mark_sealed_cargo_expired(player: Player, cargo_id: String) -> void:
	for i in range(player.sealed_cargo.size()):
		var c: Dictionary = player.sealed_cargo[i]
		if c.get("id", "") == cargo_id:
			c["is_expired"] = true
			player.sealed_cargo[i] = c
			return

# --- Contract Checking ---

func check_contract_completion(player: Player, contract_data: Dictionary) -> bool:
	var contract := Contract.from_dict(contract_data)

	match contract.type:
		Contract.Type.CARGO_HAUL:
			return _check_cargo_haul_completion(player, contract)
		Contract.Type.SUPPLY_RUN:
			return _check_supply_run_completion(player, contract)
		Contract.Type.VIP_TRANSPORT:
			return _check_vip_transport_completion(player, contract)
		# Embargo and manipulation are checked differently (over time)

	return false

func _check_cargo_haul_completion(player: Player, contract: Contract) -> bool:
	if player.current_planet != contract.destination:
		return false

	if contract.cargo_provided:
		# Just need to be at destination with sealed cargo
		for c in player.sealed_cargo:
			if c.get("contract_id", "") == contract.id and not c.get("is_expired", false):
				return true
		return false
	else:
		# Need to have delivered the goods (already at destination)
		# The actual delivery happens when player sells, so this check is for arrival
		return true

func _check_supply_run_completion(player: Player, contract: Contract) -> bool:
	# Supply run completes when player is at destination
	# The goods should have been sourced and brought
	return player.current_planet == contract.destination

func _check_vip_transport_completion(player: Player, contract: Contract) -> bool:
	# VIP transport completes when at destination
	return player.current_planet == contract.destination

func check_expired_contracts(player: Player, current_day: int) -> Array:
	var expired: Array = []

	for i in range(player.active_contracts.size() - 1, -1, -1):
		var contract_data: Dictionary = player.active_contracts[i]
		var contract := Contract.from_dict(contract_data)

		if contract.status == Contract.Status.ACCEPTED and contract.is_expired(current_day):
			fail_contract(player, contract, "Deadline expired")
			expired.append(contract)

	return expired

# --- Embargo Checking ---

func check_embargo_violation(player: Player, commodity_id: String, planet_id: String) -> Dictionary:
	# Returns {violated: bool, contract: Contract or null, detection_chance: float}
	for contract_data in player.active_contracts:
		var contract := Contract.from_dict(contract_data)
		if contract.type != Contract.Type.EMBARGO:
			continue
		if contract.status != Contract.Status.ACCEPTED:
			continue

		if commodity_id in contract.embargo_commodities and planet_id in contract.embargo_planets:
			# Violation! Check if detected (based on planet inspection chance)
			var planet := DataRepo.get_planet(planet_id)
			var detection_chance: float = 0.5  # Base 50%
			if planet:
				detection_chance = planet.inspection_chance

			return {
				"violated": true,
				"contract": contract,
				"detection_chance": detection_chance
			}

	return {"violated": false, "contract": null, "detection_chance": 0.0}

# --- Sealed Cargo Inspection ---

func inspect_sealed_cargo(player: Player, planet: Planet) -> Dictionary:
	# Check all sealed cargo for contraband during inspection
	var contraband_found: Array = []

	for cargo_data in player.sealed_cargo:
		var cargo := SealedCargo.from_dict(cargo_data)
		if cargo.is_contraband and not cargo.was_inspected:
			contraband_found.append(cargo)
			cargo.was_inspected = true

			# Update the stored cargo
			for i in range(player.sealed_cargo.size()):
				if player.sealed_cargo[i].get("id", "") == cargo.id:
					player.sealed_cargo[i] = cargo.to_dict()
					break

			sealed_cargo_inspected.emit(cargo, true)

	if contraband_found.is_empty():
		return {"found": false, "cargo": []}

	# Calculate total fine
	var total_value := 0
	for cargo in contraband_found:
		total_value += cargo.actual_value

	var fine := int(total_value * 0.5)

	return {
		"found": true,
		"cargo": contraband_found,
		"total_value": total_value,
		"fine": fine
	}

# --- Price Modifiers ---

func get_price_modifier_for_player(player: Player, planet_id: String, commodity_id: String) -> float:
	# Returns a multiplier based on corp presence and player standing
	var modifier := 1.0

	var corps := get_corporations_at_planet(planet_id)
	for corp in corps:
		if corp.is_specialty_commodity(commodity_id):
			var standing: int = get_standing(player, corp.id)
			modifier *= corp.get_price_modifier_for_standing(standing)

	return modifier

# --- Available Contracts ---

func get_available_contracts() -> Array:
	return available_contracts

func get_available_contracts_for_corp(corp_id: String) -> Array:
	var result: Array = []
	for contract in available_contracts:
		if contract.corp_id == corp_id:
			result.append(contract)
	return result

# --- Player Active Contracts ---

func get_active_contracts(player: Player) -> Array:
	if player == null:
		return []
	var result: Array = []
	for contract_data in player.active_contracts:
		var contract := Contract.from_dict(contract_data)
		if contract.status == Contract.Status.ACCEPTED:
			result.append(contract)
	return result

func get_active_contracts_for_corp(player: Player, corp_id: String) -> Array:
	var result: Array = []
	for contract in get_active_contracts(player):
		if contract.corp_id == corp_id:
			result.append(contract)
	return result

# --- Discard Expired Sealed Cargo ---

func discard_expired_sealed_cargo(player: Player, cargo_id: String) -> Dictionary:
	for i in range(player.sealed_cargo.size() - 1, -1, -1):
		var c: Dictionary = player.sealed_cargo[i]
		if c.get("id", "") == cargo_id:
			if c.get("is_expired", false):
				player.sealed_cargo.remove_at(i)
				return {"success": true, "message": "Discarded expired sealed cargo"}
			else:
				return {"success": false, "message": "Cannot discard active contract cargo"}

	return {"success": false, "message": "Cargo not found"}

# --- Serialization ---

func get_save_data(player: Player) -> Dictionary:
	var available_data: Array = []
	for contract in available_contracts:
		available_data.append(contract.to_dict())

	return {
		"available_contracts": available_data
	}

func load_save_data(data: Dictionary, player: Player) -> void:
	available_contracts.clear()
	var available_data: Array = data.get("available_contracts", [])
	for contract_data in available_data:
		available_contracts.append(Contract.from_dict(contract_data))
