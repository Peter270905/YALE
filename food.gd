@tool
extends EditorScript

# ← СЛОВАРЬ: имя_файла → [название, голод]
var FOOD_DATA = {
	# Ягоды (+0.25)
	"blackberry": ["Горсть ежевики", 0.25],
	"blueberry": ["Горсть черники", 0.25],
	"strawberry": ["Горсть клубники", 0.25],
	"raspberry": ["Горсть малины", 0.25],
	"cranberry": ["Горсть клюквы", 0.25],
	"elderberry": ["Горсть бузины", 0.25],
	"cloudberry": ["Горсть морошки", 0.25],
	"snowberry": ["Горсть снежноягодника", 0.25],
	"gooseberry": ["Горсть крыжовника", 0.25],
	"bunchberry": ["Горсть грушанки", 0.25],
	"wintergreen_berry": ["Горсть грушанки", 0.25],
	
	# Фрукты (+1.0)
	"fruit_apple": ["Яблоко", 1.0],
	"green_apple": ["Зелёное яблоко", 1.0],
	"red_apple": ["Красное яблоко", 1.0],
	"banana": ["Банан", 1.0],
	"cherry": ["Вишня", 1.0],
	"lemon": ["Лимон", 1.0],
	"orange": ["Апельсин", 1.0],
	"peach": ["Персик", 1.0],
	"plum": ["Слива", 1.0],
	"melon": ["Дыня", 1.0],
	"melon_slice": ["Ломтик дыни", 0.5],
	
	# Овощи сырые (+1.0)
	"carrot": ["Морковь", 1.0],
	"potato": ["Картофель", 1.0],
	"baked_potato": ["Печёный картофель", 2.5],
	"beet": ["Свёкла", 1.0],
	"cabbage": ["Капуста", 1.0],
	"tomato": ["Помидор", 1.0],
	"pumpkin": ["Тыква", 1.0],
	"pumpkin_chunks": ["Кусочки тыквы", 2.5],
	"squash": ["Кабачок", 1.0],
	"onion": ["Лук", 1.0],
	"garlic": ["Чеснок", 1.0],
	"green_bean": ["Зелёная фасоль", 1.0],
	"green_bell_pepper": ["Зелёный перец", 1.0],
	"red_bell_pepper": ["Красный перец", 1.0],
	"yellow_bell_pepper": ["Жёлтый перец", 1.0],
	"cattail_root": ["Корень рогоза", 1.0],
	"taro_root": ["Корень таро", 1.0],
	
	# Зерно сырое (+0.5)
	"wheat": ["Пшеница", 0.5],
	"rye": ["Рожь", 0.5],
	"oat": ["Овёс", 0.5],
	"barley": ["Ячмень", 0.5],
	"maize": ["Кукуруза", 0.5],
	"rice": ["Рис", 0.5],
	"soybean": ["Соя", 0.5],
	"wheat_grain": ["Зерно пшеницы", 0.5],
	"rye_grain": ["Зерно ржи", 0.5],
	"oat_grain": ["Зерно овса", 0.5],
	"barley_grain": ["Зерно ячменя", 0.5],
	"maize_grain": ["Зерно кукурузы", 0.5],
	"rice_grain": ["Зерно риса", 0.5],
	
	# Мука/Тесто (+1.0)
	"wheat_flour": ["Пшеничная мука", 1.0],
	"wheat_dough": ["Пшеничное тесто", 1.0],
	"rye_flour": ["Ржаная мука", 1.0],
	"rye_dough": ["Ржаное тесто", 1.0],
	"oat_flour": ["Овсяная мука", 1.0],
	"oat_dough": ["Овсяное тесто", 1.0],
	"barley_flour": ["Ячменная мука", 1.0],
	"barley_dough": ["Ячменное тесто", 1.0],
	"maize_flour": ["Кукурузная мука", 1.0],
	"maize_dough": ["Кукурузное тесто", 1.0],
	"rice_flour": ["Рисовая мука", 1.0],
	"rice_dough": ["Рисовое тесто", 1.0],
	
	# Хлеб (+2.0)
	"wheat_bread": ["Пшеничный хлеб", 2.0],
	"rye_bread": ["Ржаной хлеб", 2.0],
	"oat_bread": ["Овсяный хлеб", 2.0],
	"barley_bread": ["Ячменный хлеб", 2.0],
	"maize_bread": ["Кукурузный хлеб", 2.0],
	"rice_bread": ["Рисовый хлеб", 2.0],
	
	# Бутерброды (+3.0)
	"wheat_bread_sandwich": ["Пшеничный бутерброд", 3.0],
	"rye_bread_sandwich": ["Ржаной бутерброд", 3.0],
	"oat_bread_sandwich": ["Овсяный бутерброд", 3.0],
	"barley_bread_sandwich": ["Ячменный бутерброд", 3.0],
	"maize_bread_sandwich": ["Кукурузный бутерброд", 3.0],
	"rice_bread_sandwich": ["Рисовый бутерброд", 3.0],
	"wheat_bread_jam_sandwich": ["Пшеничный бутерброд с джемом", 3.0],
	"rye_bread_jam_sandwich": ["Ржаной бутерброд с джемом", 3.0],
	"oat_bread_jam_sandwich": ["Овсяный бутерброд с джемом", 3.0],
	"barley_bread_jam_sandwich": ["Ячменный бутерброд с джемом", 3.0],
	"maize_bread_jam_sandwich": ["Кукурузный бутерброд с джемом", 3.0],
	"rice_bread_jam_sandwich": ["Рисовый бутерброд с джемом", 3.0],
	
	# Салаты (+3.5)
	"fruit_salad": ["Фруктовый салат", 3.5],
	"vegetables_salad": ["Овощной салат", 3.5],
	"grain_salad": ["Зерновой салат", 3.5],
	"protein_salad": ["Белковый салат", 3.5],
	"dairy_salad": ["Молочный салат", 3.5],
	
	# Супы (+4.0)
	"fruit_soup": ["Фруктовый суп", 4.0],
	"vegetables_soup": ["Овощной суп", 4.0],
	"grain_soup": ["Зерновой суп", 4.0],
	"protein_soup": ["Белковый суп", 4.0],
	"dairy_soup": ["Молочный суп", 4.0],
	
	# Сырое мясо базовое (+1.0)
	"beef": ["Сырая говядина", 1.0],
	"pork": ["Сырая свинина", 1.0],
	"mutton": ["Сырая баранина", 1.0],
	"venison": ["Сырая оленина", 1.0],
	"bear": ["Сырое медвежье мясо", 1.5],
	"horse_meat": ["Сырая конина", 1.0],
	"hyena": ["Сырое мясо гиены", 1.0],
	"camelidae": ["Сырое мясо верблюда", 1.0],
	"gran_feline": ["Сырое мясо гран-фелина", 1.0],
	"grouse": ["Сырое мясо глухаря", 1.0],
	"pheasant": ["Сырое мясо фазана", 1.0],
	"peafowl": ["Сырое мясо павлина", 1.0],
	"turtle": ["Сырое мясо черепахи", 1.5],
	"frog_legs": ["Сырые лягушачьи лапки", 1.5],
	
	# Сырое мясо уникальных мобов (+1.0...1.5)
	"frigebis_meat_raw": ["Сырое мясо фригебиса", 1.5],
	"skrofus_meat": ["Сырое мясо скрофуса", 1.0],
	"yalemeatraw": ["Сырое мясо йалля", 1.5],
	"makameatraw": ["Сырое мака мясо", 1.5],
	"Gallat_raw_meat": ["Сырое мясо галлата", 1.0],
	
	# Приготовленное мясо базовое (+2.5)
	"cooked_beef": ["Жареная говядина", 2.5],
	"cooked_pork": ["Жареная свинина", 2.5],
	"cooked_mutton": ["Жареная баранина", 2.5],
	"cooked_venison": ["Жареная оленина", 2.5],
	"cooked_bear": ["Жареное медвежье мясо", 3.0],
	"cooked_horse_meat": ["Жареная конина", 2.5],
	"cooked_hyena": ["Жареное мясо гиены", 2.5],
	"cooked_gran_feline": ["Жареное мясо гран-фелина", 3.0],
	"cooked_grouse": ["Жареное мясо глухаря", 2.5],
	"cooked_pheasant": ["Жареное мясо фазана", 2.5],
	"cooked_peafowl": ["Жареное мясо павлина", 2.5],
	"cooked_turtle": ["Жареное мясо черепахи", 2.5],
	"cooked_frog_legs": ["Жареные лягушачьи лапки", 2.5],
	"boiled_egg": ["Варёное яйцо", 2.0],
	"cooked_egg": ["Жареное яйцо", 2.0],
	
	# Приготовленное мясо уникальных мобов (+3.0...4.0)
	"frigebis_meat_cooked": ["Приготовленное мясо фригебиса", 4.0],
	"skrofus_meat_coocked": ["Приготовленное мясо скрофуса", 4.0],
	"yalemeatcooked": ["Приготовленное мясо йалля", 3.0],
	"makameatcooked": ["Приготовленное мака мясо", 3.0],
	"Gallat_coocked_meat": ["Приготовленное мясо галлата", 3.0],
	
	# Сырая рыба (+1.5)
	"cod": ["Сырая треска", 1.5],
	"salmon": ["Сырой лосось", 1.5],
	"lake_trout": ["Сырая озёрная форель", 1.5],
	"rainbow_trout": ["Сырая радужная форель", 1.5],
	"largemouth_bass": ["Сырой большеротый окунь", 1.5],
	"smallmouth_bass": ["Сырой малоротый окунь", 1.5],
	"bluegill": ["Сырая синежаберная рыба", 1.5],
	"crappie": ["Сырая краппи", 1.5],
	"tropical_fish": ["Сырая тропическая рыба", 1.5],
	
	# Приготовленная рыба (+2.5)
	"cooked_cod": ["Жареная треска", 2.5],
	"cooked_salmon": ["Жареный лосось", 2.5],
	"cooked_lake_trout": ["Жареная озёрная форель", 2.5],
	"cooked_rainbow_trout": ["Жареная радужная форель", 2.5],
	"cooked_largemouth_bass": ["Жареный большеротый окунь", 2.5],
	"cooked_smallmouth_bass": ["Жареный малоротый окунь", 2.5],
	"cooked_bluegill": ["Жареная синежаберная рыба", 2.5],
	"cooked_crappie": ["Жареная краппи", 2.5],
	"cooked_tropical_fish": ["Жареная тропическая рыба", 2.5],
	
	# Морепродукты сырые (+1.5)
	"calamari": ["Сырой кальмар", 1.5],
	"shellfish": ["Сырые моллюски", 1.5],
	
	# Морепродукты приготовленные (+2.5)
	"cooked_calamari": ["Жареный кальмар", 2.5],
	"cooked_shellfish": ["Жареные моллюски", 2.5],
	
	# Прочее
	"cheese": ["Сыр", 2.0],
	"dried_kelp": ["Сушёная ламинарь", 1.0],
	"dried_seaweed": ["Сушёные водоросли", 1.0],
	"fresh_seaweed": ["Свежие водоросли", 0.5],
	"sugarcane": ["Сахарный тростник", 0.5],
	"olive": ["Оливки", 1.0],
	"wooden_bucket_empty_full_milkt": ["Ведро молока", 2.0],
	"cooked_rice": ["Приготовленный рис", 2.0],
}

