extends ItemData
class_name ItemTool

enum ToolType {AXE, PICKAXE, SHOVEL, HOE, SWORD, BOW, SCISSORS, BUCKET, HUMMER}
signal durability_changed(tool: ItemTool)
@export var tool_type: ToolType
@export var efficiency: float = 1.0 
@export var damage: int
@export var attack_speed: float = 1.0
@export var max_sockets: int = 0
@export var critical_damage_chance: float
var inserted_gems: Array[GemData] = []
@export var durability: int
var current_durability: int

signal tool_broken(tool: ItemTool)

	
func _init():
	item_type = "Инструмент"
	stackable = false
	
	

func _get_description() -> String:
	var desc = super._get_description()
	
	if current_durability == 0 and durability > 0:
			current_durability = durability
	
	
	desc += "\n\nХарактеристики:"
	desc += "\nПрочность: %.1f" % durability
	desc += "\nЭффективность: %.1f" % efficiency
	desc += "\nУрон: %d" % damage
	desc += "\nСкорость атаки: %.1f" % attack_speed
	desc += "\nШанс критического урона: %.1f" % critical_damage_chance
	desc += "\nТип предмета: Инструмент"
	
	if inserted_gems.size() > 0:
		desc += "\n\nВставленные самоцветы:"
		for gem in inserted_gems:
			desc += "\n- %s" % gem.gem_name
	
	return desc

func use_tool() -> bool:
	print("use_tool(): current_durability=", current_durability, " durability=", durability)
	
	if current_durability <= 0:
		print("  → Already broken!")
		return false
	
	current_durability -= 1
	durability_changed.emit(self)
	
	if current_durability <= 0:
		print("  → BROKEN! Emitting signal...")
		tool_broken.emit(self)
		return false
	
	return true


func can_use() -> bool:
	return current_durability > 0

func insert_gem(gem_data: GemData) -> bool:
	if inserted_gems.size() < max_sockets:
		inserted_gems.append(gem_data)
		_apply_gem_bonuses(gem_data)
		return true
	return false

func _apply_gem_bonuses(gem_data: GemData):
	for stat_type in gem_data.stat_boosts:
		var value = gem_data.stat_boosts[stat_type]
		match stat_type:
			GemData.StatType.EFFICIENCY:
				efficiency += float(value) / 100.0
			GemData.StatType.ATTACK_SPEED:
				attack_speed += float(value) / 100.0
			GemData.StatType.SWORD_DAMAGE, GemData.StatType.ARROW_DAMAGE:
				if _should_apply_damage_bonus(stat_type):
					damage += value

func _should_apply_damage_bonus(stat_type: GemData.StatType) -> bool:
	match tool_type:
		ToolType.SWORD: return stat_type == GemData.StatType.SWORD_DAMAGE
		ToolType.BOW: return stat_type == GemData.StatType.ARROW_DAMAGE
		_: return false

func get_modified_damage() -> int:
	return damage

func get_modified_efficiency() -> float:
	return efficiency

func get_mob_damage() -> int:
	var base_damage = get_modified_damage()
	
	match tool_type:
		ToolType.SWORD:
			return base_damage
		ToolType.AXE:
			return int(base_damage * 0.8)
		ToolType.PICKAXE:
			return int(base_damage * 0.6)
		ToolType.SHOVEL:
			return int(base_damage * 0.4)
		_:
			return base_damage
