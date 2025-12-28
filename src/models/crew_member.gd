class_name CrewMember
extends RefCounted

var id: String
var crew_name: String
var role_id: String
var quality: int  # 1-5 stars
var wage: int
var morale: int  # 0-100
var hired_day: int

func _init() -> void:
	id = ""
	crew_name = ""
	role_id = ""
	quality = 1
	wage = 20
	morale = 75
	hired_day = 0

static func create(role_data: Dictionary, quality_level: int, current_day: int) -> CrewMember:
	var member := CrewMember.new()
	member.id = "crew_%d_%d" % [current_day, randi() % 10000]
	member.crew_name = _generate_name()
	member.role_id = role_data.get("id", "")
	member.quality = clampi(quality_level, 1, 5)
	member.hired_day = current_day

	# Wage based on quality
	var base_wage: int = role_data.get("base_wage", 20)
	member.wage = int(base_wage * (0.8 + member.quality * 0.2))

	# Initial morale based on quality
	member.morale = 60 + member.quality * 8

	return member

static func _generate_name() -> String:
	var first_names := ["Alex", "Jordan", "Sam", "Morgan", "Riley", "Quinn", "Avery", "Drew", "Casey", "Taylor",
		"Max", "Jesse", "Blake", "Reese", "Dakota", "Skyler", "Charlie", "Emery", "Finley", "Rowan"]
	var last_names := ["Chen", "Patel", "Kim", "Singh", "Garcia", "Williams", "Mueller", "Tanaka", "Silva", "Okonkwo",
		"Volkov", "Johansson", "Costa", "Nguyen", "Ahmed", "Park", "Zhang", "Kumar", "Martinez", "Ivanova"]
	return first_names[randi() % first_names.size()] + " " + last_names[randi() % last_names.size()]

func get_daily_wage() -> int:
	return wage

func get_effectiveness() -> float:
	# Effectiveness based on quality and morale
	var quality_factor := 0.6 + quality * 0.1  # 0.7 to 1.1
	var morale_factor := float(morale) / 100.0  # 0.0 to 1.0
	return quality_factor * morale_factor

func apply_morale_change(amount: int) -> void:
	morale = clampi(morale + amount, 0, 100)

func pay_wage_success() -> void:
	# Small morale boost when paid
	if morale < 80:
		morale = mini(100, morale + 2)

func pay_wage_failure() -> void:
	# Morale penalty when not paid
	morale = maxi(0, morale - 15)

func is_quitting() -> bool:
	# Crew quits at 0 morale
	return morale <= 0

func get_quality_stars() -> String:
	return "*".repeat(quality)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"crew_name": crew_name,
		"role_id": role_id,
		"quality": quality,
		"wage": wage,
		"morale": morale,
		"hired_day": hired_day
	}

static func from_dict(data: Dictionary) -> CrewMember:
	var member := CrewMember.new()
	member.id = data.get("id", "")
	member.crew_name = data.get("crew_name", "Unknown")
	member.role_id = data.get("role_id", "")
	member.quality = data.get("quality", 1)
	member.wage = data.get("wage", 20)
	member.morale = data.get("morale", 75)
	member.hired_day = data.get("hired_day", 0)
	return member
