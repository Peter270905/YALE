extends Node
class_name BuildingSystem

var player: Node3D
var camera: Node3D
var build_ray: RayCast3D

var current_ghost: BuildGhost = null
var current_buildable: BuildableItemData = null
var is_building: bool = false
var _highlighted_piece: Node = null

var current_rotation: float = 0.0
var rotation_speed: float = 45.0

# ← Флаг активного снапа
var _was_snapped: bool = false

func _ready():
	_setup_references()

func _setup_references():
	player = get_tree().get_first_node_in_group("player")
	if player:
		camera = player.get_node("PlayerLookRaycast/InteractRay")
		_setup_raycast()

func _setup_raycast():
	build_ray = RayCast3D.new()
	build_ray.enabled = true
	build_ray.collision_mask = 0b11111111
	build_ray.target_position = Vector3(0, 0, -5)
	build_ray.exclude_parent = true
	build_ray.add_exception(player)
	camera.add_child(build_ray)

func _process(_delta):
	if is_building and current_ghost:
		if current_buildable and current_buildable.use_snap_points:
			_update_ghost_with_snap()
		else:
			_update_ghost()
		
		if Input.is_action_just_pressed("rotate_building"):
			current_rotation += 45
			current_rotation = fmod(current_rotation, 360)

func highlight_piece(piece: Node):  # ← было BuildingPiece
	if _highlighted_piece == piece:
		return
	clear_highlight()
	_highlighted_piece = piece
	_set_highlight_recursive(piece, true)

func clear_highlight():
	if _highlighted_piece and is_instance_valid(_highlighted_piece):
		_set_highlight_recursive(_highlighted_piece, false)
	_highlighted_piece = null

func _set_highlight_recursive(node: Node, highlight: bool):
	if node is MeshInstance3D:
		if highlight:
			# ← Сохраняем override если есть, иначе берём материал из меша
			if not node.has_meta("original_material"):
				var override_mat = node.get_surface_override_material(0)
				if override_mat:
					node.set_meta("original_material", override_mat)
				elif node.mesh and node.mesh.get_surface_count() > 0:
					node.set_meta("original_material", node.mesh.surface_get_material(0))
				else:
					node.set_meta("original_material", null)
			
			var mat = StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = Color(1, 0.1, 0.1, 0.5)
			mat.emission_enabled = true
			mat.emission = Color(1, 0, 0)
			mat.emission_energy_multiplier = 0.3
			node.set_surface_override_material(0, mat)
		else:
			if node.has_meta("original_material"):
				var original = node.get_meta("original_material")
				# ← Если оригинал был null — просто снимаем override
				if original:
					node.set_surface_override_material(0, original)
				else:
					node.set_surface_override_material(0, null)
				node.remove_meta("original_material")
	
	for child in node.get_children():
		_set_highlight_recursive(child, highlight)

func demolish_piece(piece: Node):
	if not is_instance_valid(piece):
		return
	
	clear_highlight()
	
	# ← Эффект сноса
	BuildingEffects.play_demolish_effect(piece.global_position, get_tree().current_scene)
	
	_free_neighbor_snap_points(piece)
	_return_resources(piece)
	piece.queue_free()

func _find_building_piece_in_parents(node: Node) -> Node:
	var current = node
	var depth = 0
	while current and depth < 4:
		if current.is_in_group("buildings"):
			return current
		current = current.get_parent()
		depth += 1
	return null

func _free_neighbor_snap_points(piece: Node):
	var piece_markers = []
	for child in piece.get_children():
		if child is Marker3D and "snap" in child.name.to_lower():
			piece_markers.append(child.global_position)
	
	# Если маркеров нет — ничего освобождать не нужно
	if piece_markers.is_empty():
		return
	
	for building in get_tree().get_nodes_in_group("buildings"):
		if building == piece or not building is BuildingPiece:
			continue
		var neighbor = building as BuildingPiece
		for neighbor_child in building.get_children():
			if not (neighbor_child is Marker3D and "snap" in neighbor_child.name.to_lower()):
				continue
			for marker_pos in piece_markers:
				if neighbor_child.global_position.distance_to(marker_pos) < 0.15:
					neighbor.free_marker(neighbor_child.name)

