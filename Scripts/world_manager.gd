extends Node3D

var player

func _ready() -> void:
	player = get_node("/root/" + get_tree().current_scene.name + "/Player")
