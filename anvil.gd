extends StaticBody3D
class_name Anvil

@export var interactable_data : InteractableData

func _ready():
	if not interactable_data:
		interactable_data = InteractableData.new()
		interactable_data.interact_text = "Ковать [F]"
	add_to_group("buildings")
func player_interact(player):
	if player and player.has_method("open_anvil"):
		player.open_anvil(self)
