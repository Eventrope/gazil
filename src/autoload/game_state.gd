extends Node

# GameState - Manages current game session and persistence

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 5  # v5: Added corporations, contracts, sealed cargo

const SAVINGS_INTEREST_RATE := 0.002  # 0.2% per day
const BASE_LOAN_RATE := 0.01  # 1% per day
const LOAN_DURATION_DAYS := 30

var player: Player = null
var price_drifts: Dictionary = {}  # {planet_id: {commodity_id: float}}
var planet_stocks: Dictionary = {}  # {planet_id: {commodity_id: int}}
var active_news_events: Array = []  # Array of NewsEvent
var is_game_active := false

# Competition mode settings
var competition_mode := false
var bot_count := 5
var difficulty := "medium"
var game_length := 200  # Days until game ends
var debug_bots := false

signal game_started()
signal game_ended(won: bool)
signal day_advanced(new_day: int)
signal player_traveled(from_planet: String, to_planet: String)
signal news_event_started(event: NewsEvent)
signal news_event_ended(event: NewsEvent)
signal bank_interest_applied(savings_interest: int, loan_interest: int)
signal loan_overdue(loan: Dictionary, days_overdue: int)
signal ship_breakdown(severity: String)  # minor, major, critical
signal investment_matured(investment: Investment, payout: int)
signal crew_quit(member: CrewMember)
signal bots_processed(actions: Array)  # Bot actions during player travel
signal competition_ended(player_rank: int, player_won: bool)
signal contracts_refreshed(contracts: Array)  # When contracts refresh on planet arrival
signal contract_completed(contract: Contract, reward: int)
signal contract_failed(contract: Contract, penalty: int)
signal embargo_violation_detected(contract: Contract, fine: int)
signal sealed_cargo_contraband_found(cargo: SealedCargo, fine: int)

func _ready() -> void:
	pass

# Called when user clicks "New Game" - prepares world state before ship selection
func start_new_game(enable_competition: bool = false, num_bots: int = 5, game_difficulty: String = "medium", days: int = 200) -> void:
	player = null
	_init_price_drifts()
	_init_planet_stocks()
	active_news_events.clear()
	is_game_active = false

	# Competition mode settings
	competition_mode = enable_competition
	bot_count = num_bots
	difficulty = game_difficulty
	game_length = days

# Called after player selects their ship - finalizes game start
func finalize_new_game(ship_id: String) -> void:
	player = Player.new()
	player.ship = DataRepo.create_ship(ship_id)
	if player.ship == null:
		push_error("GameState: Failed to create ship: " + ship_id)
		return
	player.fuel = player.ship.fuel_tank
	is_game_active = true

	# Initialize bots if in competition mode
	if competition_mode:
		BotManager.initialize_bots(bot_count, difficulty)
		BotManager.debug_mode = debug_bots
		print("GameState: Competition mode enabled with %d bots at %s difficulty" % [bot_count, difficulty])

	game_started.emit()
	print("GameState: New game started with ship: " + ship_id)

func return_to_main_menu() -> void:
	player = null
	is_game_active = false
	price_drifts.clear()
	planet_stocks.clear()
	active_news_events.clear()

func _init_price_drifts() -> void:
	price_drifts.clear()
	for planet_id in DataRepo.get_all_planet_ids():
		price_drifts[planet_id] = {}
		for commodity_id in DataRepo.get_all_commodity_ids():
			price_drifts[planet_id][commodity_id] = 0.0

func _init_planet_stocks() -> void:
	planet_stocks.clear()
	for planet_id in DataRepo.get_all_planet_ids():
		planet_stocks[planet_id] = {}
		var planet := DataRepo.get_planet(planet_id)
		for commodity_id in DataRepo.get_all_commodity_ids():
			planet_stocks[planet_id][commodity_id] = planet.get_base_stock(commodity_id)

