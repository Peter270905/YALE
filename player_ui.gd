extends CanvasLayer

#------------------------------------------------------
#                UI элементов игрока
#------------------------------------------------------

#------Ссылки на ноды------
@onready var sanity_manager: SanityManager = $"../state/SanityManager"
@onready var veins_overlay: TextureRect = $"../camera/Camera3D/VeinsOverlay"
@onready var desaturation_effect: ColorRect = $"../camera/Camera3D/DesaturationEffect"

#------Ссылки на бары------
@onready var stamina_bar: TextureProgressBar = $Stamina/Stamina/STAMINA_BAR
@onready var hp_bar: TextureProgressBar = $MarginContainer/HBoxContainer/HP_BAR
@onready var sanity_bar: TextureProgressBar = $MarginContainer/HBoxContainer/SANITY_BAR
@onready var hunger_bar: TextureProgressBar = $MarginContainer/HBoxContainer/HUNGER_BAR

#------Лейблы------
@onready var stamina_label: Label = $Stamina/Stamina/STAMINA_BAR/STAMINA_LABEL
@onready var hp_label: Label = $MarginContainer/HBoxContainer/HP_BAR/HP_LABEL
@onready var sanity_label: Label = $MarginContainer/HBoxContainer/SANITY_BAR/SANITY_LABEL
@onready var hunger_label: Label = $MarginContainer/HBoxContainer/HUNGER_BAR/HUNGER_LABEL

#------Ссылка на состояние игрока------
@onready var state: PlayerState = $"../state"

#------Настройки анимации------
@export var fade_out_speed: float = 3.0
@export var fade_in_speed: float = 5.0

#------Цвета для рассудка------
@export var sanity_critical_color: Color = Color.RED
@export var sanity_low_color: Color = Color.YELLOW
@export var sanity_normal_color: Color = Color.WHITE
var veins_tween: Tween

#------Таймеры для скрытия------
var stamina_hide_timer: float = 0.0
var stamina_hide_delay: float = 2.0
var is_stamina_visible: bool = true

#------------------------------------------------------
#                   Инициализация
#------------------------------------------------------
func _ready() -> void:
	await get_tree().process_frame
	veins_overlay.modulate.a = 0.0
	_update_max_values()
	_setup_initial_values()
	_connect_signals()
	_setup_sanity_ui()
	desaturation_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desaturation_effect.process_mode = Node.PROCESS_MODE_DISABLED

func _setup_initial_values():
	"""Установка начальных значений"""
	update_health(state.current_health)
	update_stamina(state.current_stamina)
	@warning_ignore("narrowing_conversion")
	update_hunger(state.current_hunger)
	
	if state.sanity_manager:
		update_sanity(state.sanity_manager.current_sanity)
	else:
		update_sanity(state.current_sanity)

func _connect_signals():
	"""Подключение сигналов"""
	if state.has_signal("health_changed"):
		state.health_changed.connect(update_health)
	if state.has_signal("stamina_changed"):
		state.stamina_changed.connect(update_stamina)
	if state.has_signal("hunger_changed"):
		state.hunger_changed.connect(update_hunger)
	
	if state.sanity_manager:
		state.sanity_manager.sanity_changed.connect(update_sanity)
		state.sanity_manager.sanity_critical.connect(_on_sanity_critical)
		state.sanity_manager.sanity_effect_started.connect(_on_sanity_effect_started)
		state.sanity_manager.sanity_effect_ended.connect(_on_sanity_effect_ended)
	elif state.has_signal("sanity_changed"):
		state.sanity_changed.connect(update_sanity)

func _update_max_values():
	"""Обновление максимальных значений"""
	hp_bar.max_value = state.max_health
	stamina_bar.max_value = state.max_stamina
	hunger_bar.max_value = state.max_hunger
	
	if state.sanity_manager:
		sanity_bar.max_value = state.sanity_manager.max_sanity
	else:
		sanity_bar.max_value = state.max_sanity

func _setup_sanity_ui():
	"""Настройка специального UI для рассудка"""
	if sanity_bar.has_method("setup_brain_effects"):
		sanity_bar.setup_brain_effects()

#------------------------------------------------------
#                  Функции обновления UI
#------------------------------------------------------
func update_health(value: int) -> void:
	"""Обновление здоровья"""
	hp_bar.max_value = state.max_health
	hp_bar.value = value
	hp_label.text = str(value) + " / " + str(state.max_health)
	
	_play_health_animation(value)


func update_sanity(value: float) -> void:
	"""Обновление рассудка с визуальными эффектами"""
	@warning_ignore("incompatible_ternary")
	var max_sanity_value = state.sanity_manager.max_sanity if state.sanity_manager else state.max_sanity
	var int_value = int(value)
	
	sanity_bar.max_value = max_sanity_value
	sanity_bar.value = value
	sanity_label.text = str(int_value) + " / " + str(int(max_sanity_value))
	
	_update_sanity_visuals(value, max_sanity_value)

func update_hunger(value: int) -> void:
	"""Обновление голода"""
	hunger_bar.value = value
	hunger_label.text = str(value) + " / " + str(state.max_hunger)
	
	_play_hunger_animation(value)

#------------------------------------------------------
#             Умное управление видимостью стамины
#------------------------------------------------------
func update_stamina(value: int) -> void:
	"""Обновление стамины с умным скрытием"""
	stamina_bar.max_value = state.max_stamina
	stamina_bar.value = value
	stamina_label.text = str(value) + " / " + str(state.max_stamina)
	
	var is_full = value >= state.max_stamina
	
	if is_full and is_stamina_visible:
		stamina_hide_timer = stamina_hide_delay
	elif not is_full:
		_show_stamina_ui()
		is_stamina_visible = true
		stamina_hide_timer = 0.0

