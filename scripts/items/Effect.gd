# effect resource for a status that can be applied by skills, attacks, or environment
class_name Effect
extends Resource

enum Type {
	BURN,
	FREEZE,
	DAMAGE_UP,
}

## which type of effect this is
@export var type: Type
## potency — damage per tick for burn, slow amount for freeze
@export var base_strength: float = 1.0
## how many ticks the effect lasts when applied
@export var base_duration_ticks: int = 3