func get_price_at(planet_id: String, commodity_id: String) -> int:
	var planet := DataRepo.get_planet(planet_id)
	var commodity := DataRepo.get_commodity(commodity_id)
	if planet == null or commodity == null:
		return 0
	var drift: float = price_drifts.get(planet_id, {}).get(commodity_id, 0.0)

	# Get news event effects
	var news_effects := NewsManager.get_combined_effects(active_news_events, planet_id, commodity_id)
	var news_modifier: float = news_effects["price_modifier"]

	# Calculate stock effect on price
	var current_stock: int = get_stock_at(planet_id, commodity_id)
	var base_stock: int = planet.get_base_stock(commodity_id)
	var stock_ratio: float = float(current_stock) / float(max(base_stock, 1))
	# Low stock = higher prices, high stock = lower prices
	# At 0% stock: +25%, at 100% stock: normal, at 200% stock: -25%
	var stock_effect: float = 1.0 + (0.5 - stock_ratio) * 0.5
	stock_effect = clampf(stock_effect, 0.75, 1.5)

	var base_price: int = commodity.get_price_at(planet, drift)
	var final_price: int = int(max(1, round(base_price * news_modifier * stock_effect)))
	return final_price

func advance_day(days: int = 1) -> void:
	if player == null:
		return
	player.day += days
	_drift_prices()
	_regenerate_stocks(days)
	_process_news_events()
	_process_banking(days)
	_process_crew_wages(days)
	_process_investments()
	day_advanced.emit(player.day)

func _drift_prices() -> void:
	# Prices drift slightly each day based on volatility
	for planet_id in price_drifts:
		var planet := DataRepo.get_planet(planet_id)
		if planet == null:
			continue
		for commodity_id in price_drifts[planet_id]:
			var current_drift: float = price_drifts[planet_id][commodity_id]
			var volatility: float = planet.supply_volatility
			# Random walk with mean reversion
			var change := randf_range(-volatility, volatility)
			var new_drift: float = current_drift + change
			# Mean reversion - pull back toward 0
			new_drift *= 0.95
			# Clamp to reasonable bounds
			new_drift = clampf(new_drift, -0.5, 0.5)
			price_drifts[planet_id][commodity_id] = new_drift

func _regenerate_stocks(days: int) -> void:
	for planet_id in planet_stocks:
		var planet := DataRepo.get_planet(planet_id)
		if planet == null:
			continue
		for commodity_id in planet_stocks[planet_id]:
			var current: int = planet_stocks[planet_id][commodity_id]
			var base: int = planet.get_base_stock(commodity_id)
			var regen_rate: float = planet.get_stock_regen(commodity_id)
			# Regenerate toward base stock
			var regen_amount: int = int(regen_rate * days)
			if current < base:
				planet_stocks[planet_id][commodity_id] = mini(current + regen_amount, base)
			elif current > base * 2:
				# If overstocked, slowly decay toward base
				planet_stocks[planet_id][commodity_id] = maxi(current - regen_amount / 2, base)

func _process_news_events() -> void:
	var result := NewsManager.process_day(player.day, active_news_events)

	# Remove expired events
	for expired_event in result["expired"]:
		active_news_events.erase(expired_event)
		news_event_ended.emit(expired_event)

	# Add new event if one was spawned
	if result["new_event"] != null:
		active_news_events.append(result["new_event"])
		news_event_started.emit(result["new_event"])

func _process_banking(days: int) -> void:
	if player == null:
		return

	var savings_interest := 0
	var loan_interest := 0

	# Apply savings interest
	if player.bank_balance > 0:
		for _i in range(days):
			var interest := int(player.bank_balance * SAVINGS_INTEREST_RATE)
			player.bank_balance += interest
			savings_interest += interest

	# Apply loan interest and check overdue
	for loan in player.loans:
		for _i in range(days):
			var interest := int(loan["amount_owed"] * loan.get("interest_rate", BASE_LOAN_RATE))
			loan["amount_owed"] += interest
			loan_interest += interest

		# Check if overdue
		var days_overdue: int = player.day - loan.get("due_day", 0)
		if days_overdue > 0:
			loan_overdue.emit(loan, days_overdue)
			# Penalize credit rating for overdue loans
			if days_overdue == 7 or days_overdue == 14 or days_overdue == 21:
				player.credit_rating = maxi(0, player.credit_rating - 10)

	if savings_interest > 0 or loan_interest > 0:
		bank_interest_applied.emit(savings_interest, loan_interest)

