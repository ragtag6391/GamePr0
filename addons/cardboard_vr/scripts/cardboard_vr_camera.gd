class_name CardboardVRCamera
extends Camera3D

@export var Active : bool = true

@export_category("Controls")
@export var UseGyroscope : bool = false
@export var Mouse_Sensitivity : float = 0.003
@export var GyroscopeFactor : float = 0.2
@export var RotateParent : bool = true
@export var Handle_Mouse_Capture : bool = true
@export var Input_Cancel : String = "cancel"

@export_category("Eyes")
@export_range(0.01, 0.1) var EyesSeparation : float = 0.032
@export_range(0.0, 5.0) var EyeHeight : float = 0.8
@export_range(-360, 360) var EyeConvergencyAngle : float = 3.0

var viewScene = preload("res://addons/cardboard_vr/scenes/CardboardView.tscn")

var left_camera_3d : Camera3D = Camera3D.new()
var right_camera_3d : Camera3D = Camera3D.new()

var LeftEyePivot : Node3D = Node3D.new()
var RightEyePivot : Node3D = Node3D.new()

var View : CardboardView

var LeftEyeSubViewPort : SubViewport = SubViewport.new()
var RightEyeSubViewPort : SubViewport = SubViewport.new()

var parent : Node3D


func _ready() -> void:
	parent = get_parent() as Node3D

	# Setup left eye
	LeftEyePivot.add_child(left_camera_3d)
	LeftEyeSubViewPort.add_child(LeftEyePivot)

	# Setup right eye
	RightEyePivot.add_child(right_camera_3d)
	RightEyeSubViewPort.add_child(RightEyePivot)

	# Setup view
	View = viewScene.instantiate()
	add_child(View)
	add_child(LeftEyeSubViewPort)
	add_child(RightEyeSubViewPort)

	View.SetViewPorts(
		LeftEyeSubViewPort,
		RightEyeSubViewPort
	)

	# Eye offsets
	left_camera_3d.position.x = -EyesSeparation
	right_camera_3d.position.x = EyesSeparation

	LeftEyePivot.position.y = EyeHeight
	RightEyePivot.position.y = EyeHeight

	# Eye convergence
	left_camera_3d.rotate_object_local(
		Vector3.UP,
		deg_to_rad(EyeConvergencyAngle)
	)

	right_camera_3d.rotate_object_local(
		Vector3.UP,
		-deg_to_rad(EyeConvergencyAngle)
	)


func _input(event):
	if !Active:
		return

	# Mouse capture
	if Handle_Mouse_Capture:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		elif Input.is_action_just_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Mouse look (PC testing)
	if !UseGyroscope \
	and event is InputEventMouseMotion \
	and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

		var motion := event as InputEventMouseMotion

		# Horizontal rotation
		if RotateParent and parent:
			parent.rotate_y(
				-motion.relative.x * Mouse_Sensitivity
			)

		LeftEyePivot.rotate_y(
			-motion.relative.x * Mouse_Sensitivity
		)

		RightEyePivot.rotate_y(
			-motion.relative.x * Mouse_Sensitivity
		)

		# Vertical rotation
		LeftEyePivot.rotate_object_local(
			Vector3.RIGHT,
			-motion.relative.y * Mouse_Sensitivity
		)

		RightEyePivot.rotate_object_local(
			Vector3.RIGHT,
			-motion.relative.y * Mouse_Sensitivity
		)

		# Clamp pitch
		LeftEyePivot.rotation.x = clamp(
			LeftEyePivot.rotation.x,
			deg_to_rad(-85),
			deg_to_rad(85)
		)

		RightEyePivot.rotation.x = clamp(
			RightEyePivot.rotation.x,
			deg_to_rad(-85),
			deg_to_rad(85)
		)


func _process(_delta: float) -> void:
	if !Active or !parent:
		return

	# Keep eyes attached to player
	LeftEyePivot.global_position = Vector3(
		parent.global_position.x,
		parent.global_position.y + EyeHeight,
		parent.global_position.z
	)

	RightEyePivot.global_position = Vector3(
		parent.global_position.x,
		parent.global_position.y + EyeHeight,
		parent.global_position.z
	)

	# Gyroscope controls (Android)
	if UseGyroscope:
		var gyroscope := Input.get_gyroscope()

		if RotateParent:
			parent.rotate_y(
				gyroscope.y * GyroscopeFactor
			)

		LeftEyePivot.rotate_y(
			gyroscope.y * GyroscopeFactor
		)

		RightEyePivot.rotate_y(
			gyroscope.y * GyroscopeFactor
		)

		LeftEyePivot.rotate_object_local(
			Vector3.RIGHT,
			gyroscope.x * GyroscopeFactor
		)

		RightEyePivot.rotate_object_local(
			Vector3.RIGHT,
			gyroscope.x * GyroscopeFactor
		)

		LeftEyePivot.rotation.x = clamp(
			LeftEyePivot.rotation.x,
			deg_to_rad(-85),
			deg_to_rad(85)
		)

		RightEyePivot.rotation.x = clamp(
			RightEyePivot.rotation.x,
			deg_to_rad(-85),
			deg_to_rad(85)
		)
