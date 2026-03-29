extends CharacterBody3D
class_name PlayerController

# ===== КОНСТАНТЫ =====
const PICK_UP_SCENE = preload("res://scenes/pick_up/pick_up.tscn")

# ===== ЭКСПОРТИРУЕМЫЕ ПЕРЕМЕННЫЕ =====
@export_category("Movement Settings")
@export var rotation_speed: float = 5
@export var target_velocity: Vector3 = Vector3.ZERO

@export_category("Head Tracking")
@export var enable_vertical_rotation: bool = true
@export var enable_horizontal_rotation: bool = true
@export var head_bone_name: String = "mixamorig_Head"
@export var look_strength: float = 0.5

@export_category("HeadBob")
@export var headbob_frequency := 8.0
@export var headbob_amplitude := 0.05
@export var headbob_smoothness := 12.0
var headbob_offset: Vector3 = Vector3.ZERO

var headbob_time := 0.0
var current_headbob_offset := Vector3.ZERO


@export_category("Systems")
@export var gem_manager: GemManager

# ===== НОДЫ =====
## Movement & Visuals
@onready var animation_player: AnimationPlayer = $visuals/Idle/AnimationPlayer
@onready var visuals: Node3D = $visuals
@onready var camera: Camera3D = $camera/Camera3D
@onready var item_socket: Node3D = $visuals/Idle/Skeleton3D/HandItemSocket/ItemSocket

## UI
@onready var ui: CanvasLayer = $UI
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bar_inventory: PanelContainer = $UI/HotbarContainer/HotBarInventory
@onready var interact_label: Label = $UI/InteractionPrompt/InteractLabel
@onready var inventory_layout: MarginContainer = $UI/InventoryInterface/InventoryLayout
@onready var hotbar_container: CenterContainer = $UI/HotbarContainer
@onready var furnace_ui: PanelContainer = $UI/InventoryInterface/InventoryLayout/MainVBox/HBoxContainer2/FurnaceUI
@onready var anvil_ui: PanelContainer = $UI/InventoryInterface/InventoryLayout/MainVBox/HBoxContainer2/AnvilUI
@onready var crafting_panel: PanelContainer = $UI/InventoryInterface/InventoryLayout/MainVBox/HBoxContainer2/CraftingUI
@onready var sanity_manager: SanityManager = $state/SanityManager
var wheel_menu_scene = preload("res://scenes/ui/WheelMenu/WheelMenu.tscn")


## Systems
@onready var state: PlayerState = $state
@onready var tool_system: ToolSystem = $state/ToolSystem
@onready var ability_manager: AbilityManager = $state/AbilityManager
@onready var interact_ray: RayCast3D = $PlayerLookRaycast/InteractRay
@onready var building_system: BuildingSystem = $state/BuildingSystem
@onready var cheat_console: CheatConsole = $UI/CheatConsole


# ===== ПЕРЕМЕННЫЕ СОСТОЯНИЯ =====
var running: bool = false
var current_interactable: Node = null
var current_item_instance: Node3D = null
var active_slot_index: int = 0
var double_jump_used: bool = false
var has_double_jump_accessory: bool = false
var head_bone_idx: int
var wheel_menu: WheelMenu = null
var _rmb_held: bool = false

## Stamina
var stamina_drain_timer: float = 0.0
var stamina_drain_interval: float = 0.1

# ===== ИНИЦИАЛИЗАЦИЯ =====
func _ready() -> void:
	_initialize_player()
	_connect_signals()
	_setup_inventory()
	_update_item_in_hand()
	if cheat_console:
		cheat_console.player = self

func _initialize_player() -> void:
	add_to_group("player")

func get_state() -> PlayerState:
	return state

func _connect_signals() -> void:
	state.toggle_inventory.connect(toggle_inventory_interface)
	state.camera_mode_changed.connect(_on_camera_mode_changed)
	
	if hot_bar_inventory.hot_bar_use.is_connected(_on_hotbar_use) == false:
		hot_bar_inventory.hot_bar_use.connect(_on_hotbar_use)
	
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)

