extends Label3D

func _ready() -> void:
	await get_tree().create_timer(6.0).timeout
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		visible = false
	)
