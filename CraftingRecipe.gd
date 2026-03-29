extends Resource
class_name CraftingRecipe

@export var name: String
@export var result: ItemData
@export var materials: Array[ItemData] = []
@export var material_counts: Array[int] = []
@export var output_count: int = 1

enum CraftType { INVENTORY, WORKBENCH }
@export var craft_type: CraftType