func _process_crew_wages(days: int) -> void:
	if player == null or player.crew.is_empty():
		return

	var total_wages := 0
	var quitters: Array = []

	# Process each crew member
	for i in range(player.crew.size() - 1, -1, -1):
		var crew_data = player.crew[i]
		var member: CrewMember

		if crew_data is Dictionary:
			member = CrewMember.from_dict(crew_data)
		else:
			member = crew_data

		var wage := member.get_daily_wage() * days
		total_wages += wage

		if player.credits >= wage:
			player.spend_credits(wage)
			member.pay_wage_success()
		else:
			# Can't pay - morale drops
			member.pay_wage_failure()

		# Check if quitting
		if member.is_quitting():
			crew_quit.emit(member)
			quitters.append(i)
		else:
			# Update stored data
			if crew_data is Dictionary:
				player.crew[i] = member.to_dict()
			else:
				player.crew[i] = member

	# Remove quitters (in reverse order)
	for idx in quitters:
		player.crew.remove_at(idx)

func _process_investments() -> void:
	if player == null:
		return

	var matured: Array = []
	for i in range(player.investments.size() - 1, -1, -1):
		var inv_data = player.investments[i]
		var inv: Investment

		if inv_data is Dictionary:
			inv = Investment.from_dict(inv_data)
		else:
			inv = inv_data

		if inv.is_matured(player.day):
			var payout := inv.get_payout()
			player.add_credits(payout)
			investment_matured.emit(inv, payout)
			matured.append(i)

	# Remove matured investments (in reverse order)
	for idx in matured:
		player.investments.remove_at(idx)

func _check_breakdown() -> Dictionary:
	# Check if ship breaks down based on current reliability
	if player == null or player.ship == null:
		return {"occurred": false}

	var breakdown_chance := player.ship.get_breakdown_chance()
	if breakdown_chance <= 0.0:
		return {"occurred": false}

	if randf() > breakdown_chance:
		return {"occurred": false}

	# Breakdown occurred! Determine severity
	var severity: String
	var extra_days: int
	var roll := randf()

	if roll < 0.6:
		severity = "minor"
		extra_days = randi_range(1, 2)
	elif roll < 0.9:
		severity = "major"
		extra_days = randi_range(2, 4)
	else:
		severity = "critical"
		extra_days = randi_range(4, 7)

	ship_breakdown.emit(severity)

	return {
		"occurred": true,
		"severity": severity,
		"extra_days": extra_days
	}

func _check_contraband_inspection(destination: Planet) -> Dictionary:
	# Check if player has contraband
	var contraband_qty := player.get_cargo_quantity("contraband")
	if contraband_qty <= 0:
		return {"inspected": false}

	# Roll for inspection based on planet's inspection chance
	if randf() > destination.inspection_chance:
		return {"inspected": false}

	# Inspection triggered - return info for UI to handle
	var contraband := DataRepo.get_commodity("contraband")
	var value := 0
	if contraband:
		value = get_price_at(destination.id, "contraband") * contraband_qty

	var fine := int(value * 0.5)  # 50% of goods value as fine

	return {
		"inspected": true,
		"contraband_qty": contraband_qty,
		"contraband_value": value,
		"fine": fine,
		"planet_name": destination.planet_name
	}

func confiscate_contraband(pay_fine: bool) -> Dictionary:
	# Called when player chooses to surrender
	var contraband_qty := player.get_cargo_quantity("contraband")
	if contraband_qty <= 0:
		return {"success": false, "message": "No contraband to confiscate"}

	var contraband := DataRepo.get_commodity("contraband")
	var value := 0
	if contraband:
		value = get_price_at(player.current_planet, "contraband") * contraband_qty

	var fine := int(value * 0.5)

	# Remove contraband
	player.remove_cargo("contraband", contraband_qty)

	var message := "Contraband confiscated!"
	if pay_fine and player.credits >= fine:
		player.spend_credits(fine)
		message += " Paid %d cr fine." % fine
	elif pay_fine:
		# Can't pay full fine - take what they have
		var paid := player.credits
		player.spend_credits(paid)
		message += " Paid %d cr (couldn't afford full %d fine)." % [paid, fine]

	return {"success": true, "message": message, "confiscated": contraband_qty, "fine_paid": fine}

