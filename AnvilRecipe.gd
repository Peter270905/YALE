extends Resource
class_name AnvilRecipe

@export var name: String
@export var result: ItemData
@export var materials: Array[ItemData] = []
@export var material_counts: Array[int] = []
@export var difficulty: int = 1
