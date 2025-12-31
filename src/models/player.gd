class_name Player
extends RefCounted

var credits: int
var current_planet: String
var ship: Ship
var cargo: Dictionary  # {commodity_id: quantity}
var cargo_purchase_prices: Dictionary  # {commodity_id: avg_price_per_unit}
var fuel: int
var day: int
var statistics: Dictionary

# Banking System
var bank_balance: int = 0
var loans: Array = []  # [{principal: int, interest_rate: float, due_day: int, amount_owed: int}]
var credit_rating: int = 100  # 0-200, 100 = average

# Passenger System
var accepted_passengers: Array = []  # Array of PassengerContract
var passenger_reputation: int = 50  # 0-100, affects contract availability

# Investment System
var investments: Array = []  # Array of Investment objects

# Crew System
var crew: Array = []  # Array of CrewMember objects

# Corporation System
var corp_standings: Dictionary = {}  # {corp_id: int (0-100)}
var active_contracts: Array = []  # Array of Contract dictionaries
var sealed_cargo: Array = []  # Array of SealedCargo dictionaries

signal credits_changed(new_amount: int)
signal fuel_changed(new_amount: int)
signal cargo_changed()
signal location_changed(new_planet: String)
signal bank_balance_changed(new_amount: int)
signal reputation_changed(new_amount: int)

func _init() -> void:
	credits = 1000
	current_planet = "earth"
	ship = null
	cargo = {}
	cargo_purchase_prices = {}
	fuel = 50
	day = 1
	statistics = {
		"trades_made": 0,
		"distance_traveled": 0,
		"events_survived": 0,
		"credits_earned": 0,
		"credits_spent": 0,
		"total_profit": 0
	}

func get_cargo_weight() -> int:
	var total := 0
	for commodity_id in cargo:
		var qty: int = cargo[commodity_id]
		var commodity: Commodity = DataRepo.get_commodity(commodity_id)
		if commodity:
			total += qty * commodity.weight_per_unit
		else:
			total += qty * 2  # Fallback
	return total

func get_cargo_space_used() -> int:
	return get_cargo_weight() + get_sealed_cargo_weight()

func get_sealed_cargo_weight() -> int:
	var total := 0
	for cargo_data in sealed_cargo:
		total += cargo_data.get("weight", 0)
	return total

func get_cargo_space_free() -> int:
	if ship == null:
		return 0
	return ship.cargo_tonnes - get_cargo_space_used()

func add_cargo(commodity_id: String, quantity: int, price_per_unit: int = 0) -> void:
	var old_qty: int = cargo.get(commodity_id, 0)
	var old_avg: int = cargo_purchase_prices.get(commodity_id, 0)

	if cargo.has(commodity_id):
		cargo[commodity_id] += quantity
	else:
		cargo[commodity_id] = quantity

	# Update average purchase price (weighted average)
	if price_per_unit > 0:
		var new_qty: int = cargo[commodity_id]
		var total_value: int = (old_qty * old_avg) + (quantity * price_per_unit)
		cargo_purchase_prices[commodity_id] = total_value / new_qty

	cargo_changed.emit()

func remove_cargo(commodity_id: String, quantity: int) -> bool:
	if not cargo.has(commodity_id):
		return false
	if cargo[commodity_id] < quantity:
		return false
	cargo[commodity_id] -= quantity
	if cargo[commodity_id] <= 0:
		cargo.erase(commodity_id)
		cargo_purchase_prices.erase(commodity_id)
	cargo_changed.emit()
	return true

func get_purchase_price(commodity_id: String) -> int:
	return cargo_purchase_prices.get(commodity_id, 0)

func get_cargo_quantity(commodity_id: String) -> int:
	return cargo.get(commodity_id, 0)

func add_credits(amount: int) -> void:
	credits += amount
	if amount > 0:
		statistics["credits_earned"] += amount
	credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	statistics["credits_spent"] += amount
	credits_changed.emit(credits)
	return true

func use_fuel(amount: int) -> bool:
	if fuel < amount:
		return false
	fuel -= amount
	fuel_changed.emit(fuel)
	return true

func add_fuel(amount: int) -> void:
	if ship:
		fuel = min(fuel + amount, ship.fuel_tank)
	else:
		fuel += amount
	fuel_changed.emit(fuel)

func travel_to(planet_id: String, distance: int) -> void:
	current_planet = planet_id
	day += distance
	statistics["distance_traveled"] += distance
	location_changed.emit(planet_id)

func is_bankrupt() -> bool:
	if credits >= 0:
		return false
	# Check if player has any cargo to sell
	for commodity_id in cargo:
		if cargo[commodity_id] > 0:
			return false
	return true

func is_stranded() -> bool:
	return fuel <= 0

func has_won() -> bool:
	# Include bank balance in net worth calculation
	return get_net_worth() >= 100000

func get_net_worth() -> int:
	var total := credits + bank_balance
	for loan in loans:
		total -= loan.get("amount_owed", 0)
	return total

# --- Banking Methods ---