func _setup_inventory() -> void:
	inventory_interface.set_player_inventory_data(state.inventory_data)
	hot_bar_inventory.set_inventory_data(state.inventory_data)
	inventory_interface.set_equip_inventory_data(state.equip_inventory_data)
	inventory_interface.set_accessories_inventory_data(state.accessories_inventory_data)

	if state.accessories_inventory_data:
		state.accessories_inventory_data.setup_player_controller(self)



# ===== ОБРАБОТКА ВВОДА =====
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		state.toggle_inventory.emit()
	if Input.is_action_just_pressed("interact"):
		interact()
	if Input.is_action_pressed("quick_save"):
		Save.save_game()
	if Input.is_action_pressed("quick_load"):
		Save.load_game()
	if Input.is_action_just_pressed("ctrl"):
		_on_test_button_pressed()
	
	if event.is_action_pressed("LBM") and not event.is_echo():
		if building_system.is_building:
			building_system.place_building()
		else:
			_use_current_tool()
	
	if event.is_action_pressed("cancel_build") and building_system.is_building:
		building_system.stop_building()
		
	if cheat_console and cheat_console.is_open:
		if event.is_action_pressed("ui_cancel"):  # ESC закрывает консоль
			cheat_console.close_console()
			get_viewport().set_input_as_handled()
			return
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		var current_item = get_current_item()
		if current_item is HoeItem:
			if event.pressed:
				_open_wheel_menu(current_item as HoeItem)
			else:
				_close_wheel_menu()
			get_viewport().set_input_as_handled()
			return

func _setup_building_system():
	if building_system:
		building_system.player = self
		building_system.camera = interact_ray

# ===== ФИЗИЧЕСКИЙ ПРОЦЕСС (ДВИЖЕНИЕ) =====
func _physics_process(delta: float) -> void:
	if inventory_interface.visible or wheel_menu:
		return
	if inventory_interface.visible:
		return
	if cheat_console.is_open:
		return
	
	_handle_movement_input(delta)
	_handle_jump()
	_handle_animation()
	_apply_movement(delta)
	state.check_fall_damage(self)
	if building_system and building_system.is_building:
		building_system._process(delta)

func get_current_item() -> ItemData:
	var slot_data = state.inventory_data.slot_datas[active_slot_index]
	if slot_data and slot_data.item_data:
		return slot_data.item_data
	return null

func _handle_secondary_action():
	if building_system and building_system.is_building:
		building_system.place_building()
	else:
		var current_item = get_current_item()
		if current_item is BuildableItemData:
			building_system.start_building(current_item)
		else:
			_use_item_from_hotbar()

func _handle_movement_input(delta: float) -> void:
	@warning_ignore("unused_variable")
	var was_running = running
	running = Input.is_action_pressed("run") and state.can_run
	

	_handle_stamina_drain(delta)
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (state.fall_acceleration * delta)
	else:
		target_velocity.y = 0

func _handle_stamina_drain(delta: float) -> void:
	stamina_drain_timer += delta
	var input_dir = Input.get_vector("left", "right", "up", "down")
	if running and state.can_run and stamina_drain_timer >= stamina_drain_interval and input_dir != Vector2.ZERO:
		state.update_stamina(-0.2)
		stamina_drain_timer = 0.0

func _handle_jump() -> void:
	has_double_jump_accessory = ability_manager.has_double_jump()
	
	if is_on_floor():
		double_jump_used = false
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() and state.current_stamina >= 5:
			target_velocity.y = state.jump_velocity
			state.update_stamina(-5)
			double_jump_used = false
		elif not is_on_floor() and not double_jump_used and has_double_jump_accessory and state.current_stamina >= 3:
			target_velocity.y = state.jump_velocity * 0.8
			state.update_stamina(-3)
			double_jump_used = true

