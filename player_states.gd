extends Node3D
class_name PlayerState

# ===== БАЗОВЫЕ ХАРАКТЕРИСТИКИ =====
@export var base_max_health: int = 20
@export var base_max_stamina: int = 50
@export var base_max_sanity: int = 75
@export var base_speed: float = 5.0
@export var base_health_regen_rate: float = 1.0
@export var base_stamina_regen_rate: float = 5.0

# ===== СИСТЕМА ЗДОРОВЬЯ =====
@export var max_health: int
var current_health: int
var health_regen_timer: float = 0.0
var health_regen_interval: float = 2.0
var health_regen_rate: float = 1.0
var hunger_per_health: float = 0.40
@export var health_regen_delay: float = 15.0
var last_damage_time: float = -999.0
var can_regenerate_health: bool = true

# ===== СИСТЕМА ВЫНОСЛИВОСТИ =====
@export var max_stamina: int
var current_stamina: int
var stamina_regen_timer: float = 0.0
var stamina_regen_interval: float = 0.8
var stamina_regen_rate: float = 5.0

# ===== СИСТЕМА РАССУДКА =====
@export var sanity_manager: SanityManager

# ===== СИСТЕМА ГОЛОДА =====
@export var max_hunger: int = 20
var current_hunger: float
var hunger_damage_rate: float = 0.5
var hunger_timer: float = 0.0
var hunger_per_stamina: float = 0.02

# ===== ДЕБАФФ РАССУДКА =====
var is_sanity_debuffed: bool = false
var debuff_multiplier: float = 1.0

# ===== СИСТЕМА ЭФФЕКТОВ =====
@onready var effect_manager: EffectManager = $EffectManager

# ===== ПЕРЕДВИЖЕНИЕ =====
@export var speed: float
@export var jump_velocity: float = 8.0
var can_run: bool = true
var accessory_speed_multiplier: float = 1.0
var _base_run_speed_multiplier: float = 1.5
var _accessory_run_speed_multiplier: float = 1.0

var run_speed_multiplier: float:
	get: return _base_run_speed_multiplier * _accessory_run_speed_multiplier

var run_speed: float:
	get: return speed * run_speed_multiplier

# ===== СИСТЕМА УРОНА ОТ ПАДЕНИЯ =====
var fall_damage_threshold: float = 10.0
var fall_damage_multiplier: float = 2.0
var max_fall_distance: float = 0.0
var fall_damage_immunity: bool = false

# ===== ЗАЩИТА =====
@export var defense: int = 0
var total_defense: int = 0

# ===== ИНВЕНТАРЬ =====
@export var inventory_data: InventoryData
@export var item_consumable: ItemConsumable
@export var equip_inventory_data: EquipmentInventoryData
@export var accessories_inventory_data: AccessoryInventoryData

# ===== УПРАВЛЕНИЕ =====
@export var mouse_sensitivity_horizontal: float = 0.1
@export var mouse_sensitivity_vertical: float = 0.1
@export var fall_acceleration: float = 25.0
@export var target_velocity: Vector3 = Vector3.ZERO

# ===== ССЫЛКИ НА ДРУГИЕ КОМПОНЕНТЫ =====
@onready var player: CharacterBody3D = $".."

# ===== СИСТЕМА КАМЕРЫ =====
var is_first_person: bool = false
var first_person_camera_offset: Vector3 = Vector3(0, 0.3, 0.2)
var third_person_camera_offset: Vector3 = Vector3(0, 0, 0)

# ===== СИГНАЛЫ =====
signal camera_mode_changed(is_first_person: bool)
signal health_changed(new_value: float)
signal stamina_changed(new_value: float)
@warning_ignore("unused_signal")
signal sanity_changed(new_value: float)
signal hunger_changed(new_value: float)
signal died()
@warning_ignore("unused_signal")
signal toggle_inventory()
@warning_ignore("unused_signal")
signal accessories_changed()
# ---------------------------------------------------------------------------------------------------
# ИНИЦИАЛИЗАЦИЯ
# ---------------------------------------------------------------------------------------------------

