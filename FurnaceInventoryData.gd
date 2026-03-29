# FurnaceInventoryData.gd
extends InventoryData

class_name FurnaceInventoryData

func _init():
	slot_datas.resize(3)
	for i in range(3):
		slot_datas[i] = null

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Index 0 = результат (только забирать)
	if index == 0:
		return grabbed_slot_data
	
	if not _can_place_in_slot(grabbed_slot_data, index):
		return grabbed_slot_data
	
	return super.drop_slot_data(grabbed_slot_data, index)

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Index 0 = результат (только забирать)
	if index == 0:
		return grabbed_slot_data
	
	if not _can_place_in_slot(grabbed_slot_data, index):
		return grabbed_slot_data
	
	return super.drop_single_slot_data(grabbed_slot_data, index)

func _can_place_in_slot(slot_data: SlotData, index: int) -> bool:
	if not slot_data or not slot_data.item_data:
		return false
	
	match index:
		0:  # Слот результата - НЕЛЬЗЯ класть
			return false
		1:  # Слот топлива
			return slot_data.item_data.is_fuel
		2:  # Слот материала - проверяем рецепт
			var recipe = FurnaceManager.find_recipe(slot_data.item_data)
			return recipe != null
	
	return false
