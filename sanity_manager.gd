extends Node
class_name SanityManager

# ===== СИГНАЛЫ =====
signal sanity_changed(new_value: float)
signal sanity_critical()
signal sanity_effect_started(effect_type: String)
signal sanity_effect_ended(effect_type: String)

@export_category("Sanity Settings")
@export var max_sanity: float = 75.0
@export var critical_threshold: float = 15.0
@export var passive_drain_rate: float = 0.1
@export var sanity_regen_rate: float = 0.2
@onready var state: PlayerState = $".."

var current_sanity: float
var is_regenerating: bool = false
var active_effects: Array[String] = []

var sanity_effects = {}

func _ready():
	current_sanity = max_sanity
	sanity_changed.emit(current_sanity)
	add_to_group("sanity_manager")

func _process(delta):
	_handle_passive_drain(delta)
	_handle_sanity_regeneration(delta)
	_check_sanity_effects()
	_update_sanity_effects()

# ===== ОСНОВНЫЕ ФУНКЦИИ =====
func change_sanity(amount: float):
	"""Изменение уровня рассудка"""
	var old_sanity = current_sanity
	current_sanity = clamp(current_sanity + amount, 0.0, max_sanity)
	
	if current_sanity != old_sanity:
		sanity_changed.emit(current_sanity)
		
		if current_sanity <= critical_threshold and old_sanity > critical_threshold:
			sanity_critical.emit()

func set_regeneration(enabled: bool):
	"""Включение/выключение регенерации"""
	is_regenerating = enabled

func get_sanity_percentage() -> float:
	"""Получение рассудка в процентах"""
	return current_sanity / max_sanity

func is_sanity_critical() -> bool:
	"""Проверка критического уровня рассудка"""
	return current_sanity <= critical_threshold

func add_sanity_effect(effect_type: String, duration: float = 0.0):
	"""Добавление временного эффекта"""
	if not active_effects.has(effect_type):
		active_effects.append(effect_type)
		sanity_effect_started.emit(effect_type)
		if duration > 0:
			await get_tree().create_timer(duration).timeout
			remove_sanity_effect(effect_type)

func remove_sanity_effect(effect_type: String):
	"""Удаление эффекта"""
	if active_effects.has(effect_type):
		active_effects.erase(effect_type)
		sanity_effect_ended.emit(effect_type)

func has_effect(effect_type: String) -> bool:
	"""Проверка наличия эффекта"""
	return active_effects.has(effect_type)

# ===== ВНУТРЕННЯЯ ЛОГИКА =====
func _handle_passive_drain(delta):
	"""Пассивное снижение рассудка со временем"""
	if not is_regenerating and current_sanity > 0:
		change_sanity(-passive_drain_rate * delta)

func _handle_sanity_regeneration(delta):
	"""Регенерация рассудка в безопасных условиях"""
	if is_regenerating and current_sanity < max_sanity:
		change_sanity(sanity_regen_rate * delta)

func _check_sanity_effects():
	"""Проверка и активация эффектов на основе уровня рассудка"""
	for effect_name in sanity_effects:
		var effect = sanity_effects[effect_name]
		var should_be_active = current_sanity <= effect.threshold
		
		if should_be_active and not effect.active:
			effect.active = true
			for sub_effect in effect.effects:
				add_sanity_effect(sub_effect)
		elif not should_be_active and effect.active:
			effect.active = false
			for sub_effect in effect.effects:
				remove_sanity_effect(sub_effect)

func _update_sanity_effects():
	"""Обновление интенсивности эффектов на основе уровня рассудка"""
	#надо будет мне сделать потом эффекты из-за рассудка
	pass
