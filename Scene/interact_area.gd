extends Area3D

@export var target_ui_path: NodePath

var target_ui: Control = null
var player_inside := false


func _ready() -> void:
	monitoring = true
	monitorable = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	target_ui = get_node_or_null(target_ui_path) as Control

	if target_ui == null:
		push_error("Target UI Path is wrong or empty on: " + str(get_path()))
	else:
		target_ui.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_E:
			if player_inside and target_ui != null and target_ui.visible == false:
				open_machine_ui()

		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if target_ui != null and target_ui.visible:
				close_machine_ui()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body is CharacterBody3D:
		player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body is CharacterBody3D:
		player_inside = false

		if target_ui != null and target_ui.visible:
			close_machine_ui()


func open_machine_ui() -> void:
	target_ui.visible = true
	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_machine_ui() -> void:
	target_ui.visible = false
	GameState.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
