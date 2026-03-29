extends Control

signal craft_success
signal craft_failed

@export var difficulty: int = 3

@onready var track = $Track
@onready var green_zone = $Track/GreenZone
@onready var runner = $Track/Runner

var base_speed: float = 100.0
var current_speed: float = 100.0
var max_speed: float = 200.0
var direction: float = 1.0
var is_active: bool = true
var hits_needed: int = 1
var hits_done: int = 0
var base_zone_ratio: float = 0.3
var current_zone_ratio: float = 0.3

func _ready():
	_setup_difficulty()
	_position_runner()
	_start_movement()

func _setup_difficulty():
	# Количество ударов: 1, 2, 4, 8, 12
	match difficulty:
		1: hits_needed = 1
		2: hits_needed = 3
		3: hits_needed = 6
		4: hits_needed = 9
		5: hits_needed = 12
	
	base_speed = 80 + (difficulty - 1) * 25
	max_speed = base_speed + (difficulty - 1) * 50
	current_speed = base_speed
	
	# Ширина зоны
	base_zone_ratio = 0.4 - (difficulty - 1) * 0.05
	current_zone_ratio = base_zone_ratio
	
	_update_green_zone()

func _update_green_zone():
	var green_width = track.size.x * current_zone_ratio
	green_zone.size = Vector2(green_width, track.size.y)
	
	var max_offset = track.size.x - green_width
	var offset = randf() * max_offset
	green_zone.position = Vector2(offset, 0)

func _position_runner():
	runner.position = Vector2(0, (track.size.y - runner.size.y) / 2)

func _start_movement():
	set_process(true)

func _process(delta):
	if not is_active:
		return
	
	runner.position.x += current_speed * direction * delta
	
	var min_x = 0
	var max_x = track.size.x - runner.size.x
	runner.position.x = clamp(runner.position.x, min_x, max_x)
	
	if runner.position.x <= min_x:
		direction = 1.0
	elif runner.position.x >= max_x:
		direction = -1.0
	
	green_zone.position.x += sin(Time.get_ticks_msec() * 0.01) * 50 * delta
	green_zone.position.x = clamp(green_zone.position.x, 0, track.size.x - green_zone.size.x)

func _input(event):
	if event.is_action_pressed("ui_accept") and is_active:
		_check_hit()

func _check_hit():
	var runner_center = runner.position.x + runner.size.x / 2
	var green_left = green_zone.position.x
	var green_right = green_left + green_zone.size.x
	
	if runner_center >= green_left and runner_center <= green_right:
		hits_done += 1
		
		if hits_done >= hits_needed:
			craft_success.emit()
			is_active = false
			queue_free()
			print("красава")
		else:
			current_speed = min(max_speed, current_speed + 10)
			current_zone_ratio = max(0.05, current_zone_ratio - 0.02)
			
			await get_tree().create_timer(0.1).timeout
			_update_green_zone()
	else:
		craft_failed.emit()
		is_active = false
		queue_free()
		print("Лошара")
