# enemy_waddler.gd
# simple patrolling enemy that bounces off walls.
# extends base_enemy for health/combat, adds waddler-specific movement.
extends "res://entities/enemies/base_enemy.gd"

## Initial patrol direction.
@export var initial_direction: Vector2 = Vector2(1.0, 0.0)

var _direction: Vector2 = Vector2(1.0, 0.0)


func _ready() -> void:
	super._ready()
	_direction = initial_direction.normalized()


func _physics_process(delta: float) -> void:
	# bounce off walls
	if initial_direction.x != 0 and is_on_wall():
		_direction.x *= -1
	if initial_direction.y != 0 and (is_on_ceiling() or is_on_floor()):
		_direction.y *= -1

	velocity = _direction * speed
	move_and_slide()
