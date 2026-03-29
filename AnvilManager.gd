extends Node
class_name AnvilManager

static var recipes: Array[AnvilRecipe] = []

static func load_recipes_from_folder():
	recipes.clear()
	var dir_path = "res://recipes/anvil/"
	
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
				if recipe is AnvilRecipe:
					recipes.append(recipe)
				else:
					pass
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		pass

static func get_available_recipes() -> Array[AnvilRecipe]:
	return recipes
