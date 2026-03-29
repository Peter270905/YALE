extends InventoryData
class_name AccessoryInventoryData

# -------------------------------------------------------
# КОНФИГУРАЦИЯ СЛОТОВ
# -------------------------------------------------------

var AccessorySlot := {
	0: AccessoriesItemData.AccessoryType.ACCESSORYSLOT,
	1: AccessoriesItemData.AccessoryType.ACCESSORYSLOT,
	2: AccessoriesItemData.AccessoryType.ACCESSORYSLOT,
	3: AccessoriesItemData.AccessoryType.ACCESSORYSLOT,
	4: AccessoriesItemData.AccessoryType.ACCESSORYSLOT,
	5: AccessoriesItemData.AccessoryType.ACCESSORYSLOT,
	6: AccessoriesItemData.AccessoryType.ACCESSORYSLOT,
	7: AccessoriesItemData.AccessoryType.ACCESSORYSLOT
}

func can_equip_in_slot(slot_index: int, item_data: ItemData) -> bool:
	if not item_data is AccessoriesItemData:
		return false

	var accessory_item: AccessoriesItemData = item_data as AccessoriesItemData
	return accessory_item.accessory_type == AccessorySlot.get(slot_index)

# -------------------------------------------------------
# ССЫЛКИ НА ИГРОКА
# -------------------------------------------------------

var player_controller: PlayerController
var player_state: PlayerState

func setup_player_controller(controller: PlayerController) -> void:
	player_controller = controller
	player_state = controller.state
	
var runtime_abilities: Dictionary = {}

# -------------------------------------------------------
# ОСНОВНАЯ ЛОГИКА ЭКИПИРОВКИ
# -------------------------------------------------------

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	print("📥 [AccessoryInventoryData] drop_slot_data: index=", index, " | grabbed = ", grabbed_slot_data)
	if slot_datas[index] and slot_datas[index].item_data:
		print("📤 [AccessoryInventoryData] UNEQUIP from slot ", index, " | item = ", slot_datas[index].item_data)
		_unequip_ability(index)
	else:
		print("📤 [AccessoryInventoryData] No item to unequip from slot ", index)
	var result: SlotData = super.drop_slot_data(grabbed_slot_data, index)
	if grabbed_slot_data and grabbed_slot_data.item_data:
		print("📥 [AccessoryInventoryData] EQUIP to slot ", index, " | item = ", grabbed_slot_data.item_data)
		_equip_ability(grabbed_slot_data.item_data, index)
	return result

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	if not can_equip_in_slot(index, grabbed_slot_data.item_data):
		return grabbed_slot_data

	return super.drop_single_slot_data(grabbed_slot_data, index)


# -------------------------------------------------------
# EQUIP / UNEQUIP
# -------------------------------------------------------

func _equip_ability(item_data: ItemData, slot_index: int) -> void:
	print("⚙️ [AccessoryInventoryData] _equip_ability: slot=", slot_index, " | item=", item_data)
	if player_controller == null or player_state == null:
		return

	if not item_data is AccessoriesItemData:
		return

	var accessory_item: AccessoriesItemData = item_data as AccessoriesItemData
	if accessory_item.ability == null:
		print("❌ ОШИБКА: ability = null для ", item_data.resource_path)
		return

	var ability_instance: AccessoryAbility = accessory_item.ability.duplicate(true)

	runtime_abilities[slot_index] = ability_instance

	if ability_instance.has_method("setup_player_controller"):
		ability_instance.setup_player_controller(player_controller)

	# ✅ ДОБАВЬ:
	print("⚡ EQUIP: ", ability_instance, " | has on_equip: ", ability_instance.has_method("on_equip"))

	if ability_instance.has_method("on_equip"):
		ability_instance.on_equip(player_state)

	player_state.accessories_changed.emit()  # ← УБЕДИСЬ, ЧТО ЭТО ЕСТЬ!
	if ability_instance.has_method("on_equip"):
		print("✅ [AccessoryInventoryData] Calling on_equip")
		ability_instance.on_equip(player_state)
	player_state.accessories_changed.emit()

func _unequip_ability(slot_index: int) -> void:
	if not runtime_abilities.has(slot_index):
		print("❌ [AccessoryInventoryData] No runtime ability to unequip from slot ", slot_index)
		return

	var ability_instance: AccessoryAbility = runtime_abilities[slot_index]
	print("⚙️ [AccessoryInventoryData] _unequip_ability: slot=", slot_index, " | instance=", ability_instance)

	if ability_instance.has_method("on_unequip"):
		print("✅ [AccessoryInventoryData] Calling on_unequip")
		ability_instance.on_unequip(player_state)

	runtime_abilities.erase(slot_index)
	player_state.accessories_changed.emit()  # ← УБЕДИСЬ, ЧТО ЭТО ЕСТЬ!


# -------------------------------------------------------
# ВЫЗЫВАТЬ КАЖДЫЙ КАДР!
# -------------------------------------------------------

func process_abilities(delta: float) -> void:
	if player_state == null:
		return

	for ability in runtime_abilities.values():
		if ability.has_method("on_process"):
			ability.on_process(player_state, delta)

func grab_slot_data(index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data:
		# ✅ Сначала снимаем аксессуар
		_unequip_ability(index)
		
		# Потом стандартное поведение
		slot_datas[index] = null
		inventory_updated.emit(self)
		
		return slot_data
	else:
		return null
