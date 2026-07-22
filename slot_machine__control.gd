extends Control

@onready var reels_node: GridContainer = find_child("Reels", true, false) as GridContainer
@onready var coins_label: Label = find_child("CoinsLabel", true, false) as Label
@onready var debt_label: Label = find_child("DebtLabel", true, false) as Label
@onready var bet_label: Label = find_child("BetLabel", true, false) as Label
@onready var result_label: Label = find_child("ResultLabel", true, false) as Label
@onready var bet_input: SpinBox = find_child("BetInput", true, false) as SpinBox
@onready var spin_button: Button = find_child("SpinButton", true, false) as Button
@onready var spin_sound: AudioStreamPlayer = find_child("SpinSound", true, false) as AudioStreamPlayer
@onready var coins_sound: AudioStreamPlayer = find_child("CoinsFallingSound", true, false) as AudioStreamPlayer
var horror_font := load("res://UI/Fonts/Nosifer-Regular.ttf") as FontFile



var rng := RandomNumberGenerator.new()

var bet := 5
var is_spinning := false

var reels := []
var current_grid := []

var reels_ready := false
var positions_cached := false
var base_positions := []
var reel_step_y := 0.0
var spin_tick_time := 0.08

var highlight_lines := []
var show_faint_paylines := true

var symbols := [
	{
		"id": "radioactive",
		"texture": preload("res://Assets/Slots/radioactive.png"),
		"weight": 35
	},
	{
		"id": "skull",
		"texture": preload("res://Assets/Slots/skull.png"),
		"weight": 25
	},
	{
		"id": "spider",
		"texture": preload("res://Assets/Slots/spider.png"),
		"weight": 20
	},
	{
		"id": "knife",
		"texture": preload("res://Assets/Slots/knife.png"),
		"weight": 15
	},
	{
		"id": "seven",
		"texture": preload("res://Assets/Slots/seven.png"),
		"weight": 5
	}
]

var paylines := [
	{
		"name": "Top row",
		"cells": [[0, 0], [0, 1], [0, 2]]
	},
	{
		"name": "Middle row",
		"cells": [[1, 0], [1, 1], [1, 2]]
	},
	{
		"name": "Bottom row",
		"cells": [[2, 0], [2, 1], [2, 2]]
	},
	{
		"name": "Diagonal \\",
		"cells": [[0, 0], [1, 1], [2, 2]]
	},
	{
		"name": "Diagonal /",
		"cells": [[2, 0], [1, 1], [0, 2]]
	}
]


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible and is_inside_tree():
			call_deferred("on_machine_opened")


func on_machine_opened() -> void:
	if not reels_ready:
		return
	await get_tree().process_frame
	cache_reel_positions()
	reset_column_positions()
	queue_redraw()
	_grab_main_focus()   # <-- add this


func _ready() -> void:
	rng.randomize()

	reels = [
		[get_reel("R0C0"), get_reel("R0C1"), get_reel("R0C2")],
		[get_reel("R1C0"), get_reel("R1C1"), get_reel("R1C2")],
		[get_reel("R2C0"), get_reel("R2C1"), get_reel("R2C2")]
	]

	if not check_nodes_exist():
		return

	reels_ready = true

	reels_node.columns = 3
	reels_node.columns = 3
	reels_node.clip_contents = true
	
	reels_node.clip_contents = true
	reels_node.add_theme_constant_override("h_separation", 8)
	reels_node.add_theme_constant_override("v_separation", 8)
	reels_node.position.x += 190
	spin_button.pressed.connect(_on_spin_pressed)

	if GameState.has_signal("coins_changed"):
		GameState.coins_changed.connect(_on_game_state_changed)

	if GameState.has_signal("debt_changed"):
		GameState.debt_changed.connect(_on_game_state_changed)

	if GameState.has_signal("pending_winnings_changed"):
		GameState.pending_winnings_changed.connect(_on_game_state_changed)

	bet_input.min_value = 1
	bet_input.max_value = max(1, GameState.coins)
	bet_input.step = 1
	bet_input.value = min(bet, max(1, GameState.coins))

	for row in range(3):
		for col in range(3):
			reels[row][col].custom_minimum_size = Vector2(95, 95)
			reels[row][col].size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			reels[row][col].size_flags_vertical = Control.SIZE_SHRINK_CENTER
			reels[row][col].expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			reels[row][col].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	style_ui()
	fill_start_grid()

	result_label.text = "Enter bet, then press SPIN."
	update_ui()

	await get_tree().process_frame

	if is_visible_in_tree():
		cache_reel_positions()

	queue_redraw()


