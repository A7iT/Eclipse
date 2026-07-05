extends Node

var kills: int = 0
var monsters_active: bool = false  # ← new

func activate_monsters() -> void:
	monsters_active = true

func add_kill() -> void:
	kills += 1
	print("Kills: ", kills)
	var label = get_tree().current_scene.get_node_or_null("UI/KillLabel")
	if label:
		label.text = "Kills: %d" % kills

func reset() -> void:
	kills = 0
	monsters_active = false  # ← reset this too
	var label = get_tree().current_scene.get_node_or_null("UI/KillLabel")
	if label:
		label.text = "Kills: 0"
