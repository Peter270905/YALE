extends Node
class_name EffectManager

signal effect_applied(effect: EffectInstance)
signal effect_removed(effect: EffectInstance)
signal effects_changed()

var active_effects: Array = []
var target: Node

func _ready():
	target = get_parent()
	if target is PlayerState:
		effect_applied.connect(_on_player_effect_applied)
		effect_removed.connect(_on_player_effect_removed)

func add_effect(effect_res: EffectResource):
	var effect_res_copy = effect_res.duplicate(true)
	
	var existing = get_effect_by_id(effect_res_copy.effect_id)
	if existing and !effect_res_copy.is_stackable:
		existing.refresh_duration()
		return existing
	
	var new_effect = EffectInstance.new(effect_res_copy)
	active_effects.append(new_effect)
	
	_apply_effect_modifiers(new_effect)
	effect_res_copy.on_apply(target)
	effect_applied.emit(new_effect)
	
	effects_changed.emit()
	return new_effect

func remove_effect(effect):
	_remove_effect_modifiers(effect)
	effect.effect_resource.on_remove(target)
	active_effects.erase(effect)
	effect_removed.emit(effect)
	effects_changed.emit()

func _process(delta: float):
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		effect.update(delta)
		
		if effect.should_remove():
			remove_effect(effect)
		elif effect.should_tick():
			effect.effect_resource.on_tick(target)
			effect.reset_tick_timer()

@warning_ignore("unused_parameter")
func _apply_effect_modifiers(effect):
	pass

@warning_ignore("unused_parameter")
func _remove_effect_modifiers(effect):
	pass

func get_effect_by_id(effect_id: String):
	for effect in active_effects:
		if effect.effect_resource.effect_id == effect_id:
			return effect
	return null

func get_active_effects() -> Array:
	return active_effects.duplicate()

func _on_player_effect_applied(effect):
	print("Effect applied to player: ", effect.effect_resource.display_name)

func _on_player_effect_removed(effect):
	print("Effect removed from player: ", effect.effect_resource.display_name)

func handle_event(event_type: String, event_data: Dictionary = {}):
	for effect in active_effects:
		for custom_effect in effect.effect_resource.custom_effects:
			custom_effect.handle_event(target, event_type, event_data)
