extends ItemTool
class_name HoeItem

# Список грядок которые можно построить этой мотыгой
@export var buildable_beds: Array[BuildableItemData] = []

func _init():
	super._init()
	item_type = "Инструмент"
	tool_type = ToolType.HOE
