extends CharacterBody3D

@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D


const SPEED = 5.0
const RUN_SPEED = 12.0
const JUMP_VELOCITY = 4

# Sprint energy
const SPRINT_MAX = 100.0
const SPRINT_DRAIN = 20.0
const SPRINT_REGEN = 10.0
const SPRINT_REGEN_DELAY = 1.5
const SPRINT_REACTIVATE_THRESHOLD = 30.0
var sprint_energy := SPRINT_MAX
var sprint_regen_timer := 0.0
var sprint_active := false
var sprint_was_released := true

# Movement toggle
var movable := true

# Head bob variables
const BOB_FREQ_WALK = 2.0
const BOB_FREQ_RUN = 3.0
const BOB_AMP_VERTICAL_WALK = 0.08
const BOB_AMP_VERTICAL_RUN = 0.12
const BOB_AMP_HORIZONTAL_WALK = 0.05
const BOB_AMP_HORIZONTAL_RUN = 0.08
var bob_time = 0.0

# Weapon state
var is_reloading := false
var is_inspecting := false
var is_shooting_burst := false
var is_shooting_oneshot := false
var is_drawing := true
var shoot_pressed := false
var shoot_decided := false
var shoot_held_timer := 0.0
const SHOOT_HOLD_THRESHOLD = 0.15

# Footstep timing
var footstep_timer := 0.0
const FOOTSTEP_INTERVAL_WALK = 0.5
const FOOTSTEP_INTERVAL_RUN = 0.28

# Muzzle flash
@export var muzzle_flash_scene: PackedScene
@export var muzzle_flash_marker: Marker3D  # Assign a Marker3D at the gun barrel tip

@onready var head = $Head
@onready var head_initial_y = head.position.y if head else 0.0
@onready var anim_player: AnimationPlayer = $AnimationPlayer2
@onready var sfx_shoot: AudioStreamPlayer = $"oneshot & brustshot"
@onready var sfx_footstep: AudioStreamPlayer = $"walk & run"
@onready var sfx_reload: AudioStreamPlayer = $"reload"


func _ready() -> void:
	if anim_player:
		anim_player.animation_finished.connect(_on_animation_finished)
		print("AnimationPlayer found!")
		print("Available animations: ", anim_player.get_animation_list())
		play_anim("Arms_FPS_Anim_Draw")
	else:
		print("ERROR: AnimationPlayer not found!")


