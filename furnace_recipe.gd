class_name FurnaceRecipe
extends Resource

@export var input_item: ItemData
@export var output_item: ItemData
@export var processing_time: float = 10.0
@export var required_temperature: float = 800.0
@export var fuel_consumption: float = 5.0

func get_input_id() -> String:
	return input_item.resource_path.get_file().get_basename()

func get_output_id() -> String:
	return output_item.resource_path.get_file().get_basename()
