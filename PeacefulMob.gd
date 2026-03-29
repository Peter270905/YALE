class_name PeacefulMob
extends CharacterBody3D

# Базовые настройки
@export var wander_speed: float = 1.5
@export var flee_speed: float = 4.0
@export var wander_interval: float = 3.0
@export var flee_duration: float = 4.0
@export var gravity: float = 100.0
@export var max_fall_speed: float = 50.0
@export var fall_acceleration: float = 20.0
@export var anims: AnimationPlayer
@export var interaction: Area3D
@export var controller: Node3D
@export var interactionareashape: CollisionShape3D
@export var collisionshape: CollisionShape3D
@export var interactable_data: InteractableData
@export var drops: Array[DropData] = []
# СИСТЕМА ЗДОРОВЬЯ
@export var max_health: int = 20
@export var health_regeneration: float = 5.0
@export var regeneration_delay: float = 15.0

var current_health: int
var last_damage_time: float = -999.0
var is_dead: bool = false

# Сигналы здоровья
signal health_changed(new_health: int, old_health: int)
signal mob_died()
signal mob_attacked(attacker: Node3D, damage: int)

var behaviors: Array[MobBehavior] = []
var current_state: String = "wandering"
var wander_timer: float = 0.0
var flee_timer: float = 0.0
var current_direction: Vector3 = Vector3.ZERO
var player: Node3D

func _ready():
	add_to_group("enemies")
	add_to_group("peaceful_mobs")
	
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	
	for child in get_children():
		if child is MobBehavior:
			behaviors.append(child)
	
	_choose_new_direction()
	
	if has_node("InteractionArea"):
		interaction.input_event.connect(_on_interaction_area_input_event)

func get_drop_item(drop_index: int) -> ItemData:
	if drop_index < drops.size():
		return drops[drop_index].item
	return null

func set_temp_state(state: String):
	temp_state = state

func clear_temp_state():
	temp_state = ""

var temp_state: String = ""


func _physics_process(delta):
	if temp_state != "":
		velocity = Vector3.ZERO
		return
	
	if is_dead:
		return
	
	_handle_regeneration(delta)
	
	var vertical_velocity = velocity.y
	
	if not is_on_floor():
		vertical_velocity -= fall_acceleration * delta
		vertical_velocity = max(vertical_velocity, -max_fall_speed)
	else:
		vertical_velocity = 0
	
	match current_state:
		"wandering":
			_wander_behavior(delta)
		"fleeing":
			_flee_behavior(delta)
	
	velocity.y = vertical_velocity
	
	move_and_slide()
	
	if velocity.length() > 0.1:
		var look_direction = Vector3(velocity.x, 0, velocity.z).normalized()
		if look_direction != Vector3.ZERO:
			var target_rotation = atan2(look_direction.x, look_direction.z)
			controller.rotation.y = lerp_angle(controller.rotation.y, target_rotation, delta * 5.0)
	
	for behavior in behaviors:
		if behavior:
			behavior._process_behavior(delta)

func take_damage(damage: int, attacker: Node3D, tool: ItemTool = null) -> void:
	if is_dead:
		return
	var old_health = current_health
	current_health -= damage
	last_damage_time = Time.get_unix_time_from_system()
	health_changed.emit(current_health, old_health)
	mob_attacked.emit(attacker, damage)
	current_state = "fleeing"
	flee_timer = flee_duration
	_show_damage_effects()
	if current_health <= 0:
		_die(attacker, tool)

@warning_ignore("unused_parameter")
func on_herd_alert(attacker: Node3D):
	current_state = "fleeing"
	flee_timer = flee_duration

func _handle_regeneration(delta: float) -> void:
	if is_dead:
		return
	
	var time_since_damage = Time.get_unix_time_from_system() - last_damage_time
	if time_since_damage < regeneration_delay:
		return
	
	if current_health < max_health:
		var regen_amount = health_regeneration * delta
		var old_health = current_health
		current_health = min(max_health, current_health + regen_amount)
		
		if current_health != old_health:
			health_changed.emit(current_health, old_health)

func _show_damage_effects() -> void:
	if has_node("controller"):
		var material = controller.get_surface_override_material(0)
		if material:
			var tween = create_tween()
			tween.tween_property(controller, "modulate", Color.RED, 0.1)
			tween.tween_property(controller, "modulate", Color.WHITE, 0.1)
	
	if has_node("BloodParticles"):
		$BloodParticles.emitting = true

func _die(killer: Node3D, tool: ItemTool = null) -> void:
	if is_dead:
		return
	
	is_dead = true
	_drop_loot_on_death()
	if has_node("CollisionShape3D"):
		collisionshape.disabled = true
	if has_node("InteractionArea"):
		interactionareashape.disabled = true
	
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

func _wander_behavior(delta):
	wander_timer -= delta
	if wander_timer <= 0:
		if randf() < 0.7:
			current_direction = Vector3.ZERO
			wander_timer = randf_range(2.0, 5.0)
		else:
			_choose_new_direction()
			wander_timer = randf_range(2.0, 4.0)
	
	velocity.x = current_direction.x * wander_speed
	velocity.z = current_direction.z * wander_speed
	
	_update_animation()

func _flee_behavior(delta):
	flee_timer -= delta
	if flee_timer <= 0:
		current_state = "wandering"
		wander_timer = 0
		return
	
	if player:
		var flee_direction = (global_position - player.global_position).normalized()
		flee_direction.y = 0
		current_direction = flee_direction
		
		velocity.x = current_direction.x * flee_speed
		velocity.z = current_direction.z * flee_speed
	
	_update_animation()

func _choose_new_direction():
	current_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	wander_timer = randf_range(2.0, 4.0)

func _update_animation():
	if is_dead:
		return
		
	if velocity.length() > 0.1:
		anims.play("walk")
	else:
		anims.play("idle")

func _on_interaction_area_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_interact()

func _try_interact():
	var player_controller = get_tree().get_first_node_in_group("player")
	if not player_controller:
		return
	
	var current_item = player_controller.get_current_item()
	
	for behavior in behaviors:
		if behavior and behavior._on_interact(player_controller, current_item):
			return

func get_interactable_data() -> InteractableData:
	return interactable_data

@warning_ignore("shadowed_variable")
func get_interaction_text_for_player(player: Node) -> String:
	
	for behavior in behaviors:
		if behavior and behavior.has_method("get_interaction_text"):
			var custom_text = behavior.get_interaction_text(player)
			if custom_text != "":
				return custom_text
	
	return interactable_data.interact_text

@warning_ignore("shadowed_variable")
func player_interact(player = null):
	if player and player.has_method("get_current_item"):
		var current_item = player.get_current_item()
		for behavior in behaviors:
			if behavior and behavior.has_method("_on_interact"):
				var handled = behavior._on_interact(player, current_item)
				if handled:
					return true
		return false
	return false
