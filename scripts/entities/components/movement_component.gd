# movementComponent.gd
# handles movement logic for any CharacterBody2D entity.
class_name MovementComponent
extends Node

## Base movement speed in pixels/sec.
@export var speed: float = 100.0
## If true, knockback is applied.
@export var knockback_enabled: bool = true
## Knockback decay factor per frame (0.0–1.0).
@export var knockback_decay: float = 0.8

var knockback: Vector2 = Vector2.ZERO

var _parent: CharacterBody2D = null


func _ready() -> void:
	_parent = get_parent() as CharacterBody2D
	if not _parent:
		push_error("MovementComponent must be a child of a CharacterBody2D.")


## Apply knockback force.
func apply_knockback(force: Vector2) -> void:
	if knockback_enabled:
		knockback += force


## Process movement. Call from the parent's _physics_process.
## `direction` should be a normalized input vector.
func process_movement(direction: Vector2, delta: float) -> void:
	if not _parent:
		return

	# start fresh each frame (velocity is SET, not accumulated)
	_parent.velocity = Vector2.ZERO

	# apply knockback
	if not knockback.is_zero_approx():
		_parent.velocity += knockback
		knockback *= knockback_decay

	# apply movement direction
	if direction.length() > 0.0:
		_parent.velocity += direction * speed
	
	# apply frozen slow from status effects
	var status_comp = _find_status_effect_component(_parent)
	if status_comp and status_comp.has_status(Effect.Type.FREEZE):
		_parent.velocity *= status_comp.get_slow_multiplier()

	_parent.move_and_slide()


## Stop all movement immediately.
func _find_status_effect_component(node: Node) -> StatusEffectComponent:
	if not node:
		return null
	for child in node.get_children():
		if child is StatusEffectComponent:
			return child
	if node is StatusEffectComponent:
		return node
	return null
func stop() -> void:
	if _parent:
		_parent.velocity = Vector2.ZERO
