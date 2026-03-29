extends Resource
class_name ItemData
@export var name: String = ""
@export_multiline var description: String = "":
	get:
		return _get_description()
@export var stackable: bool = true
@export var texture: Texture2D
@export var scene: PackedScene
@export var item_type: String = ""
@export var tags: Array = []

@export_category("Fuel Settings")
@export var is_fuel: bool = false
@export var fuel_value: float = 0.0
@export var fuel_temperature: float = 0.0

enum ITEM_QUALITY  {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	MYTHIC
}

@export var quality: ITEM_QUALITY

func use(_state) -> void:
	pass

func _get_description() -> String:
	var desc = "
	"
	if item_type:
		desc += item_type
	return desc

var quality_colors = {
	ITEM_QUALITY.COMMON: Color.GRAY,
	ITEM_QUALITY.UNCOMMON: Color.BLUE,
	ITEM_QUALITY.RARE: Color.GREEN,
	ITEM_QUALITY.EPIC: Color.ORANGE,
	ITEM_QUALITY.MYTHIC: Color.PURPLE
}
