extends RayCast3D

var int_text

func _ready():
	int_text = get_tree().current_scene.get_node("UI/interact_text")
	if not int_text:
		push_error("interact_text not found. Check your path, idjit.")

func _process(_delta: float) -> void:
	var hit = null

	if is_colliding():
		hit = get_collider()

	if hit and hit.has_method("interact"):
		int_text.visible = true
		if Input.is_action_just_pressed("Interact"):
			hit.interact()
	else:
		int_text.visible = false

# Called by player.gd when shooting fires
func try_shoot() -> void:
	if is_colliding():
		var hit = get_collider()
		if hit and hit.has_method("take_hit"):
			hit.take_hit()
