extends Resource
class_name GemGenerator

@export var icons: Array[Texture2D] = []
@export var rng_seed: int = 0
@export var min_stats_count: int = 1
@export var max_stats_count: int = 5

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Базовые диапазоны характеристик для разных уровней
var base_stat_ranges: Dictionary = {
	GemData.StatType.HEALTH: {"min": 1, "max": 15, "scale": 5},
	GemData.StatType.MANA: {"min": 10, "max": 120, "scale": 3},
	GemData.StatType.LUCK: {"min": 1, "max": 5, "scale": 1},
	GemData.StatType.HP_REGEN: {"min": 1, "max": 3, "scale": 1},
	GemData.StatType.ATTACK_SPEED: {"min": 5, "max": 15, "scale": 5},
	GemData.StatType.DEFENSE: {"min": 1, "max": 8, "scale": 2},
	GemData.StatType.ALL_STATS: {"min": 1, "max": 40, "scale": 1},
	GemData.StatType.SPEED: {"min": 1, "max": 5, "scale": 1},
	GemData.StatType.STAMINA: {"min": 5, "max": 20, "scale": 5},
	GemData.StatType.SANITY: {"min": 3, "max": 12, "scale": 3},
	GemData.StatType.SPELL_DAMAGE: {"min": 2, "max": 10, "scale": 2},
	GemData.StatType.ARROW_DAMAGE: {"min": 2, "max": 10, "scale": 2},
	GemData.StatType.SWORD_DAMAGE: {"min": 2, "max": 10, "scale": 2},
	GemData.StatType.CRITICAL_CHANSE_DAMAGE:{"min": 4, "max": 30, "scale": 5}
}

var percent_stats: Array = [GemData.StatType.ATTACK_SPEED, GemData.StatType.ALL_STATS, GemData.StatType.CRITICAL_CHANSE_DAMAGE]

# Шансы для каждого дополнительного свойства
var stat_count_chances: Dictionary = {
	1: 1.0,    # 100% - минимум 1 свойство
	2: 0.8,    # 80% 
	3: 0.5,    # 50%
	4: 0.3,    # 30%
	5: 0.15    # 15%
}

func _init():
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

# Главная функция генерации
func generate_gem(level: int = 1, category = null) -> GemData:
	var gem = GemData.new()
	
	# Ограничим уровень 1..4
	level = clamp(level, 1, 4)
	gem.level = level
	
	# Выбираем случайную категорию если не указана
	if category == null:
		var categories = GemData.GemCategory.values()
		category = categories[rng.randi_range(0, categories.size() - 1)]
		
	gem.gem_category = category
	
	# Генерируем имя
	_set_gem_name(gem, level, category)
	
	# Выбираем случайную иконку
	_set_gem_texture(gem)
	
	# Генерируем статы с прогрессивными шансами
	_generate_stats_with_chances(gem, level)
	
	# Генерируем описание
	_generate_description(gem)
	
	return gem

func _set_gem_texture(gem: GemData) -> void:
	if icons.size() > 0:
		gem.texture = icons[rng.randi_range(0, icons.size() - 1)]

	else:
		# Fallback - создаем простую текстуру или используем placeholder
		print("⚠️ В генераторе нет иконок! Добавь текстуры в инспекторе.")

func _set_gem_name(gem: GemData, level: int, category: int) -> void:
	if GemData.NAME_TIERS.has(category) and GemData.NAME_TIERS[category].has(level):
		var names = GemData.NAME_TIERS[category][level]
		gem.gem_name = names[rng.randi_range(0, names.size() - 1)]
	else:
		gem.gem_name = "Таинственный самоцвет"

func _generate_stats_with_chances(gem: GemData, level: int) -> void:
	# Определяем количество свойств на основе шансов
	var stat_count = _determine_stat_count()
	print("🎲 Выпало свойств: ", stat_count, " из возможных ", max_stats_count)
	
	var available_stats = base_stat_ranges.keys()
	var chosen_stats = []
	
	# Выбираем случайные статы
	while chosen_stats.size() < stat_count and available_stats.size() > 0:
		var stat_index = rng.randi_range(0, available_stats.size() - 1)
		var stat = available_stats[stat_index]
		
		if not stat in chosen_stats:
			chosen_stats.append(stat)
			available_stats.remove_at(stat_index)
	
	# Генерируем значения для выбранных статов
	gem.stat_boosts = {}
	for stat in chosen_stats:
		var range_data = base_stat_ranges[stat]
		var base_value = rng.randi_range(range_data["min"], range_data["max"])
		var scaled_value = base_value + (level - 1) * range_data["scale"]
		
		if stat in percent_stats:
			gem.stat_boosts[stat] = str(scaled_value) + "%"
		else:
			gem.stat_boosts[stat] = scaled_value

func _determine_stat_count() -> int:
	# Начинаем с 1 свойства (гарантировано)
	var count = 1
	
	# Проверяем шансы для каждого дополнительного свойства
	for additional_stats in range(1, max_stats_count):
		var chance = stat_count_chances.get(additional_stats + 1, 0.0)
		if rng.randf() <= chance:
			count += 1
		else:
			break  # Прерываем если шанс не выпал
	
	return clamp(count, min_stats_count, max_stats_count)

func _generate_description(gem: GemData) -> void:
	var description_parts = []
	
	# Добавляем базовое описание категории
	if GemData.DESCRIPTION_TEMPLATES.has(gem.gem_category):
		var base_desc = GemData.DESCRIPTION_TEMPLATES[gem.gem_category]
		description_parts.append(base_desc % "")
	else:
		description_parts.append("Загадочный самоцвет с необъяснимыми свойствами.")
	
	# Добавляем описание статов
	if gem.stat_boosts.size() > 0:
		description_parts.append("\n\nУвеличивает: ")
		for stat_type in gem.stat_boosts:
			var stat_name = gem._get_stat_name(stat_type)
			var value = gem.stat_boosts[stat_type]
			description_parts.append("
			%s: +%s" % [stat_name, value])
	
	gem.description = "".join(description_parts)

# Функция для быстрого тестирования
func debug_generate_many(count: int = 5) -> Array:
	var gems = []
	for i in range(count):
		gems.append(generate_gem(rng.randi_range(1, 4)))
	return gems
