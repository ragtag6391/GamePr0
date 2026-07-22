extends Control

@export var next_scene_path: String = "res://Intro.tscn"
@export var fade_seconds: float = 1.0

var _transitioning: bool = false

func _ready() -> void:
	modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, fade_seconds)

func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event.is_pressed() and not event.is_echo():
		_transitioning = true
		_go_to_next_scene()

func _go_to_next_scene() -> void:
	var fade_out := create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, fade_seconds)
	fade_out.tween_callback(func():
		get_tree().change_scene_to_file(next_scene_path)
)
