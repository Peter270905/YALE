extends Control

@onready var carousel_container = $Control2/CarouselContainer

const WORLDS_SAVE_FILE = "user://worlds.json"
var worlds = []
var current_index = 0
var is_dragging = false
var drag_start_pos = Vector2.ZERO

const WORLD_WIDTH = 320
const WORLD_HEIGHT = 400
const VISIBLE_CARDS = 3

func _ready():
	load_worlds()
	setup_carousel()

func load_worlds():
	if ResourceLoader.exists(WORLDS_SAVE_FILE):
		var file = FileAccess.open(WORLDS_SAVE_FILE, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var parsed = JSON.parse_string(json_text)
			if parsed is Array:
				worlds = parsed
			file.close()
	
	if worlds.is_empty():
		worlds = [
			{ "name": "Тестовая сцена", "date": "СЕГОДНЯ", "is_test": true }
		]
		save_worlds()

func save_worlds():
	var file = FileAccess.open(WORLDS_SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(worlds, "\t"))
		file.close()

func setup_carousel():
	for child in carousel_container.get_children():
		child.queue_free()
	
	var back_card = create_back_card()
	back_card.position = Vector2(0, 0)
	carousel_container.add_child(back_card)
	
	for i in range(worlds.size()):
		var world_card = create_world_card(worlds[i])
		world_card.position = Vector2((i + 1) * WORLD_WIDTH, 0)
		carousel_container.add_child(world_card)
	
	var create_card = create_create_card()
	create_card.position = Vector2((worlds.size() + 1) * WORLD_WIDTH, 0)
	carousel_container.add_child(create_card)
	
	current_index = 1
	update_carousel_position()

func create_back_card():
	var container = Control.new()
	container.custom_minimum_size = Vector2(WORLD_WIDTH, WORLD_HEIGHT)
	
	var btn = Button.new()
	btn.text = "← НАЗАД"
	btn.custom_minimum_size = Vector2(WORLD_WIDTH - 40, 60)
	btn.position = Vector2(20, WORLD_HEIGHT / 2 - 30)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(_on_back_pressed)
	container.add_child(btn)
	
	return container

func create_create_card():
	var container = Control.new()
	container.custom_minimum_size = Vector2(WORLD_WIDTH, WORLD_HEIGHT)
	
	var btn = Button.new()
	btn.text = "+ СОЗДАТЬ\nНОВЫЙ МИР"
	btn.custom_minimum_size = Vector2(WORLD_WIDTH - 40, 80)
	btn.position = Vector2(20, WORLD_HEIGHT / 2 - 40)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(_on_create_world_pressed)
	container.add_child(btn)
	
	return container

func _on_create_world_pressed():
	var create_scene = preload("res://scenes/ui/mainmenu/CreateWorld.tscn")
	var create_instance = create_scene.instantiate()
	add_child(create_instance)
	create_instance.show()

func add_new_world(world_data):
	worlds.append(world_data)
	setup_carousel()
	save_worlds()

func create_world_card(world):
	var container = Control.new()
	container.custom_minimum_size = Vector2(WORLD_WIDTH, WORLD_HEIGHT)
	
	# КЛИКАБЕЛЬНЫЙ КОНТЕЙНЕР ДЛЯ ПРЕВЬЮ
	var preview_container = Control.new()
	preview_container.custom_minimum_size = Vector2(WORLD_WIDTH - 20, WORLD_WIDTH - 20)
	preview_container.position = Vector2(10, 10)
	
	var preview_rect = TextureRect.new()
	preview_rect.custom_minimum_size = Vector2(WORLD_WIDTH - 20, WORLD_WIDTH - 20)
	preview_rect.stretch_mode = TextureRect.STRETCH_SCALE
	preview_rect.texture = generate_test_preview()  # Тестовая текстура для проверки
	preview_container.add_child(preview_rect)
	
	# ГЕНЕРИРУЕМ ПРЕВЬЮ ДИНАМИЧЕСКИ
	if world.has("seed"):
		var seed_int = 0
		
		# БЕЗОПАСНОЕ ПРЕОБРАЗОВАНИЕ СТРОКИ В ЧИСЛО
		if world.seed is String:
			var clean_seed = ""
			for char in world.seed:
				if char in "0123456789-":
					clean_seed += char
			if clean_seed != "" and clean_seed != "-":
				seed_int = int(clean_seed)
			else:
				seed_int = randi()
		else:
			seed_int = int(world.seed)
		
		# ГЕНЕРИРУЕМ И УСТАНАВЛИВАЕМ ТЕКСТУРУ
		var preview_texture = generate_world_preview(seed_int)
		if preview_texture:
			preview_rect.texture = preview_texture
		else:
			print("❌ Ошибка генерации превью для seed: ", seed_int)
	
	# ОБРАБОТКА КЛИКА ПО ВСЕМУ ПРЕВЬЮ
	preview_container.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_world_selected(world)
	)
	
	container.add_child(preview_container)
	
	# НАЗВАНИЕ (тоже кликабельное для подстраховки)
	var name_label = Button.new()
	name_label.text = world.name
	name_label.custom_minimum_size = Vector2(WORLD_WIDTH - 20, 25)
	name_label.position = Vector2(10, WORLD_WIDTH - 20 + 20)
	name_label.flat = true
	name_label.focus_mode = Control.FOCUS_NONE
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	name_label.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	name_label.pressed.connect(func(): _on_world_selected(world))
	container.add_child(name_label)
	
	# ДАТА
	var date_label = Label.new()
	if world.has("date"):
		date_label.text = str(world.date)
	else:
		date_label.text = "Без даты"
	date_label.add_theme_font_size_override("font_size", 14)
	date_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	date_label.position = Vector2(10, WORLD_WIDTH - 20 + 45)
	container.add_child(date_label)
	
	# КНОПКА УДАЛЕНИЯ
	if not (world.has("is_test") and world.is_test):
		var delete_btn = Button.new()
		delete_btn.text = "×"
		delete_btn.custom_minimum_size = Vector2(30, 30)
		delete_btn.position = Vector2(WORLD_WIDTH - 40, 15)
		delete_btn.add_theme_font_size_override("font_size", 20)
		delete_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		delete_btn.pressed.connect(func(): _on_delete_world(world))
		container.add_child(delete_btn)
	
	return container

