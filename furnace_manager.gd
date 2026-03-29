extends Node
class_name FurnaceManager

static var recipes: Array[FurnaceRecipe] = []

static func load_recipes_from_folder():
	recipes.clear()
	
	var dir_path = "res://recipes/furnace/"
	
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var recipe_path = dir_path + file_name
				var recipe = load(recipe_path)
				if recipe is FurnaceRecipe:
					recipes.append(recipe)
			file_name = dir.get_next()
		dir.list_dir_end()
	

static func find_recipe(input_item_data: ItemData) -> FurnaceRecipe:
	for recipe in recipes:
		if recipe.input_item == input_item_data:
			return recipe
	return null

static func get_available_recipes(current_temperature: float) -> Array[FurnaceRecipe]:
	return recipes.filter(func(recipe): 
		return recipe.required_temperature <= current_temperature
	)

static func _static_init():
	load_recipes_from_folder()

static func get_fuel_info(item_data: ItemData) -> Dictionary:
	if not item_data or not item_data.is_fuel:
		return {"is_fuel": false}
	
	return {
		"is_fuel": true,
		"fuel_value": item_data.fuel_value,
		"fuel_temperature": item_data.fuel_temperature
	}