func _return_resources(piece: Node):
	if not player or not player.state or not player.state.inventory_data:
		return
	
	var buildable = _find_buildable_for_piece(piece)
	if not buildable:
		return
	
	var connection_cost = 1
	if piece is BuildingPiece:
		connection_cost = piece.connection_cost
	
	var return_count = max(1, connection_cost / 2)
	var slot_data = SlotData.new()
	slot_data.item_data = buildable
	slot_data.quantity = return_count
	
	if not player.state.inventory_data.pick_up_slot_data(slot_data):
		_drop_item_at(slot_data, piece.global_position)

func _find_buildable_for_piece(piece: Node) -> BuildableItemData:
	if not player or not player.state or not player.state.inventory_data:
		return null
	
	# Ищем buildable по building_type если есть, иначе по item_type
	var piece_type = ""
	if piece.get("building_type") != null:
		piece_type = piece.building_type
	elif piece.get("item_type") != null:
		piece_type = piece.item_type
	
	if piece_type == "":
		return null
	
	for slot in player.state.inventory_data.slot_datas:
		if slot and slot.item_data is BuildableItemData:
			var buildable = slot.item_data as BuildableItemData
			if buildable.build_category == piece_type:
				return buildable
	
	return null

func _drop_item_at(slot_data: SlotData, position: Vector3):
	var pick_up_scene = load("res://scenes/pick_up/pick_up.tscn")
	if not pick_up_scene:
		return
	var pick_up = pick_up_scene.instantiate()
	pick_up.slot_data = slot_data
	get_tree().current_scene.add_child(pick_up)
	pick_up.global_position = position + Vector3.UP * 0.5

func start_building(buildable_data: BuildableItemData):
	if not buildable_data:
		return
	if is_building:
		stop_building()
	
	current_buildable = buildable_data
	is_building = true
	current_rotation = 0.0
	_was_snapped = false
	
	current_ghost = BuildGhost.new()
	get_tree().current_scene.add_child(current_ghost)
	current_ghost.setup_from_buildable(buildable_data)
	
	if player and player.current_item_instance:
		player.current_item_instance.visible = false

func stop_building():
	is_building = false
	_was_snapped = false
	
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
	
	current_rotation = 0.0
	
	if player and player.current_item_instance:
		player.current_item_instance.visible = true

func _get_player_facing_rotation() -> float:
	if not camera:
		return 0.0
	var look_dir = -camera.global_transform.basis.z
	look_dir.y = 0
	if look_dir.length_squared() < 0.001:
		return 0.0
	return rad_to_deg(atan2(look_dir.x, look_dir.z))

func _update_ghost():
	if not build_ray or not current_ghost:
		return
	
	build_ray.force_raycast_update()
	
	if not build_ray.is_colliding():
		current_ghost.set_valid(false)
		current_ghost.visible = false
		return
	
	current_ghost.visible = true
	var hit_position = build_ray.get_collision_point()
	var hit_normal = build_ray.get_collision_normal()
	var collider = build_ray.get_collider()
	
	if collider and (collider.is_in_group("player") or collider.owner is PlayerController):
		current_ghost.set_valid(false)
		return
	
	var is_valid_position = _is_position_valid_for_category(hit_position, hit_normal)
	var snapped_position = hit_position
	if is_valid_position and current_buildable and current_buildable.grid_snap:
		snapped_position = _snap_to_grid(hit_position, current_buildable.grid_size)
	
	current_ghost.rotation_degrees.y = _get_player_facing_rotation() + current_rotation
	current_ghost.update_position(snapped_position)
	current_ghost.set_valid(is_valid_position)

