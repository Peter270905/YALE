extends BuildableItemData
class_name SeedItemData

@export var harvest_item: ItemData  # Что выпадает при сборе
@export var plant_scene: PackedScene  # Сцена растения

func get_harvest_item() -> ItemData:
	return harvest_item.duplicate() if harvest_item else null

func get_plant_scene() -> PackedScene:
	return plant_scene
