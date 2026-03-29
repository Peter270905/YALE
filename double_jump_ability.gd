extends AccessoryAbility
class_name DoubleJumpAbility

var can_double_jump: bool = true
var player_controller: PlayerController

func can_extra_jump(is_on_floor: bool) -> bool:
	if is_on_floor:
		can_double_jump = true
		return false
	return can_double_jump

func perform_extra_jump() -> bool:
	if can_double_jump:
		can_double_jump = false
		return true
	return false

func setup_player_controller(controller: PlayerController):
	player_controller = controller
