# relic.gd
# resource defining a passive relic/buff that modifies gameplay.
class_name Relic
extends Resource

@export var texture: Texture2D
@export var relic_name: String = ""
@export var description: String = ""
@export var modifier_type: String = ""  # e.g. "damage", "speed", "health", "cooldown"
@export var modifier_value: float = 0.0
@export var modifier_percent: float = 0.0