func _handle_animation() -> void:
	var current_speed = state.get_movement_speed(running)
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var dir = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	dir.y = 0
	dir = dir.normalized()
	running = Input.is_action_pressed("run") and state.can_run

	if dir:
		if running and state.current_stamina >= 1:
			if animation_player.current_animation != "Running/mixamo_com":
				animation_player.play("Running/mixamo_com")
		else:
			if animation_player.current_animation != "Walking/mixamo_com":
				animation_player.play("Walking/mixamo_com")
		
		var target_angle = atan2(dir.x, dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * get_physics_process_delta_time())
		
		# Скорость
		velocity.x = dir.x * current_speed
		velocity.z = dir.z * current_speed
	else:
		velocity.x = 0
		velocity.z = 0
		
		if animation_player.current_animation != "mixamo_com":
			animation_player.play("mixamo_com")

func _apply_movement(delta: float) -> void:
	velocity.y = target_velocity.y
	if velocity != Vector3.ZERO or not is_on_floor():
		move_and_slide()
	_apply_headbob(delta)

func _apply_headbob(delta: float):
	if not state.is_first_person:
		_reset_headbob()
		headbob_offset = current_headbob_offset 
		return
	const HEADBOB_STOP_THRESHOLD_SQ = 0.000001 
	if velocity.length() > 0.1 and is_on_floor():
		var bob_speed = min(velocity.length(), 5.0) 
		headbob_time += delta * bob_speed
		var target_headbob = _calculate_headbob(headbob_time)
		current_headbob_offset = current_headbob_offset.lerp(target_headbob, delta * headbob_smoothness)
	else:
		if current_headbob_offset.length_squared() < HEADBOB_STOP_THRESHOLD_SQ:
			current_headbob_offset = Vector3.ZERO
		else:
			current_headbob_offset = current_headbob_offset.lerp(Vector3.ZERO, delta * headbob_smoothness * 2)
		headbob_time = 0.0
	headbob_offset = current_headbob_offset

func _calculate_headbob(time: float) -> Vector3:
	var bob_pos = Vector3.ZERO
	bob_pos.y = sin(time * headbob_frequency) * headbob_amplitude
	bob_pos.x = cos(time * headbob_frequency / 2) * headbob_amplitude * 0.5 
	
	return bob_pos

func _reset_headbob():
	if current_headbob_offset != Vector3.ZERO:
		current_headbob_offset = Vector3.ZERO
		camera.transform.origin = Vector3.ZERO
		headbob_time = 0.0

func _on_camera_mode_changed(is_first_person: bool):
	visuals.visible = !is_first_person
	if current_item_instance:
		current_item_instance.visible = !is_first_person

func _on_hotbar_use(index: int) -> void:
	active_slot_index = index
	_update_item_in_hand()
	
	var slot_data = state.inventory_data.slot_datas[active_slot_index]
	if slot_data and slot_data.item_data and Input.is_action_just_pressed("hotbar_use_consumable"):
		if slot_data.item_data is ItemConsumable:
			_use_item_from_hotbar()
	if slot_data and slot_data.item_data is BuildableItemData:
		if building_system.is_building:
			if building_system.current_buildable != slot_data.item_data:
				building_system.start_building(slot_data.item_data)
			else:
				building_system.stop_building()
		else:
			building_system.start_building(slot_data.item_data)
	
	else:
		if building_system.is_building:
			building_system.stop_building()
	
	_update_item_in_hand()

func _update_item_in_hand() -> void:
	if current_item_instance:
		current_item_instance.queue_free()
		current_item_instance = null
	
	var slot_data = state.inventory_data.slot_datas[active_slot_index]
	if slot_data and slot_data.item_data and slot_data.item_data.scene:
		current_item_instance = slot_data.item_data.scene.instantiate()
		item_socket.add_child(current_item_instance)
		_align_item_to_grip(current_item_instance)

