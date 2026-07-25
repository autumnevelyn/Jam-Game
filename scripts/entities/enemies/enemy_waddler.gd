# enemy_waddler.gd
# simple patrolling enemy that bounces off walls.
# extends base_enemy for health/combat, adds waddler-specific movement.
extends "res://scripts/entities/enemies/base_enemy.gd"

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
	if(effects.has("Frozen")):
		velocity *= 0.5;
		health_component.take_damage(0.01 * effects.get("Frozen")[0], null);
		
		var value = effects.get("Frozen");
		value[1] -= delta;
		if(value[1] <= 0):
			effects.erase("Frozen");
		else:
			effects.set("Frozen", value)
	if(effects.has("Fire")):
		health_component.take_damage(0.1 * effects.get("Fire")[0], null);
		
		var value = effects.get("Fire");
		value[1] -= delta;
		if(value[1] <= 0):
			effects.erase("Fire");
		else:
			effects.set("Fire", value)
	
	move_and_slide()
