extends CharacterBody2D

@export var initialDirection := Vector2(1.0, 0.0);
@export var speed = 50.0;

var direction = initialDirection;


func _physics_process(delta: float) -> void:

	if(initialDirection.x and is_on_wall()):
		direction.x *= -1;
	if(initialDirection.y and (is_on_ceiling() or is_on_floor())):
		direction.y *= -1;
	
	velocity = direction * speed;

	move_and_slide()
