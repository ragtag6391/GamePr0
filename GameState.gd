extends Node

var coins: int = 50
var debt: int = 100
var pending_winnings: int = 0
var ui_open: bool = false
var debt_cleared: bool = false

signal coins_changed(new_amount: int)
signal debt_changed(new_amount: int)
signal pending_winnings_changed(new_amount: int)
signal ui_open_changed(is_open: bool)
signal debt_cleared_signal

var right_eye_control: Control = null
var left_eye_control: Control = null

func set_ui_open(is_open: bool) -> void:
	ui_open = is_open
	ui_open_changed.emit(ui_open)


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	
	coins += amount
	coins_changed.emit(coins)


func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return false
	
	if amount > coins:
		return false
	
	coins -= amount
	coins_changed.emit(coins)
	return true


func add_pending_winnings(amount: int) -> void:
	if amount <= 0:
		return
	
	pending_winnings += amount
	pending_winnings_changed.emit(pending_winnings)


func claim_pending_winnings() -> int:
	if pending_winnings <= 0:
		return 0
	
	var amount: int = pending_winnings
	pending_winnings = 0
	pending_winnings_changed.emit(pending_winnings)
	
	add_coins(amount)
	return amount


func pay_debt(amount: int) -> int:
	if amount <= 0:
		return 0
	
	if coins <= 0:
		return 0
	
	if debt <= 0:
		return 0
	
	var actual_payment: int = min(amount, coins, debt)
	
	coins -= actual_payment
	debt -= actual_payment
	
	coins_changed.emit(coins)
	debt_changed.emit(debt)
	
	if debt <= 0 and debt_cleared == false:
		debt = 0
		debt_cleared = true
		debt_changed.emit(debt)
		debt_cleared_signal.emit()
	
	return actual_payment


func get_max_debt_payment() -> int:
	return min(coins, debt)


func can_pay_debt() -> bool:
	return coins > 0 and debt > 0


func can_gamble() -> bool:
	return coins > 0 and debt > 0


func reset_game() -> void:
	coins = 50
	debt = 100
	pending_winnings = 0
	ui_open = false
	debt_cleared = false
	
	coins_changed.emit(coins)
	debt_changed.emit(debt)
	pending_winnings_changed.emit(pending_winnings)
	ui_open_changed.emit(ui_open)

func _process(_delta: float) -> void:
	if ui_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
