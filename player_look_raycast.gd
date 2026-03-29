extends Node3D

@export_node_path("Skeleton3D") var skeleton_path
@export_node_path("Camera3D") var camera_path
@export_node_path("RayCast3D") var raycast_path

@export var head_bone_name: String = "mixamorig_Head"
@export var ray_length: float = 30.0
@export var smoothing: float = 1.0
@export var offset_from_head: Vector3 = Vector3(0, 0.12, 0)

@onready var skeleton: Skeleton3D = $"../visuals/Idle/Skeleton3D"
@onready var cam: Camera3D = $"../camera/Camera3D"
@onready var raycast: RayCast3D = $InteractRay
var head_bone_idx: int
var current_transform: Transform3D

func _ready():
	if skeleton_path:
		skeleton = get_node_or_null(skeleton_path) as Skeleton3D
	if camera_path:
		cam = get_node_or_null(camera_path) as Camera3D
	if raycast_path:
		raycast = get_node_or_null(raycast_path) as RayCast3D

	if not skeleton:
		push_warning("Скелет не назначен или не найден (skeleton_path).")
		return
	if not cam:
		push_warning("Камера не назначена или не найдена (camera_path).")
		return
	if not raycast:
		push_warning("RayCast3D не назначен или не найден (raycast_path).")
		return

	head_bone_idx = skeleton.find_bone(head_bone_name)
	if head_bone_idx == -1:
		push_warning("Кость головы не найдена: '%s'." % head_bone_name)
		return

	raycast.enabled = true
	raycast.target_position = Vector3(0, 0, -ray_length) 
	current_transform = raycast.global_transform

func _physics_process(delta: float) -> void:
	if not skeleton or not cam or not raycast or head_bone_idx == -1:
		return

	var head_pose: Transform3D = skeleton.get_bone_global_pose(head_bone_idx)
	var head_global_pos: Vector3 = skeleton.global_transform * head_pose.origin

	if offset_from_head != Vector3.ZERO:
		var offset_global = skeleton.global_transform.basis * (head_pose.basis * offset_from_head)
		head_global_pos += offset_global

	var cam_basis: Basis = cam.global_transform.basis

	var target_transform = Transform3D(cam_basis, head_global_pos)

	if smoothing <= 0.0:
		current_transform = target_transform
	elif smoothing >= 1.0:
		current_transform.origin = current_transform.origin.lerp(target_transform.origin, clamp(delta * 10.0, 0.0, 1.0))
		current_transform.basis = current_transform.basis.slerp(target_transform.basis, clamp(delta * 10.0, 0.0, 1.0))
	else:
		var t = clamp(1.0 - pow(1.0 - smoothing, delta * 60.0), 0.0, 1.0)
		current_transform.origin = current_transform.origin.lerp(target_transform.origin, t)
		current_transform.basis = current_transform.basis.slerp(target_transform.basis, t)

	raycast.global_transform = current_transform
	raycast.target_position = Vector3(0, 0, -ray_length)

	raycast.force_raycast_update()
