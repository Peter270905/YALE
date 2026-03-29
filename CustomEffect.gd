# CustomEffect.gd
extends Resource
class_name CustomEffect

@export var effect_name: String = "Custom Effect"
@export var description: String = ""

# 👇 РАЗНЫЕ ТОЧКИ ПРИМЕНЕНИЯ
enum ApplyTime { 
	ON_APPLY,      # При применении эффекта
	ON_TICK,       # Каждый тик
	ON_REMOVE,     # При удалении эффекта  
	ON_UPDATE,     # Каждый кадр
	ON_EVENT       # При специфичных событиях
}

@export var apply_time: ApplyTime = ApplyTime.ON_APPLY
@export var tick_interval: float = 0.0  # Для ON_TICK

# 👇 ВЫЗЫВАЕТСЯ В СООТВЕТСТВУЮЩЕЕ ВРЕМЯ
@warning_ignore("unused_parameter")
func execute(target: Node, data: Dictionary = {}) -> void:
	pass

# 👇 ДЛЯ СЛОЖНЫХ ЭФФЕКТОВ С СОСТОЯНИЕМ
@warning_ignore("unused_parameter")
func on_effect_start(target: Node) -> void:
	pass

@warning_ignore("unused_parameter")
func on_effect_end(target: Node) -> void:
	pass

# 👇 ДЛЯ ОБРАБОТКИ СОБЫТИЙ (урон, смерть, и т.д.)
@warning_ignore("unused_parameter")
func handle_event(target: Node, event_type: String, event_data: Dictionary = {}) -> void:
	pass
