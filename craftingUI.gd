extends PanelContainer

@onready var tree: Tree = %Tree
@onready var grid_container: GridContainer = %GridContainer
@onready var craft_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/Button

const SLOT = preload("res://scenes/inventory/slot.tscn")

var crafting_manager: CraftingManager
var current_recipe: CraftingRecipe = null
var player_controller: PlayerController
var is_workbench_mode: bool = false

func _ready():
	crafting_manager = CraftingManager.new()
	CraftingManager.load_recipes_from_folder()
	
	player_controller = get_tree().get_first_node_in_group("player")
	if not player_controller:
		push_error("❌ Не найден PlayerController!")
		return
	
	call_deferred("_deferred_init")
	craft_button.pressed.connect(_on_craft_pressed)
	craft_button.focus_mode = Control.FOCUS_NONE
	tree.focus_mode = Control.FOCUS_NONE

func _deferred_init():
	if not player_controller or not player_controller.state or not player_controller.state.inventory_data:
		push_error("❌ PlayerState или inventory_data недоступны!")
		return
	
	player_controller.state.inventory_data.inventory_updated.connect(_on_inventory_updated)
	_setup_tree()

func _on_inventory_updated(_inventory_data):
	# Перестраиваем дерево только если панель видима
	if not visible:
		return
	
	var previously_selected = current_recipe
	_setup_tree()
	
	# Восстанавливаем выбор если рецепт всё ещё доступен
	var root = tree.get_root()
	if root and previously_selected:
		var child = root.get_first_child()
		while child:
			if child.get_metadata(0) == previously_selected:
				child.select(0)
				break
			child = child.get_next()

func set_crafting_mode(is_workbench: bool):
	if is_workbench_mode == is_workbench:
		return
	
	_reset_all_state()
	
	is_workbench_mode = is_workbench
	_setup_tree()

func _setup_tree():
	tree.clear()
	var root = tree.create_item()
	
	if not player_controller or not player_controller.state or not player_controller.state.inventory_data:
		var no_access_item = tree.create_item(root)  # ← переименовали
		no_access_item.set_text(0, "Инвентарь недоступен")
		return
	
	var inventory = player_controller.state.inventory_data
	var recipes = CraftingManager.get_craftable_recipes(inventory, is_workbench_mode)
	
	
	if recipes.is_empty():
		var no_recipe = tree.create_item(root)
		no_recipe.set_text(0, "Нет доступных рецептов")
		return
	
	for recipe in recipes:
		var item = tree.create_item(root)
		item.set_text(0, recipe.name + " ×" + str(recipe.output_count))
		item.set_metadata(0, recipe)
		
		if recipe.result and recipe.result.texture:
			item.set_icon(0, recipe.result.texture)
	
	if not tree.item_selected.is_connected(_on_tree_item_selected):
		tree.item_selected.connect(_on_tree_item_selected)

func _reset_all_state():
	current_recipe = null
	
	for child in grid_container.get_children():
		child.queue_free()
	
	craft_button.disabled = true
	
	if tree.get_selected():
		tree.deselect_all()
	

func _on_tree_item_selected():
	var selected = tree.get_selected()
	if selected:
		var recipe = selected.get_metadata(0)
		if recipe:
			_show_recipe(recipe)
		else:
			_reset_all_state()
	else:
		_reset_all_state()

func _show_recipe(recipe: CraftingRecipe):
	_reset_all_state()
	
	current_recipe = recipe
	
	for i in range(recipe.materials.size()):
		var item = recipe.materials[i]
		var count = recipe.material_counts[i] if i < recipe.material_counts.size() else 1
		
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
	
	craft_button.disabled = not _has_enough_materials()

func _on_craft_pressed():
	if not current_recipe:
		return
	if not _has_enough_materials():
		return
	
	_perform_craft()

func _has_enough_materials() -> bool:
	if not player_controller:
		return false
	
	var inventory = player_controller.state.inventory_data
	for i in range(current_recipe.materials.size()):
		var item = current_recipe.materials[i]
		var count = current_recipe.material_counts[i] if i < current_recipe.material_counts.size() else 1
		if not inventory.has_enough_items(item, count):
			return false
	return true

func _perform_craft():
	if not player_controller:
		return
	
	var inventory = player_controller.state.inventory_data
	
	for i in range(current_recipe.materials.size()):
		var item = current_recipe.materials[i]
		var count = current_recipe.material_counts[i] if i < current_recipe.material_counts.size() else 1
		inventory.remove_items(item, count)
	
	var result_slot_data = SlotData.new()
	result_slot_data.item_data = current_recipe.result
	result_slot_data.quantity = current_recipe.output_count
	
	if not inventory.pick_up_slot_data(result_slot_data):
		if player_controller.has_method("_on_inventory_interface_drop_slot_data"):
			player_controller._on_inventory_interface_drop_slot_data(result_slot_data)
	
	
	# Перестраиваем дерево — некоторые рецепты могут стать недоступны
	var previously_selected_recipe = current_recipe
	_setup_tree()
	
	# Пробуем восстановить выбор, если рецепт ещё доступен
	var root = tree.get_root()
	if root:
		var child = root.get_first_child()
		while child:
			if child.get_metadata(0) == previously_selected_recipe:
				child.select(0)
				break
			child = child.get_next()

func reset_to_inventory_mode():
	set_crafting_mode(false)
