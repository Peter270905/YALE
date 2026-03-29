extends AccessoryAbility
class_name FallDamageImmunityAbility

var original_fall_threshold: float
var player_controller: PlayerController

func on_equip(player: PlayerState):
	player.fall_damage_immunity = true
	print("🪂 Амулет невесомости надет - урон от падения отключен")

func on_unequip(player: PlayerState):
	player.fall_damage_immunity = false
	print("🪂 Амулет невесомости снят")

func setup_player_controller(controller: PlayerController):
	player_controller = controller