func _ready() -> void:
	"""Инициализация всех характеристик при создании объекта"""
	max_health = base_max_health
	max_stamina = base_max_stamina
	speed = base_speed
	
	current_health = max_health
	current_stamina = max_stamina
	current_hunger = max_hunger
	
	health_regen_rate = base_health_regen_rate
	stamina_regen_rate = base_stamina_regen_rate
	
	can_run = current_stamina > 0
	
	PlayerManager.player = self
	
	health_changed.emit(current_health)
	stamina_changed.emit(current_stamina)
	hunger_changed.emit(current_hunger)
	
	if sanity_manager:
		sanity_manager.sanity_changed.connect(_on_sanity_changed)
		sanity_manager.sanity_critical.connect(_on_sanity_critical)
	
	if not has_node("EffectManager"):
		var new_effect_manager = EffectManager.new()
		add_child(new_effect_manager)
		effect_manager = new_effect_manager

# ---------------------------------------------------------------------------------------------------
# СВОЙСТВА СКОРОСТИ (всегда актуальные!)
# ---------------------------------------------------------------------------------------------------

var walk_speed: float:
	get:
		return speed

func get_movement_speed(is_running: bool = false, apply_debuff: bool = true) -> float:
	var base = speed * accessory_speed_multiplier
	if is_running and can_run:
		base *= run_speed_multiplier
	if apply_debuff:
		base *= debuff_multiplier
	return base

func get_final_speed() -> float:
	return get_movement_speed(false)

# ---------------------------------------------------------------------------------------------------
# ЗАЩИТА И УРОН
# ---------------------------------------------------------------------------------------------------

func calculate_total_defense() -> int:
	var defense_sum = 0
	
	if equip_inventory_data:
		for slot_data in equip_inventory_data.slot_datas:
			if slot_data and slot_data.item_data is ArmorItemData:
				var armor = slot_data.item_data as ArmorItemData
				defense_sum += armor.defense
	
	if accessories_inventory_data:
		for slot_data in accessories_inventory_data.slot_datas:
			if slot_data and slot_data.item_data is ArmorItemData:
				var armor = slot_data.item_data as ArmorItemData
				defense_sum += armor.defense
	
	total_defense = defense_sum
	return total_defense

func check_fall_damage(player_controller: PlayerController):
	if not player_controller.is_on_floor():
		var current_height = player_controller.global_position.y
		if current_height > max_fall_distance:
			max_fall_distance = current_height
	else:
		if max_fall_distance > 0:
			var fall_distance = max_fall_distance - player_controller.global_position.y
			if fall_distance > fall_damage_threshold and not fall_damage_immunity:
				var damage = (fall_distance - fall_damage_threshold) * fall_damage_multiplier
				take_fall_damage(damage)
			max_fall_distance = 0.0

func take_fall_damage(damage: float):
	update_health(-damage)

func take_damage(amount: int):
	"""Нанесение урона с учетом защиты от эффектов"""
	
	var defense_multiplier = 1.0
	var defense_flat_bonus = 0.0
	if effect_manager:
		for effect in effect_manager.get_active_effects():
			defense_multiplier *= effect.effect_resource.defense_multiplier
			defense_flat_bonus += effect.effect_resource.defense_flat

	var total_defense_with_bonuses = (total_defense + defense_flat_bonus) * defense_multiplier
	var damage_reduction = min(total_defense_with_bonuses * 0.05, 0.8)
	var final_damage = max(1, amount * (1.0 - damage_reduction))
	
	current_health -= final_damage
	last_damage_time = Time.get_unix_time_from_system()
	can_regenerate_health = false
	health_changed.emit(current_health)
	
	_start_regen_cooldown()
	
	if current_health <= 0:
		died.emit()

func _start_regen_cooldown():
	await get_tree().create_timer(health_regen_delay).timeout
	can_regenerate_health = true

# ---------------------------------------------------------------------------------------------------
# ОБНОВЛЕНИЕ ХАРАКТЕРИСТИК
# ---------------------------------------------------------------------------------------------------

func update_health(value: float):
	"""Обновление здоровья с ограничением и проверкой смерти"""
	current_health = clamp(current_health + value, 0.0, float(max_health))
	health_changed.emit(current_health)
	
	if current_health <= 0:
		died.emit()