func _align_item_to_grip(item_instance: Node3D) -> void:
	var item_grip = item_instance.get_node_or_null("HandlePoint")
	var hand_grip = item_socket.get_node_or_null("GripPoint")
	
	if item_grip and hand_grip:
		var offset = hand_grip.global_position - item_grip.global_position
		item_instance.global_position += offset
		item_instance.global_rotation = hand_grip.global_rotation

func _use_item_from_hotbar() -> void:
	var slot_data = state.inventory_data.slot_datas[active_slot_index]
	if slot_data and slot_data.item_data and slot_data.item_data.has_method("use"):
		slot_data.item_data.use(state)
		
		if slot_data.quantity > 1:
			slot_data.quantity -= 1
		else:
			state.inventory_data.slot_datas[active_slot_index] = null
		
		state.inventory_data.emit_signal("inventory_updated", state.inventory_data)

# ===== ИНТЕРАКТИВНЫЕ ОБЪЕКТЫ =====
func _process(delta: float) -> void:
	check_interactable()
	if state.accessories_inventory_data:
		state.accessories_inventory_data.process_abilities(delta)
	

func check_interactable() -> void:
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if not collider:
			_hide_prompt()
			return
		
		var current_tool = get_current_tool()
		if current_tool and current_tool.tool_type == ItemTool.ToolType.HUMMER:
			var piece = building_system._find_building_piece_in_parents(collider)
			if piece:
				current_interactable = piece
				interact_label.text = "Снести [ЛКМ]"
				interact_label.visible = true
				building_system.highlight_piece(piece)  # ← подсветка
				return
			else:
				building_system.clear_highlight()
		else:
			building_system.clear_highlight()
		
		if collider.has_method("get_interaction_text_for_player"):
			current_interactable = collider
			var final_text = collider.get_interaction_text_for_player(self)
			interact_label.text = final_text
			interact_label.visible = true
		
		elif collider.get("interactable_data"):
			current_interactable = collider
			var interact_data = collider.interactable_data
			interact_label.text = interact_data.interact_text
			interact_label.visible = true
		
		elif collider.has_method("player_interact"):
			current_interactable = collider
			interact_label.text = "Нажмите [F]"
			interact_label.visible = true
		
		else:
			_hide_prompt()
	else:
		_hide_prompt()

func _hide_prompt() -> void:
	building_system.clear_highlight()
	if interact_label.visible:
		_fade_out_prompt()
	current_interactable = null

func _fade_out_prompt() -> void:
	if not interact_label.visible:
		return
	var tween = create_tween()
	tween.tween_property(interact_label, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func():
		interact_label.visible = false
		interact_label.modulate.a = 1.0
	)

func interact() -> void:
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		
		if collider.has_method("player_interact"):
			if collider.player_interact(self):
				pass
			else:
				pass
			return
		
		elif collider.has_method("player_interact"):
			collider.player_interact(self)

# ===== ИНТЕРФЕЙС ИНВЕНТАРЯ =====
func toggle_inventory_interface(external_inventory_owner = null) -> void:
	inventory_interface.visible = not inventory_interface.visible
	if inventory_interface.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var main_vbox = inventory_layout.get_node("MainVBox")
		hot_bar_inventory.reparent(main_vbox)
		inventory_layout.show()
		if crafting_panel:
			crafting_panel.show()
			
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hot_bar_inventory.reparent(hotbar_container)
		hot_bar_inventory.show()
		if crafting_panel:
			crafting_panel.reset_to_inventory_mode()
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()
	
	if inventory_interface.visible and current_furnace:
		close_furnace()
		return
	if furnace_ui and not current_furnace:
		furnace_ui.hide()
	
	if not inventory_interface.visible and (current_furnace or current_anvil):
		if current_furnace:
			close_furnace()
		if current_anvil:
			close_anvil()
		return