func attempt_escape() -> Dictionary:
	# Called when player tries to run from inspection
	# Success based on ship speed vs base chance
	var base_escape_chance := 0.3  # 30% base
	var speed_bonus := 0.0
	if player.ship:
		# Faster ships have better escape chance
		speed_bonus = (player.ship.speed - 5) * 0.05  # +5% per speed point above 5

	var escape_chance := clampf(base_escape_chance + speed_bonus, 0.1, 0.7)

	if randf() < escape_chance:
		# Escaped! But banned from planet for 10 days
		# (Would need to track this - simplified for now)
		return {
			"success": true,
			"escaped": true,
			"message": "You outran the inspectors! But you're not welcome here for a while..."
		}
	else:
		# Caught - double fine and confiscation
		var contraband_qty := player.get_cargo_quantity("contraband")
		var contraband := DataRepo.get_commodity("contraband")
		var value := 0
		if contraband:
			value = get_price_at(player.current_planet, "contraband") * contraband_qty

		var fine := int(value * 1.0)  # Double fine (100% instead of 50%)

		player.remove_cargo("contraband", contraband_qty)
		if player.credits >= fine:
			player.spend_credits(fine)
		else:
			player.spend_credits(player.credits)

		return {
			"success": true,
			"escaped": false,
			"message": "Caught! Contraband confiscated and %d cr fine applied." % fine,
			"confiscated": contraband_qty,
			"fine": fine
		}

