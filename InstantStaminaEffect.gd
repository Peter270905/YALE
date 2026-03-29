extends CustomEffect
class_name InstantStaminaEffect

@export var stamina_restore: float

func execute(target: Node, data: Dictionary = {}) -> void:
	if target is PlayerState and apply_time == ApplyTime.ON_APPLY:
		var player = target as PlayerState
		player.update_stamina(stamina_restore)
