extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var pending_label: Label = $VBoxContainer/PendingLabel
@onready var inventory_label: Label = $VBoxContainer/InventoryLabel
@onready var debt_label: Label = $VBoxContainer/DebtLabel
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var claim_button: Button = $VBoxContainer/ClaimButton

@export var is_mirror_display: bool = false
func _ready() -> void:
	title_label.text = "PAYOUT MACHINE"
	claim_button.text = "CLAIM COINS"
	
	claim_button.pressed.connect(_on_claim_pressed)
	
	GameState.coins_changed.connect(_on_game_state_changed)
	GameState.debt_changed.connect(_on_game_state_changed)
	GameState.pending_winnings_changed.connect(_on_game_state_changed)
	
	style_ui()
	update_ui()
	
	result_label.text = "Insert your winnings ticket."


func _on_claim_pressed() -> void:
	if GameState.pending_winnings <= 0:
		result_label.text = "No winnings to claim."
		update_ui()
		return
	
	var claimed := GameState.claim_pending_winnings()
	
	result_label.text = "The machine spits out " + str(claimed) + " coins."
	
	update_ui()
	_grab_main_focus()

func _on_game_state_changed(_new_amount: int) -> void:
	update_ui()


func update_ui() -> void:
	pending_label.text = "PENDING WINNINGS = " + str(GameState.pending_winnings)
	inventory_label.text = "INVENTORY COINS = " + str(GameState.coins)
	debt_label.text = "DEBT = " + str(GameState.debt)
	
	if GameState.pending_winnings <= 0:
		claim_button.disabled = true
	else:
		claim_button.disabled = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible and is_inside_tree():
			_grab_main_focus()

func _grab_main_focus() -> void:
	if claim_button != null and not claim_button.disabled:
		claim_button.grab_focus()

func style_ui() -> void:
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	title_label.add_theme_font_size_override("font_size", 36)
	pending_label.add_theme_font_size_override("font_size", 26)
	inventory_label.add_theme_font_size_override("font_size", 24)
	debt_label.add_theme_font_size_override("font_size", 28)
	result_label.add_theme_font_size_override("font_size", 22)
	claim_button.add_theme_font_size_override("font_size", 28)
	
	title_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.1))
	pending_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	inventory_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	debt_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.1))
	result_label.add_theme_color_override("font_color", Color(0.8, 0.72, 0.65))
	_style_button_rustic(claim_button, 20)
	claim_button.text = "claim coins"

func _input(event: InputEvent) -> void:
	if is_mirror_display:
		return
	if not is_visible_in_tree() or not GameState.ui_open:
		return
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
