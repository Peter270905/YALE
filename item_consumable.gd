extends ItemData
class_name ItemConsumable

@export_category("Basic Restoration")
@export var hunger_restore: float
@export var health_restore: float
@export var stamina_restore: float
@export var use_cooldown: float

@export_category("Advanced Effects")
@export var effect_resources: Array[EffectResource] = []
@export var item_category: String = "food" 

func _get_description() -> String:
	var desc = "\n" + item_type + "\n"
	
	if hunger_restore != 0:
		desc += "Восстановление голода: " + ("+" if hunger_restore > 0 else "") + str(hunger_restore) + "\n"
	if health_restore != 0:
		desc += "Здоровье: " + ("+" if health_restore > 0 else "") + str(health_restore) + "\n"
	if stamina_restore != 0:
		desc += "Выносливость: " + ("+" if stamina_restore > 0 else "") + str(stamina_restore) + "\n"
	
	if effect_resources.size() > 0:
		desc += "\nЭффекты:\n"
		for effect in effect_resources:
			desc += "• " + effect.display_name + "\n"
	
	return desc

func use(target) -> void:
	if not target:
		return
	
	var state = null
	if target is PlayerState:
		state = target
	elif target.has_method("get_state"):
		state = target.get_state()
	
	if state:
		if hunger_restore != 0:
			state.update_hunger(hunger_restore)
		if stamina_restore != 0:
			state.update_stamina(stamina_restore)
		if health_restore != 0:
			state.update_health(health_restore)
	
	apply_advanced_effects(target)

func apply_advanced_effects(target: Node) -> void:
	var effect_manager = _find_effect_manager(target)
	if not effect_manager:
		effect_manager = _create_basic_effect_manager(target)
	
	for effect_res in effect_resources:
		if effect_res:
			effect_manager.add_effect(effect_res.duplicate())

func _find_effect_manager(target: Node) -> Node:
	if target.has_node("EffectManager"):
		return target.get_node("EffectManager")
	elif target.has_method("get_effect_manager"):
		return target.get_effect_manager()
	else:
		for child in target.get_children():
			if child is EffectManager:
				return child
	return null

func _create_basic_effect_manager(target: Node) -> Node:
	var effect_manager = EffectManager.new()
	target.add_child(effect_manager)
	print("Создан базовый EffectManager для ", target.name)
	return effect_manager
