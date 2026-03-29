extends StaticBody3D

@export var berry_scene: PackedScene
@export var spawn_markers: Array[Marker3D]
@export var loot: ItemData
@export var berry_type: String = "blackberry"
@export var interactable_data: InteractableData
@export var is_ripe: bool = false
var spawned_berries: Array[Node3D] = []
var growth_timer: Timer
@export var time_to_grow: int

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
	growth_timer = Timer.new()
	growth_timer.wait_time = time_to_grow
	growth_timer.timeout.connect(_on_regrow_timer_timeout)
	growth_timer.one_shot = true
	add_child(growth_timer)
	start_growth_cycle()
	add_to_group("trees")

func start_growth_cycle():
	clear_berries()
	growth_timer.start()
	is_ripe = false

func spawn_berries():
	for marker in spawn_markers:
		if randf() < 0.7:
			var berry = berry_scene.instantiate()
			marker.add_child(berry)
			spawned_berries.append(berry)
	
	is_ripe = !spawned_berries.is_empty()

func clear_berries():
	for berry in spawned_berries:
		berry.queue_free()
	spawned_berries.clear()

func player_interact(player = null) -> void:
	if !is_ripe:
		return
	
	if spawned_berries.is_empty():
		return
	
	var berry_count = spawned_berries.size()
	
	if player and "state" in player and player.state and "inventory_data" in player.state and loot:
		player.state.inventory_data.add_item(loot, berry_count)
		player.state.inventory_data.inventory_updated.emit(player.state.inventory_data)
	
	for berry in spawned_berries:
		if is_instance_valid(berry):
			berry.queue_free()
	
	spawned_berries.clear()
	is_ripe = false
	
	start_growth_cycle()

func count_items_in_inventory(inventory, item_data) -> int:
	var count = 0
	for slot in inventory.slot_datas:
		if slot and slot.item_data == item_data:
			count += slot.quantity
	return count

func _on_regrow_timer_timeout():
	spawn_berries()
