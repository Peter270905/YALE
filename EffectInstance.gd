# EffectInstance.gd
class_name EffectInstance extends RefCounted

var effect_resource: EffectResource
var time_remaining: float
var time_since_last_tick: float = 0.0
var is_expired: bool = false

func _init(resource: EffectResource):
	effect_resource = resource
	time_remaining = resource.duration

func update(delta: float) -> void:
	if time_remaining > 0:
		time_remaining -= delta
		time_since_last_tick += delta
		
		if time_remaining <= 0:
			is_expired = true

func should_remove() -> bool:
	return is_expired or (time_remaining <= 0 and effect_resource.duration > 0)

func should_tick() -> bool:
	return effect_resource.tick_interval > 0 and time_since_last_tick >= effect_resource.tick_interval

func reset_tick_timer() -> void:
	time_since_last_tick = 0.0

func refresh_duration() -> void:
	time_remaining = effect_resource.duration