# ТЕСТОВАЯ ФУНКЦИЯ ДЛЯ ПРОВЕРКИ ОТОБРАЖЕНИЯ
func generate_test_preview():
	var img = Image.create(300, 300, false, Image.FORMAT_RGBA8)
	# Простой цветной градиент для проверки
	for y in range(300):
		for x in range(300):
			var r = x / 300.0
			var g = y / 300.0
			var b = 0.5
			img.set_pixel(x, y, Color(r, g, b, 1.0))
	return ImageTexture.create_from_image(img)

func generate_world_preview(seed):
	var img = Image.create(300, 300, false, Image.FORMAT_RGBA8)
	
	var noise = FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.015
	noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	
	var detail_noise = FastNoiseLite.new()
	detail_noise.seed = seed * 2
	detail_noise.frequency = 0.05
	detail_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	
	var biome_noise = FastNoiseLite.new()
	biome_noise.seed = seed * 3
	biome_noise.frequency = 0.008
	biome_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	
	for y in range(300):
		for x in range(300):
			var nx = x / 300.0 - 0.5
			var ny = y / 300.0 - 0.5
			var dist = sqrt(nx*nx + ny*ny) * 2.0
			
			var base_height = noise.get_noise_2d(x * 0.02, y * 0.02) * 0.5 + 0.5
			var detail = detail_noise.get_noise_2d(x * 0.1, y * 0.1) * 0.2
			var biome = biome_noise.get_noise_2d(x * 0.01, y * 0.01) * 0.5 + 0.5
			
			var height = base_height + detail
			height = height * (1.0 - dist * 0.3)
			
			var color = Color()
			
			# ВОДА
			if height < 0.3:
				var depth = 1.0 - (height / 0.3)
				color = Color(0.1, 0.15, 0.3).lerp(Color(0.15, 0.25, 0.45), depth)
				if height > 0.28:
					color = color.lerp(Color(0.4, 0.5, 0.8), 0.3)
			
			# ПОБЕРЕЖЬЕ
			elif height < 0.35:
				color = Color(0.35, 0.3, 0.25)
			
			# РАВНИНЫ
			elif height < 0.6:
				if biome > 0.7:  # Пустыня
					color = Color(0.85, 0.75, 0.4).lerp(Color(0.6, 0.5, 0.3), height)
				elif biome > 0.4:  # Лес
					color = Color(0.1, 0.25, 0.1).lerp(Color(0.3, 0.45, 0.25), height)
				else:  # Тундра
					color = Color(0.9, 0.95, 1.0).lerp(Color(0.6, 0.7, 0.8), height)
			
			# ГОРЫ
			else:
				var snow = (height - 0.6) / 0.4
				color = Color(0.5, 0.45, 0.4).lerp(Color(1.0, 1.0, 1.0), snow)
			
			# ДОБАВЛЯЕМ ТЕНИ
			var shadow = noise.get_noise_2d(x * 0.2, y * 0.2) * 0.15
			color = color.darkened(abs(shadow))
			
			# СГЛАЖИВАНИЕ КРАЕВ
			if dist > 0.9:
				var fade = (1.0 - dist) * 10.0
				color = color.lerp(Color(0.1, 0.1, 0.15), fade)
			
			img.set_pixel(x, y, color)
	
	# ЗОЛОТАЯ РАМКА
	for i in range(3):
		for x in range(300):
			img.set_pixel(x, i, Color(1.0, 0.84, 0.0))
			img.set_pixel(x, 299 - i, Color(1.0, 0.84, 0.0))
		for y in range(300):
			img.set_pixel(i, y, Color(1.0, 0.84, 0.0))
			img.set_pixel(299 - i, y, Color(1.0, 0.84, 0.0))
	
	return ImageTexture.create_from_image(img)