func travel_to(planet_id: String) -> Dictionary:
	# Returns {success: bool, message: String, event: GameEvent or null}
	if player == null:
		return {"success": false, "message": "No active game", "event": null}

	var current := DataRepo.get_planet(player.current_planet)
	var destination := DataRepo.get_planet(planet_id)

	if current == null or destination == null:
		return {"success": false, "message": "Invalid planet", "event": null}

	if player.current_planet == planet_id:
		return {"success": false, "message": "Already at this planet", "event": null}

	# Check if destination is unlocked
	if not destination.is_unlocked(player.day):
		return {"success": false, "message": "Destination unlocks on Day %d" % destination.unlock_day, "event": null}

	# Check if destination is accessible (not blocked by news event)
	if not is_planet_accessible(planet_id):
		return {"success": false, "message": "Destination is currently blocked", "event": null}

	var base_distance := current.get_distance_to(planet_id)

	# Apply travel time modifier from news events
	var travel_modifier := NewsManager.get_travel_time_modifier(active_news_events, player.current_planet, planet_id)
	var distance := int(ceil(base_distance * travel_modifier))

	var fuel_cost := player.ship.get_fuel_cost(distance)

	if player.fuel < fuel_cost:
		return {"success": false, "message": "Not enough fuel (need %d)" % fuel_cost, "event": null}

	# Consume fuel
	player.use_fuel(fuel_cost)

	# Degrade ship reliability from travel
	player.ship.degrade_reliability(distance)

	# Check for breakdown
	var breakdown_result := _check_breakdown()

	# Move player
	var from_planet := player.current_planet
	var extra_days: int = breakdown_result.get("extra_days", 0)
	player.travel_to(planet_id, distance + extra_days)

	# Advance time
	_drift_prices()

	# Process bot turns during player travel (competition mode)
	var bot_actions := []
	if competition_mode:
		bot_actions = BotManager.process_bot_turns(distance + extra_days)
		bots_processed.emit(bot_actions)

	player_traveled.emit(from_planet, planet_id)

	# Process passenger mood effects from travel
	var breakdown_occurred: bool = breakdown_result.get("occurred", false)
	var breakdown_severity: String = breakdown_result.get("severity", "")
	PassengerManager.process_travel_effects(player, distance + extra_days, breakdown_occurred, breakdown_severity)

	# Check for passenger deliveries at destination
	var deliveries := PassengerManager.deliver_passengers(player, planet_id, player.day)

	# Check for random event (with news modifier for increased danger)
	var event_chance_modifier := NewsManager.get_event_chance_modifier(active_news_events, from_planet, planet_id)
	var event := EventManager.roll_event("travel", event_chance_modifier)

	# Check for contraband inspection at destination
	var inspection_result := _check_contraband_inspection(destination)

	# Check sealed cargo for contraband during inspection
	var sealed_cargo_inspection := {"found": false}
	if inspection_result.get("inspected", false):
		sealed_cargo_inspection = CorporationManager.inspect_sealed_cargo(player, destination)
		if sealed_cargo_inspection.get("found", false):
			var fine: int = sealed_cargo_inspection.get("fine", 0)
			if player.credits >= fine:
				player.spend_credits(fine)
			else:
				player.spend_credits(player.credits)
			for cargo in sealed_cargo_inspection.get("cargo", []):
				sealed_cargo_contraband_found.emit(cargo, fine)

	# Check for expired contracts
	var expired_contracts := CorporationManager.check_expired_contracts(player, player.day)
	for expired in expired_contracts:
		contract_failed.emit(expired, expired.penalty)

	# Check for cargo haul contract completion at destination
	var completed_contracts: Array = []
	for contract_data in player.active_contracts:
		var contract := Contract.from_dict(contract_data)
		if contract.status == Contract.Status.ACCEPTED:
			if CorporationManager.check_contract_completion(player, contract_data):
				var result := CorporationManager.complete_contract(player, contract)
				if result.get("success", false):
					completed_contracts.append(contract)
					contract_completed.emit(contract, contract.reward)

	# Generate new contracts at destination
	var new_contracts := CorporationManager.generate_contracts_for_planet(planet_id, player.day, player)
	if not new_contracts.is_empty():
		contracts_refreshed.emit(new_contracts)

	var travel_msg := "Traveled to %s (-%d fuel, %d days)" % [destination.planet_name, fuel_cost, distance + extra_days]
	if travel_modifier > 1.0:
		travel_msg += " [Delayed by events]"
	if breakdown_result.get("occurred", false):
		travel_msg += " [%s breakdown: +%d days]" % [breakdown_result["severity"], extra_days]

	# Add passenger delivery info
	if not deliveries.is_empty():
		var total_payment := 0
		for delivery in deliveries:
			total_payment += delivery["payment"]
		travel_msg += " [Delivered %d passengers: +%d cr]" % [deliveries.size(), total_payment]

	# Add contract completion info
	if not completed_contracts.is_empty():
		var total_reward := 0
		for c in completed_contracts:
			total_reward += c.reward
		travel_msg += " [Completed %d contracts: +%d cr]" % [completed_contracts.size(), total_reward]

	# Add sealed cargo contraband info
	if sealed_cargo_inspection.get("found", false):
		travel_msg += " [Sealed cargo inspected: contraband found, %d cr fine]" % sealed_cargo_inspection.get("fine", 0)

	return {
		"success": true,
		"message": travel_msg,
		"event": event,
		"breakdown": breakdown_result,
		"deliveries": deliveries,
		"bot_actions": bot_actions,
		"inspection": inspection_result,
		"completed_contracts": completed_contracts,
		"expired_contracts": expired_contracts,
		"new_contracts": new_contracts,
		"sealed_cargo_inspection": sealed_cargo_inspection
	}

func buy_commodity(commodity_id: String, quantity: int) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active game"}

	var commodity := DataRepo.get_commodity(commodity_id)
	if commodity == null:
		return {"success": false, "message": "Unknown commodity"}

	# Check available stock
	var available_stock := get_stock_at(player.current_planet, commodity_id)
	if available_stock < quantity:
		return {"success": false, "message": "Not enough stock (only %d available)" % available_stock}

	var price := get_price_at(player.current_planet, commodity_id)
	var total_cost := price * quantity
	var weight := commodity.weight_per_unit * quantity

	if player.credits < total_cost:
		return {"success": false, "message": "Not enough credits (need %d)" % total_cost}

	if player.get_cargo_space_free() < weight:
		return {"success": false, "message": "Not enough cargo space (need %d)" % weight}

	player.spend_credits(total_cost)
	player.add_cargo(commodity_id, quantity, price)
	player.statistics["trades_made"] += 1

	# Reduce planet stock
	_modify_stock(player.current_planet, commodity_id, -quantity)

	return {"success": true, "message": "Bought %d %s for %d credits" % [quantity, commodity.commodity_name, total_cost], "price_per_unit": price}

