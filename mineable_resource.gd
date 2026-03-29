extends Resource
class_name MineableResource

@export var name: String = ""
@export var health: int = 100
@export var required_tool_type: ItemTool.ToolType
@export var min_efficiency: float = 1.0
@export var base_harvest_time: float = 3.0

@export var drops: Array[DropData] = []


@export var scene: PackedScene
@export var texture: Texture2D

func get_random_drop_quantity(drop_index: int) -> int:
	if drop_index < drops.size():
		return drops[drop_index].get_quantity()
	return 0

func can_mine_with(tool: ItemTool) -> bool:
	return tool.tool_type == required_tool_type and tool.efficiency >= min_efficiency

func get_harvest_time(tool_efficiency: float) -> float:
	return base_harvest_time / tool_efficiency

func get_drop_item(drop_index: int) -> ItemData:
	if drop_index < drops.size():
		return drops[drop_index].item
	return null