func spawn_muzzle_flash() -> void:
	if not muzzle_flash_scene:
		push_warning("MuzzleFlash: muzzle_flash_scene is not assigned in the Inspector!")
		return
	var flash = muzzle_flash_scene.instantiate()
	# Attach to marker if available, otherwise attach to head
	if muzzle_flash_marker:
		muzzle_flash_marker.add_child(flash)
		flash.global_transform = muzzle_flash_marker.global_transform
	else:
		head.add_child(flash)
	# MuzzleFlash handles its own lifetime via queue_free()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if !movable:
		move_and_slide()
		return

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction := (transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()

	# Sprint logic
	var run_held = Input.is_action_pressed("Run")
	var run_just_pressed = Input.is_action_just_pressed("Run")
	var run_just_released = Input.is_action_just_released("Run")

	if run_just_released:
		sprint_was_released = true

	if run_just_pressed and sprint_was_released and sprint_energy >= SPRINT_MAX * (SPRINT_REACTIVATE_THRESHOLD / 100.0) and direction.length() > 0:
		sprint_active = true
		sprint_was_released = false

	if not run_held or direction.length() == 0 or sprint_energy <= 0.0:
		if sprint_energy <= 0.0:
			sprint_active = false
		elif not run_held or direction.length() == 0:
			sprint_active = false

	if sprint_active:
		sprint_energy -= SPRINT_DRAIN * delta
		sprint_regen_timer = 0.0
		if sprint_energy <= 0.0:
			sprint_energy = 0.0
			sprint_active = false
	else:
		sprint_regen_timer += delta
		if sprint_regen_timer >= SPRINT_REGEN_DELAY:
			sprint_energy = minf(sprint_energy + SPRINT_REGEN * delta, SPRINT_MAX)

	var current_speed = RUN_SPEED if sprint_active else SPEED

	if is_on_floor():
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
	else:
		velocity.x = lerp(velocity.x, direction.x * current_speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * current_speed, delta * 3.0)

	move_and_slide()
	apply_head_bob(delta, direction)
	handle_weapon(delta, direction)
	handle_footstep(delta, direction)


func handle_weapon(delta: float, direction: Vector3) -> void:
	var busy = is_reloading or is_inspecting or is_drawing

	# --- Inspect ---
	if Input.is_action_just_pressed("Inspect") and not busy:
		play_anim("Arms_FPS_Anim_rifle_inspect")
		is_inspecting = true
		return

	# --- Reload ---
	if Input.is_action_just_pressed("Reload") and not busy:
		play_anim("Arms_FPS_Anim_Reload_Fast")
		is_reloading = true
		sfx_reload.stop()
		sfx_reload.play()
		return

	if busy:
		return

	# --- Burst guard: hold this state until released ---
	if is_shooting_burst:
		if Input.is_action_just_released("Shoot"):
			sfx_shoot.stop()
			is_shooting_burst = false
			shoot_pressed = false
			shoot_decided = false
			shoot_held_timer = 0.0
		return

	# --- Oneshot guard: hold until anim finishes ---
	if is_shooting_oneshot:
		return

	# --- Shoot input detection ---
	if Input.is_action_just_pressed("Shoot"):
		shoot_pressed = true
		shoot_held_timer = 0.0
		shoot_decided = false

	if shoot_pressed:
		if Input.is_action_pressed("Shoot"):
			shoot_held_timer += delta
			if shoot_held_timer >= SHOOT_HOLD_THRESHOLD and not shoot_decided:
				shoot_decided = true
				is_shooting_burst = true
				is_shooting_oneshot = false
				play_anim("Arms_FPS_Anim_Shoot")
				sfx_shoot.stop()
				sfx_shoot.play()
				spawn_muzzle_flash()
				do_shoot()  # First burst flash
		else:
			# Released before threshold -> oneshot
			if not shoot_decided:
				is_shooting_oneshot = true
				play_anim("Arms_FPS_Anim_OneShot")
				sfx_shoot.stop()
				sfx_shoot.play()
				spawn_muzzle_flash()
				do_shoot()  # Oneshot flash
			shoot_pressed = false
			shoot_decided = false
			shoot_held_timer = 0.0
		return

	# --- Movement animations ---
	if sprint_active and direction.length() > 0:
		play_anim("Arms_FPS_Anim_Run")
	elif direction.length() > 0:
		play_anim("Arms_FPS_Anim_Walk")
	else:
		play_anim("Arms_FPS_Anim_Idle")


func handle_footstep(delta: float, direction: Vector3) -> void:
	if is_on_floor() and direction.length() > 0:
		var interval = FOOTSTEP_INTERVAL_RUN if sprint_active else FOOTSTEP_INTERVAL_WALK
		footstep_timer += delta
		if footstep_timer >= interval:
			footstep_timer = 0.0
			sfx_footstep.stop()
			sfx_footstep.play()
	else:
		footstep_timer = FOOTSTEP_INTERVAL_WALK


func play_anim(anim_name: String) -> void:
	if not anim_player:
		print("ERROR: anim_player is null!")
		return
	var full_name = "Armature|" + anim_name
	if anim_player.has_animation(full_name):
		if anim_player.current_animation != full_name:
			anim_player.play(full_name)
	else:
		print("WARNING: Animation not found: ", full_name)


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Armature|Arms_FPS_Anim_Draw":
		is_drawing = false
		play_anim("Arms_FPS_Anim_Idle")
	elif anim_name == "Armature|Arms_FPS_Anim_Reload_Fast":
		is_reloading = false
	elif anim_name == "Armature|Arms_FPS_Anim_rifle_inspect":
		is_inspecting = false
	elif anim_name == "Armature|Arms_FPS_Anim_OneShot":
		is_shooting_oneshot = false
		play_anim("Arms_FPS_Anim_Idle")
	elif anim_name == "Armature|Arms_FPS_Anim_Shoot":
		# Loop burst manually while button is still held
		if is_shooting_burst:
			play_anim("Arms_FPS_Anim_Shoot")
			sfx_shoot.stop()
			sfx_shoot.play()
			spawn_muzzle_flash()  # Flash on every burst loop
		else:
			play_anim("Arms_FPS_Anim_Idle")


func apply_head_bob(delta: float, direction: Vector3) -> void:
	if not head:
		return
	if is_on_floor() and direction.length() > 0:
		var bob_freq = BOB_FREQ_RUN if sprint_active else BOB_FREQ_WALK
		var bob_amp_vertical = BOB_AMP_VERTICAL_RUN if sprint_active else BOB_AMP_VERTICAL_WALK
		var bob_amp_horizontal = BOB_AMP_HORIZONTAL_RUN if sprint_active else BOB_AMP_HORIZONTAL_WALK
		bob_time += delta * bob_freq
		var vertical_bob = sin(bob_time * TAU) * bob_amp_vertical
		var horizontal_bob = cos(bob_time * TAU * 0.5) * bob_amp_horizontal
		head.position.y = head_initial_y + vertical_bob
		head.position.x = horizontal_bob
	else:
		head.position.y = lerp(head.position.y, head_initial_y, delta * 5.0)
		head.position.x = lerp(head.position.x, 0.0, delta * 5.0)
		bob_time = 0.0
		
func do_shoot() -> void:
	var space = get_world_3d().direct_space_state
	var cam = $Head/Camera3D

	var origin = cam.global_position
	var forward = -cam.global_transform.basis.z
	var end = origin + forward * 200.0

	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]

	var result = space.intersect_ray(query)

	if result and result.collider.has_method("take_hit"):
		result.collider.take_hit()
