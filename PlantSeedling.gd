extends HarvestableObject
class_name PlantSeedling

# ===== НАСТРОЙКИ РОСТА =====
@export var growth_time: float = 600.0  # 10 минут
@export var stages: Array[PackedScene] = []  # [росток, куст, взрослое]
@export var giant_chance: float = 0.02  # 2%

# ===== ЛУТ =====
@export var normal_loot: Array[DropData] = []
@export var giant_loot: Array[DropData] = []

# ===== СОСТОЯНИЕ =====
var timer: float = 0.0
var growth_stage: int = 0
var is_giant: bool = false
var is_ready: bool = false

func _ready():
	add_to_group("plants")
	_determine_if_giant()
	_update_visual()
	set_active(false)  # Нельзя собрать пока не выросло

func _determine_if_giant():
	if randf() < giant_chance:
		is_giant = true
		print("🎉 ГИГАНТ!")

func _process(delta):
	if not is_ready and growth_stage < stages.size() - 1:
		timer += delta
		if timer >= growth_time / stages.size():
			_grow_next_stage()

func _grow_next_stage():
	growth_stage += 1
	_update_visual()
	
	if growth_stage >= stages.size() - 1:
		is_ready = true
		set_active(true)  # Теперь можно собрать!
		print("✅ Выросло!")

func _update_visual():
	if stages.size() > growth_stage and has_node("MeshInstance3D"):
		$MeshInstance3D.mesh = stages[growth_stage].instantiate().mesh
	
	if is_giant and is_ready:
		scale = Vector3(2, 2, 2)  # Гигант в 2 раза больше

# ===== СБОР (через HarvestableObject) =====
func player_interact(player: PlayerController) -> bool:
	if not is_ready:
		if player.interact_label:
			player.interact_label.text = "⏳ Ещё не созрело..."
		return false
	
	# Если гигант — используем особый лут
	if is_giant and giant_loot.size() > 0:
		var original = drops.duplicate()
		drops = giant_loot
		var result = super.player_interact(player)
		drops = original
		return result
	
	return super.player_interact(player)
