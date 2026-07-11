extends Control

@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var coins_label: Label = find_child("CoinsLabel", true, false) as Label
@onready var debt_label: Label = find_child("DebtLabel", true, false) as Label
@onready var pay_label: Label = find_child("PayLabel", true, false) as Label
@onready var pay_input: SpinBox = find_child("PayInput", true, false) as SpinBox
@onready var result_label: Label = find_child("ResultLabel", true, false) as Label
@onready var pay_button: Button = find_child("PayButton", true, false) as Button
@onready var pay_all_button: Button = find_child("PayAllButton", true, false) as Button


func _ready() -> void:
	title_label.text = "DEBT COLLECTOR"
	pay_label.text = "COINS TO INSERT"
	pay_button.text = "INSERT COINS"
	pay_all_button.text = "PAY MAX"
	result_label.text = "The machine waits."

	pay_input.min_value = 1
	pay_input.step = 1

	pay_button.pressed.connect(_on_pay_pressed)
	pay_all_button.pressed.connect(_on_pay_all_pressed)

	GameState.coins_changed.connect(_on_game_state_changed)
	GameState.debt_changed.connect(_on_game_state_changed)

	style_ui()
	update_ui()


func _on_game_state_changed(_new_amount: int) -> void:
	update_ui()


func _on_pay_pressed() -> void:
	if GameState.debt <= 0:
		result_label.text = "Debt already cleared."
		update_ui()
		return

	if GameState.coins <= 0:
		result_label.text = "You have no coins."
		update_ui()
		return

	var amount: int = int(pay_input.value)
	var paid: int = GameState.pay_debt(amount)

	if paid <= 0:
		result_label.text = "The machine refuses."
	else:
		result_label.text = "Inserted " + str(paid) + " coins."

	if GameState.debt <= 0:
		result_label.text += "\nDebt cleared. Something unlocks."

	update_ui()


func _on_pay_all_pressed() -> void:
	if GameState.debt <= 0:
		result_label.text = "Debt already cleared."
		update_ui()
		return

	if GameState.coins <= 0:
		result_label.text = "You have no coins."
		update_ui()
		return

	var max_payment: int = int(min(GameState.coins, GameState.debt))
	var paid: int = GameState.pay_debt(max_payment)

	result_label.text = "Inserted " + str(paid) + " coins."

	if GameState.debt <= 0:
		result_label.text += "\nDebt cleared. Something unlocks."

	update_ui()


func update_ui() -> void:
	coins_label.text = "INVENTORY COINS = " + str(GameState.coins)
	debt_label.text = "DEBT = " + str(GameState.debt)

	var max_payment: int = int(min(GameState.coins, GameState.debt))

	if max_payment <= 0:
		pay_input.max_value = 1
		pay_input.value = 1
		pay_input.editable = false
		pay_button.disabled = true
		pay_all_button.disabled = true
	else:
		pay_input.max_value = max_payment
		pay_input.editable = true
		pay_button.disabled = false
		pay_all_button.disabled = false

		if pay_input.value > max_payment:
			pay_input.value = max_payment


func style_ui() -> void:
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title_label.add_theme_font_size_override("font_size", 36)
	coins_label.add_theme_font_size_override("font_size", 24)
	debt_label.add_theme_font_size_override("font_size", 32)
	pay_label.add_theme_font_size_override("font_size", 22)
	result_label.add_theme_font_size_override("font_size", 22)
	pay_button.add_theme_font_size_override("font_size", 28)
	pay_all_button.add_theme_font_size_override("font_size", 24)

	title_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.1))
	coins_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	debt_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.08))
	pay_label.add_theme_color_override("font_color", Color(0.75, 0.68, 0.55))
	result_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.7))
