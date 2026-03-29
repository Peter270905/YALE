extends PanelContainer
class_name Slot
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var quantity_label: Label = $QuantityLabel
@onready var highlight_anim: AnimatedSprite2D = $HighlightAnim
@onready var durability_bar: TextureProgressBar = $MarginContainer/TextureProgressBar


signal  slot_clicked(index: int, button: int)



func update_durability_bar(tool: ItemTool):
	if tool and tool.durability > 0:
		durability_bar.show()
		
		durability_bar.max_value = tool.durability
		durability_bar.value = tool.current_durability
		
		var percent = float(tool.current_durability) / tool.durability
		if percent > 0.6:
			durability_bar.modulate = Color.GREEN
		elif percent > 0.3:
			durability_bar.modulate = Color.YELLOW
		else:
			durability_bar.modulate = Color.RED
	else:
		durability_bar.hide()


func set_slot_data(slot_data: SlotData) -> void:
	if not slot_data or not slot_data.item_data:
		if texture_rect:
			texture_rect.texture = null
		tooltip_text = ""
		quantity_label.hide()
		durability_bar.hide()
		return
		
	var item_data = slot_data.item_data
	
	if not texture_rect:
		return
	
	if item_data.texture:
		texture_rect.texture = item_data.texture
	else:
		texture_rect.texture = preload("res://assets/items/missing_texture.png")
	
	tooltip_text = "%s\n%s" % [item_data.name, item_data.description]
	
	if slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()
		
	if slot_data.item_data is ItemTool:
		var tool = slot_data.item_data as ItemTool
		if not tool.durability_changed.is_connected(update_durability_bar):
			tool.durability_changed.connect(update_durability_bar)
		update_durability_bar(tool)
	else:
		durability_bar.hide()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT \
			or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)


func highlight(is_active: bool) -> void:
	highlight_anim.visible = is_active
	if is_active:
		highlight_anim.play("active")
	else:
		highlight_anim.stop()

@export var has_background: bool = false
@export var background_texture: Texture2D
@export_range(0, 1) var background_opacity: float = 0.1

func _ready():
	if has_background and background_texture:
		@warning_ignore("shadowed_variable")
		var texture_rect = TextureRect.new()
		texture_rect.texture = background_texture
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.self_modulate = Color(1, 1, 1, background_opacity)
		add_child(texture_rect)
		move_child(texture_rect, 0)
		var _fill_style = StyleBoxFlat.new()