func _update_ghost_with_snap():
	if not build_ray or not current_ghost:
		return
	
	build_ray.force_raycast_update()
	
	var hit_position: Vector3
	var hit_normal: Vector3
	var ray_hit = build_ray.is_colliding()
	
	if ray_hit:
		hit_position = build_ray.get_collision_point()
		hit_normal = build_ray.get_collision_normal()
		current_ghost.visible = true
	else:
		if camera:
			hit_position = camera.global_position + (-camera.global_transform.basis.z * 2.0)
			hit_normal = Vector3.UP
			current_ghost.visible = true
		else:
			current_ghost.visible = false
			current_ghost.set_valid(false)
			return
	
	# ← Сначала ставим призрак на позицию без снапа чтобы его маркеры
	# оказались в правильном месте для поиска пары
	var base_rotation = _get_player_facing_rotation() + current_rotation
	current_ghost.global_position = hit_position
	current_ghost.rotation_degrees.y = base_rotation
	
	# ← Ищем лучшую пару маркеров
	var snap_result = _find_best_marker_pair()
	
	var final_position: Vector3
	var snapped_to_point = false
	var snap_source_parent: Node = null
	
	if snap_result.has("offset"):
		snapped_to_point = true
		snap_source_parent = snap_result.get("source_parent", null)
		
		# ← Первый кадр снапа — сбрасываем накопленный поворот игрока
		if not _was_snapped:
			current_rotation = 0.0
			_was_snapped = true
		
		# Поворот: берём угол постройки-источника + ручная коррекция кнопкой
		var target_rotation = snap_result.get("target_rotation", 0.0) + current_rotation
		current_ghost.rotation_degrees.y = lerp_angle(
			current_ghost.rotation_degrees.y,
			target_rotation,
			0.25
		)
		
		# Позиция: смещаем призрак так чтобы его маркер совпал с маркером постройки
		final_position = hit_position + snap_result.offset
	else:
		# Нет снапа — смотрит на игрока
		_was_snapped = false
		current_ghost.rotation_degrees.y = base_rotation
		final_position = hit_position
		if current_buildable and current_buildable.grid_snap:
			final_position = _snap_to_grid(final_position, current_buildable.grid_size)
	
	# Валидация
	var is_valid: bool
	if snapped_to_point:
		is_valid = not _check_collision_at(final_position, snap_source_parent)
	elif not ray_hit:
		is_valid = false
	else:
		is_valid = _is_position_valid_for_category(hit_position, hit_normal)
		if is_valid:
			is_valid = not _check_collision_at(final_position)
	
	current_ghost.update_position(final_position)
	current_ghost.set_valid(is_valid)

# ← Главная функция: ищет ближайшую пару маркеров призрак ↔ постройка
func _find_best_marker_pair() -> Dictionary:
	if not current_ghost or not current_buildable:
		return {}
	
	var ghost_markers = current_ghost.get_snap_markers_world()
	if ghost_markers.is_empty():
		return {}
	
	var best_distance = current_buildable.snap_distance
	var best_result = {}
	
	for building in get_tree().get_nodes_in_group("buildings"):
		if not building.has_method("get_snap_points"):
			continue
		
		var building_points = building.get_snap_points()
		
		for b_point in building_points:
			for g_marker in ghost_markers:
				var dist = b_point.position.distance_to(g_marker.world_position)
				if dist < best_distance:
					best_distance = dist
					
					# Смещение чтобы маркер призрака совпал с маркером постройки
					var offset = b_point.position - g_marker.world_position
					
					best_result = {
						"offset": offset,
						"target_rotation": building.rotation_degrees.y,
						"source_parent": building,
						"b_point": b_point,
						"g_marker": g_marker,
					}
	
	return best_result

func place_building():
	if not is_building or not current_buildable or not current_ghost:
		return
	if not current_ghost.is_valid:
		return
	if not _has_ingredients(current_buildable):
		current_ghost.set_valid(false)
		return
	
	var build_position = current_ghost.global_position
	var build_rotation = current_ghost.rotation_degrees.y
	var building_instance = current_buildable.build_scene.instantiate()
	get_tree().current_scene.add_child(building_instance)
	building_instance.global_position = build_position
	building_instance.rotation_degrees.y = build_rotation
	
	BuildingEffects.play_place_effect(build_position, get_tree().current_scene)
	_occupy_snap_points(building_instance)
	
	if current_buildable.recipe:
		# ← Рецепт есть — тратим ингредиенты по тегам
		_consume_ingredients(current_buildable)
	else:
		# ← Рецепта нет — тратим предмет из слота
		# Но только если это НЕ мотыга
		var slot = player.state.inventory_data.slot_datas[player.active_slot_index]
		if slot and slot.item_data and not (slot.item_data is HoeItem):
			_consume_build_item()
	
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
	
	is_building = false
	_was_snapped = false
	current_rotation = 0.0
	
	if player and player.current_item_instance:
		player.current_item_instance.visible = true

