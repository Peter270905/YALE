extends Resource
class_name EffectResource

@export_category("Basic Settings")
@export var effect_id: String = "unknown_effect"
@export var display_name: String = "Эффект"
@export var description: String = ""
@export var is_positive: bool = true
@export var is_stackable: bool = false

@export_category("Duration")
@export var duration: float = 10.0
@export var tick_interval: float = 0.0

@export_category("Stat Modifiers")
@export_group("Multipliers")
@export var speed_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var defense_multiplier: float = 1.0
@export var health_multiplier: float = 1.0
@export var stamina_multiplier: float = 1.0
@export var health_regen_multiplier: float = 1.0
@export var stamina_regen_multiplier: float = 1.0

@export_category("Flat Modifiers")
@export var health_flat: float = 0.0
@export var stamina_flat: float = 0.0
@export var defense_flat: float = 0.0
@export var health_regen_per_tick: float = 0.0
@export var stamina_regen_per_tick: float = 0.0

@export_category("Custom Effects")
@export var custom_effects: Array[CustomEffect] = []

func on_apply(target: Node) -> void:
	for custom_effect in custom_effects:
		if custom_effect.apply_time == CustomEffect.ApplyTime.ON_APPLY:
			var custom_effect_copy = custom_effect.duplicate(true)
			custom_effect_copy.on_effect_start(target)
			custom_effect_copy.execute(target)
	
func on_tick(target: Node) -> void:
	if target is PlayerState:
		var player = target as PlayerState
		
		if health_regen_per_tick != 0:
			player.update_health(health_regen_per_tick)
		if stamina_regen_per_tick != 0:
			player.update_stamina(stamina_regen_per_tick)

func on_remove(target: Node) -> void:
	for custom_effect in custom_effects:
		if custom_effect.apply_time == CustomEffect.ApplyTime.ON_REMOVE:
			custom_effect.execute(target)
			custom_effect.on_effect_end(target)

func on_update(target: Node, delta: float) -> void:
	for custom_effect in custom_effects:
		if custom_effect.apply_time == CustomEffect.ApplyTime.ON_UPDATE:
			custom_effect.execute(target, {"delta": delta})
