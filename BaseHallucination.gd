extends Node3D
class_name BaseHallucination

# ------ Сигналы ------
signal hallucination_spawned()
signal hallucination_disappeared()
signal player_looked_at()

# ------ Настройки ------
@export_category("Hallucination Settings")
@export var disappear_on_look: bool = true
@export var life_time: float = 30.0
@export var transparency: float = 0.4
@export var sanity_cost_to_spawn: float = 5.0
var wander_direction: Vector3
var wander_speed: float = 1.0

# ------ Ссылки ------
@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")
var player: Node3D
var sanity_manager: SanityManager
var camera: Camera3D

# ------ Состояние ------
var is_vanishing: bool = false
var spawn_time: float = 0.0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	sanity_manager = get_tree().get_first_node_in_group("sanity_manager")
	if player:
		camera = player.get_node_or_null("Camera3D")
	
	_setup_appearance()
	_setup_collision()
	_start_life_timer()
	
	hallucination_spawned.emit()
	
	if sanity_manager:
		sanity_manager.change_sanity(-sanity_cost_to_spawn)
	wander_direction = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
	wander_speed = randf_range(0.5, 2.0)

func _setup_appearance():
	if not mesh_instance:
		return
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.7, 0.2, 0.2, transparency)
	material.emission_enabled = true
	material.emission = Color(0.3, 0, 0)
	
	mesh_instance.material_override = material

func _setup_collision():
	if collision_shape:
		collision_shape.disabled = true

func _start_life_timer():
	spawn_time = Time.get_time_dict_from_system()["second"]

func _process(delta):
	if is_vanishing:
		return
	
	_check_life_time()
	_check_player_look()
	_custom_behavior(delta)

func _check_life_time():
	var current_time = Time.get_time_dict_from_system()["second"]
	if current_time - spawn_time >= life_time:
		_disappear()

func _check_player_look():
	if not disappear_on_look or not player or not camera:
		return
	
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(
		camera.global_position,
		global_position
	)
	var result = space_state.intersect_ray(query)
	
	if result.is_empty() or result.collider == self:
		var look_direction = camera.global_transform.basis.z
		var to_hallucination = global_position - camera.global_position
		var dot_product = look_direction.dot(to_hallucination.normalized())
		
		if dot_product > 0.95:
			player_looked_at.emit()
			_disappear()

func _disappear():
	if is_vanishing:
		return
	
	is_vanishing = true
	
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.5)
		tween.tween_callback(_on_disappear_finished)
	else:
		_on_disappear_finished()

func _on_disappear_finished():
	hallucination_disappeared.emit()
	queue_free()

# ------ ВИРТУАЛЬНЫЕ МЕТОДЫ ------
func _custom_behavior(delta: float):
	global_position += wander_direction * wander_speed * delta
	if randf() < 0.02:
		wander_direction = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()

func get_hallucination_type() -> String:
	return "base"
