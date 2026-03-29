class_name ShearBehavior
extends MobBehavior

@export var shear_amount: int = 1
@export var shear_cooldown: float = 1200.0
@export var wool_visual: MeshInstance3D
var last_sheared_time: float = -999.0

@warning_ignore("unused_parameter")
func _on_interact(player: Node, item: ItemData) -> bool:
	if not item or not item is ItemTool:
		return false
	var tool = item as ItemTool
	if tool.tool_type != ItemTool.ToolType.SCISSORS:
		return false
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_sheared_time < shear_cooldown:
		return true
	if tool.use_tool():
		_shear_mob()
		return true
	else:
		return true

func _shear_mob():
	last_sheared_time = Time.get_unix_time_from_system()
	
	if wool_visual:
		wool_visual.hide()
	
	_drop_items()
	
	var timer = get_tree().create_timer(shear_cooldown)
	timer.timeout.connect(_regrow_wool)

func _regrow_wool():
	if wool_visual:
		wool_visual.show()

func _drop_items():
	var random_amount = randi_range(1, 3)
	for i in range(shear_amount):
		var pickup = preload("res://scenes/pick_up/pick_up.tscn").instantiate()
		
		var wool_item = load("res://items/materials/mob loot/wool.tres")
		if not wool_item:
			return
		
		var slot_data = SlotData.new()
		slot_data.item_data = wool_item
		slot_data.quantity = random_amount
		
		pickup.slot_data = slot_data
		get_parent().get_parent().add_child(pickup)
		pickup.global_position = mob.global_position + Vector3(randf_range(-1, 1), 1, randf_range(-1, 1))

func get_interaction_text(player: Node) -> String:
	if not player or not player.has_method("get_current_item"):
		return ""
	var current_item = player.get_current_item()
	if current_item is ItemTool:
		if current_item.tool_type == ItemTool.ToolType.SCISSORS:
			return "Подстричь [F]"
	
	return ""
