extends StaticBody3D
class_name Chest
@warning_ignore("unused_signal")
signal toggle_inventory(external_inventory_owner)

# ← ИЗМЕНИЛ: это теперь ШАБЛОН, а не сам инвентарь
@export var inventory_template: InventoryData

# ← НОВое: уникальный инвентарь для ЭТОГО ящика
var inventory_data : InventoryData

func _ready() -> void:
	add_to_group("external_inventory")
	_initialize_inventory()

# ← НОВАЯ ФУНКЦИЯ: создаёт УНИКАЛЬНУЮ копию инвентаря
func _initialize_inventory():
	if inventory_template:
		# duplicate(true) = глубокая копия (копирует и содержимое слотов!)
		inventory_data = inventory_template.duplicate(true)
	else:
		# Если шаблона нет — создаём пустой с 9 слотами
		inventory_data = InventoryData.new()
		inventory_data.slot_datas.resize(9)

func player_interact(player = null):
	# ← Проверяем, что инвентарь инициализирован
	if not inventory_data:
		_initialize_inventory()
	
	if player and player.has_method("toggle_inventory_interface"):
		player.toggle_inventory_interface(self)
