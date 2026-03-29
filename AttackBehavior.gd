extends MobBehavior
class_name AttackBehavior

@export var attack_damage: int = 10
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 2.0

var last_attack_time: float = -999.0

@warning_ignore("unused_parameter")
func _process_combat(delta: float, target: Node3D, state: String):
	
	if state == "attacking":
		# 🔥 ЕСЛИ TARGET NULL - БЕРЁМ ИГРОКА НАПРЯМУЮ
		var actual_target = target
		if not actual_target:
			actual_target = get_tree().get_first_node_in_group("player")
		
		if actual_target and _can_attack():
			_melee_attack(actual_target)

func _melee_attack(target: Node3D):
	last_attack_time = Time.get_unix_time_from_system()
	
	if target and target.has_method("take_damage"):
		target.take_damage(attack_damage)
	else:
		pass
	if mob.anims and mob.anims.has_animation("attack"):
		mob.anims.play("attack")

func _can_attack() -> bool:
	return Time.get_unix_time_from_system() - last_attack_time >= attack_cooldown
