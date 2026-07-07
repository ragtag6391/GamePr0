extends Control

@onready var reels_node: GridContainer = find_child("Reels", true, false) as GridContainer
@onready var coins_label: Label = find_child("CoinsLabel", true, false) as Label
@onready var debt_label: Label = find_child("DebtLabel", true, false) as Label
@onready var bet_label: Label = find_child("BetLabel", true, false) as Label
@onready var result_label: Label = find_child("ResultLabel", true, false) as Label
@onready var bet_input: SpinBox = find_child("BetInput", true, false) as SpinBox
@onready var spin_button: Button = find_child("SpinButton", true, false) as Button

var rng := RandomNumberGenerator.new()

var coins := 50
var debt := 100
var bet := 5
var is_spinning := false

var reels := []
var current_grid := []

var base_positions := []
var reel_step_y := 0.0
var spin_tick_time := 0.08

var highlight_lines := []
var show_faint_paylines := true

var symbols := [
	{
		"id": "radioactive",
		"texture": preload("res://assets/slots/radioactive.png"),
		"weight": 35
	},
	{
		"id": "skull",
		"texture": preload("res://assets/slots/skull.png"),
		"weight": 25
	},
	{
		"id": "spider",
		"texture": preload("res://assets/slots/spider.png"),
		"weight": 20
	},
	{
		"id": "knife",
		"texture": preload("res://assets/slots/knife.png"),
		"weight": 15
	},
	{
		"id": "seven",
		"texture": preload("res://assets/slots/seven.png"),
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


func _ready() -> void:
	rng.randomize()

	reels = [
		[get_reel("R0C0"), get_reel("R0C1"), get_reel("R0C2")],
		[get_reel("R1C0"), get_reel("R1C1"), get_reel("R1C2")],
		[get_reel("R2C0"), get_reel("R2C1"), get_reel("R2C2")]
	]

	if not check_nodes_exist():
		return

	reels_node.columns = 3
	reels_node.clip_contents = true
	reels_node.add_theme_constant_override("h_separation", 8)
	reels_node.add_theme_constant_override("v_separation", 8)

	spin_button.pressed.connect(_on_spin_pressed)

	bet_input.min_value = 1
	bet_input.max_value = coins
	bet_input.step = 1
	bet_input.value = bet

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
	cache_reel_positions()

	queue_redraw()


func get_reel(node_name: String) -> TextureRect:
	var node = find_child(node_name, true, false)

	if node == null:
		push_error("Missing reel node: " + node_name)
		return null

	if node is not TextureRect:
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


func cache_reel_positions() -> void:
	base_positions.clear()

	for row in range(3):
		var row_positions := []

		for col in range(3):
			row_positions.append(reels[row][col].position)

		base_positions.append(row_positions)

	reel_step_y = base_positions[1][0].y - base_positions[0][0].y


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
	highlight_lines.clear()

	result_label.text = "Rolling..."
	update_ui()
	queue_redraw()

	var final_grid := generate_final_grid()

	await roll_reels(final_grid)

	evaluate_grid(final_grid)

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
	queue_redraw()


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


func reset_column_positions() -> void:
	for row in range(3):
		for col in range(3):
			reels[row][col].position = base_positions[row][col]


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
	var net_profit := payout - bet

	if total_multiplier > 0:
		coins += payout

		if net_profit > 0:
			debt -= net_profit
			if debt < 0:
				debt = 0

		result_label.text = "WIN!\nPayout: " + str(payout) + " coins."

		for line_text in winning_lines:
			result_label.text += "\n" + line_text

		if net_profit > 0:
			result_label.text += "\nDebt reduced by " + str(net_profit) + "."
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
	coins_label.text = "CURRENT BALANCE = " + str(coins)
	debt_label.text = "DEBT = " + str(debt)
	bet_label.text = "BET AMOUNT = " + str(bet)

	bet_input.max_value = max(1, coins)

	if bet_input.value > coins and coins > 0:
		bet_input.value = coins


func style_ui() -> void:
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	coins_label.add_theme_font_size_override("font_size", 24)
	debt_label.add_theme_font_size_override("font_size", 32)
	bet_label.add_theme_font_size_override("font_size", 24)
	result_label.add_theme_font_size_override("font_size", 20)
	spin_button.add_theme_font_size_override("font_size", 30)

	coins_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	debt_label.add_theme_color_override("font_color", Color(1.0, 0.12, 0.1))
	bet_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	result_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.7))

	spin_button.text = "SPIN"


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
