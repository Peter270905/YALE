extends Node3D
class_name BuildingPiece

@export var building_type: String = "wall"
@export var snap_points: Array[String] = ["left", "right", "top", "bottom"]
@export var connection_cost: int = 1
var connected_pieces: Array = []

# ← Хранит имена занятых маркеров
var occupied_markers: Array[String] = []

func _ready():
	add_to_group("buildings")
	add_to_group(building_type)

func get_snap_points() -> Array:
	var points = []
	for child in get_children():
		if child is Marker3D and "snap" in child.name.to_lower():
			# ← Пропускаем занятые точки
			if child.name in occupied_markers:
				continue
			
			var full_name = child.name.to_lower().replace("snap_", "")
			var snap_type = full_name.split("_")[0]
			
			var direction: Vector3
			if "top" in full_name:
				direction = child.global_transform.basis.y.normalized()
			elif "bottom" in full_name:
				direction = -child.global_transform.basis.y.normalized()
			else:
				direction = -child.global_transform.basis.z.normalized()
			
			points.append({
				"position": child.global_position,
				"rotation": child.global_rotation,
				"type": snap_type,
				"direction": direction,
				"parent": self,
				"marker_name": child.name  # ← имя маркера для пометки
			})
	return points

# ← Помечаем маркер как занятый
func occupy_marker(marker_name: String):
	if marker_name not in occupied_markers:
		occupied_markers.append(marker_name)

# ← Освобождаем маркер (при разборе соседа)
func free_marker(marker_name: String):
	occupied_markers.erase(marker_name)

# ← Найти ближайший маркер к позиции
func get_nearest_marker_name(world_position: Vector3) -> String:
	var best_name = ""
	var best_dist = INF
	for child in get_children():
		if child is Marker3D and "snap" in child.name.to_lower():
			var dist = child.global_position.distance_to(world_position)
			if dist < best_dist:
				best_dist = dist
				best_name = child.name
	return best_name

func get_free_snap_point(exclude_type: String = "") -> Dictionary:
	var points = get_snap_points()
	for point in points:
		if point.type != exclude_type:
			if not _is_point_occupied(point):
				return point
	return {}

func _is_point_occupied(point: Dictionary) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.3
	query.shape = sphere
	query.transform = Transform3D(Basis(), point.position)
	var results = space_state.intersect_shape(query)
	return results.size() > 0

func connect_piece(other: BuildingPiece):
	if not connected_pieces.has(other):
		connected_pieces.append(other)
		other.connected_pieces.append(self)

func disconnect_piece(other: BuildingPiece):
	connected_pieces.erase(other)
	other.connected_pieces.erase(self)
