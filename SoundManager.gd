extends Node
class_name SoundManager

@onready var heartbeat_player: AudioStreamPlayer = $Sanity/Heartbeat/HeartbeatPlayer
@onready var distortion_player: AudioStreamPlayer = $Sanity/Distortion/DistortionPlayer
@onready var whisper_player: AudioStreamPlayer = $Sanity/Whisper/WhisperPlayer

@export var whisper_sounds: Array[AudioStream]
@export var distortion_sounds: Array[AudioStream]

# ------ Настройки градации ------
@export_category("Sanity Sound Levels")
@export var start_at_percentage: float = 0.45  # 45%
@export var max_intensity_percentage: float = 0.1  # 10%

# ------ Таймеры для случайных звуков ------
var whisper_timer: float = 0.0
var distortion_timer: float = 0.0
var current_sanity_level: float = 1.0

func _ready():
	_set_initial_volumes()
	
	var sanity_manager = get_tree().get_first_node_in_group("sanity_manager")
	if sanity_manager:
		sanity_manager.sanity_changed.connect(_on_sanity_changed_from_manager)
	else:
		print("❌ SanityManager не найден!")

func _on_sanity_changed_from_manager(new_value: float):
	var sanity_manager = get_tree().get_first_node_in_group("sanity_manager")
	var max_sanity = sanity_manager.max_sanity if sanity_manager else 100.0
	var sanity_perc = new_value / max_sanity
	
	current_sanity_level = sanity_perc
	_update_sanity_sounds()

func _update_sanity_sounds():
	var sanity_perc = current_sanity_level
	
	if sanity_perc > start_at_percentage:
		_stop_all_sounds()
		return
	
	var intensity = 1.0 - (sanity_perc / start_at_percentage)
	intensity = clamp(intensity, 0.0, 1.0)
	_update_background_sounds(intensity)
	_update_random_sounds(intensity)

func _update_background_sounds(intensity: float):
	distortion_player.volume_db = linear_to_db(intensity * 0.6) - 15
	
	if intensity > 0.5 and not distortion_player.playing:
		distortion_player.play()
	elif intensity <= 0.1 and distortion_player.playing:
		distortion_player.stop()

func _update_random_sounds(intensity: float):
	var min_interval = 2.0
	var max_interval = 10.0
	var current_interval = lerp(max_interval, min_interval, intensity)
	
	whisper_timer += get_process_delta_time()
	
	if whisper_timer >= current_interval:
		whisper_timer = 0.0
		_play_random_whisper(intensity)

func _play_random_whisper(intensity: float):
	if whisper_sounds.is_empty():
		return
	
	# Выбираем случайный звук
	var random_sound = whisper_sounds[randi() % whisper_sounds.size()]
	
	var temp_player = AudioStreamPlayer.new()
	add_child(temp_player)
	temp_player.stream = random_sound
	
	temp_player.volume_db = linear_to_db(intensity * 0.8) - 10
	
	temp_player.pitch_scale = randf_range(0.9, 1.1)
	
	temp_player.play()
	temp_player.finished.connect(func(): temp_player.queue_free())

func _stop_all_sounds():
	whisper_timer = 0.0
	distortion_timer = 0.0
	
	if distortion_player.playing:
		var tween = create_tween()
		tween.tween_property(distortion_player, "volume_db", -80, 2.0)
		tween.tween_callback(distortion_player.stop)

func _set_initial_volumes():
	distortion_player.volume_db = -80
	whisper_player.volume_db = -80
