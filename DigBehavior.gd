extends MobBehavior
class_name DigBehavior

@export var found_items: Array[ItemData]
@export var dig_cooldown_min: float = 180.0
@export var dig_cooldown_max: float = 480.0
@export var dig_chance: float = 0.3
@export var anims: AnimationPlayer

var next_dig_time: float = 0.0

func _setup_behavior():
	_reset_dig_timer()

func _process_behavior(_delta):
	var current_time = Time.get_unix_time_from_system()
	
	if current_time >= next_dig_time:
		_try_dig()
		_reset_dig_timer()

func _reset_dig_timer():
	var random_cooldown = randf_range(dig_cooldown_min, dig_cooldown_max)
	next_dig_time = Time.get_unix_time_from_system() + random_cooldown

func _try_dig():
	if randf() <= dig_chance:
		_dig_mob()

var is_digging: bool = false

func _dig_mob():
	is_digging = true
	
	# 🔥 БЛОКИРУЕМ ДВИЖЕНИЕ
	mob.velocity = Vector3.ZERO
	if mob.has_method("set_temp_state"):
		mob.set_temp_state("digging")
	
	
	if anims:
		
		anims.stop()
		anims.play("dig")
		
		# 🔥 ПРОВЕРЯЕМ ДЕЙСТВИТЕЛЬНО ЛИ АНИМАЦИЯ ИГРАЕТ
		await get_tree().process_frame
		
		# 🔥 ЖДЕМ ЗАВЕРШЕНИЯ ИЛИ ТАЙМАУТ
		var timeout = get_tree().create_timer(2.0)  # 🔥 2 СЕКУНДЫ МАКСИМУМ
		var _animation_finished = anims.animation_finished
		
		var _result = await timeout.timeout
		
	else:
		await get_tree().create_timer(1.0).timeout
	
	# 🔥 РАЗБЛОКИРУЕМ ДВИЖЕНИЕ
	if mob.has_method("clear_temp_state"):
		mob.clear_temp_state()
	is_digging = false
	
	_find_random_item()


func _find_random_item():
	if found_items.is_empty():
		return
	
	var random_item = found_items[randi() % found_items.size()]
	var random_amount = randi_range(1, 2)
	_create_dig_pickup(random_item, random_amount)

func _create_dig_pickup(item_data: ItemData, quantity: int):
	var pickup = preload("res://scenes/pick_up/pick_up.tscn").instantiate()
	var slot_data = SlotData.new()
	slot_data.item_data = item_data
	slot_data.quantity = quantity
	pickup.slot_data = slot_data
	
	get_parent().get_parent().add_child(pickup)
	var offset = Vector3(randf_range(-1.5, 1.5), 0.5, randf_range(-1.5, 1.5))
	pickup.global_position = mob.global_position + offset
