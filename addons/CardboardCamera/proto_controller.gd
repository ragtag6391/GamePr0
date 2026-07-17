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
@export var gamepad_sensitivity := 3.0        # NEW — radians/sec at full stick tilt
@export var min_pitch := -80.0                # NEW — degrees, how far you can look down
@export var max_pitch := 80.0                 # NEW — degrees, how far you can look up

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
	print("interact events: ", InputMap.action_get_events("interact"))
	print("look_left events: ", InputMap.action_get_events("look_left"))
	print("look_right events: ", InputMap.action_get_events("look_right"))
	print("look_up events: ", InputMap.action_get_events("look_up"))
	print("look_down events: ", InputMap.action_get_events("look_down"))

func _unhandled_input(event: InputEvent) -> void:
	if GameState.ui_open:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		print("INTERACT PRESSED")
	# If a machine UI is open, stop player movement and looking.
	if GameState.ui_open:
		velocity.x = 0.0
		velocity.z = 0.0

		if has_gravity and !is_on_floor():
			velocity += get_gravity() * delta

		move_and_slide()
		return

	# Gamepad right-stick look
	var look_dir := Input.get_vector(
	"look_left",
	"look_right",
	"look_up",
    "look_down"
)

	print(look_dir)
	if look_dir != Vector2.ZERO:
		print("LOOK:", look_dir)
		print("HEAD BEFORE:", head.rotation)

		rotate_y(-look_dir.x * gamepad_sensitivity * delta)
		head.rotate_x(-look_dir.y * gamepad_sensitivity * delta)

		print("HEAD AFTER:", head.rotation)

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

	if can_move:
		var input_dir := Input.get_vector(
			input_left,
			input_right,
			input_forward,
			input_back
		)
		var forward := -transform.basis.z
		var right := transform.basis.x
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