func sell_commodity(commodity_id: String, quantity: int) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active game"}

	var commodity := DataRepo.get_commodity(commodity_id)
	if commodity == null:
		return {"success": false, "message": "Unknown commodity"}

	if player.get_cargo_quantity(commodity_id) < quantity:
		return {"success": false, "message": "Not enough cargo"}

	var price := get_price_at(player.current_planet, commodity_id)
	var total_value := price * quantity

	# Calculate profit/loss
	var purchase_price := player.get_purchase_price(commodity_id)
	var cost_basis := purchase_price * quantity
	var profit := total_value - cost_basis

	# Check for embargo violations
	var embargo_result := CorporationManager.check_embargo_violation(player, commodity_id, player.current_planet)
	var embargo_detected := false
	var embargo_fine := 0
	if embargo_result.get("violated", false):
		var detection_chance: float = embargo_result.get("detection_chance", 0.5)
		if randf() < detection_chance:
			embargo_detected = true
			var contract: Contract = embargo_result.get("contract")
			if contract:
				# Fail the embargo contract
				embargo_fine = contract.penalty
				CorporationManager.fail_contract(player, contract, "Embargo violation detected")
				embargo_violation_detected.emit(contract, embargo_fine)

	player.remove_cargo(commodity_id, quantity)
	player.add_credits(total_value)
	player.statistics["trades_made"] += 1
	player.statistics["total_profit"] = player.statistics.get("total_profit", 0) + profit

	# Increase planet stock
	_modify_stock(player.current_planet, commodity_id, quantity)

	var profit_str := ""
	if profit > 0:
		profit_str = " (+%d profit)" % profit
	elif profit < 0:
		profit_str = " (%d loss)" % profit

	var result := {
		"success": true,
		"message": "Sold %d %s for %d credits%s" % [quantity, commodity.commodity_name, total_value, profit_str],
		"profit": profit,
		"embargo_detected": embargo_detected,
		"embargo_fine": embargo_fine
	}

	if embargo_detected:
		result["message"] += " [EMBARGO VIOLATION: -%d cr penalty]" % embargo_fine

	return result

func buy_upgrade(upgrade_id: String) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active game"}

	var upgrade := DataRepo.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return {"success": false, "message": "Unknown upgrade"}

	if player.ship.has_upgrade(upgrade_id):
		return {"success": false, "message": "Already installed"}

	var cost: int = upgrade.get("cost", 0)
	if player.credits < cost:
		return {"success": false, "message": "Not enough credits (need %d)" % cost}

	# Check prerequisites
	var prereqs: Array = upgrade.get("requires", [])
	for prereq in prereqs:
		if not player.ship.has_upgrade(prereq):
			var prereq_upgrade := DataRepo.get_upgrade(prereq)
			var prereq_name: String = prereq_upgrade.get("name", prereq)
			return {"success": false, "message": "Requires: %s" % prereq_name}

	player.spend_credits(cost)
	player.ship.apply_upgrade(upgrade)

	return {"success": true, "message": "Installed %s" % upgrade.get("name", upgrade_id)}

