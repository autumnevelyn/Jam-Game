# enemy_waddler.gd
# simple patrolling enemy that bounces off walls.
# extends base_enemy for health/combat, adds waddler-specific movement.
extends "res://scripts/entities/enemies/base_enemy.gd"

enum BossState { IDLE, TELEGRAPH_JUMP, JUMP, IN_AIR, LAND };

@onready var detect_shape: Area2D = $detect_shape
@onready var check_position: Area2D = $check_position
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2

const SKILL = preload("res://scenes/prefabs/skill.tscn")

#@export var item_drop: ItemDrop;

## Initial patrol direction.

var target: Node2D;
var startPos := Vector2(0.0, 0.0);

var _direction: Vector2 = Vector2(0.0, 0.0)
var jump_pos: Vector2;
var land_pos: Vector2;
var invinsible: bool = false;


func _ready() -> void:
	super._ready()
	
	startPos = position;
	EventBus.subscribe(EventBus.ENEMY_KILLED, _on_eneny_killed);

func _physics_process(delta: float) -> void:
	
	detect_shape.position = startPos - position;

	move_and_slide()

func state_idle_enter():
	animated_sprite_2d.play("idle");
	
	collision_shape_2d.shape.size = Vector2(26.0, 8.0);
	
	timer.wait_time = 5;
	timer.start();

func state_idle_process():
	pass


func state_telegraph_jump_enter():
	print("aaaaaaaaa")
	jump_pos = position;
	land_pos = startPos + Vector2().from_angle(randf_range(-PI, PI)) * randi_range(0, 175);
	
	animated_sprite_2d.play("telegraph_jump");
	timer.wait_time = 0.5;
	timer.start();
	
func state_telegraph_jump_process():
	pass


func state_jump_enter():
	animated_sprite_2d.play("jump");
	timer.wait_time = 0.1;
	timer.start();

func state_jump_process():
	pass


func state_in_air_enter():
	animated_sprite_2d.play("in_air");
	
	collision_shape_2d.disabled = true;
	
	var tween = create_tween();
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", land_pos, (land_pos.distance_to(jump_pos) / speed) + 1);
	
	await tween.finished;
	
	state_machine.transition("LAND");

func state_in_air_process():
	pass


func state_land_enter():
	collision_shape_2d.disabled = false;
	collision_shape_2d.shape.size = Vector2(84.0, 64.0);
	
	animated_sprite_2d.play("land");
	animated_sprite_2d_2.play("default");
	
	timer.wait_time = 0.1;
	timer.start();

func state_land_process():
	pass


func _on_eneny_killed(data: Dictionary):
	if(data["enemy"] == self):
		#var item_type = item_drop.getItem();
		var droped_item = SKILL.instantiate();
		
		add_sibling(droped_item);
		#droped_item.skill = item_type;
		droped_item.position = position;
		droped_item.update();

func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.name == "player"):
		target = body;
		print("a")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if(body.name == "player"):
		target = null;

func _on_timer_timeout() -> void:
	print("timer " + state_machine.current_state)
	match(state_machine.current_state):
		"IDLE":
			print("idle")
			state_machine.transition("TELEGRAPH_JUMP");
		"TELEGRAPH_JUMP":
			print("telergraph")
			state_machine.transition("JUMP");
		"JUMP":
			print("jump")
			state_machine.transition("IN_AIR");
		"IN_AIR":
			pass
		"LAND":
			print("jump")
			state_machine.transition("IDLE");
