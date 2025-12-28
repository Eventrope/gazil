extends Control

@onready var credits_label: Label = $MarginContainer/VBoxContainer/Header/CreditsLabel
@onready var balance_label: Label = $MarginContainer/VBoxContainer/Header/BalanceLabel
@onready var rating_label: Label = $MarginContainer/VBoxContainer/Header/RatingLabel

@onready var savings_amount: Label = $MarginContainer/VBoxContainer/ContentContainer/SavingsPanel/VBoxContainer/SavingsAmount
@onready var interest_info: Label = $MarginContainer/VBoxContainer/ContentContainer/SavingsPanel/VBoxContainer/InterestInfo
@onready var deposit_input: SpinBox = $MarginContainer/VBoxContainer/ContentContainer/SavingsPanel/VBoxContainer/DepositRow/DepositInput
@onready var deposit_button: Button = $MarginContainer/VBoxContainer/ContentContainer/SavingsPanel/VBoxContainer/DepositRow/DepositButton
@onready var withdraw_input: SpinBox = $MarginContainer/VBoxContainer/ContentContainer/SavingsPanel/VBoxContainer/WithdrawRow/WithdrawInput
@onready var withdraw_button: Button = $MarginContainer/VBoxContainer/ContentContainer/SavingsPanel/VBoxContainer/WithdrawRow/WithdrawButton

@onready var loan_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/LoansPanel/VBoxContainer/LoanList
@onready var new_loan_container: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/LoansPanel/VBoxContainer/NewLoanContainer
@onready var loan_amount_input: SpinBox = $MarginContainer/VBoxContainer/ContentContainer/LoansPanel/VBoxContainer/NewLoanContainer/LoanAmountRow/LoanAmountInput
@onready var loan_info_label: Label = $MarginContainer/VBoxContainer/ContentContainer/LoansPanel/VBoxContainer/NewLoanContainer/LoanInfoLabel
@onready var take_loan_button: Button = $MarginContainer/VBoxContainer/ContentContainer/LoansPanel/VBoxContainer/NewLoanContainer/TakeLoanButton

@onready var message_label: Label = $MarginContainer/VBoxContainer/Footer/MessageLabel

func _ready() -> void:
	_update_display()
	deposit_input.value_changed.connect(_on_deposit_value_changed)
	withdraw_input.value_changed.connect(_on_withdraw_value_changed)
	loan_amount_input.value_changed.connect(_on_loan_amount_changed)

func _update_display() -> void:
	var player := GameState.player

	# Header
	credits_label.text = "Cash: %s cr" % _format_number(player.credits)
	balance_label.text = "Savings: %s cr" % _format_number(player.bank_balance)
	rating_label.text = "Credit Rating: %s" % _get_rating_text(player.credit_rating)
	rating_label.add_theme_color_override("font_color", _get_rating_color(player.credit_rating))

	# Savings section
	savings_amount.text = "%s cr" % _format_number(player.bank_balance)
	var daily_interest := int(player.bank_balance * GameState.SAVINGS_INTEREST_RATE)
	interest_info.text = "Earns ~%s cr/day (0.2%%)" % _format_number(daily_interest)

	# Deposit/Withdraw limits
	deposit_input.max_value = player.credits
	deposit_input.value = mini(int(deposit_input.value), player.credits)
	withdraw_input.max_value = player.bank_balance
	withdraw_input.value = mini(int(withdraw_input.value), player.bank_balance)

	# Loan section
	_build_loan_list()
	_update_new_loan_section()

func _build_loan_list() -> void:
	for child in loan_list.get_children():
		child.queue_free()

	var player := GameState.player

	if player.loans.is_empty():
		var no_loans := Label.new()
		no_loans.text = "No active loans"
		no_loans.add_theme_font_size_override("font_size", 14)
		no_loans.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		no_loans.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		loan_list.add_child(no_loans)
		return

	for i in range(player.loans.size()):
		var loan: Dictionary = player.loans[i]
		var loan_row := _create_loan_row(i, loan)
		loan_list.add_child(loan_row)

func _create_loan_row(index: int, loan: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)

	var player := GameState.player
	var days_left: int = loan.get("due_day", 0) - player.day
	var is_overdue := days_left < 0

	# Loan info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var amount_label := Label.new()
	amount_label.text = "Owed: %s cr" % _format_number(loan.get("amount_owed", 0))
	amount_label.add_theme_font_size_override("font_size", 16)
	if is_overdue:
		amount_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	info.add_child(amount_label)

	var due_label := Label.new()
	if is_overdue:
		due_label.text = "OVERDUE by %d days!" % abs(days_left)
		due_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		due_label.text = "Due in %d days (Day %d)" % [days_left, loan.get("due_day", 0)]
		if days_left <= 5:
			due_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
		else:
			due_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	due_label.add_theme_font_size_override("font_size", 12)
	info.add_child(due_label)

	row.add_child(info)

	# Repay input
	var repay_input := SpinBox.new()
	repay_input.min_value = 0
	repay_input.max_value = mini(player.credits, loan.get("amount_owed", 0))
	repay_input.value = repay_input.max_value
	repay_input.custom_minimum_size = Vector2(120, 35)
	repay_input.suffix = " cr"
	row.add_child(repay_input)

	# Repay button
	var repay_btn := Button.new()
	repay_btn.text = "Repay"
	repay_btn.custom_minimum_size = Vector2(80, 35)
	repay_btn.disabled = player.credits < 1
	repay_btn.pressed.connect(_on_repay_pressed.bind(index, repay_input))
	row.add_child(repay_btn)

	# Pay full button
	var full_btn := Button.new()
	full_btn.text = "Pay Full"
	full_btn.custom_minimum_size = Vector2(90, 35)
	var owed: int = loan.get("amount_owed", 0)
	full_btn.disabled = player.credits < owed
	full_btn.pressed.connect(_on_repay_full_pressed.bind(index))
	row.add_child(full_btn)

	return row