func hire_crew(role_id: String, quality: int) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active game"}

	var role_data := DataRepo.get_crew_role(role_id)
	if role_data.is_empty():
		return {"success": false, "message": "Unknown role"}

	# Check ship min_crew limit
	var max_crew := player.ship.min_crew + 3  # Can have up to 3 more than minimum
	if player.crew.size() >= max_crew:
		return {"success": false, "message": "Maximum crew reached (%d)" % max_crew}

	# Hiring cost based on quality
	var base_wage: int = role_data.get("base_wage", 20)
	var hiring_cost := base_wage * quality * 5  # 5 days wages upfront

	if player.credits < hiring_cost:
		return {"success": false, "message": "Not enough credits (need %d)" % hiring_cost}

	player.spend_credits(hiring_cost)
	var member := CrewMember.create(role_data, quality, player.day)
	player.crew.append(member.to_dict())

	return {
		"success": true,
		"message": "Hired %s as %s (%d cr)" % [member.crew_name, role_data.get("name", role_id), hiring_cost],
		"member": member
	}

func fire_crew(index: int) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active game"}

	if index < 0 or index >= player.crew.size():
		return {"success": false, "message": "Invalid crew member"}

	var crew_data = player.crew[index]
	var member: CrewMember
	if crew_data is Dictionary:
		member = CrewMember.from_dict(crew_data)
	else:
		member = crew_data

	# Check if this would put us below minimum crew
	if player.crew.size() <= player.ship.min_crew:
		return {"success": false, "message": "Cannot go below minimum crew (%d)" % player.ship.min_crew}

	player.crew.remove_at(index)

	return {
		"success": true,
		"message": "Released %s from duty" % member.crew_name
	}

func buy_investment(type_id: String, amount: int) -> Dictionary:
	if player == null:
		return {"success": false, "message": "No active game"}

	var type_data := DataRepo.get_investment_type(type_id)
	if type_data.is_empty():
		return {"success": false, "message": "Unknown investment type"}

	var min_inv: int = type_data.get("min_investment", 100)
	var max_inv: int = type_data.get("max_investment", 10000)

	if amount < min_inv:
		return {"success": false, "message": "Minimum investment: %d cr" % min_inv}
	if amount > max_inv:
		return {"success": false, "message": "Maximum investment: %d cr" % max_inv}
	if player.credits < amount:
		return {"success": false, "message": "Not enough credits"}

	# Max 5 concurrent investments
	if player.investments.size() >= 5:
		return {"success": false, "message": "Maximum 5 active investments"}

	player.spend_credits(amount)
	var investment := Investment.create(type_data, amount, player.day)
	player.investments.append(investment.to_dict())

	var type_name: String = type_data.get("name", "Investment")
	return {
		"success": true,
		"message": "Invested %d cr in %s" % [amount, type_name],
		"investment": investment
	}

func repair_ship(amount: int) -> Dictionary:
	if player == null or player.ship == null:
		return {"success": false, "message": "No active game"}

	var ship := player.ship
	var need_repair := ship.reliability - ship.current_reliability
	if need_repair <= 0:
		return {"success": false, "message": "Ship is already at full reliability"}

	var to_repair := mini(amount, need_repair)
	var cost_per_point := ship.get_repair_cost_per_point()

	# TODO: Apply cheap_repairs trait here when implemented
	var total_cost := to_repair * cost_per_point

	if player.credits < total_cost:
		# Repair what we can afford
		to_repair = player.credits / cost_per_point
		if to_repair <= 0:
			return {"success": false, "message": "Not enough credits for repairs"}
		total_cost = to_repair * cost_per_point

	player.spend_credits(total_cost)
	var repaired := ship.repair(to_repair)

	return {
		"success": true,
		"message": "Repaired %d points for %d credits" % [repaired, total_cost],
		"repaired": repaired,
		"cost": total_cost
	}