func _process(delta):
	"""Обработка таймеров для UI"""
	if stamina_hide_timer > 0:
		stamina_hide_timer -= delta
		if state.current_stamina >= state.max_stamina:
			_hide_stamina_ui()
			is_stamina_visible = false
	sanity_effects()

func _show_stamina_ui():
	"""Показать UI стамины"""
	var tween = create_tween()
	tween.parallel().tween_property(stamina_bar, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(stamina_label, "modulate:a", 1.0, 0.3)

func _hide_stamina_ui():
	"""Скрыть UI стамины"""
	var tween = create_tween()
	tween.parallel().tween_property(stamina_bar, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(stamina_label, "modulate:a", 0.0, 0.5)

#------------------------------------------------------
#             Визуальные эффекты для рассудка
#------------------------------------------------------
func sanity_effects():
	if desaturation_effect and desaturation_effect.material is ShaderMaterial:
		# Получаем текущую силу безумия из состояния игрока
		var current_sanity = state.sanity_manager.current_sanity if state.sanity_manager else state.current_sanity
		var max_sanity = state.sanity_manager.max_sanity if state.sanity_manager else state.max_sanity
		var strength = 1.0 - (current_sanity / max_sanity)
		
		desaturation_effect.material.set_shader_parameter("desaturation_amount", strength)
		desaturation_effect.material.set_shader_parameter("time", Time.get_unix_time_from_system())
	
func _update_sanity_visuals(current_sanity: float, max_sanity: float):
	"""Обновление визуальных эффектов рассудка"""
	var sanity_percentage = current_sanity / max_sanity
	# Анимация вен
	var veins_alpha = (1.0 - sanity_percentage) * 0.5 #0.5
	_update_veins_alpha(veins_alpha)
	if sanity_percentage <= 0.3: #0.3
		sanity_bar.tint_progress = sanity_critical_color
		sanity_label.modulate = sanity_critical_color
		_play_critical_sanity_effects()
	elif sanity_percentage <= 0.6: #0.6
		sanity_bar.tint_progress = sanity_low_color
		sanity_label.modulate = sanity_low_color
	else:
		sanity_bar.tint_progress = sanity_normal_color
		sanity_label.modulate = sanity_normal_color
	var material: ShaderMaterial = desaturation_effect.material
	var desaturation_strength = (1.0 - sanity_percentage) * 0.8 #0.8
	material.set_shader_parameter("desaturation_amount", desaturation_strength)

func _play_critical_sanity_effects():
	"""Эффекты при критическом уровне рассудка"""
	var tween = create_tween()
	tween.tween_property(sanity_bar, "modulate", Color(1, 0.5, 0.5, 1), 0.5)
	tween.tween_property(sanity_bar, "modulate", Color.WHITE, 0.5)
	tween.set_loops()

func _update_veins_alpha(alpha: float):
	"""Плавное обновление прозрачности вен"""
	if veins_tween:
		veins_tween.kill()
	veins_tween = create_tween()
	veins_tween.tween_property(veins_overlay, "modulate:a", alpha, 0.8)
#------------------------------------------------------
#             Обработчики сигналов рассудка
#------------------------------------------------------
func _on_sanity_critical():
	"""Критический уровень рассудка"""

func _on_sanity_effect_started(effect_type: String):
	"""Начало эффекта рассудка"""
	match effect_type:
		"visual_distortion":
			_show_distortion_effect()
		"whispers":
			_show_whispers_indicator()
		"hallucinations":
			_show_hallucination_warning()

func _on_sanity_effect_ended(effect_type: String):
	"""Конец эффекта рассудка"""
	match effect_type:
		"visual_distortion":
			_hide_distortion_effect()
		"whispers":
			_hide_whispers_indicator()
		"hallucinations":
			_hide_hallucination_warning()

#------------------------------------------------------
#             Дополнительные эффекты
#------------------------------------------------------
var health_tween: Tween
func _play_health_animation(value: int):
	if value > state.max_health * 0.3:
		if health_tween and health_tween.is_valid():
			health_tween.kill()
			health_tween = null
		hp_bar.modulate = Color.WHITE
		return
	
	if health_tween and health_tween.is_valid():
		health_tween.kill()
	
	health_tween = create_tween()
	health_tween.tween_property(hp_bar, "modulate", Color.RED, 0.3)
	health_tween.tween_property(hp_bar, "modulate", Color.WHITE, 0.3)
	health_tween.set_loops(3)


var hunger_tween: Tween
func _play_hunger_animation(value: int):	
	if value > state.max_hunger * 0.2:
		if hunger_tween and hunger_tween.is_valid():
			hunger_tween.kill()
			hunger_tween = null
		hunger_bar.modulate = Color.WHITE
		return
	
	if hunger_tween and hunger_tween.is_valid():
		hunger_tween.kill()
	
	hunger_tween = create_tween()
	hunger_tween.tween_property(hunger_bar, "modulate", Color.ORANGE_RED, 0.5)
	hunger_tween.tween_property(hunger_bar, "modulate", Color.WHITE, 0.5)
	hunger_tween.set_loops()

#------------------------------------------------------
#             Вспомогательные функции для эффектов
#------------------------------------------------------
func _show_distortion_effect():
	"""Показать эффект искажения"""
	# Можно добавить шейдер или overlay
	pass

func _show_whispers_indicator():
	"""Показать индикатор шепотов"""
	# Иконка уха или звуковых волн
	pass

func _show_hallucination_warning():
	"""Предупреждение о галлюцинациях"""
	# Специальный индикатор
	pass

func _hide_distortion_effect():
	pass

func _hide_whispers_indicator():
	pass

func _hide_hallucination_warning():
	pass