var current_furnace: FurnaceStation = null
func open_furnace(furnace: FurnaceStation):
	if current_furnace:
		close_furnace()
	current_furnace = furnace
	if not inventory_interface.visible:
		toggle_inventory_interface()
	
	if furnace_ui:
		furnace_ui.visible = true
		furnace_ui.set_furnace_inventory(furnace.inventory_data)
		furnace.set_ui_panel(furnace_ui)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_furnace():
	if current_furnace:
		current_furnace.set_ui_panel(null)
		current_furnace = null
	
	if furnace_ui:
		furnace_ui.visible = false
	
	if inventory_interface.grabbed_slot_data:
		if not state.inventory_data.pick_up_slot_data(inventory_interface.grabbed_slot_data):
			_on_inventory_interface_drop_slot_data(inventory_interface.grabbed_slot_data)
		inventory_interface.grabbed_slot_data = null
		inventory_interface.update_grabbed_slot()

var current_anvil: Anvil = null
func open_anvil(anvil: Anvil):
	if current_anvil:
		close_anvil()
	current_anvil = anvil
	
	if not inventory_interface.visible:
		toggle_inventory_interface()
	
	if anvil_ui:
		anvil_ui.visible = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_anvil():
	if current_anvil:
		current_anvil = null
	
	if anvil_ui:
		anvil_ui.visible = false

func get_inventory_data() -> InventoryData:
	return state.inventory_data
	
func on_inventory_interact(inventory: InventoryData, index: int, button: int):
	
	if button == MOUSE_BUTTON_LEFT:
		PlayerManager.handle_left_click(inventory, index)

	elif button == MOUSE_BUTTON_RIGHT:
		PlayerManager.handle_right_click(inventory, index)

func _open_wheel_menu(hoe: HoeItem):
	if wheel_menu or hoe.buildable_beds.is_empty():
		return
	
	_rmb_held = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	wheel_menu = wheel_menu_scene.instantiate()
	add_child(wheel_menu)
	wheel_menu.setup(hoe.buildable_beds)
	
	# Центрируем мышь
	var center = get_viewport().get_visible_rect().size / 2.0
	Input.warp_mouse(center)

func _close_wheel_menu():
	if not wheel_menu:
		return
	
	_rmb_held = false
	
	var selected = wheel_menu.get_selected()
	wheel_menu.queue_free()
	wheel_menu = null
	
	# Восстанавливаем режим мыши
	if not inventory_interface.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Запускаем строительство если что-то выбрали
	if selected:
		building_system.start_building(selected)

# ===== СИСТЕМА ИНСТРУМЕНТОВ =====
func get_current_tool() -> ItemTool:
	var slot_data = state.inventory_data.slot_datas[active_slot_index]
	if slot_data and slot_data.item_data is ItemTool:
		return slot_data.item_data as ItemTool
	return null

# Когда инструмент появляется в инвентаре/руке:
func _on_tool_acquired(tool: ItemTool) -> void:
	# ← Подключаем сигнал ОДИН РАЗ
	if not tool.tool_broken.is_connected(_on_tool_broken):
		tool.tool_broken.connect(_on_tool_broken.bind(tool))

# Обработчик поломки:
func _on_tool_broken(broken_tool: ItemTool) -> void:	
	# Ищем слот с этим инструментом
	for i in range(state.inventory_data.slot_datas.size()):
		var slot = state.inventory_data.slot_datas[i]
		if slot and slot.item_data == broken_tool:
			# Удаляем из инвентаря
			state.inventory_data.slot_datas[i] = null
			state.inventory_data.inventory_updated.emit(state.inventory_data)
			return


func get_current_tool_type() -> int:
	var tool = get_current_tool()
	if tool:
		return tool.tool_type
	return -1