func check_game_over() -> Dictionary:
	# Returns {game_over: bool, won: bool, reason: String, rank: int}
	if player == null:
		return {"game_over": false, "won": false, "reason": "", "rank": 0}

	# Check standard loss conditions first
	if player.is_stranded():
		is_game_active = false
		game_ended.emit(false)
		return {"game_over": true, "won": false, "reason": "You ran out of fuel and are stranded in space!", "rank": 0}

	if player.is_bankrupt():
		is_game_active = false
		game_ended.emit(false)
		return {"game_over": true, "won": false, "reason": "You went bankrupt!", "rank": 0}

	# Competition mode: game ends after game_length days
	if competition_mode:
		if player.day >= game_length:
			var leaderboard := BotManager.get_leaderboard()
			var player_rank := 1
			for entry in leaderboard:
				if entry["is_player"]:
					player_rank = entry["rank"]
					break

			var won := player_rank == 1
			is_game_active = false
			competition_ended.emit(player_rank, won)
			game_ended.emit(won)

			if won:
				return {"game_over": true, "won": true, "reason": "You finished in 1st place!", "rank": 1}
			else:
				return {"game_over": true, "won": false, "reason": "Competition ended. You placed #%d" % player_rank, "rank": player_rank}
	else:
		# Classic mode: win at 100k
		if player.has_won():
			is_game_active = false
			game_ended.emit(true)
			return {"game_over": true, "won": true, "reason": "You reached 100,000 credits!", "rank": 1}

	return {"game_over": false, "won": false, "reason": "", "rank": 0}

# --- Stock and News Helper Functions ---

func get_stock_at(planet_id: String, commodity_id: String) -> int:
	return planet_stocks.get(planet_id, {}).get(commodity_id, 0)

func _modify_stock(planet_id: String, commodity_id: String, amount: int) -> void:
	if not planet_stocks.has(planet_id):
		planet_stocks[planet_id] = {}
	var current: int = planet_stocks[planet_id].get(commodity_id, 0)
	planet_stocks[planet_id][commodity_id] = maxi(0, current + amount)

func is_planet_accessible(planet_id: String) -> bool:
	return NewsManager.is_planet_accessible(active_news_events, planet_id)

func get_active_news_events() -> Array:
	return active_news_events

func get_fuel_price_at(planet_id: String) -> int:
	var planet := DataRepo.get_planet(planet_id)
	if planet == null:
		return 5
	return int(max(1, round(5.0 * planet.fuel_price_modifier)))

func save_game() -> bool:
	if player == null:
		return false

	# Serialize news events
	var news_events_data: Array = []
	for event in active_news_events:
		news_events_data.append(event.to_dict())

	var save_data := {
		"version": SAVE_VERSION,
		"player": player.to_dict(),
		"price_drifts": price_drifts,
		"planet_stocks": planet_stocks,
		"active_news_events": news_events_data,
		# Competition mode data
		"competition_mode": competition_mode,
		"bot_count": bot_count,
		"difficulty": difficulty,
		"game_length": game_length,
		"debug_bots": debug_bots,
		"bots": BotManager.to_dict() if competition_mode else {},
		# Corporation data
		"corporation_data": CorporationManager.get_save_data(player)
	}

	var json_string := JSON.stringify(save_data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: Cannot save game")
		return false

	file.store_string(json_string)
	file.close()
	print("GameState: Game saved")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("GameState: Cannot parse save file")
		return false

	var save_data: Dictionary = json.data
	var version: int = save_data.get("version", 0)

	# Only support v3 saves (new ship system)
	if version != SAVE_VERSION:
		push_error("GameState: Incompatible save version (expected %d, got %d)" % [SAVE_VERSION, version])
		return false

	player = Player.from_dict(save_data.get("player", {}))
	price_drifts = save_data.get("price_drifts", {})
	planet_stocks = save_data.get("planet_stocks", {})

	active_news_events.clear()
	var news_events_data: Array = save_data.get("active_news_events", [])
	for event_data in news_events_data:
		active_news_events.append(NewsEvent.from_dict(event_data))

	# Restore competition mode settings
	competition_mode = save_data.get("competition_mode", false)
	bot_count = save_data.get("bot_count", 5)
	difficulty = save_data.get("difficulty", "medium")
	game_length = save_data.get("game_length", 200)
	debug_bots = save_data.get("debug_bots", false)

	# Restore bot data
	if competition_mode and save_data.has("bots"):
		BotManager.from_dict(save_data.get("bots", {}))
		BotManager.debug_mode = debug_bots

	# Restore corporation data
	if save_data.has("corporation_data"):
		CorporationManager.load_save_data(save_data.get("corporation_data", {}), player)

	is_game_active = true

	print("GameState: Game loaded" + (" (competition mode)" if competition_mode else ""))
	game_started.emit()
	return true

func has_save_game() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
