extends AccessoryAbility
class_name SpeedBootsAbility

@export var run_speed_multiplier: float = 1.5
@export var acceleration_time: float = 0.5
@export var deceleration_time: float = 0.2

var player_state: PlayerState = null
var player_controller: PlayerController = null

var _target_multiplier: float = 1.0
var _current_multiplier: float = 1.0
var _is_accelerating: bool = false

func setup_player_controller(controller: PlayerController):
	player_controller = controller
	player_state = controller.state

func on_equip(player: PlayerState):
	if player_state == null:
		player_state = player
	_target_multiplier = run_speed_multiplier
	_current_multiplier = 1.0
	player_state.accessory_speed_multiplier = _current_multiplier

@warning_ignore("unused_parameter")
func on_unequip(player: PlayerState):
	_target_multiplier = 1.0
	_is_accelerating = true

@warning_ignore("unused_parameter")
func on_process(player: PlayerState, delta: float):
	if not player_state or not player_controller:
		return

	var is_running = player_controller.running and player_controller.state.can_run

	if _target_multiplier == 1.0:
		if abs(_current_multiplier - 1.0) > 0.001:
			_current_multiplier = lerp(_current_multiplier, 1.0, delta / deceleration_time)
			player_state.accessory_speed_multiplier = _current_multiplier
		else:
			_current_multiplier = 1.0
			player_state.accessory_speed_multiplier = 1.0
			_is_accelerating = false
		return

	var target = run_speed_multiplier if is_running else 1.0
	var current_time = acceleration_time if target > _current_multiplier else deceleration_time

	if abs(_current_multiplier - target) > 0.001:
		_current_multiplier = lerp(_current_multiplier, target, delta / current_time)
		player_state.accessory_speed_multiplier = _current_multiplier
	else:
		_current_multiplier = target
		player_state.accessory_speed_multiplier = _current_multiplier