func _occupy_snap_points(new_building: Node):
	# Ждём один кадр чтобы маркеры новой постройки получили глобальные позиции
	await get_tree().process_frame
	
	if not is_instance_valid(new_building):
		return
	
	var new_piece = new_building as BuildingPiece
	if not new_piece:
		return
	
	# Получаем все маркеры новой постройки
	for new_child in new_building.get_children():
		if not (new_child is Marker3D and "snap" in new_child.name.to_lower()):
			continue
		
		# Ищем маркеры соседних построек которые совпадают по позиции
		for building in get_tree().get_nodes_in_group("buildings"):
			if building == new_building:
				continue
			if not building.has_method("get_nearest_marker_name"):
				continue
			
			var piece = building as BuildingPiece
			if not piece:
				continue
			
			# Проверяем все маркеры соседа
			for neighbor_child in building.get_children():
				if not (neighbor_child is Marker3D and "snap" in neighbor_child.name.to_lower()):
					continue
				
				var dist = new_child.global_position.distance_to(neighbor_child.global_position)
				
				# ← Если маркеры совпадают с точностью 0.15 — помечаем оба как занятые
				if dist < 0.15:
					new_piece.occupy_marker(new_child.name)
					piece.occupy_marker(neighbor_child.name)

func _snap_to_grid(position: Vector3, grid_size: float) -> Vector3:
	var snapped_pos = position
	snapped_pos.x = snappedf(snapped_pos.x, grid_size)
	snapped_pos.z = snappedf(snapped_pos.z, grid_size)
	if current_buildable and current_buildable.build_category == "floor":
		snapped_pos.y = snappedf(snapped_pos.y, grid_size)
	return snapped_pos

func _is_position_valid_for_category(_position: Vector3, normal: Vector3) -> bool:
	if not current_buildable:
		return false
	match current_buildable.build_category:
		"floor":
			return normal.y > 0.3
		"wall":
			return true
		"pillar":
			return normal.y > 0.5
		"farm":
			return normal.y > 0.7
		_:
			return true

func _check_collision_at(position: Vector3, exclude_node: Node = null) -> bool:
	var space_state = get_tree().current_scene.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.4
	query.shape = sphere
	query.transform = Transform3D(Basis(), position)
	query.collision_mask = 4
	if exclude_node:
		var body = _find_static_body(exclude_node)
		if body:
			query.exclude = [body.get_rid()]
	var results = space_state.intersect_shape(query)
	return results.size() > 0

func _consume_build_item():
	if not player or not player.state or not player.state.inventory_data:
		return
	var slot_data = player.state.inventory_data.slot_datas[player.active_slot_index]
	if slot_data and slot_data.quantity > 0:
		slot_data.quantity -= 1
		if slot_data.quantity <= 0:
			player.state.inventory_data.slot_datas[player.active_slot_index] = null
		player.state.inventory_data.inventory_updated.emit(player.state.inventory_data)

func toggle_building(buildable_data: BuildableItemData = null):
	if is_building:
		stop_building()
	elif buildable_data:
		start_building(buildable_data)

func _find_static_body(node: Node) -> StaticBody3D:
	if node is StaticBody3D:
		return node
	for child in node.get_children():
		var result = _find_static_body(child)
		if result:
			return result
	return null

func _find_mesh_in_scene(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var mesh = _find_mesh_in_scene(child)
		if mesh:
			return mesh
	return null

func _get_pivot_offset(building: Node3D) -> Vector3:
	var mesh = _find_mesh_in_scene(building)
	if mesh:
		return -mesh.transform.origin
	return Vector3.ZERO

func _has_ingredients(buildable: BuildableItemData) -> bool:
	if not buildable.recipe or buildable.recipe.ingredients.is_empty():
		return true
	
	var inventory = player.state.inventory_data
	for ingredient in buildable.recipe.ingredients:
		var found = _count_items_with_tag(inventory, ingredient.required_tag)
		if found < ingredient.amount:
			return false
	return true

func _consume_ingredients(buildable: BuildableItemData):
	if not buildable.recipe or buildable.recipe.ingredients.is_empty():
		return
	
	var inventory = player.state.inventory_data
	for ingredient in buildable.recipe.ingredients:
		var to_consume = ingredient.amount
		for i in range(inventory.slot_datas.size()):
			if to_consume <= 0:
				break
			var slot = inventory.slot_datas[i]
			if not slot or not slot.item_data:
				continue
			if ingredient.required_tag in slot.item_data.tags:
				var take = min(slot.quantity, to_consume)
				slot.quantity -= take
				to_consume -= take
				if slot.quantity <= 0:
					inventory.slot_datas[i] = null
	
	inventory.inventory_updated.emit(inventory)

func _count_items_with_tag(inventory: InventoryData, tag: String) -> int:
	var total = 0
	for slot in inventory.slot_datas:
		if slot and slot.item_data and tag in slot.item_data.tags:
			total += slot.quantity
	return total
