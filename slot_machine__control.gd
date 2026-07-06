extends Control

@onready var reel_1: Label = $VBoxContainer/Reels/Reel1
@onready var reel_2: Label = $VBoxContainer/Reels/Reel2
@onready var reel_3: Label = $VBoxContainer/Reels/Reel3

@onready var coins_label: Label = $VBoxContainer/CoinsLabel
@onready var debt_label: Label = $VBoxContainer/DebtLabel
@onready var bet_label: Label = $VBoxContainer/BetLabel
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var bet_input: SpinBox = $VBoxContainer/BetInput
@onready var spin_button: Button = $VBoxContainer/SpinButton

var rng := RandomNumberGenerator.new()

var coins := 50
var debt := 100
var bet := 5
var is_spinning := false

var reels: Array[Label]

var symbols := [
	{"id": "cherry", "display": "CHERRY", "weight": 35},
	{"id": "lemon", "display": "LEMON", "weight": 30},
	{"id": "bell", "display": "BELL", "weight": 20},
	{"id": "skull", "display": "SKULL", "weight": 10},
	{"id": "seven", "display": "7", "weight": 5}
]


func _ready() -> void:
	rng.randomize()
	reels = [reel_1, reel_2, reel_3]

	spin_button.pressed.connect(_on_spin_pressed)

	bet_input.min_value = 1
	bet_input.max_value = coins
	bet_input.step = 1
	bet_input.value = bet

	result_label.text = "Enter bet, then press SPIN."

	for reel in reels:
		reel.text = "?"

	update_ui()


func _on_spin_pressed() -> void:
	if is_spinning:
		return

	bet = int(bet_input.value)

	if bet <= 0:
		result_label.text = "Bet must be at least 1 coin."
		return

	if bet > coins:
		result_label.text = "You cannot bet more coins than you have."
		return

	coins -= bet
	is_spinning = true
	spin_button.disabled = true
	bet_input.editable = false
	result_label.text = "Rolling..."
	update_ui()

	var final_result := [
		get_weighted_symbol(),
		get_weighted_symbol(),
		get_weighted_symbol()
	]

	await roll_reels(final_result)
	evaluate_result(final_result)

	is_spinning = false

	if debt <= 0:
		result_label.text += "\nDebt paid. The door unlocks."
		spin_button.disabled = true
		bet_input.editable = false
	elif coins < 1:
		result_label.text += "\nNo coins left. You failed."
		spin_button.disabled = true
		bet_input.editable = false
	else:
		spin_button.disabled = false
		bet_input.editable = true

	update_ui()


func roll_reels(final_result: Array) -> void:
	var elapsed := 0.0
	var tick := 0.05

	var stop_times := [0.8, 1.2, 1.6]
	var stopped := [false, false, false]

	while elapsed < 1.7:
		for i in range(reels.size()):
			if elapsed < stop_times[i]:
				reels[i].text = get_random_symbol_display()
			elif stopped[i] == false:
				reels[i].text = final_result[i]["display"]
				stopped[i] = true

		await get_tree().create_timer(tick).timeout
		elapsed += tick

	for i in range(reels.size()):
		reels[i].text = final_result[i]["display"]


func evaluate_result(result: Array) -> void:
	var id_1 := str(result[0]["id"])
	var id_2 := str(result[1]["id"])
	var id_3 := str(result[2]["id"])

	var multiplier := 0
	var message := ""

	if id_1 == id_2 and id_2 == id_3:
		multiplier = get_triple_multiplier(id_1)
		message = "Triple " + id_1 + "!"
	elif id_1 == id_2 or id_2 == id_3 or id_1 == id_3:
		multiplier = 2
		message = "Two matched."
	else:
		multiplier = 0
		message = "No match."

	var payout := bet * multiplier
	var net_profit := payout - bet

	if payout > 0:
		coins += payout

		if net_profit > 0:
			debt -= net_profit
			if debt < 0:
				debt = 0

		result_label.text = message + "\nWon: " + str(payout) + " coins."

		if net_profit > 0:
			result_label.text += "\nDebt reduced by " + str(net_profit) + "."
	else:
		result_label.text = message + "\nLost: " + str(bet) + " coins."


func get_triple_multiplier(symbol_id: String) -> int:
	match symbol_id:
		"seven":
			return 10
		"bell":
			return 6
		"skull":
			return 5
		"cherry":
			return 4
		"lemon":
			return 3
		_:
			return 2


func get_weighted_symbol() -> Dictionary:
	var total_weight := 0

	for symbol in symbols:
		total_weight += int(symbol["weight"])

	var roll := rng.randi_range(1, total_weight)
	var current := 0

	for symbol in symbols:
		current += int(symbol["weight"])
		if roll <= current:
			return symbol

	return symbols[0]


func get_random_symbol_display() -> String:
	var index := rng.randi_range(0, symbols.size() - 1)
	return str(symbols[index]["display"])


func update_ui() -> void:
	coins_label.text = "Coins: " + str(coins)
	debt_label.text = "Debt: " + str(debt)
	bet_label.text = "Current Bet: " + str(bet)

	bet_input.max_value = max(1, coins)

	if bet_input.value > coins and coins > 0:
		bet_input.value = coins
