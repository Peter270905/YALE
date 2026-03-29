extends Node
class_name AbilityManager

@onready var player_state: PlayerState = $".."
var equipped_accessories: Array[AccessoriesItemData] = []

func _ready():
	player_state.accessories_inventory_data.inventory_updated.connect(_on_accessories_updated)
	_update_abilities()

func _process(delta: float):
	for accessory in equipped_accessories:
		if accessory.ability:
			accessory.ability.on_process(player_state, delta)


func has_double_jump() -> bool:
	var inventory_data = player_state.accessories_inventory_data
	
	for i in range(inventory_data.slot_datas.size()):
		var slot_data = inventory_data.slot_datas[i]
		if slot_data and slot_data.item_data is AccessoriesItemData:
			var accessory = slot_data.item_data as AccessoriesItemData
				
			if accessory.ability and (accessory.ability is DoubleJumpAbility or accessory.ability is TravelBootsAbility):
				return true
	return false

func get_double_jump_ability() -> AccessoryAbility:
	var inventory_data = player_state.accessories_inventory_data
	for slot_data in inventory_data.slot_datas:
		if slot_data and slot_data.item_data is AccessoriesItemData:
			var accessory = slot_data.item_data as AccessoriesItemData
			if accessory.ability and accessory.ability.has_method("can_extra_jump") and accessory.ability.has_method("perform_extra_jump"):
				return accessory.ability
	return null

func can_double_jump(is_on_floor: bool) -> bool:
	var ability = get_double_jump_ability()
	if ability:
		return ability.can_extra_jump(is_on_floor)
	return false

func perform_double_jump() -> bool:
	var ability = get_double_jump_ability()
	if ability:
		return ability.perform_extra_jump()
	return false

func _on_accessories_updated(_inventory_data: InventoryData):
	_update_abilities()

func _update_abilities():
	var old_accessories = equipped_accessories.duplicate()
	equipped_accessories.clear()
	
	var inventory_data = player_state.accessories_inventory_data
	
	# Загружаем новые аксессуары
	for slot_data in inventory_data.slot_datas:
		if slot_data and slot_data.item_data is AccessoriesItemData:
			var accessory = slot_data.item_data as AccessoriesItemData
			equipped_accessories.append(accessory)
	
	# Вызываем on_unequip для удалённых аксессуаров
	for old_accessory in old_accessories:
		var still_equipped = false
		for new_accessory in equipped_accessories:
			if new_accessory == old_accessory:
				still_equipped = true
				break
		
		if not still_equipped:
			if old_accessory.ability and old_accessory.ability.has_method("on_unequip"):
				old_accessory.ability.on_unequip(player_state)
	
	# Вызываем on_equip для новых аксессуаров
	for new_accessory in equipped_accessories:
		var was_equipped = false
		for old_accessory in old_accessories:
			if new_accessory == old_accessory:
				was_equipped = true
				break
		
		if not was_equipped:
			if new_accessory.ability and new_accessory.ability.has_method("on_equip"):
				new_accessory.ability.on_equip(player_state)
