extends Control

@export var is_mirror_display: bool = false

@onready var resume_button: Button = find_child("ResumeButton", true, false) as Button
@onready var restart_button: Button = find_child("RestartButton", true, false) as Button
@onready var quit_button: Button = find_child("QuitButton", true, false) as Button

func _ready() -> void:
	visible = false
	if not is_mirror_display:
		resume_button.pressed.connect(_on_resume)
		restart_button.pressed.connect(_on_restart)
		quit_button.pressed.connect(_on_quit)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible and is_inside_tree() and not is_mirror_display:
			if resume_button != null:
				resume_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if is_mirror_display:
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause() -> void:
	visible = not visible
	GameState.ui_open = visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED

func _on_resume() -> void:
	_toggle_pause()

func _on_restart() -> void:
	GameState.reset_game()
	get_tree().reload_current_scene()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		print("UI_DOWN DETECTED")
func _on_quit() -> void:
	get_tree().quit()

func _process(_delta: float) -> void:
	if is_mirror_display:
		if GameState.right_eye_control:
			var primary = GameState.right_eye_control.get_node_or_null("PauseMenu")
			if primary:
				visible = primary.visible
			else:
				print("PRIMARY PAUSEMENU NOT FOUND")
		else:
			print("right_eye_control IS NULL")
