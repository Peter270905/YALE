extends Node
class_name GemManager

@export var gem_generator: GemGenerator
@export var gem_textures: Array[Texture2D]

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	add_to_group("gem_manager")

func add_random_gem_to_inventory(inventory_data: InventoryData, level: int = 1) -> bool:
	if not gem_generator:
		return false
	
	var gem = gem_generator.generate_gem(level)
	
	return add_gem_to_inventory(gem, inventory_data)

func add_gem_to_inventory(gem_data: GemData, inventory_data: InventoryData) -> bool:
	if not gem_data or not inventory_data:
		return false
	
	var gem_item = GemItemData.new()
	gem_item.name = gem_data.gem_name
	
	if gem_textures.size() > 0:
		gem_item.texture = gem_textures[rng.randi_range(0, gem_textures.size() - 1)]
	else:
		return false
	
	gem_item.description = gem_data.description
	gem_item.gem_data = gem_data
	gem_item.stackable = false
	
	var slot_data = SlotData.new()
	slot_data.item_data = gem_item
	slot_data.quantity = 1
	
	var result = inventory_data.pick_up_slot_data(slot_data)
	
	if result:
		inventory_data.inventory_updated.emit(inventory_data)
	
	return result

func add_multiple_gems(inventory_data: InventoryData, count: int, level: int = 1) -> void:
	for i in range(count):
		add_random_gem_to_inventory(inventory_data, level)