func _on_game_state_changed(_new_amount: int) -> void:
	update_ui()


func get_reel(node_name: String) -> TextureRect:
	var node = find_child(node_name, true, false)

	if node == null:
		push_error("Missing reel node: " + node_name)
		return null

	if not (node is TextureRect):
		push_error(node_name + " exists, but it is not a TextureRect.")
		return null

	return node as TextureRect


func check_nodes_exist() -> bool:
	if reels_node == null:
		push_error("Missing Reels node. It must be a GridContainer.")
		return false

	if coins_label == null:
		push_error("Missing CoinsLabel.")
		return false

	if debt_label == null:
		push_error("Missing DebtLabel.")
		return false

	if bet_label == null:
		push_error("Missing BetLabel.")
		return false

	if result_label == null:
		push_error("Missing ResultLabel.")
		return false

	if bet_input == null:
		push_error("Missing BetInput. It must be a SpinBox.")
		return false

	if spin_button == null:
		push_error("Missing SpinButton. It must be a Button.")
		return false

	for row in range(3):
		for col in range(3):
			if reels[row][col] == null:
				push_error("Missing one of the 9 reel TextureRects.")
				return false

	return true


func cache_reel_positions() -> bool:
	positions_cached = false

	if not reels_ready:
		return false

	if not is_visible_in_tree():
		return false

	if reels.size() != 3:
		return false

	for row in range(3):
		if reels[row].size() != 3:
			return false

		for col in range(3):
			if reels[row][col] == null:
				return false

	base_positions.clear()

	for row in range(3):
		var row_positions := []

		for col in range(3):
			row_positions.append(reels[row][col].position)

		base_positions.append(row_positions)

	if base_positions.size() != 3:
		return false

	if base_positions[0].size() != 3:
		return false

	reel_step_y = base_positions[1][0].y - base_positions[0][0].y

	if reel_step_y <= 0:
		reel_step_y = reels[0][0].size.y + 8

	positions_cached = true
	return true


func reset_column_positions() -> void:
	if not positions_cached:
		return

	if base_positions.size() != 3:
		return

	for row in range(3):
		if base_positions[row].size() != 3:
			return

		for col in range(3):
			reels[row][col].position = base_positions[row][col]


func fill_start_grid() -> void:
	current_grid.clear()

	for row in range(3):
		var row_data := []

		for col in range(3):
			var symbol = get_weighted_symbol()
			row_data.append(symbol)
			reels[row][col].texture = symbol["texture"]

		current_grid.append(row_data)


func _on_spin_pressed() -> void:
	if is_spinning:
		return

	await ensure_positions_ready()

	if not positions_cached:
		result_label.text = "Machine is not ready yet."
		return

	bet = int(bet_input.value)

	if bet <= 0:
		result_label.text = "Bet must be at least 1 coin."
		return

	if bet > GameState.coins:
		result_label.text = "You cannot bet more coins than you have."
		return

	if GameState.debt <= 0:
		result_label.text = "Debt already cleared."
		return

	var spent_successfully := GameState.spend_coins(bet)

	if spent_successfully == false:
		result_label.text = "Not enough coins."
		return

	if spin_sound != null:
		spin_sound.play()

	is_spinning = true
	spin_button.disabled = true
	bet_input.editable = false
	highlight_lines.clear()

	result_label.text = "Rolling..."
	update_ui()
	queue_redraw()

	var final_grid := generate_final_grid()

	await roll_reels(final_grid)

	evaluate_grid(final_grid)

	is_spinning = false

	if GameState.coins < 1:
		result_label.text += "\nNo inventory coins left."
		spin_button.disabled = true
		bet_input.editable = false
	else:
		spin_button.disabled = false
		bet_input.editable = true

	update_ui()
	queue_redraw()
	_grab_main_focus()

