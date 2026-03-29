@tool
extends TextureRect

const BG_CACHE_FILE = "user://main_menu_bg.res"

func _ready():
	load_or_generate_background()
	
	if material == null:
		material = ShaderMaterial.new()
	
	var shader = load("res://scripts/UI/MAINMENU/BG_shager.gdshader")
	material.shader = shader

func load_or_generate_background():
	# Проверяем, есть ли сохранённый фон
	if ResourceLoader.exists(BG_CACHE_FILE):
		# Загружаем существующий файл
		texture = ResourceLoader.load(BG_CACHE_FILE)
	else:
		# Генерируем и сохраняем
		generate_and_save_background()

func generate_and_save_background():
	var width = 1920
	var height = 1080
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Градиент
	for y in height:
		var t = float(y) / height
		var color = Color(0.15, 0.15, 0.2).lerp(Color(0.05, 0.05, 0.1), t)
		for x in width:
			img.set_pixel(x, y, color)
	
	# Шум
	var noise = FastNoiseLite.new()
	noise.seed = 1337
	noise.frequency = 0.002
	
	for y in height:
		for x in width:
			var n = noise.get_noise_2d(x, y)
			var current_color = img.get_pixel(x, y)
			var final_color = current_color.lightened(n * 0.05)
			img.set_pixel(x, y, final_color)
	
	# Создаём текстуру
	var bg_texture = ImageTexture.create_from_image(img)
	texture = bg_texture
	
	# Сохраняем как ресурс Godot
	ResourceSaver.save(bg_texture, BG_CACHE_FILE)
