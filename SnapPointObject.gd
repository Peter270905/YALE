extends Node3D
class_name SnapPointObject

@export var snap_points: Array[Dictionary] = []

func _ready():
	# Автоматически находим все маркеры в объекте
	_find_snap_markers()

func _find_snap_markers():
	for child in get_children():
		if child is Marker3D:
			var point_data = {
				"type": _get_snap_type_from_name(child.name),
				"position": child.global_position,
				"rotation": child.rotation_degrees.y,
				"normal": child.global_transform.basis.z
			}
			snap_points.append(point_data)

func _get_snap_type_from_name(marker_name: String) -> String:
	var name_lower = marker_name.to_lower()
	if "floor" in name_lower: return "floor"
	if "wall" in name_lower: return "wall" 
	if "ceiling" in name_lower: return "ceiling"
	if "foundation" in name_lower: return "foundation"
	return "generic"

func get_snap_points() -> Array:
	return snap_points
