extends Panel
class_name CheatConsole

@onready var input_line: LineEdit = $VBoxContainer/LineEdit
@onready var output_log: RichTextLabel = $VBoxContainer/RichTextLabel

var is_open: bool = false
var player: PlayerController = null

func _ready():
	# ← Отключаем в релизе
	if OS.has_feature("release"):
		queue_free()
		return
	
	visible = false
	input_line.text_submitted.connect(_on_command_submitted)
	_log("[color=green]🎮 Cheat Console активирована[/color]")
	_log("Введите [color=yellow]@help[/color] для списка команд")

func _unhandled_input(event):
	if event.is_action_pressed("toggle_console") or (event.is_action_pressed("ui_cancel") and is_open):
		if is_open:
			close_console()
		else:
			open_console()
		get_viewport().set_input_as_handled()

func open_console():
	is_open = true
	visible = true
	input_line.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_console():
	is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if player and player.camera:
		player.camera.current = true

func _on_command_submitted(command: String):
	if command.strip_edges().is_empty():
		return
	
	_log("> " + command)
	
	var result = _execute_command(command)
	_log(result)
	
	input_line.clear()

func _log(message: String):
	output_log.append_text(message + "\n")
	# ✅ Godot 4: прокрутка вниз
	output_log.scroll_to_line(output_log.get_line_count() - 1)

func _execute_command(raw_command: String) -> String:
	var command = raw_command.strip_edges()
	if command.begins_with("@") or command.begins_with("/"):
		command = command.substr(1)
	
	var parts = command.split(" ", false)
	if parts.is_empty():
		return "[color=red]❌ Пустая команда[/color]"
	
	var cmd_name = parts[0].to_lower()
	var args = parts.slice(1)
	
	match cmd_name:
		"give":
			return _cmd_give(args)
		"health":
			return _cmd_health(args)
		"stamina":
			return _cmd_stamina(args)
		"hunger":
			return _cmd_hunger(args)
		"sanity":
			return _cmd_santity(args)
		"items":  # ← НОВОЕ
			return _cmd_items(args)
		"fly":  # ← НОВОЕ
			return _cmd_fly(args)
		"clear":
			output_log.clear()
			return "🧹 Консоль очищена"
		"help":
			return _cmd_help()
		_:
			return "[color=red]❌ Неизвестная команда: %s[/color]" % cmd_name

# ===== КОМАНДЫ =====

# ===== ПОЛЁТ =====
func _cmd_fly(args: Array) -> String:
	if not player:
		return "[color=red]❌ Игрок не найден[/color]"
	
	player.fly_enabled = not player.fly_enabled
	
	# ← Сброс флага при выключении
	if not player.fly_enabled:
		player.is_flying = false
	
	var status = "включен" if player.fly_enabled else "выключен"
	var hint = ""
	if player.fly_enabled:
		hint = "\n[color=gray]Управление: Space=вверх, Ctrl=вниз, WASD=движение[/color]"
	
	return "[color=green]✅ Режим полёта %s[/color]%s" % [status, hint]

# ===== СПИСОК ПРЕДМЕТОВ =====
func _cmd_items(args: Array) -> String:
	var folder = "res://items/"
	if args.size() >= 1:
		folder = args[0]
	
	var items = _find_all_items(folder)
	
	if items.is_empty():
		return "[color=yellow]⚠️ Предметы не найдены в: %s[/color]" % folder
	
	var output = "[color=cyan]📦 Найдено предметов: %d[/color]\n\n" % items.size()
	
	# ← Группируем по типам (ИСПРАВЛЕНО)
	var by_type = {}
	for item in items:
		# ← Правильный способ получить item_type из Resource:
		var type = "item"  # По умолчанию
		
		# Способ 1: через "in" оператор
		if "item_type" in item:
			type = item.item_type
		# Способ 2: через has_method + get (если это свойство экспортировано)
		elif item.has_method("get_item_type"):
			type = item.get_item_type()
		# Способ 3: просто по классу
		elif item is ItemConsumable:
			type = "consumable"
		elif item is ItemTool:
			type = "tool"
		elif item is BuildableItemData:
			type = "building"
		elif item is ArmorItemData:
			type = "armor"
		
		if not by_type.has(type):
			by_type[type] = []
		by_type[type].append(item)
	
	for type in by_type.keys():
		output += "[color=yellow]📌 %s:[/color]\n" % type
		for item in by_type[type]:
			# ← Безопасное получение имени предмета
			var name = "unknown"
			if "name" in item and item.name:
				name = item.name
			elif item.resource_path:
				name = item.resource_path.get_file().get_basename()
			
			output += "  • @give %s\n" % name
		output += "\n"
	
	return output

