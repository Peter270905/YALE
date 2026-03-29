extends Node
class_name SaveManager

const SAVE_PATH = "user://game_save.json"

func save_game():
	var save_data = _collect_save_data()
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("✅ Игра сохранена! Время: ", Time.get_time_string_from_system())
	else:
		push_error("❌ Ошибка сохранения: ", FileAccess.get_open_error())

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("ℹ️ Файл сохранения не найден")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("❌ Не удалось открыть файл сохранения")
		return false
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("❌ Ошибка парсинга JSON: ", json.get_error_message())
		return false
	
	var save_data = json.data
	if save_data:
		_apply_save_data(save_data)
		print("✅ Игра загружена! Сохранение от: ", _get_save_time_string(save_data))
		return true
	else:
		push_error("❌ Ошибка загрузки данных")
		return false

func _collect_save_data() -> Dictionary:
	var player = _get_player()
	if not player:
		push_error("❌ Игрок не найден для сохранения")
		return {}
	
	return {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"save_time": Time.get_datetime_string_from_system(),
		
		"player": _get_player_data(player),
		"world": _get_world_data(),
		"systems": _get_systems_data()
	}

func _get_player_data(player) -> Dictionary:
	var state = player.state
	return {
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y, 
			"z": player.global_position.z
		},
		"rotation": player.rotation.y,
		"stats": {
			"health": state.current_health,
			"max_health": state.max_health,
			"stamina": state.current_stamina,
			"max_stamina": state.max_stamina,
			"hunger": state.current_hunger,
			"sanity": state.sanity_manager.current_sanity if state.sanity_manager else 0,
			"defense": state.defense
		},
		"inventory": _get_inventory_data(player),
		"last_damage_time": state.last_damage_time
	}

func _get_world_data() -> Dictionary:
	return {
		"time_of_day": 0,
		"weather": "clear"
	}

func _get_systems_data() -> Dictionary:
	return {
		"game_stage": 1
	}

func _apply_save_data(save_data: Dictionary):
	var player = _get_player()
	if not player:
		push_error("❌ Игрок не найден для загрузки")
		return
	
	var player_data = save_data.get("player", {})
	
	var pos = player_data.get("position", {})
	player.global_position = Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0))
	player.rotation.y = player_data.get("rotation", 0)
	
	_set_player_stats(player, player_data.get("stats", {}))
	_set_inventory_data(player, player_data.get("inventory", {}))
	
	var state = player.state
	state.last_damage_time = player_data.get("last_damage_time", -999.0)

func _set_player_stats(player, stats: Dictionary):
	var state = player.state
	
	state.max_health = stats.get("max_health", state.max_health)
	state.max_stamina = stats.get("max_stamina", state.max_stamina)
	
	state.current_health = min(stats.get("health", state.current_health), state.max_health)
	state.current_stamina = min(stats.get("stamina", state.current_stamina), state.max_stamina)
	state.current_hunger = stats.get("hunger", state.current_hunger)
	state.defense = stats.get("defense", state.defense)
	
	if state.sanity_manager:
		state.sanity_manager.current_sanity = stats.get("sanity", state.sanity_manager.current_sanity)
	
	state.health_changed.emit(state.current_health)
	state.stamina_changed.emit(state.current_stamina)
	state.hunger_changed.emit(state.current_hunger)

# 🔥 ДОБАВЛЯЕМ ВСЕ НЕДОСТАЮЩИЕ МЕТОДЫ:

func _get_player():
	return get_tree().get_first_node_in_group("player")

func _get_inventory_data(player) -> Dictionary:
	var state = player.state
	
	return {
		"main_inventory": _get_slot_datas_array(state.inventory_data.slot_datas),
		"equipment_inventory": _get_slot_datas_array(state.equip_inventory_data.slot_datas),
		"accessories_inventory": _get_slot_datas_array(state.accessories_inventory_data.slot_datas)
	}

func _set_inventory_data(player, saved_data: Dictionary):
	var state = player.state
	
	_restore_slot_datas(state.inventory_data.slot_datas, saved_data.get("main_inventory", []))
	_restore_slot_datas(state.equip_inventory_data.slot_datas, saved_data.get("equipment_inventory", []))
	_restore_slot_datas(state.accessories_inventory_data.slot_datas, saved_data.get("accessories_inventory", []))
	
	state.inventory_data.inventory_updated.emit(state.inventory_data)
	state.equip_inventory_data.inventory_updated.emit(state.equip_inventory_data)
	state.accessories_inventory_data.inventory_updated.emit(state.accessories_inventory_data)

