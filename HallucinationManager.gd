extends Node
class_name HallucinationManager

@export_category("Hallucination Settings")
@export var possible_hallucinations: Array[PackedScene] = []
@export var min_spawn_interval: float = 10.0
@export var max_spawn_interval: float = 30.0

# ------ ЛИМИТЫ НА КАЖДЫЙ ТИП ------
@export_category("Hallucination Limits")
@export var max_total_hallucinations: int = 8  # Общий максимум
@export var type_limits: Array[Dictionary] = [
	{"type": "flying_mouth", "max_count": 4},
	{"type": "false_enemy", "max_count": 3},
	{"type": "creepy_eye", "max_count": 2}
]

@onready var sanity_manager: SanityManager = get_tree().get_first_node_in_group("sanity_manager")
var player: Node3D

var spawn_timer: float = 0.0
var current_interval: float = 0.0
var active_hallucinations: Array[BaseHallucination] = []

func _ready():
	player = get_tree().get_first_node_in_group("player")
	_reset_spawn_timer()
	
	if sanity_manager:
		sanity_manager.sanity_changed.connect(_on_sanity_changed)

func _process(delta):
	if possible_hallucinations.is_empty():
		return
	
	spawn_timer += delta
	
	if spawn_timer >= current_interval:
		_try_spawn_hallucination()
		_reset_spawn_timer()

func _on_sanity_changed(new_sanity: float):
	if not sanity_manager:
		return
		
	var sanity_percentage = new_sanity / sanity_manager.max_sanity
	
	if sanity_percentage <= 0.15:
		min_spawn_interval = 5.0
		max_spawn_interval = 15.0
	elif sanity_percentage <= 0.3:
		min_spawn_interval = 8.0  
		max_spawn_interval = 20.0
	elif sanity_percentage <= 0.45:
		min_spawn_interval = 12.0
		max_spawn_interval = 25.0
	else:
		min_spawn_interval = 999.0
		max_spawn_interval = 999.0

func _try_spawn_hallucination():
	if not sanity_manager:
		return
	
	if active_hallucinations.size() >= max_total_hallucinations:
		return
		
	var sanity_percentage = sanity_manager.current_sanity / sanity_manager.max_sanity
	var spawn_chance = 1.0 - sanity_percentage
	
	if randf() <= spawn_chance:
		_spawn_random_hallucination()

func _spawn_random_hallucination():
	if possible_hallucinations.is_empty() or not player:
		return
	
	var available_hallucinations = _get_available_hallucination_types()
	
	if available_hallucinations.is_empty():
		return
	
	var random_index = randi() % available_hallucinations.size()
	var hallucination_scene = available_hallucinations[random_index]
	var hallucination: BaseHallucination = hallucination_scene.instantiate()
	
	call_deferred("_add_hallucination", hallucination)

func _get_available_hallucination_types() -> Array[PackedScene]:
	var available: Array[PackedScene] = []
	
	for hallucination_scene in possible_hallucinations:
		var temp_instance = hallucination_scene.instantiate()
		var hallucination_type = temp_instance.get_hallucination_type()
		temp_instance.queue_free()
		
		if _can_spawn_hallucination_type(hallucination_type):
			available.append(hallucination_scene)
	
	return available

func _can_spawn_hallucination_type(hallucination_type: String) -> bool:
	var current_count = 0
	for hallucination in active_hallucinations:
		if hallucination.get_hallucination_type() == hallucination_type:
			current_count += 1
	
	for limit in type_limits:
		if limit["type"] == hallucination_type:
			return current_count < limit["max_count"]
	
	return true

func _add_hallucination(hallucination: BaseHallucination):
	get_parent().add_child(hallucination)
	
	var spawn_radius = 4.0
	var max_attempts = 10
	var spawn_pos: Vector3
	@warning_ignore("unused_variable")
	var found_position = false
	
	for attempt in range(max_attempts):
		var random_angle = randf() * TAU
		spawn_pos = player.global_position + Vector3(
			cos(random_angle) * spawn_radius,
			1.0 + randf() * 2.0,
			sin(random_angle) * spawn_radius
		)
		
		var too_close = false
		for active_hallucination in active_hallucinations:
			if active_hallucination.global_position.distance_to(spawn_pos) < 2.0:
				too_close = true
				break
		
		if not too_close:
			found_position = true
			break
	
	hallucination.global_position = spawn_pos
	active_hallucinations.append(hallucination)
	
	hallucination.hallucination_disappeared.connect(
		func(): active_hallucinations.erase(hallucination)
	)

func _reset_spawn_timer():
	spawn_timer = 0.0
	current_interval = randf_range(min_spawn_interval, max_spawn_interval)

# ------ Публичные методы ------
func add_hallucination_type(hallucination_scene: PackedScene):
	if not possible_hallucinations.has(hallucination_scene):
		possible_hallucinations.append(hallucination_scene)

func remove_hallucination_type(hallucination_scene: PackedScene):
	possible_hallucinations.erase(hallucination_scene)

func clear_all_hallucinations():
	for hallucination in active_hallucinations:
		hallucination.queue_free()
	active_hallucinations.clear()

# ------ ДЕБАГ ИНФОРМАЦИЯ ------
func get_debug_info() -> Dictionary:
	var type_counts = {}
	for hallucination in active_hallucinations:
		var type = hallucination.get_hallucination_type()
		type_counts[type] = type_counts.get(type, 0) + 1
	
	return {
		"total_active": active_hallucinations.size(),
		"type_counts": type_counts,
		"max_total": max_total_hallucinations
	}
