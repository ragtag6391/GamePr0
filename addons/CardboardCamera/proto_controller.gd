extends CharacterBody3D

@export var can_move := true
@export var has_gravity := true
@export var can_jump := true
@export var can_sprint := false

@export_group("Speeds")
@export var base_speed := 7.0
@export var sprint_speed := 10.0
@export var jump_velocity := 4.5

@export_group("Input Actions")
@export var input_left := "ui_left"
@export var input_right := "ui_right"
@export var input_forward := "ui_down"
@export var input_back := "ui_up"
@export var input_jump := "ui_accept"
@export var input_sprint := "sprint"

@onready var head: Node3D = $Head

var move_speed := 0.0

func _physics_process(delta):
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

		# Move relative to the Head's direction
		var forward = -head.global_transform.basis.z
		var right = head.global_transform.basis.x

		forward.y = 0
		right.y = 0

		forward = forward.normalized()
		right = right.normalized()

		var move_dir = (
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
