# item.gd
# base Resource for all equippable items.
class_name Item
extends Resource

@export var texture: Texture2D
@export var item_name: String = ""
@export var description: String = ""
@export var countdown_time: float = 0.0
@export var damage: float = 1.0
@export var rarity: String = "common"  # common, uncommon, rare, epic, legendary
