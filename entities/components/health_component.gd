# healthComponent.gd
# reusable health management for any entity (player, enemy, destructible).
class_name HealthComponent
extends Node

## Emitted when health changes.
signal health_changed(old_value: float, new_value: float, max_value: float)
## Emitted when the entity takes damage.
signal damaged(amount: float, source: Node)
## Emitted when the entity dies.
signal died

## Maximum health.
@export var max_health: float = 3.0
## Invincibility duration after taking damage (seconds). 0 = no i-frames.
@export var invincibility_time: float = 0.0

## Current health.
var health: float:
	set(value):
		var old = health
		health = clampf(value, 0.0, max_health)
		health_changed.emit(old, health, max_health)
		if health <= 0.0:
			died.emit()

## Whether the entity is currently invincible.
var is_invincible: bool = false


func _ready() -> void:
	health = max_health


## Apply damage to this entity.
## Returns the actual damage dealt (after armor/invincibility).
func take_damage(amount: float, source: Node = null) -> float:
	if is_invincible or health <= 0.0:
		return 0.0

	var actual = min(amount, health)
	health -= amount
	damaged.emit(actual, source)

	if invincibility_time > 0.0:
		_start_invincibility()

	return actual


## Heal the entity. Returns actual amount healed.
func heal(amount: float) -> float:
	var before = health
	health += amount
	return health - before


## Kill the entity instantly.
func kill() -> void:
	health = 0.0


func _start_invincibility() -> void:
	if is_invincible:
		return
	is_invincible = true
	await get_tree().create_timer(invincibility_time).timeout
	is_invincible = false
