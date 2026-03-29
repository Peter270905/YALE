# AnvilUI.gd
extends PanelContainer

@onready var tree: Tree = %Tree
@onready var grid_container: GridContainer = %GridContainer
@onready var minigame_point: Control = $MarginContainer/HBoxContainer/VBoxContainer/MinigamePoint
@onready var forge_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/Button

const SLOT = preload("res://scenes/inventory/slot.tscn")

var anvil_manager: AnvilManager
var current_recipe: AnvilRecipe = null
var player_controller: PlayerController  # ← Добавляем ссылку на игрока

func _ready():
	anvil_manager = AnvilManager.new()
	AnvilManager.load_recipes_from_folder()
	
	# Получаем PlayerController
	player_controller = get_tree().get_first_node_in_group("player")
	if not player_controller:
		push_error("Не найден PlayerController!")
	
	_setup_tree()
	forge_button.pressed.connect(_on_forge_pressed)
	forge_button.focus_mode = Control.FOCUS_NONE
	tree.focus_mode = Control.FOCUS_NONE

func _setup_tree():
	tree.clear()
	var root = tree.create_item()
	
	@warning_ignore("static_called_on_instance")
	var recipes = anvil_manager.get_available_recipes()
	for recipe in recipes:
		var item = tree.create_item(root)
		item.set_text(0, recipe.name)
		item.set_metadata(0, recipe)
		
		if recipe.result and recipe.result.texture:
			item.set_icon(0, recipe.result.texture)

	tree.item_selected.connect(_on_tree_item_selected)

func _on_tree_item_selected():
	var selected = tree.get_selected()
	if selected:
		var recipe = selected.get_metadata(0)
		if recipe:
			_show_recipe(recipe)

func _show_recipe(recipe: AnvilRecipe):
	
	current_recipe = recipe
	
	for child in grid_container.get_children():
		child.queue_free()
	
	for i in range(recipe.materials.size()):
		var item = recipe.materials[i]
		var count = recipe.material_counts[i] if i < recipe.material_counts.size() else 0
	
	for i in range(recipe.materials.size()):
		var item = recipe.materials[i]
		var count = recipe.material_counts[i]
		
		var slot = SLOT.instantiate()
		var slot_data = SlotData.new()
		slot_data.item_data = item
		slot_data.quantity = count
		slot.set_slot_data(slot_data)
		
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		grid_container.add_child(slot)
		
		if not slot_data.item_data.texture:
			slot_data.item_data.texture = preload("res://assets/items/missing_texture.png")
		slot.set_slot_data(slot_data)

func _on_forge_pressed():
	if not current_recipe:
		return
	if not _has_enough_materials():
		return
	_start_minigame()

func _has_enough_materials() -> bool:
	if not player_controller:
		return false
	
	var inventory = player_controller.get_inventory_data()
	for i in range(current_recipe.materials.size()):
		var item = current_recipe.materials[i]
		var count = current_recipe.material_counts[i] if i < current_recipe.material_counts.size() else 1
		if not inventory.has_enough_items(item, count):
			return false
	return true

func _start_minigame():
	# Очищаем старую мини-игру
	for child in minigame_point.get_children():
		child.queue_free()
	
	# Создаём новую
	var minigame = preload("res://minigames/AnvilMinigame/AnvilMinigame.tscn").instantiate()
	minigame.difficulty = current_recipe.difficulty if current_recipe.difficulty > 0 else 1
	minigame.craft_success.connect(_on_craft_success)
	minigame.craft_failed.connect(_on_craft_failed)
	minigame_point.add_child(minigame)
	minigame.show()

func _on_craft_success():
	if not player_controller:
		return
	
	var inventory = player_controller.get_inventory_data()
	
	for i in range(current_recipe.materials.size()):
		var item = current_recipe.materials[i]
		var count = current_recipe.material_counts[i] if i < current_recipe.material_counts.size() else 1
		inventory.remove_items(item, count)
	
	var result_slot_data = SlotData.new()
	result_slot_data.item_data = current_recipe.result
	result_slot_data.quantity = 1
	
	if not inventory.pick_up_slot_data(result_slot_data):
		if player_controller.has_method("_on_inventory_interface_drop_slot_data"):
			player_controller._on_inventory_interface_drop_slot_data(result_slot_data)

func _on_craft_failed():
	print("Ковка не удалась!")