func _get_slot_datas_array(slot_datas: Array) -> Array:
	var result = []
	for slot_data in slot_datas:
		if slot_data and slot_data.item_data:
			var slot_dict = {
				"quantity": slot_data.quantity
			}
			
			if slot_data.item_data is GemItemData:
				var gem_item = slot_data.item_data as GemItemData
				slot_dict["type"] = "gem"
				slot_dict["gem_data"] = _serialize_gem_data(gem_item.gem_data)
			else:
				slot_dict["type"] = "regular"
				slot_dict["item_path"] = slot_data.item_data.resource_path
			
			result.append(slot_dict)
		else:
			result.append(null)
	return result

func _serialize_gem_data(gem_data: GemData) -> Dictionary:
	var gem_manager = _get_gem_manager()
	var texture_index = -1
	
	if gem_manager and gem_data.texture:
		for i in range(gem_manager.gem_textures.size()):
			if gem_manager.gem_textures[i] == gem_data.texture:
				texture_index = i
				break
	
	return {
		"gem_id": gem_data.gem_id,
		"gem_name": gem_data.gem_name,
		"gem_category": gem_data.gem_category,
		"level": gem_data.level,
		"stat_boosts": gem_data.stat_boosts,
		"description": gem_data.description,
		"texture_index": texture_index
	}

func _restore_slot_datas(target_slots: Array, saved_slots: Array):
	for i in range(min(target_slots.size(), saved_slots.size())):
		var slot_info = saved_slots[i]
		
		if slot_info:
			var slot_data = SlotData.new()
			
			if slot_info.get("type") == "gem":
				var gem_item = _restore_gem_item(slot_info["gem_data"])
				if gem_item:
					slot_data.item_data = gem_item
					slot_data.quantity = slot_info["quantity"]
					target_slots[i] = slot_data
				else:
					target_slots[i] = null
					print("❌ Не удалось восстановить самоцвет")
			else:
				var item_data = load(slot_info["item_path"])
				if item_data:
					slot_data.item_data = item_data
					slot_data.quantity = slot_info["quantity"]
					target_slots[i] = slot_data
				else:
					target_slots[i] = null
		else:
			target_slots[i] = null

func _restore_gem_item(gem_dict: Dictionary) -> GemItemData:
	var gem_item = GemItemData.new()
	var gem_data = GemData.new()
	
	gem_data.gem_id = gem_dict.get("gem_id", "")
	gem_data.gem_name = gem_dict.get("gem_name", "Восстановленный самоцвет")
	gem_data.gem_category = gem_dict.get("gem_category", 0)
	gem_data.level = gem_dict.get("level", 1)
	gem_data.stat_boosts = gem_dict.get("stat_boosts", {})
	gem_data.description = gem_dict.get("description", "")
	
	var gem_manager = _get_gem_manager()
	var texture_index = gem_dict.get("texture_index", -1)
	
	if gem_manager and texture_index >= 0 and texture_index < gem_manager.gem_textures.size():
		gem_data.texture = gem_manager.gem_textures[texture_index]
		print("✅ Восстановлена текстура самоцвета по индексу: ", texture_index)
	else:
		if gem_manager and gem_manager.gem_textures.size() > 0:
			gem_data.texture = gem_manager.gem_textures[randi() % gem_manager.gem_textures.size()]
			print("⚠️ Использована случайная текстура для самоцвета")
	
	gem_item.name = gem_data.gem_name
	gem_item.description = gem_data.description
	gem_item.gem_data = gem_data
	gem_item.texture = gem_data.texture
	
	return gem_item

func _get_gem_manager() -> GemManager:
	return get_tree().get_first_node_in_group("gem_manager")

func _get_save_time_string(save_data: Dictionary) -> String:
	var timestamp = save_data.get("timestamp", 0)
	if timestamp > 0:
		return Time.get_time_string_from_unix_time(timestamp)
	return save_data.get("save_time", "неизвестно")

func _check_save_compatibility(save_data: Dictionary) -> bool:
	var version = save_data.get("version", "0.0")
	return version == "1.0"
