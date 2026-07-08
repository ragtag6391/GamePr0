extends Node

var coins: int = 50
var debt: int = 100
var pending_winnings: int = 0

signal coins_changed(new_amount: int)
signal debt_changed(new_amount: int)
signal pending_winnings_changed(new_amount: int)


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
	
	var amount := pending_winnings
	pending_winnings = 0
	pending_winnings_changed.emit(pending_winnings)
	
	add_coins(amount)
	return amount


func pay_debt(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var actual_payment = min(amount, coins, debt)
	
	coins -= actual_payment
	debt -= actual_payment
	
	coins_changed.emit(coins)
	debt_changed.emit(debt)
	
	return actual_payment
