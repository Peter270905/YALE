extends InventoryData
class_name EquipmentInventoryData

var slot_assignments = {
	0: ArmorItemData.ArmorType.HELMET,      # Слот 0 - шлем
	1: ArmorItemData.ArmorType.CHESTPLATE,  # Слот 1 - нагрудник  
	2: ArmorItemData.ArmorType.LEGGINGS,    # Слот 2 - поножи
	3: ArmorItemData.ArmorType.BOOTS        # Слот 3 - ботинки
}

func can_equip_in_slot(slot_index: int, item_data: ItemData) -> bool:
	if not item_data is ArmorItemData:
		return false
	
	var armor_item = item_data as ArmorItemData
	var required_type = slot_assignments.get(slot_index)
	
	return armor_item.armor_type == required_type

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	if not can_equip_in_slot(index, grabbed_slot_data.item_data):
		return grabbed_slot_data
	
	return super.drop_slot_data(grabbed_slot_data, index)

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	if not can_equip_in_slot(index, grabbed_slot_data.item_data):
		return grabbed_slot_data
	
	return super.drop_single_slot_data(grabbed_slot_data, index)
