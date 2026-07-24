# enemy_waddler.gd
# simple patrolling enemy that bounces off walls.
# extends base_enemy for health/combat, adds waddler-specific movement.
extends "res://scripts/entities/enemies/base_enemy.gd"

@onready var detect_shape: Area2D = $detect_shape

const SKILL = preload("res://scenes/prefabs/skill.tscn")

@export var item_drop: ItemDrop;

## Initial patrol direction.

var target: Node2D;
var startPos := Vector2(0.0, 0.0);

var _direction: Vector2 = Vector2(0.0, 0.0)


func _ready() -> void:
	super._ready()
	
	startPos = position;
	EventBus.subscribe(EventBus.ENEMY_KILLED, _on_eneny_killed);


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

func _on_eneny_killed(data: Dictionary):
	if(data["enemy"] == self):
		var item_type = item_drop.getItem();
		var droped_item = SKILL.instantiate();
		
		#droped_item.get_child(1).texture = item_type.texture;
		
		add_sibling(droped_item);
		droped_item.skill = item_type;
		print(item_type)
		droped_item.position = position;
		droped_item.update();
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.name == "player"):
		target = body;
		print("a")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if(body.name == "player"):
		target = null;
