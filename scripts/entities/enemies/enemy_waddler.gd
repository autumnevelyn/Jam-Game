# enemy_waddler.gd
# simple patrolling enemy that bounces off walls.
# extends base_enemy for health/combat, adds waddler-specific movement.
extends "res://scripts/entities/enemies/base_enemy.gd"


## Initial patrol direction.
@export var initial_direction: Vector2 = Vector2(1.0, 0.0)

var _direction: Vector2 = Vector2(1.0, 0.0)


func _ready() -> void:
	super._ready()
	
	animated_sprite_2d = $AnimatedSprite2D
	_direction = initial_direction.normalized()


func _physics_process(delta: float) -> void:
	# bounce off walls
	#print(animated_sprite_2d.animation)
	if(not isDead and not hurting):
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
			
		if(effects.has("Frozen")):
			modulate = Color(0.7, 0.7, 1.0, 1.0);
			animated_sprite_2d.speed_scale = 0.5;
		elif(effects.has("Fire")):
			modulate = Color(1.0, 0.5, 0.5, 1.0);
			animated_sprite_2d.speed_scale = 1.0;
		else:
			modulate = Color(1.0, 1.0, 1.0, 1.0);
			animated_sprite_2d.speed_scale = 1.0;
			
		if(not hurting):
			if(_direction.is_equal_approx(Vector2.DOWN)):
				animated_sprite_2d.play("walk_down");
			elif(_direction.is_equal_approx(Vector2.UP)):
				animated_sprite_2d.play("walk_up");
			elif(_direction.is_equal_approx(Vector2.LEFT) or _direction.is_equal_approx(Vector2.RIGHT)):
				animated_sprite_2d.play("walk_side");
				animated_sprite_2d.flip_h = _direction.is_equal_approx(Vector2.LEFT);
		
		
		move_and_slide()
	else:
		if(isDead and animated_sprite_2d.animation != "dies"):
			animated_sprite_2d.play("dies");
		elif(hurting and not isDead):
			move_and_slide();
			if(animated_sprite_2d.animation != "hurt_down" and animated_sprite_2d.animation != "hurt_up" and animated_sprite_2d.animation != "hurt_side"):
				if(velocity.angle() > PI / 4 and velocity.angle() < PI * 3 / 4):
					animated_sprite_2d.play("hurt_up");
				elif(velocity.angle() < -PI / 4 and velocity.angle() > -PI * 3 / 4):
					animated_sprite_2d.play("hurt_down");
				else:
					animated_sprite_2d.play("hurt_side");
					animated_sprite_2d.flip_h = velocity.is_equal_approx(Vector2.LEFT);
		

func _on_animated_sprite_2d_animation_finished() -> void:
	if(animated_sprite_2d.animation == "dies"):
		queue_free();
	elif(hurting):
		hurting = false;
