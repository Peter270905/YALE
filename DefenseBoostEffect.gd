extends CustomEffect
class_name DefenseBoostEffect

@export var defense_multiplier: float = 1.5
var original_defense: int = 0

func on_effect_start(target: Node) -> void:
	if target is PlayerState:
		var player = target as PlayerState
		original_defense = player.defense
		player.defense = player.defense * defense_multiplier
		print("🛡️ Защита увеличена: ", original_defense, " -> ", player.defense)

func on_effect_end(target: Node) -> void:
	if target is PlayerState:
		var player = target as PlayerState
		player.defense = original_defense
		print("🛡️ Защита восстановлена: ", player.defense)
