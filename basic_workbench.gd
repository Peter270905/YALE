extends StaticBody3D
class_name Workbench

@export var interactable_data: InteractableData

func _ready():
	if not interactable_data:
		interactable_data = InteractableData.new()
		interactable_data.interact_text = "Использовать верстак"
	add_to_group("buildings")

# ИЗМЕНИЛ ВОЗВРАЩАЕМЫЙ ТИП НА bool
func player_interact(player = null) -> bool:
	if not player:
		return false
	
	# ИСПРАВЛЕННЫЙ ПУТЬ (убран "2")
	var crafting_panel = player.get_node_or_null("UI/InventoryInterface/InventoryLayout/MainVBox/HBoxContainer2/CraftingUI")
	var inventory_interface = player.get_node_or_null("UI/InventoryInterface")
	
	if not crafting_panel or not inventory_interface:
		return false
	
	# ПРАВИЛЬНОЕ ОТКРЫТИЕ ИНВЕНТАРЯ
	if not inventory_interface.visible:
		if player.has_method("toggle_inventory_interface"):
			player.toggle_inventory_interface()
	
	# УСТАНАВЛИВАЕМ РЕЖИМ ВЕРСТАКА
	crafting_panel.set_crafting_mode(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	return true  # Успешно обработано
