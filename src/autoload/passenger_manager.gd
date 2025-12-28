extends Node

# PassengerManager - Handles passenger contract generation and processing

var passenger_types: Dictionary = {}  # {id: type_data}
var available_contracts: Dictionary = {}  # {planet_id: [PassengerContract]}

signal passenger_delivered(contract: PassengerContract, payment: int, was_early: bool)
signal passenger_abandoned(contract: PassengerContract)
signal passenger_mood_changed(contract: PassengerContract, new_mood: int)

func _ready() -> void:
	_load_passenger_types()

func _load_passenger_types() -> void:
	var file := FileAccess.open("res://data/passenger_types.json", FileAccess.READ)
	if file == null:
		push_error("PassengerManager: Cannot load passenger_types.json")
		return

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("PassengerManager: Cannot parse passenger_types.json")
		return

	var data: Dictionary = json.data
	for type_data in data.get("passenger_types", []):
		var type_id: String = type_data.get("id", "")
		if type_id != "":
			passenger_types[type_id] = type_data

	print("PassengerManager: Loaded %d passenger types" % passenger_types.size())

func get_passenger_type(type_id: String) -> Dictionary:
	return passenger_types.get(type_id, {})

func generate_contracts_at(planet_id: String, player_reputation: int, current_day: int) -> Array:
	# Generate available passenger contracts at a planet
	var contracts: Array = []

	# Get all possible destinations from this planet
	var planet := DataRepo.get_planet(planet_id)
	if planet == null:
		return contracts

	var all_planets := DataRepo.get_all_planets()
	var destinations: Array = []
	for p in all_planets:
		if p.id != planet_id and p.is_unlocked(current_day):
			destinations.append(p)

	if destinations.is_empty():
		return contracts

	# Generate 2-5 contracts based on planet economy
	var num_contracts := randi_range(2, 5)

	for _i in range(num_contracts):
		# Pick a random destination
		var dest: Planet = destinations[randi() % destinations.size()]
		var travel_days := planet.get_distance_to(dest.id)

		# Pick a passenger type based on reputation
		var available_types: Array = []
		for type_id in passenger_types:
			var type_data: Dictionary = passenger_types[type_id]
			if player_reputation >= type_data.get("min_reputation", 0):
				available_types.append(type_data)

		if available_types.is_empty():
			continue

		var type_data: Dictionary = available_types[randi() % available_types.size()]
		var contract := PassengerContract.create(type_data, planet_id, dest.id, current_day, travel_days)
		contracts.append(contract)

	available_contracts[planet_id] = contracts
	return contracts

func get_contracts_at(planet_id: String) -> Array:
	return available_contracts.get(planet_id, [])

func refresh_contracts_at(planet_id: String, player_reputation: int, current_day: int) -> Array:
	# Clear old contracts and generate new ones
	available_contracts.erase(planet_id)
	return generate_contracts_at(planet_id, player_reputation, current_day)

func accept_contract(contract: PassengerContract) -> bool:
	# Remove from available list
	var origin := contract.origin
	if available_contracts.has(origin):
		available_contracts[origin].erase(contract)
	return true

func deliver_passengers(player: Player, current_planet: String, current_day: int) -> Array:
	# Check all accepted passengers for delivery at current planet
	var delivered: Array = []

	var to_remove: Array = []
	for contract in player.accepted_passengers:
		# Handle both Dictionary and PassengerContract
		var dest: String
		var contract_obj: PassengerContract

		if contract is Dictionary:
			dest = contract.get("destination", "")
			contract_obj = PassengerContract.from_dict(contract)
		else:
			dest = contract.destination
			contract_obj = contract

		if dest != current_planet:
			continue

		# Deliver this passenger
		var type_data := get_passenger_type(contract_obj.passenger_type)
		var is_early := current_day < contract_obj.deadline
		var payment := contract_obj.calculate_final_payment(type_data, is_early)

		player.add_credits(payment)

		# Update reputation based on mood
		if contract_obj.mood >= 80:
			player.change_reputation(5)
		elif contract_obj.mood >= 50:
			player.change_reputation(2)
		elif contract_obj.mood < 30:
			player.change_reputation(-5)

		passenger_delivered.emit(contract_obj, payment, is_early)
		to_remove.append(contract)

		delivered.append({
			"contract": contract_obj,
			"payment": payment,
			"was_early": is_early
		})

	# Remove delivered passengers
	for contract in to_remove:
		player.accepted_passengers.erase(contract)

	return delivered

func process_travel_effects(player: Player, days_traveled: int, breakdown_occurred: bool, breakdown_severity: String) -> void:
	# Apply mood decay for delays and events
	for i in range(player.accepted_passengers.size()):
		var contract = player.accepted_passengers[i]
		var contract_obj: PassengerContract

		if contract is Dictionary:
			contract_obj = PassengerContract.from_dict(contract)
		else:
			contract_obj = contract

		var type_data := get_passenger_type(contract_obj.passenger_type)

		# Check if we're behind schedule
		var expected_arrival := contract_obj.accepted_day + days_traveled
		if expected_arrival > contract_obj.deadline:
			var overdue := expected_arrival - contract_obj.deadline
			contract_obj.apply_delay(overdue, type_data)

		# Apply breakdown penalty
		if breakdown_occurred:
			contract_obj.apply_event_penalty(breakdown_severity)

		passenger_mood_changed.emit(contract_obj, contract_obj.mood)

		# Update the stored contract
		if contract is Dictionary:
			player.accepted_passengers[i] = contract_obj.to_dict()
		else:
			player.accepted_passengers[i] = contract_obj

func abandon_contract(player: Player, contract_index: int) -> bool:
	if contract_index < 0 or contract_index >= player.accepted_passengers.size():
		return false

	var contract = player.accepted_passengers[contract_index]
	var contract_obj: PassengerContract

	if contract is Dictionary:
		contract_obj = PassengerContract.from_dict(contract)
	else:
		contract_obj = contract

	# Reputation penalty for abandonment
	player.change_reputation(-10)

	passenger_abandoned.emit(contract_obj)
	player.accepted_passengers.remove_at(contract_index)

	return true

func get_total_expected_payment(player: Player, current_day: int) -> int:
	var total := 0
	for contract in player.accepted_passengers:
		if contract is Dictionary:
			total += contract.get("base_payment", 0) * contract.get("count", 1)
		else:
			total += contract.base_payment * contract.count
	return total
