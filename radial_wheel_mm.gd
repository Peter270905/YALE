@tool
extends Control

@onready var menu_items = $MenuItems

var menu_options = ["Выйти", "Настройки", "Мультиплеер", "Соло"]
var buttons = []
var is_open = false

func _ready():
	create_center_button()
	create_menu_buttons()

# ================= CENTER =================

func create_center_button():
	var container = Control.new()
	container.name = "Center"
	container.custom_minimum_size = Vector2(110, 110)
	container.position = size / 2 - container.custom_minimum_size / 2
	add_child(container)
	
	# ФОН ДЛЯ ЦЕНТРАЛЬНОЙ КНОПКИ С ГРАНИЦЕЙ
	var bg = create_background_panel(Vector2(110, 110), true)
	container.add_child(bg)
	
	# ПРОЗРАЧНАЯ КНОПКА
	var btn = Button.new()
	btn.text = "ЖМИ"
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.anchor_left = 0.5
	btn.anchor_top = 0.5
	btn.anchor_right = 0.5
	btn.anchor_bottom = 0.5
	btn.offset_left = -40
	btn.offset_right = 40
	btn.offset_top = -15
	btn.offset_bottom = 15
	btn.add_theme_font_size_override("font_size", 20)
	
	# ДЕЛАЕМ КНОПКУ ПРОЗРАЧНОЙ
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	
	container.add_child(btn)
	btn.pressed.connect(toggle_menu)
	
	# АНИМАЦИЯ ФОНА (не кнопки)
	animate_background(bg, btn)

# ================= ITEMS =================

func create_menu_buttons():
	for i in menu_options.size():
		var container = Control.new()
		container.custom_minimum_size = Vector2(140, 60)
		container.visible = false
		container.modulate = Color(1, 1, 1, 0)
		menu_items.add_child(container)
		
		# ФОН ДЛЯ КНОПКИ МЕНЮ С ГРАНИЦЕЙ
		var bg = create_background_panel(Vector2(140, 60), false)
		container.add_child(bg)
		
		# ПРОЗРАЧНАЯ КНОПКА
		var btn = Button.new()
		btn.text = menu_options[i]
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.anchor_left = 0.5
		btn.anchor_top = 0.5
		btn.anchor_right = 0.5
		btn.anchor_bottom = 0.5
		btn.offset_left = -50
		btn.offset_right = 50
		btn.offset_top = -12
		btn.offset_bottom = 12
		btn.add_theme_font_size_override("font_size", 18)
		
		# ПРОЗРАЧНАЯ КНОПКА
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		
		container.add_child(btn)
		btn.pressed.connect(on_menu_pressed.bind(i))
		buttons.append(container)
		
		# АНИМАЦИЯ ФОНА
		animate_background(bg, btn)

# ================= BACKGROUND WITH BORDER =================

func create_background_panel(size, is_center = false):
	var container = Control.new()
	container.custom_minimum_size = size
	
	# ОСНОВНОЙ ФОН
	var bg = TextureRect.new()
	bg.custom_minimum_size = size
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture = generate_background_texture(size.x, size.y, is_center)
	container.add_child(bg)
	
	# ГРАНИЦА (отдельный слой поверх фона)
	var border = TextureRect.new()
	border.custom_minimum_size = size
	border.stretch_mode = TextureRect.STRETCH_SCALE
	border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# СОЗДАЁМ ТЕКСТУРУ ГРАНИЦЫ
	border.texture = generate_border_texture(size.x, size.y, is_center)
	container.add_child(border)
	
	return container

