# skill.gd
# resource defining a skill/ability that can be equipped to a slot.
# tick-based timer system: each tick = 0.5s
class_name Skill
extends Resource

## Types of skills
enum SkillType {
	BASIC_ATTACK,  # The default click-to-attack; 1-tick timer, small damage
	DAMAGE,        # Deals damage; combines with other attacks on timer expiry
	BUFF,          # Self-buff; wasted if no outgoing attack when timer expires
	MOD,           # Modifies an outgoing attack; wasted if no attack when timer expires
	UTIL,          # Utility effect; wasted if no outgoing attack when timer expires
}

@export var texture: Texture2D
@export var skill_name: String = ""
@export var description: String = ""

## The type of skill – determines behaviour on timer expiry
@export var skill_type: SkillType = SkillType.DAMAGE

## Duration in ticks (1 tick = 0.5 seconds)
@export var ticks: int = 1

## Base damage dealt (for BASIC_ATTACK and DAMAGE types)
@export var base_damage: float = 1.0

## Named effect applied on hit (e.g. "burn", "freeze", "stun")
@export var effect_name: String = ""

## Strength/stack of the effect
@export var effect_strength: float = 1.0

## Hitbox shape and range
@export var hitbox_size: Shape2D
@export var range: float = 1.0
@export var homing: bool = false