func _use_current_tool() -> void:
	var tool = get_current_tool()
	if not tool:
		return
	
	if tool.tool_type == ItemTool.ToolType.HUMMER:
		if interact_ray.is_colliding():
			var collider = interact_ray.get_collider()
			var piece = building_system._find_building_piece_in_parents(collider)
			if piece:
				tool.use_tool()  # тратим прочность
				building_system.demolish_piece(piece)
		return
	
	if tool.tool_type == ItemTool.ToolType.HOE:
		return
	
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		
		# ===== ПРОВЕРКА МОБОВ =====
		if can_tool_interact_with(tool, collider):
			if collider.has_method("take_damage"):
				var damage = tool.get_modified_damage()
				collider.take_damage(damage, self, tool)
				tool.use_tool()
				return
		
		# ===== ПРОВЕРКА САМОГО КОЛЛАЙДЕРА =====
		if collider and collider.has_method("mine"):
			if can_tool_interact_with(tool, collider):
				collider.mine(self, tool)
				tool.use_tool()
				return
		
		# ===== ПОИСК РОДИТЕЛЯ ← ИСПРАВЛЕНО =====
		if collider:  # ← ДОБАВИЛИ ПРОВЕРКУ!
			var mineable_parent = collider.get_parent()
			var depth = 0
			while mineable_parent and depth < 5:
				if mineable_parent.has_method("mine"):
					if can_tool_interact_with(tool, mineable_parent):
						mineable_parent.mine(self, tool)
						tool.use_tool()
						return
				mineable_parent = mineable_parent.get_parent()
				depth += 1
		

func can_tool_interact_with(tool: ItemTool, collider: Node) -> bool:
	if not collider:
		return false
	
	var tool_type = tool.tool_type
	
	match tool_type:
		ItemTool.ToolType.PICKAXE:
			return (collider.is_in_group("ores") or 
					collider.is_in_group("stones") or
					collider.is_in_group("rocks"))
		
		ItemTool.ToolType.AXE:
			return (is_instance_valid(collider) and 
				   (collider.is_in_group("enemies") or 
					collider.is_in_group("peaceful_mobs") or
					collider.has_method("take_damage") or
					collider.is_in_group("trees")
					))
			
		
		ItemTool.ToolType.SHOVEL:
			return (collider.is_in_group("dirt") or
					collider.is_in_group("sand") or 
					collider.is_in_group("gravel"))
		
		ItemTool.ToolType.SWORD:
			return (is_instance_valid(collider) and 
				   (collider.is_in_group("enemies") or 
					collider.is_in_group("peaceful_mobs") or
					collider.has_method("take_damage")))
		
		ItemTool.ToolType.BOW:
			return false
		
		ItemTool.ToolType.SCISSORS, ItemTool.ToolType.BUCKET:
			return (is_instance_valid(collider) and 
				   collider.is_in_group("peaceful_mobs") and 
				   collider.has_method("take_damage"))
	
	return false

# ===== СИСТЕМА ПРЕДМЕТОВ =====
func _on_inventory_interface_drop_slot_data(slot_data: SlotData) -> void:
	var pick_up = PICK_UP_SCENE.instantiate()
	pick_up.slot_data = slot_data
	get_tree().current_scene.add_child(pick_up)
	
	await get_tree().process_frame
	
	var drop_distance := 3
	var forward_dir := -camera.global_transform.basis.z.normalized()
	var drop_origin := global_position + Vector3.UP * 1.0
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(drop_origin, drop_origin + forward_dir * drop_distance * 2.0)
	var result = space_state.intersect_ray(query)

	var drop_pos: Vector3
	if result:
		drop_pos = result.position + Vector3.UP * 0.3
	else:
		drop_pos = drop_origin + forward_dir * drop_distance

	pick_up.global_position = drop_pos

# ===== ТЕСТОВЫЕ ФУНКЦИИ =====
func _on_test_button_pressed() -> void:
	if gem_manager:
		gem_manager.add_random_gem_to_inventory(state.inventory_data, 1)
