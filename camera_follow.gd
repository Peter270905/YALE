extends Camera3D

@export var lerp_power: float = 4.0
@onready var spring_arm: Node3D = $"../SpringArm3D/spring_pos"
@onready var state: PlayerState = $"../../state"
@onready var player: PlayerController = $"../.."

# Параметры камеры
var first_person_fov: float = 85.0
var third_person_fov: float = 70.0
var camera_lerp_speed: float = 8.0

func _process(delta: float) -> void:
	if state.is_first_person:
		var target_position = state.first_person_camera_offset
		
		target_position += player.headbob_offset 
		
		position = position.lerp(target_position, delta * camera_lerp_speed)
		fov = lerp(fov, first_person_fov, delta * camera_lerp_speed)
	else:
		position = lerp(position, spring_arm.position, delta * lerp_power)
		fov = lerp(fov, third_person_fov, delta * camera_lerp_speed)
