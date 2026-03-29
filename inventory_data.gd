extends Resource
class_name InventoryData

@export var slot_datas: Array[SlotData]
signal inventory_interact(inventory_data: InventoryData, index: int, button: int)
signal inventory_updated(inventory_data: InventoryData)

func on_slot_clicked(index: int, button: int) ->void:
	inventory_interact.emit(self, index, button)

func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Left‑click: place entire grabbed stack into a slot. Perform partial merge if same item,
	# otherwise swap with whatever is in the slot.
	if grabbed_slot_data == null:
		return null

	var slot_data: SlotData = slot_datas[index]
	# empty target – just move the grabbed stack there
	if slot_data == null:
		slot_datas[index] = grabbed_slot_data
		inventory_updated.emit(self)
		return null
	
	# same item and stackable → try to merge
	if slot_data.item_data == grabbed_slot_data.item_data and slot_data.item_data.stackable:
		var remainder = slot_data.partial_merge_with(grabbed_slot_data)
		inventory_updated.emit(self)
		# remainder is either null (fully consumed) or a SlotData with leftovers
		return remainder
	
	# different item or can't merge → swap
	slot_datas[index] = grabbed_slot_data
	inventory_updated.emit(self)
	return slot_data

func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	# Right‑click: drop a single item from the grabbed stack.
	if grabbed_slot_data == null:
		return null
	
	var slot_data: SlotData = slot_datas[index]
	
	if slot_data == null:
		# place one item into empty slot
		slot_datas[index] = SlotData.new()
		slot_datas[index].item_data = grabbed_slot_data.item_data
		slot_datas[index].quantity = 1
		grabbed_slot_data.quantity = max(grabbed_slot_data.quantity - 1, 0)
	elif slot_data.item_data == grabbed_slot_data.item_data and slot_data.item_data.stackable and slot_data.quantity < SlotData.MAX_STACK_SIZE:
		# can merge one
		slot_data.quantity += 1
		grabbed_slot_data.quantity = max(grabbed_slot_data.quantity - 1, 0)
	else:
		# cannot drop a single item into this slot (different item or slot full)
		# leave everything as-is
		pass

	inventory_updated.emit(self)

	if grabbed_slot_data and grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null

func remove_slot_at_index(index: int) -> void:
	if index >= 0 and index < slot_datas.size():
		slot_datas[index] = null
		inventory_updated.emit(self)

func pick_up_slot_data(slot_data: SlotData) -> bool:
	if slot_data == null:
		return false

	# try to merge into existing stacks (partial/full)
	for i in range(slot_datas.size()):
		var s = slot_datas[i]
		if s and s.item_data == slot_data.item_data and s.item_data.stackable:
			var remainder = s.partial_merge_with(slot_data)
			inventory_updated.emit(self)
			if remainder == null:
				return true
			# otherwise continue trying other slots with leftover
			slot_data = remainder
	
	# if we still have items, drop into empty slot
	for i in range(slot_datas.size()):
		if not slot_datas[i]:
			slot_datas[i] = slot_data
			inventory_updated.emit(self)
			return true
	
	return false

func grab_slot_data(index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)
		return slot_data
	else:
		return null


func use_slot_data(index: int) -> void:
	var slot_data = slot_datas[index]
	if not slot_data:
		return
	if slot_data.item_data is ItemConsumable:
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			slot_datas[index] = null
	PlayerManager.use_slot_data(slot_data)
	inventory_updated.emit(self)


func has_enough_items(item_data: ItemData, amount: int) -> bool:
	var count := 0
	for slot in slot_datas:
		if slot and slot.item_data and slot.item_data.resource_path == item_data.resource_path:
			count += slot.quantity
	return count >= amount

func remove_items(item_data: ItemData, amount: int) -> void:
	for slot in slot_datas:
		if slot and slot.item_data and slot.item_data.resource_path == item_data.resource_path:
			var take = min(slot.quantity, amount)
			slot.quantity -= take
			amount -= take
			if slot.quantity <= 0:
				slot_datas[slot_datas.find(slot)] = null
			if amount <= 0:
				return

func add_item(item_data: ItemData, amount: int) -> void:
	# add items to existing stacks first, then to empty slots; respect MAX_STACK_SIZE
	var remaining := amount
	for slot in slot_datas:
		if slot and slot.item_data == item_data and item_data.stackable:
			var space := SlotData.MAX_STACK_SIZE - slot.quantity
			var to_add: int = min(space, remaining)
			slot.quantity += to_add
			remaining -= to_add
			if remaining <= 0:
				return
	# place leftovers into new slots
	for i in range(slot_datas.size()):
		if remaining <= 0:
			return
		if slot_datas[i] == null:
			slot_datas[i] = SlotData.new()
			slot_datas[i].item_data = item_data
			slot_datas[i].quantity = min(remaining, SlotData.MAX_STACK_SIZE)
			remaining -= slot_datas[i].quantity
