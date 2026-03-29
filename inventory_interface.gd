extends Control
class_name InventoryInterface

@onready var player_inventory: PanelContainer = $InventoryLayout/MainVBox/HBoxContainer/PlayerInventory
@onready var grabbed_slot: PanelContainer = $GrabbedSlot
@onready var external_inventory: PanelContainer = $InventoryLayout/MainVBox/HBoxContainer2/ExternalInventory
@onready var state: PlayerState = $"../../state"
@onready var equip_inventory: PanelContainer = %EquipInventory
@onready var accessories_inventory: PanelContainer = %AccessoriesInventory
@onready var crafting_panel: PanelContainer = $InventoryLayout/MainVBox/HBoxContainer2/CraftingUI


signal drop_slot_data(slot_data: SlotData)


func set_equip_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory.set_inventory_data(inventory_data)


func set_accessories_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	accessories_inventory.set_inventory_data(inventory_data)

@warning_ignore("shadowed_variable")
func on_external_slot_clicked(external_inventory: InventoryData, slot_index: int, button: int):
	if get_parent() and get_parent().has_method("on_inventory_interact"):
		get_parent().on_inventory_interact(external_inventory, slot_index, button)

func _on_crafting_slot_clicked(index: int, button: int):
	if button != MOUSE_BUTTON_LEFT:
		return
	
	if grabbed_slot_data:
		crafting_panel.set_slot_data(index, grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()
	else:
		var slot_data = crafting_panel.get_slot_data(index)
		if slot_data:
			grabbed_slot_data = slot_data
			crafting_panel.set_slot_data(index, null)
			update_grabbed_slot()

func _on_craft_performed(slot_data: SlotData):
	if not state.inventory_data.pick_up_slot_data(slot_data):
		drop_slot_data.emit(slot_data)

var external_inventory_owner

func _physics_process(_delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5,5)


var grabbed_slot_data: SlotData

func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func on_inventory_interact(inventory_data: InventoryData, index: int, button: int) -> void:
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]:
			inventory_data.use_slot_data(index)
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
	update_grabbed_slot()

func set_external_inventory(_external_inventory_owner) -> void:
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
	inventory_data.inventory_interact.connect(on_inventory_interact)
	external_inventory.set_inventory_data(inventory_data)
	external_inventory.show()
	crafting_panel.hide()


func clear_external_inventory() -> void:
	if external_inventory_owner:
		
		var inventory_data = external_inventory_owner.inventory_data
	
		inventory_data.inventory_interact.disconnect(on_inventory_interact)
		external_inventory.clear_inventory_data(inventory_data)

		external_inventory.hide()
		external_inventory_owner = null


func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.is_pressed() \
			and grabbed_slot_data:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				drop_slot_data.emit(grabbed_slot_data)
				grabbed_slot_data = null
			MOUSE_BUTTON_RIGHT:
				var single := grabbed_slot_data.create_single_slot_data()
				if single:
					drop_slot_data.emit(single)
		update_grabbed_slot()
	if not visible and crafting_panel:
		crafting_panel.reset_to_inventory_mode()
