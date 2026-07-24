# enemy_waddler.gd
# simple patrolling enemy that bounces off walls.
# extends base_enemy for health/combat, adds waddler-specific movement.
extends "res://scripts/entities/enemies/base_enemy.gd"

@onready var detect_shape: Area2D = $detect_shape

@export var item_drop: Skill;

## Initial patrol direction.

var target: Node2D;
var startPos := Vector2(0.0, 0.0);

var _direction: Vector2 = Vector2(0.0, 0.0)


func _ready() -> void:
	super._ready()
	
	startPos = position;


func _physics_process(delta: float) -> void:
	
	detect_shape.position = startPos - position;
	
	if(target):
		var direction = Vector2.from_angle(get_angle_to(target.position)).normalized();
		_direction = direction;
	else:
		#_direction = Vector2((startPos - position), (startPos - position).normalized());
		if (startPos - position) < (startPos - position).normalized():
			_direction = (startPos - position)
		else:
			_direction = (startPos - position).normalized()

	velocity = _direction * speed
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("a")
	if(body.name == "player"):
		target = body;
		print("a")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if(body.name == "player"):
		target = null;
