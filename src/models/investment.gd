class_name Investment
extends RefCounted

var id: String
var type_id: String
var amount: int
var purchase_day: int
var maturity_day: int
var expected_return: float  # Calculated at purchase based on risk

func _init() -> void:
	id = ""
	type_id = ""
	amount = 0
	purchase_day = 0
	maturity_day = 0
	expected_return = 0.0

static func create(type_data: Dictionary, invest_amount: int, current_day: int) -> Investment:
	var inv := Investment.new()
	inv.id = "inv_%d_%d" % [current_day, randi() % 10000]
	inv.type_id = type_data.get("id", "")
	inv.amount = invest_amount
	inv.purchase_day = current_day

	var duration: int = type_data.get("duration_days", 30)
	inv.maturity_day = current_day + duration

	# Calculate expected return with some randomness based on volatility
	var base_return: float = type_data.get("base_return", 0.05)
	var volatility: float = type_data.get("volatility", 0.0)
	var risk: float = type_data.get("risk", 0.0)

	# Roll for success/failure based on risk
	if randf() < risk:
		# Partial or total loss
		var loss_severity := randf()
		if loss_severity < 0.5:
			# Partial loss - get back 20-80% of investment
			inv.expected_return = -1.0 + randf_range(0.2, 0.8)
		else:
			# Total loss
			inv.expected_return = -1.0
	else:
		# Success - return varies by volatility
		var variance := randf_range(-volatility, volatility)
		inv.expected_return = base_return + variance

	return inv

func is_matured(current_day: int) -> bool:
	return current_day >= maturity_day

func get_days_remaining(current_day: int) -> int:
	return maxi(0, maturity_day - current_day)

func get_payout() -> int:
	# Returns the total payout (original + return)
	var return_amount := int(float(amount) * expected_return)
	return maxi(0, amount + return_amount)

func get_profit() -> int:
	# Just the profit/loss portion
	return int(float(amount) * expected_return)

func is_profitable() -> bool:
	return expected_return > 0

func to_dict() -> Dictionary:
	return {
		"id": id,
		"type_id": type_id,
		"amount": amount,
		"purchase_day": purchase_day,
		"maturity_day": maturity_day,
		"expected_return": expected_return
	}

static func from_dict(data: Dictionary) -> Investment:
	var inv := Investment.new()
	inv.id = data.get("id", "")
	inv.type_id = data.get("type_id", "")
	inv.amount = data.get("amount", 0)
	inv.purchase_day = data.get("purchase_day", 0)
	inv.maturity_day = data.get("maturity_day", 0)
	inv.expected_return = data.get("expected_return", 0.0)
	return inv