func ensure_positions_ready() -> void:
	if positions_cached:
		return

	await get_tree().process_frame
	cache_reel_positions()
	reset_column_positions()


func generate_final_grid() -> Array:
	var grid := []

	for row in range(3):
		var grid_row := []

		for col in range(3):
			grid_row.append(get_weighted_symbol())

		grid.append(grid_row)

	return grid


func roll_reels(final_grid: Array) -> void:
	var column_0_ticks := 16
	var column_1_ticks := 23
	var column_2_ticks := 30

	for tick_count in range(column_2_ticks):
		if tick_count < column_0_ticks:
			animate_column_down(0, spin_tick_time)
		elif tick_count == column_0_ticks:
			animate_column_to_final(0, final_grid, spin_tick_time)

		if tick_count < column_1_ticks:
			animate_column_down(1, spin_tick_time)
		elif tick_count == column_1_ticks:
			animate_column_to_final(1, final_grid, spin_tick_time)

		if tick_count < column_2_ticks:
			animate_column_down(2, spin_tick_time)
		elif tick_count == column_2_ticks - 1:
			animate_column_to_final(2, final_grid, spin_tick_time)

		await get_tree().create_timer(spin_tick_time).timeout

	set_column_to_final(0, final_grid)
	set_column_to_final(1, final_grid)
	set_column_to_final(2, final_grid)
	reset_column_positions()


func animate_column_down(col: int, duration: float) -> void:
	var new_symbol = get_random_symbol()

	var old_top = current_grid[0][col]
	var old_middle = current_grid[1][col]

	current_grid[2][col] = old_middle
	current_grid[1][col] = old_top
	current_grid[0][col] = new_symbol

	for row in range(3):
		reels[row][col].texture = current_grid[row][col]["texture"]
		reels[row][col].position = base_positions[row][col] + Vector2(0, -reel_step_y)

	var tween := create_tween()
	tween.set_parallel(true)

	for row in range(3):
		tween.tween_property(
			reels[row][col],
			"position",
			base_positions[row][col],
			duration
		).set_trans(Tween.TRANS_LINEAR)


