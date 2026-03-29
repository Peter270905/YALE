extends CustomEffect
class_name InstantHealthEffect

@export var health_restore: float = 10.0
var has_applied: bool = false

func execute(target: Node, data: Dictionary = {}) -> void:
	if target is PlayerState and apply_time == ApplyTime.ON_APPLY and !has_applied:
		var player = target as PlayerState
		player.update_health(health_restore)
		has_applied = true

func on_effect_start(target: Node) -> void:
	has_applied = false
