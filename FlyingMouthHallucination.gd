extends BaseHallucination
class_name FlyingMouthHallucination

@export var whisper_sounds: Array[AudioStream]
@export var follow_speed: float = 0.5
@export var min_follow_distance: float = 3.0
@export var max_follow_distance: float = 6.0

var current_offset: Vector3
var target_offset: Vector3
var offset_change_timer: float = 0.0

func _ready():
	super._ready()
	_generate_new_offset()
	current_offset = target_offset

func _custom_behavior(delta: float):
	if not player:
		return
	
	offset_change_timer += delta
	if offset_change_timer > 3.0:
		_generate_new_offset()
		offset_change_timer = 0.0
	
	current_offset = current_offset.lerp(target_offset, delta * 0.5)
	var target_pos = player.global_position + current_offset
	global_position = global_position.lerp(target_pos, delta * follow_speed)
	look_at(player.global_position, Vector3.UP)
	
	var random_wobble = Vector3(
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1),
		randf_range(-0.1, 0.1)
	) * (1.0 - (sanity_manager.current_sanity / sanity_manager.max_sanity))
	
	global_position += random_wobble

func _generate_new_offset():
	var distance = randf_range(min_follow_distance, max_follow_distance)
	var angle = randf() * TAU
	
	target_offset = Vector3(
		cos(angle) * distance,
		randf_range(1.0, 3.0),
		sin(angle) * distance
	)

func get_hallucination_type() -> String:
	return "flying_mouth"
