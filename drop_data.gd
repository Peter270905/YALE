class_name DropData
extends Resource

@export var item: ItemData
@export var min_quantity: int = 1
@export var max_quantity: int = 1
@export var drop_chance: float = 1.0  # Шанс выпадения от 0.0 до 1.0

func get_quantity() -> int:
	if randf() <= drop_chance:
		return randi_range(min_quantity, max_quantity)
	return 0
