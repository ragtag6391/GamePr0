extends Area3D

# Name of the UI node to show, e.g. "PayoutMachine", "SlotMachine Control",
# "DebtCollector Control" - must match the exact node name of the UI instance
# under both LeftEyeControl and RightEyeControl in CardboardView.
@export var ui_node_name: String = ""

var player_inside := false

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_inside and not _get_target_ui_visible():
			open_machine_ui()
			get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_cancel"):
		if _get_target_ui_visible():
			close_machine_ui()
			get_viewport().set_input_as_handled()
	if GameState.ui_open and _get_target_ui_visible():
		var inner := _get_inner_control()
		if inner != null:
			if event.is_action_pressed("bet_left") and inner.has_method("_adjust_amount"):
				inner._adjust_amount(-1)
				get_viewport().set_input_as_handled()
			elif event.is_action_pressed("bet_right") and inner.has_method("_adjust_amount"):
				inner._adjust_amount(1)
				get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body is CharacterBody3D:
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body is CharacterBody3D:
		player_inside = false
		if _get_target_ui_visible():
			close_machine_ui()

func _get_target_ui() -> Control:
	if GameState.right_eye_control == null:
		return null
	return GameState.right_eye_control.get_node_or_null(ui_node_name) as Control

func _get_mirror_ui() -> Control:
	if GameState.left_eye_control == null:
		return null
	return GameState.left_eye_control.get_node_or_null(ui_node_name) as Control

func _get_target_ui_visible() -> bool:
	var t := _get_target_ui()
	return t != null and t.visible

func open_machine_ui() -> void:
	var target_ui := _get_target_ui()
	var mirror_ui := _get_mirror_ui()

	if target_ui == null:
		push_error("Could not find UI node named '%s' under RightEyeControl" % ui_node_name)
		return

	target_ui.visible = true
	if mirror_ui != null:
		mirror_ui.visible = true

	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var inner := _get_inner_control()
	if inner and inner.has_method("_grab_main_focus"):
		inner._grab_main_focus()
	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_machine_ui() -> void:
	var target_ui := _get_target_ui()
	var mirror_ui := _get_mirror_ui()

	if target_ui != null:
		target_ui.visible = false
	if mirror_ui != null:
		mirror_ui.visible = false

	GameState.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _get_inner_control() -> Node:
	var target_ui := _get_target_ui()
	if target_ui == null:
		return null
	if target_ui is SubViewportContainer:
		var vp := target_ui.get_node_or_null("SubViewport")
		if vp and vp.get_child_count() > 0:
			return vp.get_child(0)
	return target_ui
