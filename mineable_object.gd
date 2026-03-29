extends Node3D
class_name MineableObject

@export var resource_data: MineableResource
@export var current_health: int

signal resource_mined(harvester)
signal health_changed(new_health)
var is_active = true

func set_active(active: bool):
	if is_active == active:
		return
	is_active = active
	if active:
		enable_logic()
	else:
		disable_logic()

func enable_logic():
	set_process(true)
	if has_method("set_physics_process"):
		set_physics_process(true)

func disable_logic():
	set_process(false)
	if has_method("set_physics_process"):
		set_physics_process(false)

func _ready():
	if resource_data:
		current_health = resource_data.health
		if resource_data.scene:
			var instance = resource_data.scene.instantiate()
			add_child(instance)
	
	_auto_add_to_groups()

func mine(harvester, tool: ItemTool) -> void:
	if not resource_data:
		return
	
	if not tool:
		return
	
	if not resource_data.can_mine_with(tool):
		return
	
	var efficiency = tool.get_modified_efficiency()
	var damage = int(efficiency)
	
	current_health -= damage
	health_changed.emit(current_health)
	
	
	if current_health <= 0:
		_harvest(harvester)
		queue_free()

func _harvest(harvester):
	
	for i in range(resource_data.drops.size()):
		var drop = resource_data.drops[i]
		var quantity = resource_data.get_random_drop_quantity(i)
		
		
		if quantity > 0 and drop and drop.item:
			_create_pick_up(drop.item, quantity, global_position)
	
	resource_mined.emit(harvester)

@warning_ignore("shadowed_variable_base_class")
func _create_pick_up(item_data: ItemData, quantity: int, position: Vector3):
	var pick_up_scene = preload("res://scenes/pick_up/pick_up.tscn")
	var pick_up = pick_up_scene.instantiate()
	
	var slot_data = SlotData.new()
	slot_data.item_data = item_data
	slot_data.quantity = quantity
	
	pick_up.slot_data = slot_data
	get_tree().current_scene.add_child(pick_up)
	
	var random_offset = Vector3(
		randf_range(-1.0, 1.0),
		0.5,
		randf_range(-1.0, 1.0)
	)
	pick_up.global_position = position + random_offset
	
	if pick_up is RigidBody3D:
		var impulse_force = Vector3(
			randf_range(-2.0, 2.0),
			randf_range(3.0, 5.0),
			randf_range(-2.0, 2.0)
		)
		pick_up.apply_impulse(impulse_force)
	

func _auto_add_to_groups():
	if not resource_data:
		return
	
	match resource_data.required_tool_type:
		ItemTool.ToolType.AXE:  # 0 = AXE
			add_to_group("trees")
		ItemTool.ToolType.PICKAXE:  # 1 = PICKAXE  
			add_to_group("stones")
			add_to_group("ores")
		ItemTool.ToolType.SHOVEL:  # 2 = SHOVEL
			add_to_group("dirt")
			add_to_group("sand")
		ItemTool.ToolType.SWORD:  # 3 = SWORD
			add_to_group("enemies")
