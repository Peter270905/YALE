class_name AgressiveMob
extends CharacterBody3D

@export_category("AI Settings")
@export var wander_radius: float = 8.0
@export var wander_speed: float = 1.5
@export var chase_speed: float = 4.0
@export var max_chase_distance: float = 20.0
@export var detection_range: float = 10.0

@export var anims: AnimationPlayer
@export var controller: Node3D
@export var collisionshape: CollisionShape3D
@export var attack_ray: RayCast3D
@export var drops: Array[DropData] = []
var home_position: Vector3
var current_wander_center: Vector3
var current_target: Node3D = null
var current_state: String = "wandering"
var behaviors: Array[MobBehavior] = []
var is_dead: bool = false

@export var max_health: int = 20
@export var health_regeneration: float = 5.0
@export var regeneration_delay: float = 15.0

var current_health: int
var last_damage_time: float = -999.0

signal health_changed(new_health: int, old_health: int)
signal mob_died()
signal mob_attacked(attacker: Node3D, damage: int)

@export_category("Combat Settings")
@export var attack_range: float = 3.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 2.0

func _ready():
	add_to_group("aggressive_mobs")
	add_to_group("enemies")
	home_position = global_position
	current_wander_center = home_position
	
	current_health = max_health
	
	for child in get_children():
		if child is MobBehavior:
			behaviors.append(child)

func _physics_process(delta):
	var vertical_velocity = velocity.y
	
	if not is_on_floor():
		vertical_velocity -= 20.0 * delta
		vertical_velocity = max(vertical_velocity, -50.0)
	else:
		vertical_velocity = 0
	
	match current_state:
		"wandering":
			_wander_behavior(delta)
		"chasing":
			_chase_behavior(delta)
		"attacking":
			_attack_behavior(delta)
		"returning_home":
			_return_home_behavior(delta)
	_update_animation()
	
	velocity.y = vertical_velocity
	
	move_and_slide()
	
	if velocity.length() > 0.1:
		var look_direction = Vector3(velocity.x, 0, velocity.z).normalized()
		if look_direction != Vector3.ZERO:
			var target_rotation = atan2(look_direction.x, look_direction.z)
			controller.rotation.y = lerp_angle(controller.rotation.y, target_rotation, delta * 5.0)
	
	for behavior in behaviors:
		if behavior.has_method("_process_combat"):
			behavior._process_combat(delta, current_target, current_state)

func _update_animation():
	if is_dead:
		return
		
	if current_state == "attacking":
		return
	
	if anims:
		if velocity.length() > 0.1 and is_on_floor():
			if anims.current_animation != "walk":
				anims.play("walk")
		else:
			if anims.current_animation != "idle":
				anims.play("idle")

@warning_ignore("unused_parameter")
func _attack_behavior(delta):
	velocity = Vector3.ZERO
	if current_target and global_position.distance_to(current_target.global_position) > 3.0:
		current_state = "chasing"

@warning_ignore("unused_parameter")
func _wander_behavior(delta):
	if velocity.length() < 0.1:
		_choose_new_wander_direction()
	
	_detect_player()
	
	var distance_to_center = global_position.distance_to(current_wander_center)
	if distance_to_center > wander_radius:
		var direction_to_center = (current_wander_center - global_position).normalized()
		velocity = direction_to_center * wander_speed

@warning_ignore("unused_parameter")
func _chase_behavior(delta):
	if not current_target:
		current_state = "wandering"
		return
	
	var distance_to_target = global_position.distance_to(current_target.global_position)
	var distance_to_home = global_position.distance_to(home_position)
	
	if distance_to_home > max_chase_distance:
		current_target = null
		current_state = "returning_home"
		return
	
	if distance_to_target <= attack_range:
		current_state = "attacking"
		velocity = Vector3.ZERO
	else:
		var direction = (current_target.global_position - global_position).normalized()
		velocity = direction * chase_speed

func can_attack_target() -> bool:
	if not current_target:
		return false
	
	var distance = global_position.distance_to(current_target.global_position)
	return distance <= attack_range


func _can_attack_target() -> bool:
	if not attack_ray or not current_target:
		return false
	
	var distance = global_position.distance_to(current_target.global_position)
	if distance > attack_range:
		return false
	
	if attack_ray.is_colliding():
		var collider = attack_ray.get_collider()
		return collider == current_target
	
	return false

@warning_ignore("unused_parameter")
func _return_home_behavior(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= detection_range:
		current_target = player
		current_state = "chasing"
		return
	
	var direction = (home_position - global_position).normalized()
	velocity = direction * wander_speed
	
	if global_position.distance_to(home_position) <= 2.0:
		current_wander_center = home_position
		current_state = "wandering"

func _choose_new_wander_direction():
	var random_angle = randf() * 2 * PI
	var target_pos = current_wander_center + Vector3(
		cos(random_angle) * wander_radius * 0.7,
		0,
		sin(random_angle) * wander_radius * 0.7
	)
	
	var direction = (target_pos - global_position).normalized()
	velocity = direction * wander_speed

func _detect_player():
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= detection_range:
		if player.has_node("state"):
			current_target = player.get_node("state")
		else:
			current_target = player
		current_state = "chasing"

func take_damage(damage: int, attacker: Node3D, tool: ItemTool = null) -> void:
	if is_dead:
		return
	var old_health = current_health
	current_health -= damage
	last_damage_time = Time.get_unix_time_from_system()
	health_changed.emit(current_health, old_health)
	mob_attacked.emit(attacker, damage)
	if current_health <= 0:
		_die(attacker, tool)


func _die(killer: Node3D, tool: ItemTool = null) -> void:
	if is_dead:
		return
	
	is_dead = true
	_drop_loot_on_death()
	if has_node("CollisionShape3D"):
		collisionshape.disabled = true
	
	for behavior in behaviors:
		if behavior and behavior.has_method("_on_mob_died"):
			behavior._on_mob_died(killer, tool)
	
	if has_node("AnimationPlayer"):
		anims.play("die")
		await anims.animation_finished
		queue_free()
	else:
		await get_tree().process_frame
		queue_free()
	
	mob_died.emit()


func _drop_loot_on_death():
	for drop in drops:
		if randf() <= drop.drop_chance:  
			var quantity = drop.get_quantity()
			if quantity > 0:
				_create_pick_up(drop.item, quantity, global_position)

@warning_ignore("shadowed_variable_base_class")
func _create_pick_up(item_data: ItemData, quantity: int, position: Vector3):
	var pick_up_scene = preload("res://scenes/pick_up/pick_up.tscn")
	var pick_up = pick_up_scene.instantiate()
	
	var slot_data = SlotData.new()
	slot_data.item_data = item_data
	slot_data.quantity = quantity
	
	pick_up.slot_data = slot_data
	get_tree().current_scene.add_child(pick_up)
	
	var random_offset = Vector3(
		randf_range(-1.0, 1.0),
		0.5,
		randf_range(-1.0, 1.0)
	)
	pick_up.global_position = position + random_offset
	
	if pick_up is RigidBody3D:
		var impulse_force = Vector3(
			randf_range(-2.0, 2.0),
			randf_range(3.0, 5.0),
			randf_range(-2.0, 2.0)
		)
		pick_up.apply_impulse(impulse_force)

func get_drop_item(drop_index: int) -> ItemData:
	if drop_index < drops.size():
		return drops[drop_index].item
	return null
