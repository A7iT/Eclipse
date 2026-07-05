class_name MuzzleFlash
extends Node3D

@export var _particles: GPUParticles3D
@export var _life_time: float = 0.3

func _ready() -> void:
	_particles.emitting = true
	_start_lifetime_timer()

func _start_lifetime_timer() -> void:
	await get_tree().create_timer(_life_time).timeout
	queue_free()
