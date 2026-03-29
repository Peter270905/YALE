extends CustomEffect
class_name FeatherFallingEffect

var original_fall_damage_threshold: float = 0.0
var original_fall_damage_multiplier: float = 0.0

func on_effect_start(target: Node) -> void:
	if target is PlayerState:
		original_fall_damage_threshold = target.fall_damage_threshold
		original_fall_damage_multiplier = target.fall_damage_multiplier
		
		
		target.fall_damage_threshold *= 2.0
		target.fall_damage_multiplier *= 0.3
		
		print("🪶 Легкое падение активировано! Порог: ", target.fall_damage_threshold)

func on_effect_end(target: Node) -> void:
	if target is PlayerState:
		target.fall_damage_threshold = original_fall_damage_threshold
		target.fall_damage_multiplier = original_fall_damage_multiplier
		print("🪶 Легкое падение деактивировано!")
