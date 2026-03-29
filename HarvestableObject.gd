extends StaticBody3D
class_name HarvestableObject

@export var drops: Array[DropData] = []
@export var interaction_text: InteractableData

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

@warning_ignore("unused_parameter")
func get_interaction_text_for_player(player: PlayerController) -> String:
	if interaction_text:
		return interaction_text.interact_text 
	else:
		return "Собрать [E]"

@warning_ignore("unused_parameter")
func player_interact(player: PlayerController) -> bool:
	for drop in drops:
		if randf() <= drop.drop_chance:  
			var quantity = drop.get_quantity()
			if quantity > 0:
				_drop_item(drop.item, quantity, global_position)
				queue_free()
				return true
		else:
			pass
	return false

@warning_ignore("shadowed_variable_base_class")
func _drop_item(item_data: ItemData, quantity: int, position: Vector3):
	var pick_up_scene = preload("res://scenes/pick_up/pick_up.tscn")
	var pick_up = pick_up_scene.instantiate()
	
	var slot_data = SlotData.new()
	slot_data.item_data = item_data
	slot_data.quantity = quantity
	
	pick_up.slot_data = slot_data
	get_tree().current_scene.add_child(pick_up)
	
	var random_offset = Vector3(
		randf_range(0, 0),
		0.5,
		randf_range(0, 0)
	)
	pick_up.global_position = position + random_offset
	
	if pick_up is RigidBody3D:
		var impulse_force = Vector3(
			randf_range(-0, 0),
			randf_range(2.0, 3.0),
			randf_range(0, 0)
		)
		pick_up.apply_impulse(impulse_force)