func generate_border_texture(width, height, is_center):
	var img = Image.create(int(width), int(height), false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var border_size = 1  # Толщина границы в пикселях
	
	# РИСУЕМ ГРАНИЦУ
	for y in height:
		for x in width:
			if (x < border_size || x >= width - border_size || 
				y < border_size || y >= height - border_size):
				# Цвет границы (тёмный с лёгким свечением)
				var border_color = Color(0.3, 0.3, 0.4, 0.8)
				if is_center:
					border_color = Color(0.4, 0.4, 0.5, 0.9)  # Центр ярче
				img.set_pixel(x, y, border_color)
	
	return ImageTexture.create_from_image(img)

func generate_background_texture(width, height, is_center):
	var img = Image.create(int(width), int(height), false, Image.FORMAT_RGBA8)
	
	# ГРАДИЕНТ (как в твоём фоне)
	for y in height:
		var t = float(y) / height
		var base_color = Color(0.12, 0.12, 0.18)
		var end_color = Color(0.08, 0.08, 0.12)
		if is_center:
			base_color = Color(0.15, 0.15, 0.22)
			end_color = Color(0.1, 0.1, 0.15)
		var color = base_color.lerp(end_color, t)
		for x in width:
			img.set_pixel(x, y, color)
	
	# ШУМ (как в твоём фоне)
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.005 if is_center else 0.008  # Мягкий шум
	
	for y in height:
		for x in width:
			var n = noise.get_noise_2d(x, y)
			var current_color = img.get_pixel(x, y)
			var final_color = current_color.lightened(n * 0.08)
			img.set_pixel(x, y, final_color)
	
	return ImageTexture.create_from_image(img)

func animate_background(bg, btn):
	# bg здесь это container с фоном и границей
	var background_rect = bg.get_child(0)  # Основной фон
	var border_rect = bg.get_child(1)      # Граница
	
	btn.mouse_entered.connect(func():
		background_rect.modulate = Color(1.0, 1.0, 1.0, 0.95)
		border_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Граница ярче при наведении
		bg.scale = Vector2(1.03, 1.03)
	)
	
	btn.mouse_exited.connect(func():
		background_rect.modulate = Color.WHITE
		border_rect.modulate = Color(1.0, 1.0, 1.0, 0.8)  # Обычная прозрачность границы
		bg.scale = Vector2.ONE
	)

# ================= MENU =================

func toggle_menu():
	if is_open:
		close_menu()
	else:
		open_menu()

func open_menu():
	if is_open: return
	is_open = true
	
	var center = size / 2
	
	for i in buttons.size():
		var item = buttons[i]
		item.visible = true
		item.modulate = Color(1, 1, 1, 0)
		item.position = center - item.size / 2
		
		await get_tree().process_frame
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		# РАДИАЛЬНАЯ АНИМАЦИЯ ОТКРЫТИЯ
		var angle = TAU * float(i) / buttons.size()
		var target_pos = center + Vector2(180, 0).rotated(angle) - item.size / 2
		
		tween.tween_property(item, "position", target_pos, 0.4)\
			 .set_trans(Tween.TRANS_BACK)\
			 .set_ease(Tween.EASE_OUT)
		
		tween.tween_property(item, "modulate", Color.WHITE, 0.4)

func close_menu():
	if not is_open: return
	is_open = false
	
	var center = size / 2
	
	for i in buttons.size():
		var item = buttons[i]
		var tween = create_tween()
		tween.set_parallel(true)
		
		# РАДИАЛЬНАЯ АНИМАЦИЯ ЗАКРЫТИЯ (обратная траектория)
		var angle = TAU * float(i) / buttons.size()
		var start_pos = item.position
		var target_pos = center - item.size / 2  # Центр
		
		tween.tween_method(
			func(pos): item.position = pos,
			start_pos,
			target_pos,
			0.35
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
		tween.tween_property(item, "modulate", Color(1, 1, 1, 0), 0.35)
		
		tween.tween_callback(func(): item.visible = false)

func on_menu_pressed(i):
	match i:
		0: get_tree().quit()
		1: print("Settings")
		2: print("Multiplayer")
		3: get_tree().change_scene_to_file("res://scenes/ui/mainmenu/WorldSelect.tscn")