func update_carousel_position():
	var target_x = -current_index * WORLD_WIDTH + (size.x - WORLD_WIDTH) / 2
	carousel_container.position.x = target_x
	hide_offscreen_cards()

func hide_offscreen_cards():
	var screen_left = -carousel_container.position.x
	var screen_right = screen_left + size.x
	
	for i in range(carousel_container.get_child_count()):
		var card = carousel_container.get_child(i)
		var card_left = card.position.x
		var card_right = card_left + WORLD_WIDTH
		
		if card_right > screen_left and card_left < screen_right:
			card.visible = true
		else:
			card.visible = false

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			prev_card()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			next_card()
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = true
			drag_start_pos = get_global_mouse_position()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = false
			var drag_end_pos = get_global_mouse_position()
			var drag_distance = drag_end_pos.x - drag_start_pos.x
			
			if drag_distance > 50:
				prev_card()
			elif drag_distance < -50:
				next_card()

func next_card():
	if current_index < carousel_container.get_child_count() - 1:
		current_index += 1
		update_carousel_position()

func prev_card():
	if current_index > 0:
		current_index -= 1
		update_carousel_position()

func _on_world_selected(world):
	var game_scene = preload("res://scenes/gen/world/World.tscn").instantiate()
	
	# ИСПРАВЛЕНО: путь к ноде "World" вместо "WorldGenerator"
	var world_gen_node = game_scene.get_node("World")
	if world_gen_node == null:
		print("❌ Ошибка: нода 'World' не найдена в сцене Game!")
		return
	
	if world.has("is_test") and world.is_test:
		world_gen_node.WorldSeed = 0
	else:
		var seed_int = 0
		if world.seed is String:
			var clean_seed = ""
			for char in world.seed:
				if char in "0123456789-":
					clean_seed += char
			if clean_seed != "":
				seed_int = int(clean_seed)
			else:
				seed_int = randi()
		else:
			seed_int = int(world.seed)
		
		world_gen_node.WorldSeed = seed_int
	
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(game_scene)

func _on_delete_world(world):
	for i in range(worlds.size()):
		if worlds[i].name == world.name:
			worlds.remove_at(i)
			setup_carousel()
			save_worlds()
			break

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/mainmenu/MAINMENU.tscn")