# ← Вспомогательная: найти все предметы рекурсивно
func _find_all_items(folder_path: String) -> Array:
	var items = []
	var dir = DirAccess.open(folder_path)
	if not dir:
		return items
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var file_path = folder_path.path_join(file_name)
		
		if dir.current_is_dir():
			items.append_array(_find_all_items(file_path))
		else:
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var item = load(file_path)
				if item and item is ItemData:
					items.append(item)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return items

#Рассудок
func _cmd_santity(args: Array) -> String:
	if args.size() < 1:
		return "[color=red]❌ Использование: @sanity <value>[/color]"
	var value = int(args[0])
	if player and player.sanity_manager:
		player.sanity_manager.change_sanity(value - player.sanity_manager.current_sanity) #ищет в менеджере рассудка
		return "[color=green]✅ Рассудок: %d/%d[/color]" % [player.sanity_manager.current_sanity, player.sanity_manager.max_sanity]
	return "[color=red]❌ Ошибка: sanity_manager не найден[/color]"

func _cmd_give(args: Array) -> String:
	if args.size() < 1:
		return "[color=red]❌ Использование: @give <item_name> [amount][/color]"
	
	var item_name = args[0].to_lower()  # ← Ищем без учёта регистра
	var amount = 1
	if args.size() >= 2:
		amount = int(args[1])
	
	# ← РЕКУРСИВНЫЙ ПОИСК в папке items/
	var item_data = _find_item_by_name("res://items/", item_name)
	
	if not item_data:
		return "[color=red]❌ Предмет не найден: %s[/color]" % item_name
	
	if player and player.state and player.state.inventory_data:
		player.state.inventory_data.add_item(item_data, amount)
		player.state.inventory_data.inventory_updated.emit(player.state.inventory_data)  # ← Важно!
		return "[color=green]✅ Выдано: %s x%d[/color]" % [item_data.name, amount]
	else:
		return "[color=red]❌ Ошибка: инвентарь не найден[/color]"

func _find_item_by_name(folder_path: String, target_name: String) -> ItemData:
	var dir = DirAccess.open(folder_path)
	if not dir:
		return null
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var file_path = folder_path.path_join(file_name)
		
		if dir.current_is_dir():
			# ← Рекурсивно ищем в подпапке
			var found = _find_item_by_name(file_path, target_name)
			if found:
				dir.list_dir_end()
				return found
		else:
			# ← Проверяем файлы .tres/.res
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var item = load(file_path)
				if item and item is ItemData:
					# ← Сравниваем по имени файла или по name ресурса
					var item_file_name = file_name.get_file().get_basename().to_lower()
					var item_resource_name = item.name.to_lower() if item.name else ""
					
					if item_file_name == target_name or item_resource_name == target_name:
						dir.list_dir_end()
						return item
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return null

func _cmd_health(args: Array) -> String:
	if args.size() < 1:
		return "[color=red]❌ Использование: @health <value>[/color]"
	
	var value = int(args[0])
	if player and player.state:
		player.state.update_health(value - player.state.current_health)
		return "[color=green]✅ Здоровье: %d/%d[/color]" % [player.state.current_health, player.state.max_health]
	return "[color=red]❌ Ошибка: state не найден[/color]"

func _cmd_stamina(args: Array) -> String:
	if args.size() < 1:
		return "[color=red]❌ Использование: @stamina <value>[/color]"
	
	var value = int(args[0])
	if player and player.state:
		player.state.update_stamina(value - player.state.current_stamina)
		return "[color=green]✅ Стамина: %d/%d[/color]" % [player.state.current_stamina, player.state.max_stamina]
	return "[color=red]❌ Ошибка: state не найден[/color]"

func _cmd_hunger(args: Array) -> String:
	if args.size() < 1:
		return "[color=red]❌ Использование: @hunger <value>[/color]"
	
	var value = int(args[0])
	if player and player.state:
		player.state.update_hunger(value - player.state.current_hunger)
		return "[color=green]✅ Голод: %d/%d[/color]" % [player.state.current_hunger, player.state.max_hunger]
	return "[color=red]❌ Ошибка: state не найден[/color]"

func _cmd_help() -> String:
	return """
[color=cyan]📋 Доступные команды:[/color]

[color=yellow]🎒 Инвентарь:[/color]
  @give <item> [кол-во]  - Выдать предмет
  @items [папка]         - Показать все предметы

[color=yellow]❤️ Характеристики:[/color]
  @health <значение>     - Установить здоровье
  @stamina <значение>    - Установить стамину
  @hunger <значение>     - Установить голод
  @sanity <значение>     - Установить рассудок

[color=yellow]✈️ Режимы:[/color]
  @fly                   - Полёт (вкл/выкл)

[color=yellow]🔧 Другое:[/color]
  @clear                 - Очистить консоль
  @help                  - Эта справка

[color=gray]Подсказка: в полёте Space=вверх, Ctrl=вниз[/color]
"""
