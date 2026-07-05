extends SpotLight3D

var picked_up = false

func _input(event: InputEvent) -> void:
	if picked_up and event.is_action_pressed("Flashlight"):
		visible = !visible
		$toggle.play()
