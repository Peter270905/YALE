extends CanvasLayer
class_name  InteractionPrompt
@onready var prompt_label: Label = $Control/prompt_label


func show_prompt(text: String):
	prompt_label.label.text = text
	prompt_label.label.visible = true

func hide_prompt():
	prompt_label.label.visible = false
