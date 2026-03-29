extends ItemData
class_name GemItemData

@export var gem_data: GemData

func _init():
	item_type = "Самоцвет"

func _get_description() -> String:
	if gem_data:
		return gem_data.description
	return "Загадочный самоцвет"
