extends StaticBody3D

class_name FurnaceStation

@export var interactable_data: InteractableData

var inventory_data: FurnaceInventoryData = FurnaceInventoryData.new()

var current_temperature: float = 0.0
@export var max_temperature: float = 1500.0
var fuel_remaining: float = 0.0
var max_fuel: float = 100.0
var crafting_progress: float = 0.0
var current_recipe: FurnaceRecipe = null

var temperature_increase_rate: float = 50.0
var temperature_decrease_rate: float = 20.0
var crafting_speed: float = 1.0

var furnace_panel: PanelContainer = null

func _ready():
	if not interactable_data:
		interactable_data = InteractableData.new()
		interactable_data.interact_text = "Использовать печку [F]"
	
	inventory_data.inventory_updated.connect(_on_inventory_updated)
	add_to_group("buildings")
func player_interact(player):
	if player and player.has_method("open_furnace"):
		player.open_furnace(self)

func _process(delta):
	if fuel_remaining > 0:
		fuel_remaining -= delta
		current_temperature = min(current_temperature + temperature_increase_rate * delta, max_temperature)
	else:
		current_temperature = max(current_temperature - temperature_decrease_rate * delta, 0.0)
		_try_consume_fuel()
	
	if current_recipe:
		if current_temperature >= current_recipe.required_temperature:
			crafting_progress += delta * crafting_speed
			
			if crafting_progress >= current_recipe.processing_time:
				_complete_crafting()
		else:
			crafting_progress = max(crafting_progress - delta * 0.5, 0.0)
	else:
		_try_start_recipe()
		crafting_progress = 0.0
	
	_update_ui()

func _try_consume_fuel():
	var fuel_slot = inventory_data.slot_datas[1]  # Топливо на индексе 1
	if not fuel_slot or not fuel_slot.item_data:
		return
	
	var fuel_info = FurnaceManager.get_fuel_info(fuel_slot.item_data)
	
	var is_food_fuel = false
	if fuel_slot.item_data is ItemConsumable and fuel_slot.item_data.item_category == "food":
		is_food_fuel = true
	
	if fuel_info.is_fuel or is_food_fuel:
		var fuel_value = fuel_info.fuel_value if fuel_info.is_fuel else 20.0
		fuel_remaining = fuel_value
		max_fuel = fuel_remaining
		
		# ← Если это еда — добавляем уголь в выходной слот!
		if is_food_fuel:
			_add_coal_to_output()
		
		# Списываем топливо
		fuel_slot.quantity -= 1
		if fuel_slot.quantity <= 0:
			inventory_data.slot_datas[1] = null
		
		inventory_data.inventory_updated.emit(inventory_data)

func _add_coal_to_output():
	var output_slot = inventory_data.slot_datas[0]  # Результат на индексе 0
	var coal_path = "res://items/materials/ore/coal.tres"
	
	# ← Проверяем, существует ли уголь
	if not ResourceLoader.exists(coal_path):
		return
	
	var coal_item = load(coal_path)
	if not coal_item:
		return
	
	if not output_slot:
		var new_slot = SlotData.new()
		new_slot.item_data = coal_item
		new_slot.quantity = 1
		inventory_data.slot_datas[0] = new_slot
		
	elif output_slot.item_data == coal_item and output_slot.quantity < SlotData.MAX_STACK_SIZE:
		output_slot.quantity += 1
	else:
		pass
	
	inventory_data.inventory_updated.emit(inventory_data)

func _try_start_recipe():
	var input_slot = inventory_data.slot_datas[2]  # Материал на индексе 2
	var output_slot = inventory_data.slot_datas[0]  # Результат на индексе 0
	
	if not input_slot or not input_slot.item_data:
		return
	
	var recipe = FurnaceManager.find_recipe(input_slot.item_data)
	if recipe:
		if not output_slot or (output_slot.item_data == recipe.output_item and output_slot.quantity < SlotData.MAX_STACK_SIZE):
			current_recipe = recipe
			crafting_progress = 0.0

func _complete_crafting():
	if not current_recipe:
		return
	
	var input_slot = inventory_data.slot_datas[2]
	if input_slot:
		input_slot.quantity -= 1
		if input_slot.quantity <= 0:
			inventory_data.slot_datas[2] = null
	
	var output_slot = inventory_data.slot_datas[0]
	if not output_slot:
		var new_slot = SlotData.new()
		new_slot.item_data = current_recipe.output_item
		new_slot.quantity = 1
		inventory_data.slot_datas[0] = new_slot
	else:
		output_slot.quantity += 1
	
	current_recipe = null
	crafting_progress = 0.0
	inventory_data.inventory_updated.emit(inventory_data)

func _on_inventory_updated(inv: FurnaceInventoryData):
	var input_slot = inv.slot_datas[2]
	if current_recipe and (not input_slot or input_slot.item_data != current_recipe.input_item):
		current_recipe = null
		crafting_progress = 0.0

func _update_ui():
	pass

func set_ui_panel(panel: PanelContainer):
	furnace_panel = panel
