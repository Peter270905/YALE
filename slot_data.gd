extends Resource
class_name SlotData

const MAX_STACK_SIZE: int = 80

@export var item_data: ItemData
@export_range(0, MAX_STACK_SIZE)
var quantity: int = 1:
	set(value):
		_quantity = clamp(value, 0, MAX_STACK_SIZE)
		if item_data and not item_data.stackable:
			_quantity = min(_quantity, 1)
	get:
		return _quantity

var _quantity: int = 1

func can_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data \
			and item_data.stackable \
			and quantity < MAX_STACK_SIZE

func can_fully_merge_with(other_slot_data: SlotData) -> bool:
	if other_slot_data == null:
		return false
	return item_data == other_slot_data.item_data \
		and item_data.stackable \
		and quantity + other_slot_data.quantity <= MAX_STACK_SIZE

func fully_merge_with(other_slot_data: SlotData) -> void:
	# caller must ensure other_slot_data is not null
	if other_slot_data == null:
		return
	quantity += other_slot_data.quantity

func partial_merge_with(other_slot_data: SlotData) -> SlotData:
	# try to merge as much as possible into this stack
	# returns leftover slot (may be the same object if nothing merged, or null if fully consumed)
	if other_slot_data == null:
		return null
	if item_data != other_slot_data.item_data or not item_data.stackable:
		return other_slot_data

	var space := MAX_STACK_SIZE - quantity
	if space <= 0:
		# this stack is full, nothing absorbed
		return other_slot_data
	
	if other_slot_data.quantity <= space:
		# we can take all of the other stack
		quantity += other_slot_data.quantity
		return null
	else:
		# fill this stack and leave remainder in other
		quantity = MAX_STACK_SIZE
		other_slot_data.quantity -= space
		return other_slot_data

func create_single_slot_data() -> SlotData:
	# split off one item from this stack
	if quantity <= 0 or not item_data:
		return null
	var new_slot_data: SlotData = duplicate()
	new_slot_data.quantity = 1
	quantity = max(quantity - 1, 0)
	return new_slot_data


func set_quantity(value: int) -> void:
	quantity = value
	if quantity > 1 and not item_data.stackable:
		quantity = 1
