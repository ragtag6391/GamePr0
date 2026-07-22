extends Control

@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var coins_label: Label = find_child("CoinsLabel", true, false) as Label
@onready var debt_label: Label = find_child("DebtLabel", true, false) as Label
@onready var pay_label: Label = find_child("PayLabel", true, false) as Label
@onready var pay_input: SpinBox = find_child("PayInput", true, false) as SpinBox
@onready var result_label: Label = find_child("ResultLabel", true, false) as Label
@onready var pay_button: Button = find_child("PayButton", true, false) as Button
@onready var pay_all_button: Button = find_child("PayAllButton", true, false) as Button

@export var is_mirror_display: bool = false
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

func _grab_main_focus() -> void:
	if pay_all_button != null and not pay_all_button.disabled:
		pay_all_button.grab_focus()

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
	_grab_main_focus() 


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
	_grab_main_focus() 
	
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
func _adjust_amount(direction: int) -> void:
	if direction < 0:
		pay_input.value = max(pay_input.min_value, pay_input.value - pay_input.step)
	else:
		pay_input.value = min(pay_input.max_value, pay_input.value + pay_input.step)
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
	_style_button_rustic(pay_button, 18)
	_style_button_rustic(pay_all_button, 18)
	pay_button.text = "insert coins"
	pay_all_button.text = "pay max"
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible and is_inside_tree():
			_grab_main_focus()
			
func _style_button_rustic(btn: Button, font_size: int = 20) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.067, 0.051, 1.0)
	normal.border_color = Color(0.22, 0.145, 0.098, 1.0)
	normal.set_border_width_all(1)
	normal.border_width_top = 2
	normal.set_corner_radius_all(10)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.12, 0.09, 0.07, 1.0)
	hover.border_color = Color(0.28, 0.19, 0.13, 1.0)
	hover.set_border_width_all(1)
	hover.border_width_top = 2
	hover.set_corner_radius_all(10)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.06, 0.045, 0.035, 1.0)
	pressed.border_color = Color(0.18, 0.12, 0.08, 1.0)
	pressed.set_border_width_all(1)
	pressed.set_corner_radius_all(10)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)

	btn.add_theme_color_override("font_color", Color(0.65, 0.54, 0.41))
	btn.add_theme_color_override("font_hover_color", Color(0.72, 0.60, 0.46))
	btn.add_theme_color_override("font_pressed_color", Color(0.55, 0.45, 0.34))
	btn.add_theme_font_size_override("font_size", font_size)
