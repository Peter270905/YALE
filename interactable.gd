extends Node3D
class_name Interactable

@export var interactable_data: InteractableData
signal interacted(player)

func player_interact(player):
	if interactable_data and interactable_data.can_interact:
		interacted.emit(player)
