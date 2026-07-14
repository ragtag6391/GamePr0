extends Control

@export var main_scene := "res://Scene/Room.tscn"


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event):
	if event.is_pressed():
		get_tree().change_scene_to_file(main_scene)
