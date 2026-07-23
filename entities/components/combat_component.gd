# combatComponent.gd
# handles attack hitbox management for entities that deal damage.
class_name CombatComponent
extends Node

## Reference to the attack hitbox Area2D.
@export var hitbox: Area2D = null
## Base damage dealt.
@export var base_damage: float = 1.0
## How long the hitbox stays active (seconds).
@export var hitbox_duration: float = 0.25

## Whether an attack is currently active.
var is_attacking: bool = false

var _timer: Timer = null


func _ready() -> void:
	if hitbox:
		hitbox.active = false
		hitbox.visible = false

		# set up auto-deactivation timer
		_timer = Timer.new()
		_timer.one_shot = true
		_timer.wait_time = hitbox_duration
		_timer.timeout.connect(_on_hitbox_timeout)
		add_child(_timer)


## Start an attack, placing the hitbox in the given direction.
func attack(direction: Vector2) -> void:
	if not hitbox or is_attacking:
		return

	is_attacking = true
	hitbox.active = true
	hitbox.position = direction * 16.0
	hitbox.visible = true
	hitbox.damage = base_damage

	if _timer:
		_timer.start()


## Cancel the current attack.
func cancel_attack() -> void:
	is_attacking = false
	if hitbox:
		hitbox.active = false
		hitbox.visible = false
		hitbox.position = Vector2.ZERO
	if _timer:
		_timer.stop()


func _on_hitbox_timeout() -> void:
	cancel_attack()