func _run() -> void:
	print("\n========================================")
	print("🍽️ АВТОГЕНЕРАЦИЯ ЕДЫ НАЧАТА")
	print("========================================\n")
	
	var created_count = 0
	var skipped_count = 0
	var error_count = 0
	
	# ← Сканируем папку с текстурами
	var texture_folder = "res://assets/items/food/"
	var dir = DirAccess.open(texture_folder)
	
	if not dir:
		print("❌ Не удалось открыть папку: ", texture_folder)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".png"):
			var item_key = file_name.get_basename()  # Убираем .png
			
			if FOOD_DATA.has(item_key):
				var result = _create_food_item(item_key, texture_folder)
				if result:
					created_count += 1
					print("✅ Создано: %s.tres" % item_key)
				else:
					error_count += 1
					print("❌ Ошибка при создании: %s.tres" % item_key)
			else:
				skipped_count += 1
				print("⚠️ Пропущено (нет в FOOD_DATA): %s" % item_key)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	print("\n========================================")
	print("📊 ИТОГИ:")
	print("✅ Создано: %d предметов" % created_count)
	print("⚠️ Пропущено: %d предметов" % skipped_count)
	print("❌ Ошибок: %d" % error_count)
	print("========================================\n")

func _create_food_item(item_key: String, texture_folder: String) -> bool:
	var data = FOOD_DATA[item_key]
	var item_name = data[0]
	var hunger_value = data[1]
	
	# ← Создаём ItemConsumable
	var item = ItemConsumable.new()
	item.name = item_name
	item.hunger_restore = hunger_value
	item.item_type = "Еда"
	item.item_category = "food"
	
	# ← Устанавливаем текстуру
	var texture_path = texture_folder + item_key + ".png"
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		# Здесь можно добавить текстуру в item, если нужно
	
	# ← Сохраняем как .tres файл
	var save_path = "res://items/food/%s.tres" % item_key
	var err = ResourceSaver.save(item, save_path)
	
	if err == OK:
		return true
	else:
		print("   Ошибка сохранения: ", err)
		return false
