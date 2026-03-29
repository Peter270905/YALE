class_name BuildableItemData
extends ItemData

@export var build_scene: PackedScene
@export var build_category: String = "structure"
@export var grid_snap: bool = false
@export var grid_size: float = 1.0
@export var rotation_steps: int = 4
@export var allowed_surfaces: Array[String] = ["ground", "wall", "ceiling"]

#система маркеров
@export var use_snap_points: bool = false
@export var snap_point_names: Array[String] = []
@export var snap_distance: float = 1.5
@export var snap_offset: float = 1.0

@export var recipe: BuildableCraftingRecipe = null
