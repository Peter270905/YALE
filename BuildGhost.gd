extends Node3D
class_name BuildGhost

var mesh_instance: MeshInstance3D
var is_valid: bool = true

func _ready():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 2.0, 0.2)
	mesh_instance.mesh = box_mesh
	_setup_material()

func _setup_material():
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if is_valid:
		material.albedo_color = Color(0, 1, 0, 0.3)
	else:
		material.albedo_color = Color(1, 0, 0, 0.3)
	mesh_instance.set_surface_override_material(0, material)

@warning_ignore("shadowed_variable_base_class")
func update_position(position: Vector3):
	global_position = position

func set_valid(valid: bool):
	if is_valid != valid:
		is_valid = valid
		_setup_material()

func cleanup():
	queue_free()

func setup_from_buildable(buildable_data: BuildableItemData):
	if not buildable_data.build_scene:
		return
	
	var preview_scene = buildable_data.build_scene.instantiate()
	
	var meshes = _find_all_meshes(preview_scene)
	if meshes.is_empty():
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.mesh.size = Vector3(1, 1, 1)
	else:
		mesh_instance.mesh = meshes[0].mesh.duplicate()
		mesh_instance.transform = meshes[0].transform
	
	_apply_ghost_material()
	
	# ← Копируем маркеры из оригинальной сцены в призрак
	for child in preview_scene.get_children():
		if child is Marker3D and "snap" in child.name.to_lower():
			var marker_copy = Marker3D.new()
			marker_copy.name = child.name
			marker_copy.position = child.position
			marker_copy.rotation = child.rotation
			add_child(marker_copy)
	
	preview_scene.queue_free()

# ← Возвращает все snap-маркеры с их мировыми позициями
func get_snap_markers_world() -> Array:
	var markers = []
	for child in get_children():
		if child is Marker3D and "snap" in child.name.to_lower():
			markers.append({
				"world_position": child.global_position,
				"local_position": child.position,
				"name": child.name
			})
	return markers

func _find_all_meshes(node: Node) -> Array:
	var meshes = []
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		var child_meshes = _find_all_meshes(child)
		for mesh in child_meshes:
			meshes.append(mesh)
	return meshes

func _apply_ghost_material():
	for i in range(mesh_instance.get_surface_override_material_count()):
		var original = mesh_instance.get_surface_override_material(i)
		if original:
			var ghost_mat = original.duplicate()
			ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ghost_mat.albedo_color.a = 0.4
			mesh_instance.set_surface_override_material(i, ghost_mat)
		else:
			var new_mat = StandardMaterial3D.new()
			new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			new_mat.albedo_color = Color(0, 1, 0, 0.4)
			mesh_instance.set_surface_override_material(i, new_mat)

func _find_mesh_in_scene(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var mesh = _find_mesh_in_scene(child)
		if mesh:
			return mesh
	return null
