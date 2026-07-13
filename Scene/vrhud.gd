extends Node3D

@onready var stats_label: Label3D = $StatsLabel


func _ready() -> void:
	# Position in front of the camera/head
	position = Vector3(0, 0, -2)

	stats_label.visible = true
	stats_label.text = "COINS: " + str(GameState.coins) + "\nDEBT: " + str(GameState.debt)

	# Make it big and readable for testing
	stats_label.pixel_size = 0.01
	stats_label.font_size = 64
	stats_label.modulate = Color(1.0, 0.85, 0.65, 1.0)

	# Make it visible even if geometry is in front
	stats_label.no_depth_test = true

	# Make it face the camera
	stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	# Outline for readability
	stats_label.outline_size = 16
	stats_label.outline_modulate = Color(0, 0, 0, 1)

	GameState.coins_changed.connect(_on_game_state_changed)
	GameState.debt_changed.connect(_on_game_state_changed)

	update_text()


func _on_game_state_changed(_new_amount: int) -> void:
	update_text()


func update_text() -> void:
	stats_label.text = "COINS: " + str(GameState.coins) + "\nDEBT: " + str(GameState.debt)
