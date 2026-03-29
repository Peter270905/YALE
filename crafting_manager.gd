extends Node
class_name CraftingManager

static var recipes: Array[CraftingRecipe] = []

static func load_recipes_from_folder():
	recipes.clear()
	var dir_path = "res://recipes/crafting/"
	
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	
	var dir = DirAccess.open(dir_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var recipe_path = dir_path + file_name
			var recipe = ResourceLoader.load(recipe_path)
			if recipe is CraftingRecipe:
				recipes.append(recipe)
		file_name = dir.get_next()
	dir.list_dir_end()

static func get_recipes_for_station(is_workbench: bool) -> Array[CraftingRecipe]:
	if is_workbench:
		return recipes
	else:
		# ЯВНО УКАЗЫВАЕМ ТИП МАССИВА:
		var inventory_recipes: Array[CraftingRecipe] = []
		
		for recipe in recipes:
			if recipe.craft_type == CraftingRecipe.CraftType.INVENTORY:
				inventory_recipes.append(recipe)
		
		return inventory_recipes


static func get_available_recipes() -> Array[CraftingRecipe]:
	return recipes

static func get_craftable_recipes(inventory_data, is_workbench: bool) -> Array[CraftingRecipe]:
	var source = get_recipes_for_station(is_workbench)	
	var result: Array[CraftingRecipe] = []
	
	for recipe in source:
		var can_craft = true
		for i in range(recipe.materials.size()):
			var item = recipe.materials[i]
			var count = recipe.material_counts[i] if i < recipe.material_counts.size() else 1
			var has = inventory_data.has_enough_items(item, count)
			if not has:
				can_craft = false
				break
		if can_craft:
			result.append(recipe)
	
	return result
