extends PanelContainer
class_name HotbarInventory
signal hot_bar_use(index: int)

@warning_ignore("shadowed_global_identifier")
const Slot = preload("res://scenes/inventory/slot.tscn")
var active_index: int = 0
var slots: Array = []
var initialized := false

@onready var h_box_container: HBoxContainer = $MarginContainer/HBoxContainer

func set_inventory_data(inventory_data: InventoryData) -> void:
	if inventory_data.inventory_updated.is_connected(populate_hot_bar):
		inventory_data.inventory_updated.disconnect(populate_hot_bar)
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)


func populate_hot_bar(inventory_data: InventoryData) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	slots.clear()

	# Берем только первые 9 слотов
	for slot_data in inventory_data.slot_datas.slice(0, 9):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		if slot_data:
			slot.set_slot_data(slot_data)
		slots.append(slot)

	initialized = true
	update_highlight()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not initialized:
		return
	if event.is_action_pressed("hotbar_use_consumable"):
		hot_bar_use.emit(active_index)
	# Переключение цифрами (1–9)
	for i in range(slots.size()):
		if event.is_action_pressed("hotbar_" + str(i + 1)):
			active_index = i
			update_highlight()
			emit_signal("hot_bar_use", i)

	# Переключение клавишами Q / E
	if event.is_action_pressed("hotbar_prev"):
		active_index = (active_index - 1 + slots.size()) % slots.size()
		update_highlight()
		emit_signal("hot_bar_use", active_index)
	elif event.is_action_pressed("hotbar_next"):
		active_index = (active_index + 1) % slots.size()
		update_highlight()
		emit_signal("hot_bar_use", active_index)
	
	
	


func update_highlight() -> void:
	if not initialized:
		return
	for i in range(slots.size()):
		var slot = slots[i]
		slot.highlight(i == active_index)
