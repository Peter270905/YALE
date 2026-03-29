extends PanelContainer

@onready var input_slot = $MarginContainer/HBoxContainer/InputSlot
@onready var fuel_slot = $MarginContainer/HBoxContainer/FuelSlot
@onready var output_slot = $MarginContainer/HBoxContainer/OutputSlot
var furnace_inventory: FurnaceInventoryData

func _ready():
	if input_slot:
		input_slot.slot_clicked.connect(_on_input_slot_clicked)
	if fuel_slot:
		fuel_slot.slot_clicked.connect(_on_fuel_slot_clicked)
	if output_slot:
		output_slot.slot_clicked.connect(_on_output_slot_clicked)

func set_furnace_inventory(inv: FurnaceInventoryData):
	furnace_inventory = inv
	if not furnace_inventory.inventory_updated.is_connected(_on_inventory_updated):
		furnace_inventory.inventory_updated.connect(_on_inventory_updated)
	
	if not furnace_inventory.inventory_interact.is_connected(_on_furnace_slot_interact):
		furnace_inventory.inventory_interact.connect(_on_furnace_slot_interact)
	
	_on_inventory_updated(furnace_inventory)

func _on_inventory_updated(inv: FurnaceInventoryData):
	if inv.slot_datas.size() > 2:
		input_slot.set_slot_data(inv.slot_datas[2])
	else:
		input_slot.set_slot_data(null)
	
	if inv.slot_datas.size() > 1:
		fuel_slot.set_slot_data(inv.slot_datas[1])
	else:
		fuel_slot.set_slot_data(null)
	
	if inv.slot_datas.size() > 0:
		output_slot.set_slot_data(inv.slot_datas[0])
	else:
		output_slot.set_slot_data(null)

@warning_ignore("unused_parameter")
func _on_input_slot_clicked(index: int, button: int) -> void:
	furnace_inventory.on_slot_clicked(2, button)

@warning_ignore("unused_parameter")
func _on_fuel_slot_clicked(index: int, button: int):
	furnace_inventory.on_slot_clicked(1, button)

@warning_ignore("unused_parameter")
func _on_output_slot_clicked(index: int, button: int):
	furnace_inventory.on_slot_clicked(0, button)

func _on_furnace_slot_interact(inventory_data: InventoryData, index: int, button: int):
	var inventory_interface = get_tree().get_first_node_in_group("player").inventory_interface
	
	if not inventory_interface:
		return
	
	match [inventory_interface.grabbed_slot_data != null, button]:
		[true, MOUSE_BUTTON_LEFT]:
			inventory_interface.grabbed_slot_data = inventory_data.drop_slot_data(
				inventory_interface.grabbed_slot_data, index
			)
		[false, MOUSE_BUTTON_LEFT]:
			inventory_interface.grabbed_slot_data = inventory_data.grab_slot_data(index)
		[true, MOUSE_BUTTON_RIGHT]:
			inventory_interface.grabbed_slot_data = inventory_data.drop_single_slot_data(
				inventory_interface.grabbed_slot_data, index
			)
		[false, MOUSE_BUTTON_RIGHT]:
			var slot_data = inventory_data.slot_datas[index]
			if slot_data:
				var single = slot_data.create_single_slot_data()
				inventory_interface.grabbed_slot_data = single
				if slot_data.quantity <= 0:
					inventory_data.slot_datas[index] = null
				inventory_interface.update_grabbed_slot()
				inventory_data.inventory_updated.emit(inventory_data)
	
	inventory_interface.update_grabbed_slot()
