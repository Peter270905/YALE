extends MobBehavior
class_name GallatBehavior

@export_category("Herd Settings")
@export var herd_range: float = 15.0
@export var herd_update_interval: float = 5.0

@export_category("Combat Settings")
@export var attack_damage: int = 5
@export var attack_cooldown: float = 1.5

@export_category("Egg Laying Settings") 
@export var egg_laying_cooldown_min: float = 180
@export var egg_laying_cooldown_max: float = 240
@export var egg_laying_animation: String = "egg_laying"
@export var egg_item: ItemData
@export var anims: AnimationPlayer

var herd_members: Array = []
var herd_update_timer := 0.0
var is_attacking := false
var current_target: Node = null
var last_attack_time := -999.0
var next_laying_time := 0.0
var is_laying_egg := false

func _setup_behavior():
	_find_herd_members()
	_reset_laying_timer()

func _process_behavior(delta):
	if is_laying_egg:
		return
		
	herd_update_timer -= delta
	if herd_update_timer <= 0:
		_find_herd_members()
		herd_update_timer = herd_update_interval
	
	if is_attacking and current_target:
		_handle_combat()
	
	var current_time = Time.get_unix_time_from_system()
	
	if current_time >= next_laying_time:
		_lay_egg()

func _find_herd_members():
	herd_members.clear()
	herd_members.append(mob)
	
	var all_gallat = get_tree().get_nodes_in_group("gallat")
	for gallat in all_gallat:
		if gallat == mob:
			continue
			
		var distance = mob.global_position.distance_to(gallat.global_position)
		if distance <= herd_range:
			herd_members.append(gallat)

@warning_ignore("unused_parameter")
func _on_mob_attacked(attacker: Node3D, damage: int):
	for member in herd_members:
		if member != mob and member.has_method("on_herd_alert"):
			member.on_herd_alert(attacker)
	
	current_target = attacker
	is_attacking = true

func on_herd_alert(attacker: Node3D):
	if not is_attacking:
		current_target = attacker
		is_attacking = true
# ==================================================
#                     БОЙ
# ==================================================

func _handle_combat():
	var now = Time.get_unix_time_from_system()
	if now - last_attack_time < attack_cooldown:
		return

	if mob.global_position.distance_to(current_target.global_position) > 3.0:
		return

	last_attack_time = now
	_attack()

func _attack():
	if current_target and current_target.has_method("take_damage"):
		current_target.take_damage(attack_damage, mob)

	if anims:
		anims.play("attack")

func _apply_bleed_effect(target):
	if target.has_method("add_status_effect"):
		target.add_status_effect("bleed", 5.0, 1)

# ==================================================
#                     ЯЙЦА
# ==================================================

func _lay_egg():
	is_laying_egg = true
	var old_vel = mob.velocity
	mob.velocity = Vector3.ZERO

	if mob.has_method("set_temp_state"):
		mob.set_temp_state("laying_egg")

	if anims and anims.has_animation(egg_laying_animation):
		anims.stop()
		anims.play(egg_laying_animation)
		await anims.animation_finished
	else:
		await get_tree().create_timer(2).timeout
	
	if mob.has_method("clear_temp_state"):
		mob.clear_temp_state()

	if egg_item:
		_spawn_egg()
	else:
		pass

	mob.velocity = old_vel
	is_laying_egg = false
	
	_reset_laying_timer()

func _spawn_egg():
	var scene := preload("res://scenes/pick_up/pick_up.tscn").instantiate()
	var slot := SlotData.new()
	slot.item_data = egg_item
	slot.quantity = 1
	scene.slot_data = slot

	get_tree().current_scene.add_child(scene)
	scene.global_position = mob.global_position + Vector3(randf_range(-0.5,0.5), 0.1, randf_range(-0.5,0.5))


func _reset_laying_timer():
	next_laying_time = Time.get_unix_time_from_system() + randf_range(egg_laying_cooldown_min, egg_laying_cooldown_max)

# ==================================================
#                ВЗАИМОДЕЙСТВИЕ
# ==================================================

@warning_ignore("unused_parameter")
func get_interaction_text(player: Node) -> String:
	if is_attacking:
		return "Агрессивен!"
	if is_laying_egg:
		return "Кладёт яйцо..."
	return " "
