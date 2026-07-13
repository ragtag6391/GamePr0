class_name CardboardVRCamera3D
extends Camera3D

@export var Active: bool = true

@export_category("Controls")
@export var UseGyroscope: bool = false
@export var Mouse_Sensitivity: float = 0.003
@export var GyroscopeFactor: float = 0.2
@export var RotateParent: bool = true
@export var Handle_Mouse_Capture: bool = true
@export var Input_Cancel: String = "cancel"

@export_category("Eyes")
@export_range(0.01, 0.1) var EyesSeparation: float = 0.032
@export_range(0.0, 5.0) var EyeHeight: float = 0.8
@export_range(-360, 360) var EyeConvergencyAngle: float = 3.0

@export_category("HUD")
@export var ShowHUD: bool = true
@export var HUDDistance: float = 2.2
@export var HUDX: float = -0.42
@export var HUDY: float = 0.26
@export var HUDFontSize: int = 32
@export var HUDPixelSize: float = 0.0022

const LEFT_HUD_LAYER := 19
const RIGHT_HUD_LAYER := 20

var viewScene = preload("res://addons/cardboard_vr/scenes/CardboardView.tscn")

var left_camera_3d: Camera3D = Camera3D.new()
var right_camera_3d: Camera3D = Camera3D.new()

var LeftEyePivot: Node3D = Node3D.new()
var RightEyePivot: Node3D = Node3D.new()

var View: CardboardView

var LeftEyeSubViewPort: SubViewport = SubViewport.new()
var RightEyeSubViewPort: SubViewport = SubViewport.new()

var parent: Node3D

var left_hud_label: Label3D = Label3D.new()
var right_hud_label: Label3D = Label3D.new()


func _ready() -> void:
	parent = get_parent() as Node3D

	# Setup left eye
	LeftEyePivot.add_child(left_camera_3d)
	LeftEyeSubViewPort.add_child(LeftEyePivot)

	# Setup right eye
	RightEyePivot.add_child(right_camera_3d)
	RightEyeSubViewPort.add_child(RightEyePivot)

	# Setup VR view
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

	setup_hud()

	if GameState.has_signal("coins_changed"):
		GameState.coins_changed.connect(_on_game_state_changed)

	if GameState.has_signal("debt_changed"):
		GameState.debt_changed.connect(_on_game_state_changed)

	update_hud()


func setup_hud() -> void:
	if not ShowHUD:
		return

	left_camera_3d.add_child(left_hud_label)
	right_camera_3d.add_child(right_hud_label)

	setup_single_hud_label(left_hud_label)
	setup_single_hud_label(right_hud_label)

	# Put each HUD label on a separate visibility layer.
	left_hud_label.layers = 0
	right_hud_label.layers = 0

	left_hud_label.set_layer_mask_value(LEFT_HUD_LAYER, true)
	right_hud_label.set_layer_mask_value(RIGHT_HUD_LAYER, true)

	# Make each eye camera see only its own HUD.
	left_camera_3d.set_cull_mask_value(LEFT_HUD_LAYER, true)
	left_camera_3d.set_cull_mask_value(RIGHT_HUD_LAYER, false)

	right_camera_3d.set_cull_mask_value(LEFT_HUD_LAYER, false)
	right_camera_3d.set_cull_mask_value(RIGHT_HUD_LAYER, true)


func setup_single_hud_label(label: Label3D) -> void:
	label.visible = true
	label.text = "COINS: 0\nDEBT: 0"

	label.position = Vector3(HUDX, HUDY, -HUDDistance)

	label.font_size = HUDFontSize
	label.pixel_size = HUDPixelSize

	label.modulate = Color(1.0, 0.84, 0.62, 1.0)
	label.outline_size = 5
	label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)

	label.no_depth_test = true
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP


func _on_game_state_changed(_new_amount: int) -> void:
	update_hud()


func update_hud() -> void:
	var hud_text: String = "COINS: " + str(GameState.coins) + "\nDEBT: " + str(GameState.debt)

	left_hud_label.text = hud_text
	right_hud_label.text = hud_text


func _input(event: InputEvent) -> void:
	if not Active:
		return

	# If machine UI is open, do not capture mouse or rotate camera.
	if GameState.ui_open:
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	# Mouse capture
	if Handle_Mouse_Capture:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		elif Input.is_action_just_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Mouse look for PC testing
	if not UseGyroscope \
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
	if not Active or not parent:
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

	# If UI is open, keep the camera in place but stop gyro rotation.
	if GameState.ui_open:
		return

	# Gyroscope controls
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
