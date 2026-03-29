# Rock.gd
extends StaticBody3D
class_name Rock

# ===== МИНИМАЛЬНЫЕ НАСТРОЙКИ =====
@export var texture: Texture2D
@export var drop_item: Array[ItemData]
@export var base_health: int = 10
@export var base_drop: int = 2
@export var required_tool_type: ItemTool.ToolType = ItemTool.ToolType.PICKAXE
@export var min_efficiency: float = 1.0

# ===== ВНУТРЕННИЕ ПЕРЕМЕННЫЕ =====
var size: float = 1.0
var current_health: int = 0
var is_active: bool = true

# ===== СИГНАЛЫ =====
signal resource_mined(harvester)
signal health_changed(new_health)

func _ready():
	add_to_group("stones")
	
	# ===== ГЕНЕРАЦИЯ РАЗМЕРА С РЕДКИМИ ОГРОМНЫМИ КАМНЯМИ =====
	if randf() < 0.1:
		size = randf_range(10.0, 20.0)
	else:
		size = randf_range(0.6, 5.0)
	
	current_health = int(base_health * size)
	
	var generator = get_node_or_null("RockGenerator")
	if not generator:
		generator = preload("res://scenes/gen/rock/rock_generator.tscn").instantiate()
		generator.name = "RockGenerator"
		add_child(generator)
	
	generator.size = size
	generator.roughness = randf_range(0.25, 0.5)
	generator.resolution = randi_range(3, 5)
	generator.rock_seed = randi()
	generator.generate = true
	
	# ПРИМЕНЯЕМ ТЕКСТУРУ
	if texture and generator:
		var material = StandardMaterial3D.new()
		material.albedo_texture = texture
		material.roughness = 0.85
		material.uv1_triplanar = true
		generator.material_override = material
	
	_auto_add_to_groups()
	

func _auto_add_to_groups():
	match required_tool_type:
		ItemTool.ToolType.AXE:
			add_to_group("trees")
		ItemTool.ToolType.PICKAXE:
			add_to_group("stones")
			add_to_group("ores")
		ItemTool.ToolType.SHOVEL:
			add_to_group("dirt")
			add_to_group("sand")
			add_to_group("gravel")
		ItemTool.ToolType.SWORD:
			add_to_group("enemies")

# ===== ЛОГИКА ДОБЫЧИ =====
func mine(harvester, tool: ItemTool) -> void:
	if not tool or not can_mine_with(tool):
		return
	
	var damage = int(tool.get_modified_efficiency())
	current_health -= damage
	health_changed.emit(current_health)
	
	if current_health <= 0:
		_harvest(harvester)
		queue_free()

func can_mine_with(tool: ItemTool) -> bool:
	return tool.tool_type == required_tool_type and tool.efficiency >= min_efficiency

func _harvest(harvester):
	if drop_item:
		var quantity = int(base_drop * size)
		for item in drop_item:
			_create_pick_up(item, quantity, global_position)
	
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
	pick_up.global_position = position + Vector3(
		randf_range(-1.0, 1.0),
		0.5,
		randf_range(-1.0, 1.0)
	)
	
	if pick_up is RigidBody3D:
		pick_up.apply_impulse(Vector3(
			randf_range(-2.0, 2.0),
			randf_range(3.0, 5.0),
			randf_range(-2.0, 2.0)
		))
