extends Node3D

@export var mouse_sens: float = 0.003
@export_range(-90.0,0.0,0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2
@export_range(0.0,90.0,0.1, "radians_as_degrees") var max_vertical_angle: float = -PI/2
@onready var spring_arm_3d: SpringArm3D = $SpringArm3D
@onready var state: PlayerState = $"../state"  # Добавь эту ссылку
@onready var visuals: Node3D = $"../visuals"


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * mouse_sens
		rotation.y = wrapf(rotation.y, 0, TAU)
		
		rotation.x -= event.relative.y * mouse_sens
		rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)
	
	if event.is_action_pressed("wheel_up"):
		spring_arm_3d.spring_length -= 1
	if event.is_action_pressed("wheel_down"):
		spring_arm_3d.spring_length += 1
	if event.is_action_pressed("toggle_camera"):
		state.set_first_person_mode(!state.is_first_person)
		_update_camera_mode()
	spring_arm_3d.spring_length = clamp(spring_arm_3d.spring_length, 0.8, 6.0)

func _update_camera_mode():
	if state.is_first_person:
		spring_arm_3d.spring_length = 0.1  # Минимальное расстояние
	else:
		spring_arm_3d.spring_length = 3.0  # Нормальное расстояние
