extends Control

@onready var name_input = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/NameInput
@onready var seed_input = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SeedInput

func _ready():
	seed_input.text = str(randi() % 1000000)
	if name_input.text == "":
		name_input.text = "Мир " + str(get_parent().worlds.size() + 1)

func _on_cancel_btn_pressed() -> void:
	hide()

func _on_create_btn_pressed() -> void:
	if name_input.text.strip_edges() == "":
		return
	
	var now = Time.get_datetime_dict_from_system()
	var date_str = "%02d.%02d.%04d" % [now.day, now.month, now.year]
	
	var new_world = {
		"name": name_input.text,
		"date": date_str
	}
	
	# ГЕНЕРИРУЕМ SEED И СОХРАНЯЕМ КАК СТРОКУ
	var seed_str = seed_input.text.strip_edges() if seed_input.text != "" else str(randi() % 1000000)
	
	# ОЧИЩАЕМ СТРОКУ ОТ НЕЦИФРОВЫХ СИМВОЛОВ
	var clean_seed = ""
	for i in range(seed_str.length()):
		var char = seed_str[i]
		if (i == 0 and char == '-') or (char >= '0' and char <= '9'):
			clean_seed += char
	
	if clean_seed == "" or clean_seed == "-":
		clean_seed = str(randi() % 1000000)
	
	# СОХРАНЯЕМ SEED КАК СТРОКУ (это важно для JSON)
	new_world.seed = clean_seed
	
	# ДОБАВЛЯЕМ МИР
	var world_select = get_tree().current_scene
	if world_select and world_select.has_method("add_new_world"):
		world_select.add_new_world(new_world)
	
	hide()

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
			height = height * (1.0 - dist * 0.3)  # Приглушаем края
			
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
