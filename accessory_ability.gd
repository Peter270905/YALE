extends Resource
class_name AccessoryAbility

@export var ability_name: String
@export var description: String

# Вызывается при экипировке
func on_equip(_player: PlayerState):
	pass

# Вызывается при снятии  
func on_unequip(_player: PlayerState):
	pass

# Вызывается каждый кадр/в процессе
func on_process(_player: PlayerState, _delta: float):
	pass

# Вызывается при определенных событиях
func on_event(_player: PlayerState, _event_type: String, _data: Dictionary = {}):
	pass
