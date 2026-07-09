extends Area3D

@export var slot_machine: Control

var player_inside := false
func _ready():
	print("SlotMachineArea READY")
func _on_body_entered(body):
	print("ENTER:", body.name)
	player_inside = true

func _on_body_exited(body):
	print("EXIT:", body.name)
	player_inside = false

func _process(delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		print("E pressed while inside")
		slot_machine.spin()

	if player_inside and Input.is_action_just_pressed("interact"):
		print("Trying to spin")
		slot_machine.spin()
