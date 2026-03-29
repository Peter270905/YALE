extends "res://scenes/inventory/slot.gd"
class_name EquipmentSlot

@export var equipment_type: ArmorItemData.ArmorType

signal equipment_clicked(slot_type: ArmorItemData.ArmorType, button: int)
signal equipment_dropped(slot_type: ArmorItemData.ArmorType, slot_data: SlotData)

var equipped_item: ArmorItemData = null

func _ready():
	gui_input.connect(_on_gui_input)

func set_equipment_data(armor_item: ArmorItemData) -> void:
	equipped_item = armor_item
	if armor_item:
		var slot_data = SlotData.new()
		slot_data.item_data = armor_item
		slot_data.quantity = 1
		set_slot_data(slot_data)
	else:
		texture_rect.texture = null
		tooltip_text = ""
		quantity_label.hide()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT \
			or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		equipment_clicked.emit(equipment_type, event.button_index)

# Функции для перетаскивания
func can_drop_data(_position, data) -> bool:
	# Проверяем, можно ли бросить этот предмет в слот
	if data is Dictionary and data.has("type") and data["type"] == "inventory_slot":
		var slot_data = data["slot_data"]
		if slot_data and slot_data.item_data is ArmorItemData:
			var armor_item = slot_data.item_data as ArmorItemData
			return armor_item.armor_type == equipment_type
	return false

func drop_data(_position, data) -> void:
	# Обрабатываем бросок предмета в слот
	if data is Dictionary and data.has("type") and data["type"] == "inventory_slot":
		var slot_data = data["slot_data"]
		if slot_data and slot_data.item_data is ArmorItemData:
			var armor_item = slot_data.item_data as ArmorItemData
			if armor_item.armor_type == equipment_type:
				print("Перетаскивание брони в слот: ", equipment_type)
				equipment_dropped.emit(equipment_type, slot_data)