func deposit_to_bank(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	bank_balance += amount
	credits_changed.emit(credits)
	bank_balance_changed.emit(bank_balance)
	return true

func withdraw_from_bank(amount: int) -> bool:
	if bank_balance < amount:
		return false
	bank_balance -= amount
	credits += amount
	credits_changed.emit(credits)
	bank_balance_changed.emit(bank_balance)
	return true

func take_loan(principal: int, interest_rate: float, duration_days: int) -> bool:
	if loans.size() >= 3:  # Max 3 concurrent loans
		return false
	var loan := {
		"principal": principal,
		"interest_rate": interest_rate,
		"due_day": day + duration_days,
		"amount_owed": principal
	}
	loans.append(loan)
	credits += principal
	credits_changed.emit(credits)
	return true

func repay_loan(loan_index: int, amount: int) -> Dictionary:
	if loan_index < 0 or loan_index >= loans.size():
		return {"success": false, "message": "Invalid loan"}
	if credits < amount:
		return {"success": false, "message": "Not enough credits"}

	var loan: Dictionary = loans[loan_index]
	var owed: int = loan.get("amount_owed", 0)
	var payment := mini(amount, owed)

	credits -= payment
	loan["amount_owed"] = owed - payment
	credits_changed.emit(credits)

	if loan["amount_owed"] <= 0:
		loans.remove_at(loan_index)
		# Improve credit rating for paying off loan
		var due_day: int = loan.get("due_day", day)
		var on_time: bool = day <= due_day
		if on_time:
			credit_rating = mini(200, credit_rating + 5)
		return {"success": true, "message": "Loan paid off!", "paid_off": true, "on_time": on_time}

	return {"success": true, "message": "Paid %d towards loan" % payment, "paid_off": false}

func get_max_loan_amount() -> int:
	# Credit rating 100 = 10,000 max, scales with rating
	return 5000 + (credit_rating * 50)

func get_loan_interest_rate() -> float:
	# Base 1%, modified by credit rating (lower rating = higher rate)
	return 0.01 * (200.0 - credit_rating) / 100.0

func get_total_debt() -> int:
	var total := 0
	for loan in loans:
		total += loan.get("amount_owed", 0)
	return total

func has_overdue_loans() -> bool:
	for loan in loans:
		if day > loan.get("due_day", 0):
			return true
	return false

# --- Passenger Methods ---

func get_passenger_count() -> int:
	var count := 0
	for contract in accepted_passengers:
		count += contract.count if contract.has("count") else 1
	return count

func get_passenger_berths_free() -> int:
	if ship == null:
		return 0
	return ship.passenger_berths - get_passenger_count()

func change_reputation(amount: int) -> void:
	passenger_reputation = clampi(passenger_reputation + amount, 0, 100)
	reputation_changed.emit(passenger_reputation)

# --- Crew Methods ---

func get_crew_count() -> int:
	return crew.size()

func get_daily_wages() -> int:
	var total := 0
	for member in crew:
		if member.has_method("get_daily_wage"):
			total += member.get_daily_wage()
		else:
			total += member.get("wage", 20)
	return total

func to_dict() -> Dictionary:
	# Serialize passengers
	var passengers_data: Array = []
	for contract in accepted_passengers:
		if contract.has_method("to_dict"):
			passengers_data.append(contract.to_dict())
		elif contract is Dictionary:
			passengers_data.append(contract)

	# Serialize investments
	var investments_data: Array = []
	for inv in investments:
		if inv.has_method("to_dict"):
			investments_data.append(inv.to_dict())
		elif inv is Dictionary:
			investments_data.append(inv)

	# Serialize crew
	var crew_data: Array = []
	for member in crew:
		if member.has_method("to_dict"):
			crew_data.append(member.to_dict())
		elif member is Dictionary:
			crew_data.append(member)

	return {
		"credits": credits,
		"current_planet": current_planet,
		"ship": ship.to_dict() if ship else {},
		"cargo": cargo.duplicate(),
		"cargo_purchase_prices": cargo_purchase_prices.duplicate(),
		"fuel": fuel,
		"day": day,
		"statistics": statistics.duplicate(),
		# Banking
		"bank_balance": bank_balance,
		"loans": loans.duplicate(true),
		"credit_rating": credit_rating,
		# Passengers
		"accepted_passengers": passengers_data,
		"passenger_reputation": passenger_reputation,
		# Investments
		"investments": investments_data,
		# Crew
		"crew": crew_data,
		# Corporations
		"corp_standings": corp_standings.duplicate(),
		"active_contracts": active_contracts.duplicate(true),
		"sealed_cargo": sealed_cargo.duplicate(true)
	}

static func from_dict(data: Dictionary) -> Player:
	var player := Player.new()
	player.credits = data.get("credits", 1000)
	player.current_planet = data.get("current_planet", "earth")
	player.cargo = data.get("cargo", {})
	player.cargo_purchase_prices = data.get("cargo_purchase_prices", {})
	player.fuel = data.get("fuel", 50)
	player.day = data.get("day", 1)
	player.statistics = data.get("statistics", player.statistics)
	if data.has("ship") and not data["ship"].is_empty():
		player.ship = Ship.from_dict(data["ship"])

	# Banking (v4+)
	player.bank_balance = data.get("bank_balance", 0)
	player.loans = data.get("loans", [])
	player.credit_rating = data.get("credit_rating", 100)

	# Passengers (v4+)
	player.accepted_passengers = data.get("accepted_passengers", [])
	player.passenger_reputation = data.get("passenger_reputation", 50)

	# Investments (v4+)
	player.investments = data.get("investments", [])

	# Crew (v4+)
	player.crew = data.get("crew", [])

	# Corporations (v5+)
	player.corp_standings = data.get("corp_standings", {})
	player.active_contracts = data.get("active_contracts", [])
	player.sealed_cargo = data.get("sealed_cargo", [])

	return player
