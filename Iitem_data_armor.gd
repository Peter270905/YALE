extends ItemData
class_name ArmorItemData

enum ArmorType {HELMET, CHESTPLATE, LEGGINGS, BOOTS}

@export var armor_type: ArmorType
@export var defense: int = 0

@export var gem_slots: int = 1
var inserted_gems: Array[GemData] = []

#------Максимальный бонус------
@export var max_health_bonus: int = 0
@export var max_stamina_bonus: int = 0
@export var max_sanity_bonus: int = 0
@export var max_mana_bonus: int = 0
@export var max_luck_bonus: int = 0
@export var max_defense_bonus: int = 0
@export var max_critical_damage_bonus: int = 0
@export var max_efficiency_bonus: int = 0
@export var max_attack_speed_bonus: int = 0
@export var max_all_stats_bonus: int = 0
@export var max_speed_bonus: int = 0
@export var max_sword_damage_bonus: int = 0
@export var max_arrow_damage_bonus: int = 0
@export var max_spell_damage_bonus: int = 0
@export var max_spell_cooldown_bonus: int = 0

#------Регенерация------
@export var max_health_regen_bonus: int = 0
@export var max_stamina_regen_bonus: int = 0
@export var max_sanity_regen_bonus: int = 0
@export var max_mana_regen_bonus: int = 0


func can_insert_gem() -> bool:
	return inserted_gems.size() < gem_slots

func insert_gem(gem_data: GemData) -> bool:
	if can_insert_gem():
		inserted_gems.append(gem_data)
		return true
	return false


func remove_gem(index: int) -> GemData:
	if index < inserted_gems.size():
		return inserted_gems.pop_at(index)
	return null

func get_gem_bonuses() -> Dictionary:
	var bonuses = {}
	
	for gem in inserted_gems:
		for stat_type in gem.stat_boosts:
			var value = gem.stat_boosts[stat_type]
			
			if not bonuses.has(stat_type):
				bonuses[stat_type] = 0
			
			if value is String and value.ends_with("%"):
				bonuses[stat_type] += value.trim_suffix("%").to_float()
			else:
				bonuses[stat_type] += value
	
	return bonuses

var applied_enchantment: EnchantmentData = null

func can_apply_enchantment(enchantment: EnchantmentData) -> bool:
	return applied_enchantment == null and enchantment.can_apply_to(armor_type)

func apply_enchantment(enchantment: EnchantmentData) -> bool:
	if can_apply_enchantment(enchantment):
		applied_enchantment = enchantment
		return true
	return false

func remove_enchantment() -> EnchantmentData:
	var old_enchant = applied_enchantment
	applied_enchantment = null
	return old_enchant

func get_all_bonuses() -> Dictionary:
	var bonuses = get_gem_bonuses()
	
	if applied_enchantment:
		pass
	
	return bonuses
