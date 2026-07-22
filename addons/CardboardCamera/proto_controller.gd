extends CharacterBody3D

@export var can_move := true
@export var has_gravity := true
@export var can_jump := true
@export var can_sprint := false

@export_group("Speeds")
@export var base_speed := 7.0
@export var sprint_speed := 10.0
@export var jump_velocity := 4.5

@export_group("Look")
@export var mouse_sensitivity := 0.003
@export var gamepad_sensitivity := 3.0

@export_group("Input Actions")
@export var input_left := "ui_left"
@export var input_right := "ui_right"
@export var input_forward := "ui_down"
@export var input_back := "ui_up"
@export var input_jump := "ui_accept"
@export var input_sprint := "sprint"

@onready var head: Node3D = $Head

var move_speed := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Verify input actions exist
	_verify_input_actions()
	
	# Setup cameras based on platform
	_setup_cameras()
	
	print("✓ ProtoController3 ready")
	var win_label := head.get_node_or_null("WinLabel") as Label3D
	var death_label := head.get_node_or_null("DeathLabel") as Label3D

	print("win_label found: ", win_label)
	print("death_label found: ", death_label)
	
	
	GameState.game_won.connect(func():
		print("WIN SIGNAL RECEIVED")
		if win_label:
			print("Setting win_label visible")
			win_label.visible = true
		else:
			print("win_label is NULL!")
		GameState.ui_open = true
		_restart_after_delay()
	)
	GameState.game_lost.connect(func():
		print("LOSE SIGNAL RECEIVED")
		if death_label:
			print("Setting death_label visible")
			death_label.visible = true
		else:
			print("death_label is NULL!")
		GameState.ui_open = true
		_restart_after_delay()
)

func _restart_after_delay() -> void:
	await get_tree().create_timer(4.0).timeout
	GameState.reset_game()
	get_tree().reload_current_scene()
	
func _verify_input_actions() -> void:
	"""Check if all required input actions exist"""
	var required_actions = [
		"interact",
		"look_left",
		"look_right",
		"look_up",
		"look_down"
	]
	
	for action in required_actions:
		var events = InputMap.action_get_events(action)
		if events.is_empty():
			print("⚠ WARNING: Input action '%s' not found in Input Map!" % action)
		else:
			print("✓ Action '%s': %s" % [action, events])

func _setup_cameras() -> void:
	"""Setup cameras based on platform"""
	var debug_camera = head.get_node_or_null("Camera3D")
	var vr_camera = head.get_node_or_null("CardboardVRCamera3D")
	
	if OS.get_name() == "Android":
		# VR mode: disable debug camera
		if debug_camera:
			debug_camera.current = false
			
		if vr_camera:
			vr_camera.current = true
		print("✓ VR mode active")
	else:
		# Debug mode: enable debug camera
		if debug_camera:
			debug_camera.current = true
		if vr_camera:
			vr_camera.current = false
		print("✓ Debug mode active")

func _unhandled_input(event: InputEvent) -> void:
	if GameState.ui_open:
		return
	
	# ONLY handle mouse look on PC debug mode
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if OS.get_name() != "Android":  # PC only
			rotate_y(-event.relative.x * mouse_sensitivity)
			var debug_camera = head.get_node_or_null("Camera3D")
			if debug_camera:
				debug_camera.rotate_x(-event.relative.y * mouse_sensitivity)
				debug_camera.rotation.x = clamp(debug_camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# Check interact button
	if Input.is_action_just_pressed("interact"):
		print("✓ INTERACT PRESSED")
	
	# ESC key handling
	if Input.is_action_just_pressed("ui_cancel"):
		print("✓ ESC PRESSED")
		if GameState.ui_open:
			GameState.ui_open = false
	
	# If a machine UI is open, stop player movement and looking
	if GameState.ui_open:
		velocity.x = 0.0
		velocity.z = 0.0
		if has_gravity and !is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return
	
	# ONLY use gamepad look on PC debug mode (not on Android)

	
	# ON ANDROID: CardboardVR plugin handles camera rotation automatically
	# DO NOT rotate head.rotate_x() or head.rotate_y() on Android
	# The plugin OWNS the camera and will overwrite any manual rotation
	
	# Gravity
	if has_gravity and !is_on_floor():
		velocity += get_gravity() * delta
	
	# Jump
	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity
	
	# Speed
	move_speed = base_speed
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	
	# Movement
	if can_move:
		var input_dir := Input.get_vector(
			input_left,
			input_right,
			input_forward,
			input_back
		)
		var forward := -head.global_transform.basis.z
		var right := head.global_transform.basis.x
		
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		var move_dir := (
			right * input_dir.x +
			forward * input_dir.y
		).normalized()
		if move_dir != Vector3.ZERO:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)
			velocity.z = move_toward(velocity.z, 0.0, move_speed)
	
	move_and_slide()
