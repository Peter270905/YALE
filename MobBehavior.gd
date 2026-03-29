extends Node
class_name MobBehavior

@export var behavior_name: String = "Unnamed"
var mob: Node

func _ready():
	mob = get_parent()
	if not mob.has_method("take_damage"):
		push_error("MobBehavior должен быть child моба!")
	
	if mob.has_signal("mob_attacked"):
		mob.mob_attacked.connect(_on_mob_attacked)
	
	_setup_behavior()

func _setup_behavior():
	pass

@warning_ignore("unused_parameter")
func _process_behavior(delta):
	pass

@warning_ignore("unused_parameter")
func _on_interact(player: Node, item: ItemData) -> bool:
	return false

@warning_ignore("unused_parameter")
func _on_mob_attacked(attacker: Node3D, damage: int) -> void:
	pass
