extends Resource
class_name EnchantmentData

@export var enchant_name: String
@export var description: String
@export var texture: Texture2D
@export var rarity: Rarity

enum Rarity {COMMON, RARE, EPIC, LEGENDARY}

# Активируемая способность
@warning_ignore("unused_parameter")
func activate(player: PlayerController, armor: ArmorItemData):
	pass

# Пассивный эффект
@warning_ignore("unused_parameter")
func apply_passive_effect(player: PlayerController):
	pass

# Можно ли применить к этому типу брони
@warning_ignore("unused_parameter")
func can_apply_to(armor_type: ArmorItemData.ArmorType) -> bool:
	return true