func _update_new_loan_section() -> void:
	var player := GameState.player

	if player.loans.size() >= 3:
		new_loan_container.visible = false
		return

	new_loan_container.visible = true

	var max_loan := player.get_max_loan_amount()
	var rate := player.get_loan_interest_rate()

	loan_amount_input.max_value = max_loan
	loan_amount_input.value = mini(int(loan_amount_input.value), max_loan)

	var amount := int(loan_amount_input.value)
	var daily_interest := int(amount * rate)
	loan_info_label.text = "Rate: %.1f%%/day (~%s cr/day) | Due in %d days" % [
		rate * 100,
		_format_number(daily_interest),
		GameState.LOAN_DURATION_DAYS
	]

	take_loan_button.disabled = amount < 100

func _get_rating_text(rating: int) -> String:
	if rating >= 180:
		return "Excellent (%d)" % rating
	elif rating >= 140:
		return "Good (%d)" % rating
	elif rating >= 100:
		return "Average (%d)" % rating
	elif rating >= 60:
		return "Poor (%d)" % rating
	else:
		return "Bad (%d)" % rating

func _get_rating_color(rating: int) -> Color:
	if rating >= 180:
		return Color(0.3, 0.9, 0.3)
	elif rating >= 140:
		return Color(0.6, 0.9, 0.3)
	elif rating >= 100:
		return Color(0.9, 0.9, 0.3)
	elif rating >= 60:
		return Color(0.9, 0.6, 0.3)
	else:
		return Color(0.9, 0.3, 0.3)

func _on_deposit_value_changed(_value: float) -> void:
	pass

func _on_withdraw_value_changed(_value: float) -> void:
	pass

func _on_loan_amount_changed(_value: float) -> void:
	_update_new_loan_section()

func _on_deposit_pressed() -> void:
	var amount := int(deposit_input.value)
	if amount <= 0:
		_show_message("Enter an amount to deposit", Color(0.9, 0.7, 0.3))
		return

	if GameState.player.deposit_to_bank(amount):
		_show_message("Deposited %s cr to savings" % _format_number(amount), Color(0.4, 0.9, 0.4))
		deposit_input.value = 0
	else:
		_show_message("Not enough credits!", Color(0.9, 0.3, 0.3))
	_update_display()

func _on_withdraw_pressed() -> void:
	var amount := int(withdraw_input.value)
	if amount <= 0:
		_show_message("Enter an amount to withdraw", Color(0.9, 0.7, 0.3))
		return

	if GameState.player.withdraw_from_bank(amount):
		_show_message("Withdrew %s cr from savings" % _format_number(amount), Color(0.4, 0.9, 0.4))
		withdraw_input.value = 0
	else:
		_show_message("Not enough in savings!", Color(0.9, 0.3, 0.3))
	_update_display()

func _on_deposit_all_pressed() -> void:
	var amount := GameState.player.credits
	if amount <= 0:
		_show_message("No credits to deposit", Color(0.9, 0.7, 0.3))
		return

	if GameState.player.deposit_to_bank(amount):
		_show_message("Deposited all %s cr to savings" % _format_number(amount), Color(0.4, 0.9, 0.4))
	_update_display()

func _on_withdraw_all_pressed() -> void:
	var amount := GameState.player.bank_balance
	if amount <= 0:
		_show_message("No savings to withdraw", Color(0.9, 0.7, 0.3))
		return

	if GameState.player.withdraw_from_bank(amount):
		_show_message("Withdrew all %s cr from savings" % _format_number(amount), Color(0.4, 0.9, 0.4))
	_update_display()

func _on_take_loan_pressed() -> void:
	var amount := int(loan_amount_input.value)
	if amount < 100:
		_show_message("Minimum loan is 100 cr", Color(0.9, 0.7, 0.3))
		return

	var player := GameState.player
	var rate := player.get_loan_interest_rate()

	if player.take_loan(amount, rate, GameState.LOAN_DURATION_DAYS):
		_show_message("Loan of %s cr approved!" % _format_number(amount), Color(0.4, 0.9, 0.4))
		loan_amount_input.value = 0
	else:
		_show_message("Maximum 3 loans allowed!", Color(0.9, 0.3, 0.3))
	_update_display()

func _on_repay_pressed(loan_index: int, repay_input: SpinBox) -> void:
	var amount := int(repay_input.value)
	if amount <= 0:
		_show_message("Enter an amount to repay", Color(0.9, 0.7, 0.3))
		return

	var result := GameState.player.repay_loan(loan_index, amount)
	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.9, 0.4))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_display()

func _on_repay_full_pressed(loan_index: int) -> void:
	var player := GameState.player
	if loan_index >= player.loans.size():
		return

	var loan: Dictionary = player.loans[loan_index]
	var owed: int = loan.get("amount_owed", 0)

	var result := player.repay_loan(loan_index, owed)
	if result["success"]:
		_show_message(result["message"], Color(0.4, 0.9, 0.4))
	else:
		_show_message(result["message"], Color(0.9, 0.3, 0.3))
	_update_display()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")

func _show_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)

func _format_number(num: int) -> String:
	var str_num := str(num)
	var result := ""
	var count := 0
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	return result