func update_stamina(value: float):
	"""Обновление стамины с ограничением и учетом затрат голода"""
	var old_stamina = current_stamina
	current_stamina = clamp(current_stamina + value, 0.0, float(max_stamina))
	stamina_changed.emit(current_stamina)
	
	can_run = current_stamina > 1 and current_hunger > 6
	
	if value > 0 and current_stamina > old_stamina:
		var stamina_restored = current_stamina - old_stamina
		var hunger_cost = stamina_restored * hunger_per_stamina
		
		if current_hunger >= hunger_cost:
			update_hunger(-hunger_cost)

func update_hunger(value: float):
	"""Обновление уровня голода с ограничением"""
	var old_hunger = current_hunger
	current_hunger = clamp(current_hunger + value, 0.0, float(max_hunger))
	
	if current_hunger != old_hunger:
		hunger_changed.emit(current_hunger)

# ---------------------------------------------------------------------------------------------------
# ИГРОВОЙ ЦИКЛ
# ---------------------------------------------------------------------------------------------------
 
func _process(delta):
	"""Основной игровой цикл - обновление систем регенерации"""
	stamina_regeneration(delta)
	health_regeneration(delta)

# ---------------------------------------------------------------------------------------------------
# СИСТЕМА РАССУДКА И ДЕБАФФОВ
# ---------------------------------------------------------------------------------------------------

func apply_sanity_debuff(multiplier: float):
	"""Применить дебафф рассудка (влияет на max_health, max_stamina, speed)"""
	debuff_multiplier = multiplier
	max_health = int(base_max_health * multiplier)
	max_stamina = int(base_max_stamina * multiplier)
	current_health = min(current_health, max_health)
	current_stamina = min(current_stamina, max_stamina)
	health_changed.emit(current_health)
	stamina_changed.emit(current_stamina)

func remove_sanity_debuff():
	"""Убрать дебафф рассудка"""
	debuff_multiplier = 1.0
	max_health = base_max_health
	max_stamina = base_max_stamina
	health_changed.emit(current_health)
	stamina_changed.emit(current_stamina)

func _on_sanity_changed(new_sanity: float):
	"""Обработчик изменения рассудка - применяем дебаффы"""
	var sanity_percentage = new_sanity / sanity_manager.max_sanity
	
	if sanity_percentage <= 0.3:
		apply_sanity_debuff(0.5)
		is_sanity_debuffed = true
	elif sanity_percentage <= 0.6:
		apply_sanity_debuff(0.8)
		is_sanity_debuffed = true
	else:
		remove_sanity_debuff()
		is_sanity_debuffed = false

func _on_sanity_critical():
	pass

func enter_sanity_drain_area(drain_rate: float):
	if sanity_manager:
		sanity_manager.set_regeneration(false)
		sanity_manager.passive_drain_rate = drain_rate

func exit_sanity_drain_area():
	if sanity_manager:
		sanity_manager.set_regeneration(true)
		# Исправлено: не было опечатки в оригинале, но на всякий — явно:
		sanity_manager.passive_drain_rate = sanity_manager.base_passive_drain_rate  # ← если есть такое поле

# ---------------------------------------------------------------------------------------------------
# РЕГЕНЕРАЦИЯ
# ---------------------------------------------------------------------------------------------------

func stamina_regeneration(delta):
	if current_hunger <= 0:
		hunger_timer += delta
		if hunger_timer >= 1.0:
			update_health(-hunger_damage_rate)
			hunger_timer = 0.0
	
	stamina_regen_timer += delta
	if stamina_regen_timer >= stamina_regen_interval:
		if not Input.is_action_pressed("run") and current_hunger > 0:
			update_stamina(stamina_regen_rate)
		stamina_regen_timer = 0.0

func health_regeneration(delta):
	health_regen_timer += delta
	if not can_regenerate_health:
		return
	
	if health_regen_timer >= health_regen_interval and current_health < max_health:
		if current_hunger > hunger_per_health and current_hunger > max_hunger * 0.3:
			update_health(health_regen_rate)
			update_hunger(-hunger_per_health)
		health_regen_timer = 0.0

# ---------------------------------------------------------------------------------------------------
# КАМЕРА
# ---------------------------------------------------------------------------------------------------

func set_first_person_mode(enabled: bool):
	if is_first_person != enabled:
		is_first_person = enabled
		camera_mode_changed.emit(is_first_person)
