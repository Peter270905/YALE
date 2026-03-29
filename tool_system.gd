extends Node
class_name ToolSystem

@onready var player_state: PlayerState = $".."

func mine_resource(resource_node: MineableObject, tool: ItemTool) -> bool:
	if not tool or not tool.can_use():
		return false
	
	if resource_node and resource_node.resource_data.can_mine_with(tool):
		resource_node.mine(player_state, tool)
		tool.use_tool()
		return true
	
	return false

# Атака моба
func attack_mob(_mob_node, tool: ItemTool) -> bool:
	if not tool or not tool.can_use():
		return false
	
	if tool.use_tool():
		var _damage = tool.get_modified_damage()
		return true
	
	return false

func _can_mine_with_tool(_resource_node, _tool: ItemTool) -> bool:
	return true