func animate_column_to_final(col: int, final_grid: Array, duration: float) -> void:
	for row in range(3):
		current_grid[row][col] = final_grid[row][col]
		reels[row][col].texture = final_grid[row][col]["texture"]
		reels[row][col].position = base_positions[row][col] + Vector2(0, -reel_step_y)

	var tween := create_tween()
	tween.set_parallel(true)

	for row in range(3):
		tween.tween_property(
			reels[row][col],
			"position",
			base_positions[row][col],
			duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func set_column_to_final(col: int, final_grid: Array) -> void:
	for row in range(3):
		current_grid[row][col] = final_grid[row][col]
		reels[row][col].texture = final_grid[row][col]["texture"]


func evaluate_grid(grid: Array) -> void:
	var total_multiplier := 0
	var winning_lines := []
	highlight_lines.clear()

	for line in paylines:
		var cells = line["cells"]
		var r1 := int(cells[0][0])
		var c1 := int(cells[0][1])
		var r2 := int(cells[1][0])
		var c2 := int(cells[1][1])
		var r3 := int(cells[2][0])
		var c3 := int(cells[2][1])
		var id_1 := str(grid[r1][c1]["id"])
		var id_2 := str(grid[r2][c2]["id"])
		var id_3 := str(grid[r3][c3]["id"])

		if id_1 == id_2 and id_2 == id_3:
			var line_multiplier := get_triple_multiplier(id_1)
			total_multiplier += line_multiplier
			winning_lines.append(line["name"] + ": triple " + id_1)
			highlight_lines.append(cells)

	var payout := bet * total_multiplier

	if total_multiplier > 0:
		GameState.add_pending_winnings(payout)

		if coins_sound != null:
			coins_sound.play()

		result_label.text = "WIN!\nPayout ticket: " + str(payout) + " coins."
		result_label.text += "\nGo to the payout machine."

		for line_text in winning_lines:
			result_label.text += "\n" + line_text
	else:
		result_label.text = "No winning line.\nLost: " + str(bet) + " coins."

	queue_redraw()


func get_triple_multiplier(symbol_id: String) -> int:
	match symbol_id:
		"seven":
			return 10
		"skull":
			return 6
		"knife":
			return 5
		"spider":
			return 4
		"radioactive":
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


func get_random_symbol() -> Dictionary:
	var index := rng.randi_range(0, symbols.size() - 1)
	return symbols[index]


func update_ui() -> void:
	coins_label.text = "CURRENT BALANCE = " + str(GameState.coins)
	debt_label.text = "DEBT = " + str(GameState.debt)
	bet_label.text = "BET AMOUNT"

	bet_input.max_value = max(1, GameState.coins)

	if GameState.coins > 0 and bet_input.value > GameState.coins:
		bet_input.value = GameState.coins

	if not is_spinning:
		if GameState.coins < 1 or GameState.debt <= 0:
			spin_button.disabled = true
			bet_input.editable = false
		else:
			spin_button.disabled = false
			bet_input.editable = true


func style_ui() -> void:
	
	coins_label.add_theme_font_override("font", horror_font)
	debt_label.add_theme_font_override("font", horror_font)
	coins_label.add_theme_font_size_override("font_size", 28)
	debt_label.add_theme_font_size_override("font_size", 32)
	# Main text alignment
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Font sizes (slightly smaller overall since panel is shrinking)
	coins_label.add_theme_font_size_override("font_size", 26)
	debt_label.add_theme_font_size_override("font_size", 30)
	bet_label.add_theme_font_size_override("font_size", 18)
	result_label.add_theme_font_size_override("font_size", 19)
	spin_button.add_theme_font_size_override("font_size", 38)

	# Sickly, decayed color palette
	coins_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
	debt_label.add_theme_color_override("font_color", Color(0.85, 0.05, 0.03))
	bet_label.add_theme_color_override("font_color", Color(0.55, 0.5, 0.42))
	result_label.add_theme_color_override("font_color", Color(0.78, 0.62, 0.55))
	_style_button_rustic(spin_button, 22)
	spin_button.text = "spin"
	
	_style_button_image(spin_button, "res://UI/SlotMachine/SlotMachineButton.png")
	spin_button.text = "spin"
	# Distressed text shadows (gives a scratched, decaying look)
	for lbl in [coins_label, debt_label, bet_label, result_label]:
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.add_theme_constant_override("shadow_outline_size", 1)

	# Debt label gets a slow, sickly pulse - like it's breathing
	var debt_pulse := create_tween()
	debt_pulse.set_loops()
	debt_pulse.tween_property(debt_label, "modulate", Color(1.0, 0.3, 0.25), 1.2).set_trans(Tween.TRANS_SINE)
	debt_pulse.tween_property(debt_label, "modulate", Color(1.0, 1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE)

	# Button text
	spin_button.text = "SPIN"
	spin_button.custom_minimum_size = Vector2(250, 100)
	bet_input.custom_minimum_size = Vector2(180, 60)

	# --- Shrink + center the whole panel ---
	var machine_panel := find_child("MachinePanel", true, false) as Control
	if machine_panel != null:
		machine_panel.custom_minimum_size = Vector2(360, 0)
		machine_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		machine_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		# Wrap in centering if not already inside one
		var parent := machine_panel.get_parent()
		if parent != null and not (parent is CenterContainer):
			var center := CenterContainer.new()
			center.set_anchors_preset(Control.PRESET_FULL_RECT)
			var idx := machine_panel.get_index()
			parent.remove_child(machine_panel)
			parent.add_child(center)
			parent.move_child(center, idx)
			center.add_child(machine_panel)

	# Style panel: sharp corners, torn/bleeding border look
	if machine_panel is PanelContainer:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.015, 0.01, 0.01, 0.3)
		panel_style.border_color = Color(0.5, 0.0, 0.0, 0.85)
		panel_style.border_width_left = 2
		panel_style.border_width_right = 2
		panel_style.border_width_top = 2
		panel_style.border_width_bottom = 2
		# Sharp corners read as more unsettling than rounded ones
		panel_style.corner_radius_top_left = 0
		panel_style.corner_radius_top_right = 0
		panel_style.corner_radius_bottom_left = 0
		panel_style.corner_radius_bottom_right = 0
		panel_style.shadow_color = Color(0.4, 0.0, 0.0, 0.35)
		panel_style.shadow_size = 24
		panel_style.expand_margin_left = 14
		panel_style.expand_margin_right = 14
		panel_style.expand_margin_top = 14
		panel_style.expand_margin_bottom = 14
		(machine_panel as PanelContainer).add_theme_stylebox_override("panel", panel_style)

		# Slow pulsing border glow - like something behind it is alive
		var glow_tween := create_tween()
		glow_tween.set_loops()
		glow_tween.tween_method(
			func(a: float): panel_style.border_color = Color(0.5, 0.0, 0.0, a),
			0.5, 0.95, 1.8
		).set_trans(Tween.TRANS_SINE)
		glow_tween.tween_method(
			func(a: float): panel_style.border_color = Color(0.5, 0.0, 0.0, a),
			0.95, 0.5, 1.8
		).set_trans(Tween.TRANS_SINE)

	# Style spin button: cracked-blood look, sharp corners


func _style_button_image(btn: Button, texture_path: String, font_size: int = 22) -> void:
	var tex := load(texture_path) as Texture2D

	var sb := StyleBoxTexture.new()
	sb.texture = tex
	# These margins protect the ornate corners from stretching -
	# tune these numbers to roughly match how deep the blood-drip
	# corner flourish extends into the image, in pixels.
	sb.texture_margin_left = 40
	sb.texture_margin_right = 40
	sb.texture_margin_top = 30
	sb.texture_margin_bottom = 30

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)

	btn.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.9))
	btn.add_theme_font_size_override("font_size", font_size)

