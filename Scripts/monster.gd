extends CharacterBody3D

var SPEED = 1.7
var jumpscareTime = 3
var player
var caught = false
var distance: float
@export var scene_name: String
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Navigation update throttle
var _nav_update_timer := 0.0
const NAV_UPDATE_INTERVAL := 0.1

func _ready():
	player = get_node("/root/" + get_tree().current_scene.name + "/Player")
	var anim = $"Sketchfab_Scene/AnimationPlayer"
	anim.play("Take 001")
	anim.get_animation("Take 001").loop_mode = Animation.LOOP_LINEAR
	$AudioStreamPlayer3D.stream.loop = true
	$AudioStreamPlayer3D.play()
	$Flashlight.visible = false
	await get_tree().physics_frame
	await get_tree().physics_frame

func _physics_process(delta):
	if visible and not caught:
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Update navigation target only 10 times per second
		_nav_update_timer += delta
		if _nav_update_timer >= NAV_UPDATE_INTERVAL:
			_nav_update_timer = 0.0
			$NavigationAgent3D.target_position = player.global_transform.origin

		var current_location = global_transform.origin
		var next_location = $NavigationAgent3D.get_next_path_position()

		var direction = next_location - current_location
		if direction.length() > 0.1:
			# Normalize only once
			var dir_normalized = direction.normalized()
			velocity.x = dir_normalized.x * SPEED
			velocity.z = dir_normalized.z * SPEED
		else:
			velocity.x = 0
			velocity.z = 0

		# Face the player directly
		var player_pos = player.global_transform.origin
		var look_dir = atan2(
			-(player_pos.x - global_position.x),
			-(player_pos.z - global_position.z)
		) + PI
		rotation.y = look_dir

		move_and_slide()

		# Use squared distance (avoids expensive sqrt)
		var dist_sq = player.global_transform.origin.distance_squared_to(global_transform.origin)
		if dist_sq <= 4.0: # 2 * 2
			player.visible = false
			SPEED = 0
			caught = true
			$"Sketchfab_Scene/AnimationPlayer".stop()
			$jumpscare_camera.current = true
			$Flashlight.visible = true
			$deathAudio.play()
			await get_tree().create_timer(jumpscareTime, false).timeout
			get_tree().change_scene_to_file("res://Scenes/" + scene_name + ".tscn")

func update_target_location(target_location):
	$NavigationAgent3D.target_position = target_location

func take_hit() -> void:
	if caught:
		return

	# Award kill point
	GameManager.add_kill()

	# Stop audio & navigation
	$AudioStreamPlayer3D.stop()
	SPEED = 0

	# Disappear
	queue_free()
