# skill.gd
# resource defining a skill/ability that can be equipped to a slot.
class_name Skill
extends Resource

@export var texture: Texture2D
@export var skill_name: String = ""
@export var description: String = ""

@export var auto_trigger: bool = false
@export var cast_time: float = 1.0
@export var cooldown_time: float = 1.0

@export var damage: float = 1.0
@export var hitbox_size: Shape2D
@export var range: float = 1.0
@export var homing: bool = false
