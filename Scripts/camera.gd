extends Node3D

# Mouse sensitivity
var sens := 0.001

# Controller sensitivity
var controller_sens := 2.0

# Vertical rotation (pitch)
var pitch := 0.0

# Movement toggle
var movable := true


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if !movable:
		return

	if event is InputEventMouseMotion:
		_handle_mouse_look(event)


func _process(delta: float) -> void:
	if !movable:
		return

	_handle_controller_look(delta)


# MOUSE LOOK
func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	# Horizontal (Player rotates)
	get_parent().rotate_y(-event.relative.x * sens)

	# Vertical (CameraPivot rotates)
	pitch += event.relative.y * sens
	pitch = clamp(pitch, deg_to_rad(-50), deg_to_rad(50))
	rotation.x = pitch


# CONTROLLER LOOK
func _handle_controller_look(delta: float) -> void:
	var look_x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var look_y = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")

	# Horizontal (Player)
	if abs(look_x) > 0.01:
		get_parent().rotate_y(-look_x * controller_sens * delta)

	# Vertical (CameraPivot)
	if abs(look_y) > 0.01:
		pitch += -look_y * controller_sens * delta
		pitch = clamp(pitch, deg_to_rad(-50), deg_to_rad(50))
		rotation.x = pitch
