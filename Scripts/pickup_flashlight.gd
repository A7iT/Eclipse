extends StaticBody3D

var flashlight

func _ready():
	flashlight = get_node("/root/" + get_tree().current_scene.name + "/Player/Head/Flashlight")

func interact():
	flashlight.picked_up = true
	GameManager.activate_monsters()  # ← triggers monsters
	queue_free()
