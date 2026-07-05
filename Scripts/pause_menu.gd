extends Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		get_tree().paused = !get_tree().paused
		visible = get_tree().paused

		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func resume():
	get_tree().paused = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func quit_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func exit_game():
	get_tree().quit()
