extends StaticBody3D

@export var paper_material: StandardMaterial3D
var toggle = false

func _ready():
	$MeshInstance3D.material_override = paper_material
	
func interact():
	toggle = !toggle
	$AudioStreamPlayer.play()
	get_node("/root/" + get_tree().current_scene.name + "/UI/paper").visible = toggle
	get_node("/root/" + get_tree().current_scene.name + "/Player").movable = !toggle
	get_node("/root/" + get_tree().current_scene.name + "/Player/Head").movable = !toggle