func _draw() -> void:
	if reels.size() != 3:
		return

	if reels[0].size() != 3:
		return

	if reels[0][0] == null:
		return

	if show_faint_paylines:
		for line in paylines:
			draw_payline(line["cells"], Color(0.4, 0.0, 0.0, 0.35), 3.0)

	for cells in highlight_lines:
		draw_payline(cells, Color(1.0, 0.05, 0.02, 0.95), 8.0)

func _grab_main_focus() -> void:
	if spin_button != null and not spin_button.disabled:
		spin_button.grab_focus()
		
func draw_payline(cells: Array, color: Color, width: float) -> void:
	var p0 := get_cell_center(int(cells[0][0]), int(cells[0][1]))
	var p1 := get_cell_center(int(cells[1][0]), int(cells[1][1]))
	var p2 := get_cell_center(int(cells[2][0]), int(cells[2][1]))

	draw_line(p0, p1, color, width, true)
	draw_line(p1, p2, color, width, true)

	draw_circle(p0, width * 0.6, color)
	draw_circle(p1, width * 0.6, color)
	draw_circle(p2, width * 0.6, color)


func get_cell_center(row: int, col: int) -> Vector2:
	var cell_rect: Rect2 = reels[row][col].get_global_rect()
	var cell_center: Vector2 = cell_rect.position + cell_rect.size * 0.5

	var self_rect: Rect2 = get_global_rect()
	var local_center: Vector2 = cell_center - self_rect.position

	return local_center


func _adjust_amount(direction: int) -> void:
	if is_spinning:
		return
	if direction < 0:
		bet_input.value = max(bet_input.min_value, bet_input.value - bet_input.step)
	else:
		bet_input.value = min(bet_input.max_value, bet_input.value + bet_input.step)
	spin_button.grab_focus()
	
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
