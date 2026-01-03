class_name PassengerContract
extends RefCounted

var id: String
var passenger_type: String
var passenger_name: String
var origin: String
var destination: String
var deadline: int  # Day by which they must arrive
var base_payment: int
var count: int  # Number of passengers in this contract
var accepted_day: int  # Day when contract was accepted
var mood: int  # 0-100, affects final payment

func _init() -> void:
	id = ""
	passenger_type = "tourist"
	passenger_name = ""
	origin = ""
	destination = ""
	deadline = 0
	base_payment = 100
	count = 1
	accepted_day = 0
	mood = 100

static func create(type_data: Dictionary, from_planet: String, to_planet: String, current_day: int, travel_days: int) -> PassengerContract:
	var contract := PassengerContract.new()
	contract.id = "pc_%d_%d" % [current_day, randi() % 10000]
	contract.passenger_type = type_data.get("id", "tourist")
	contract.passenger_name = _generate_name()
	contract.origin = from_planet
	contract.destination = to_planet
	contract.accepted_day = current_day

	# Deadline based on travel time + patience
	var patience: int = type_data.get("patience", 3)
	contract.deadline = current_day + travel_days + patience

	# Payment based on distance and type
	var base: int = type_data.get("base_payment", 100)
	contract.base_payment = int(base * (1.0 + travel_days * 0.1))

	# Random group size (1-4 passengers)
	contract.count = 1
	if randf() < 0.3:
		contract.count = randi_range(2, 4)

	contract.mood = 100

	return contract

static func _generate_name() -> String:
	var first_names := ["Alex", "Jordan", "Sam", "Morgan", "Riley", "Quinn", "Avery", "Drew", "Casey", "Taylor",
		"Zara", "Kai", "Nova", "Orion", "Luna", "Sol", "Vega", "Atlas", "Lyra", "Phoenix"]
	var last_names := ["Chen", "Patel", "Kim", "Singh", "Garcia", "Williams", "Mueller", "Tanaka", "Silva", "Okonkwo",
		"Volkov", "Johansson", "Costa", "Nguyen", "Ahmed", "Park", "Zhang", "Kumar", "Martinez", "Ivanova"]
	return first_names[randi() % first_names.size()] + " " + last_names[randi() % last_names.size()]

func get_days_remaining(current_day: int) -> int:
	return deadline - current_day

func is_overdue(current_day: int) -> bool:
	return current_day > deadline

func get_days_overdue(current_day: int) -> int:
	return maxi(0, current_day - deadline)

func apply_delay(days: int, type_data: Dictionary) -> void:
	# Reduce mood based on delay
	var decay: int = type_data.get("mood_decay", 10)
	mood = maxi(0, mood - decay * days)

func apply_event_penalty(severity: String) -> void:
	# Reduce mood for dangerous events
	match severity:
		"minor":
			mood = maxi(0, mood - 10)
		"major":
			mood = maxi(0, mood - 25)
		"critical":
			mood = maxi(0, mood - 50)

func calculate_final_payment(type_data: Dictionary, is_early: bool) -> int:
	var payment := base_payment * count

	# Apply mood modifier
	var mood_modifier := float(mood) / 100.0
	payment = int(payment * mood_modifier)

	# Early bonus
	if is_early:
		payment = int(payment * 1.1)

	# Check for tip
	var tip_chance: float = type_data.get("tip_chance", 0.1)
	var tip_multiplier: float = type_data.get("tip_multiplier", 1.2)
	if randf() < tip_chance and mood >= 50:
		payment = int(payment * tip_multiplier)

	return maxi(0, payment)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"passenger_type": passenger_type,
		"passenger_name": passenger_name,
		"origin": origin,
		"destination": destination,
		"deadline": deadline,
		"base_payment": base_payment,
		"count": count,
		"accepted_day": accepted_day,
		"mood": mood
	}

static func from_dict(data: Dictionary) -> PassengerContract:
	var contract := PassengerContract.new()
	contract.id = data.get("id", "")
	contract.passenger_type = data.get("passenger_type", "tourist")
	contract.passenger_name = data.get("passenger_name", "Unknown")
	contract.origin = data.get("origin", "")
	contract.destination = data.get("destination", "")
	contract.deadline = data.get("deadline", 0)
	contract.base_payment = data.get("base_payment", 100)
	contract.count = data.get("count", 1)
	contract.accepted_day = data.get("accepted_day", 0)
	contract.mood = data.get("mood", 100)
	return contract
