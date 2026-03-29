extends Node
class_name StatManager

@onready var player_state: PlayerState = $".."

func _ready():
	player_state.equip_inventory_data.inventory_updated.connect(_on_equipment_updated)
	player_state.accessories_changed.connect(_on_accessories_changed)
	_recalculate_all_bonuses()
	_recalculate_all_bonuses()
	if player_state.has_node("EffectManager"):
		var effect_manager = player_state.get_node("EffectManager")
		effect_manager.effects_changed.connect(_on_effects_changed)
		
func _on_effects_changed():
	_recalculate_all_bonuses()

func _on_equipment_updated(_inventory_data: InventoryData):
	_recalculate_all_bonuses()

func _recalculate_all_bonuses():
	var old_max_health = player_state.max_health
	@warning_ignore("unused_variable")
	var old_max_stamina = player_state.max_stamina
	
	player_state.max_health = player_state.base_max_health
	player_state.max_stamina = player_state.base_max_stamina  
	player_state.speed = player_state.base_speed
	player_state.defense = 0
	player_state.health_regen_rate = player_state.base_health_regen_rate
	player_state.stamina_regen_rate = player_state.base_stamina_regen_rate
	
	player_state.calculate_total_defense()
	
	var equipment_data = player_state.equip_inventory_data
	for slot_data in equipment_data.slot_datas:
		if slot_data and slot_data.item_data is ArmorItemData:
			_apply_armor_bonuses(slot_data.item_data as ArmorItemData)
	
	_apply_effect_bonuses()
	
	player_state.current_health = min(player_state.current_health, player_state.max_health)
	player_state.current_stamina = min(player_state.current_stamina, player_state.max_stamina)
	
	if old_max_health > player_state.max_health and player_state.current_health == old_max_health:
		player_state.current_health = player_state.max_health
	
	_update_ui()

func _apply_armor_bonuses(armor: ArmorItemData):
	player_state.max_health += armor.max_health_bonus
	player_state.max_stamina += armor.max_stamina_bonus
	if player_state.sanity_manager:
		player_state.sanity_manager.max_sanity += armor.max_sanity_bonus
	player_state.defense += armor.defense
	
	var gem_bonuses = armor.get_gem_bonuses()
	for stat_type in gem_bonuses:
		_apply_gem_bonus(stat_type, gem_bonuses[stat_type])

func _apply_gem_bonus(stat_type: int, value):
	match stat_type:
		GemData.StatType.HEALTH:
			player_state.max_health += value
		GemData.StatType.STAMINA:
			player_state.max_stamina += value
		GemData.StatType.SANITY:
			if player_state.sanity_manager:
				player_state.sanity_manager.max_sanity += value
		GemData.StatType.DEFENSE:
			player_state.defense += value
		GemData.StatType.SPEED:
			player_state.speed += value

func _apply_effect_bonuses():
	if not player_state.has_node("EffectManager"):
		return
	
	var effect_manager = player_state.get_node("EffectManager")
	var active_effects = effect_manager.get_active_effects()
	
	# Собираем бонусы ОТДЕЛЬНО
	var health_multiplier = 1.0
	var stamina_multiplier = 1.0
	var speed_multiplier = 1.0
	var defense_multiplier = 1.0
	var health_regen_multiplier = 1.0
	var stamina_regen_multiplier = 1.0
	
	var health_flat_bonus = 0.0
	var stamina_flat_bonus = 0.0
	var defense_flat_bonus = 0.0
	
	for effect_instance in active_effects:
		var res = effect_instance.effect_resource
		
		health_multiplier *= res.health_multiplier
		stamina_multiplier *= res.stamina_multiplier
		speed_multiplier *= res.speed_multiplier
		defense_multiplier *= res.defense_multiplier
		health_regen_multiplier *= res.health_regen_multiplier
		stamina_regen_multiplier *= res.stamina_regen_multiplier
		
		health_flat_bonus += res.health_flat
		stamina_flat_bonus += res.stamina_flat
		defense_flat_bonus += res.defense_flat
	
	
	player_state.max_health = player_state.base_max_health * health_multiplier + health_flat_bonus
	player_state.max_stamina = player_state.base_max_stamina * stamina_multiplier + stamina_flat_bonus
	player_state.speed = player_state.base_speed * speed_multiplier  # ✅ ЕДИНСТВЕННОЕ применение!
	player_state.defense = player_state.defense * defense_multiplier + defense_flat_bonus  # defense уже включает броню
	
	player_state.health_regen_rate = player_state.base_health_regen_rate * health_regen_multiplier
	player_state.stamina_regen_rate = player_state.base_stamina_regen_rate * stamina_regen_multiplier
	
	player_state._accessory_run_speed_multiplier = 1.0
	
func _update_ui():
	player_state.health_changed.emit(player_state.current_health)
	player_state.stamina_changed.emit(player_state.current_stamina)

func _on_accessories_changed():
	_recalculate_all_bonuses()

func _on_armor_equipped():
	if PlayerManager.player:
		PlayerManager.player.calculate_total_defense()

func _on_armor_unequipped():
	if PlayerManager.player:
		PlayerManager.player.calculate_total_defense()
