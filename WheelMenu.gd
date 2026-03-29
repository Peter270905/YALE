extends Control
class_name WheelMenu

signal item_selected(buildable: BuildableItemData)
signal menu_closed

var _sectors: Array = []
var _hovered_index: int = -1
var _center: Vector2
var _outer_radius: float = 180.0
var _inner_radius: float = 60.0
var _items: Array[BuildableItemData] = []

func _ready():
	# Растягиваем на весь экран чтобы ловить мышь
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup(buildables: Array[BuildableItemData]):
	_items = buildables
	_center = get_viewport_rect().size / 2.0
	_sectors.clear()
	
	var count = _items.size()
	var angle_step = TAU / count
	
	for i in range(count):
		var angle_from = i * angle_step - PI / 2.0
		var angle_to = angle_from + angle_step
		_sectors.append({
			"from": angle_from,
			"to": angle_to,
			"mid": angle_from + angle_step / 2.0,
			"item": _items[i]
		})
	
	queue_redraw()

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		_update_hover(event.position)
		queue_redraw()

func _update_hover(mouse_pos: Vector2):
	var dir = mouse_pos - _center
	var dist = dir.length()
	
	# Внутри внутреннего круга — ничего не выбрано
	if dist < _inner_radius * 0.5:
		_hovered_index = -1
		return
	
	var angle = atan2(dir.y, dir.x)
	
	for i in range(_sectors.size()):
		var s = _sectors[i]
		var from = s.from
		var to = s.to
		
		# Нормализуем угол в диапазон сектора
		var a = angle
		while a < from:
			a += TAU
		while a > from + TAU:
			a -= TAU
		
		if a >= from and a <= to:
			_hovered_index = i
			return
	
	_hovered_index = -1

func _draw():
	if _sectors.is_empty():
		return
	
	var count = _sectors.size()
	var angle_step = TAU / count
	
	for i in range(_sectors.size()):
		var s = _sectors[i]
		var is_hovered = (i == _hovered_index)
		
		# Цвет сектора
		var fill_color = Color(0.1, 0.1, 0.1, 0.82) if not is_hovered else Color(0.2, 0.55, 0.2, 0.92)
		var border_color = Color(0.5, 0.5, 0.5, 0.6) if not is_hovered else Color(0.4, 0.9, 0.4, 1.0)
		
		# Рисуем сектор через полигон
		var points = _build_sector_polygon(s.from, s.to)
		draw_colored_polygon(points, fill_color)
		
		# Граница сектора
		var border_points = PackedVector2Array(points)
		border_points.append(points[0])
		draw_polyline(border_points, border_color, 1.5)
		
		# Иконка и текст
		var mid_angle = s.mid
		var icon_dist = (_inner_radius + _outer_radius) / 2.0
		var icon_pos = _center + Vector2(cos(mid_angle), sin(mid_angle)) * icon_dist
		
		var item = s.item as BuildableItemData
		if item:
			# Иконка
			if item.texture:
				var icon_size = Vector2(40, 40)
				draw_texture_rect(item.texture, Rect2(icon_pos - icon_size / 2.0, icon_size), false)
			
			# Название
			var font = ThemeDB.fallback_font
			var font_size = 13
			var text_pos = icon_pos + Vector2(0, 28)
			draw_string(font, text_pos - Vector2(font.get_string_size(item.name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x / 2.0, 0), item.name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE if not is_hovered else Color(0.6, 1.0, 0.6))
	
	# Внутренний круг
	draw_circle(_center, _inner_radius * 0.5, Color(0.08, 0.08, 0.08, 0.9))
	draw_arc(_center, _inner_radius * 0.5, 0, TAU, 32, Color(0.4, 0.4, 0.4, 0.5), 1.5)

func _build_sector_polygon(from_angle: float, to_angle: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var steps = 16  # плавность дуги
	
	# Внутренняя дуга (от to к from чтобы обойти по часовой)
	for i in range(steps + 1):
		var t = float(i) / steps
		var angle = lerp(from_angle, to_angle, t)
		points.append(_center + Vector2(cos(angle), sin(angle)) * (_inner_radius + 4.0))
	
	# Внешняя дуга (от to к from в обратную сторону)
	for i in range(steps + 1):
		var t = float(i) / steps
		var angle = lerp(to_angle, from_angle, t)
		points.append(_center + Vector2(cos(angle), sin(angle)) * (_outer_radius - 4.0))
	
	return points

# Возвращает выбранный элемент или null
func get_selected() -> BuildableItemData:
	if _hovered_index >= 0 and _hovered_index < _items.size():
		return _items[_hovered_index]
	return null
