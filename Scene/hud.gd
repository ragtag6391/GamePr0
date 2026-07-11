extends CanvasLayer

@onready var stats_label: Label = $StatsLabel


func _ready() -> void:
	layer = 20

	stats_label.position = Vector2(20, 20)
	stats_label.text = ""

	style_ui()
	update_text()

	GameState.coins_changed.connect(_on_game_state_changed)
	GameState.debt_changed.connect(_on_game_state_changed)


func _on_game_state_changed(_new_amount: int) -> void:
	update_text()


func update_text() -> void:
	stats_label.text = "COINS: " + str(GameState.coins) + "\nDEBT: " + str(GameState.debt)


func style_ui() -> void:
	stats_label.add_theme_font_size_override("font_size", 28)
	stats_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.72))
	stats_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	stats_label.add_theme_constant_override("shadow_offset_x", 3)
	stats_label.add_theme_constant_override("shadow_offset_y", 3) 
