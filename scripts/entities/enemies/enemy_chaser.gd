# enemy_waddler.gd
# simple patrolling enemy that bounces off walls.
# extends base_enemy for health/combat, adds waddler-specific movement.
extends "res://scripts/entities/enemies/base_enemy.gd"

@onready var detect_shape: Area2D = $detect_shape

const SKILL = preload("res://scenes/prefabs/skill.tscn")
const HEART = preload("res://scenes/prefabs/heart.tscn")

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var item_drop: ItemDrop = preload("res://scenes/prefabs/items/item_drop_default.tres");
@export var health_drop: float = 0.5;

## Initial patrol direction.

var target: Node2D;
var startPos := Vector2(0.0, 0.0);

var _direction: Vector2 = Vector2(0.0, 0.0)


func _ready() -> void:
	super._ready()
	knockback_power = 50.0;
	
	animated_sprite_2d = $AnimatedSprite2D
	startPos = position;

func _physics_process(delta: float) -> void:
	
	if(not isDead and not hurting):
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
			if(velocity.angle() > PI / 4 and velocity.angle() < PI * 3 / 4):
				animated_sprite_2d.play("walk_down");
			elif(velocity.angle() < -PI / 4 and velocity.angle() > -PI * 3 / 4):
				animated_sprite_2d.play("walk_up");
			else:
				animated_sprite_2d.play("walk_side");
				animated_sprite_2d.flip_h = abs(velocity.angle()) > PI * 3 / 4;
		if(not audio_stream_player_2d.playing):
			audio_stream_player_2d.pitch_scale = randf_range(0.8, 1.1);
			audio_stream_player_2d.play();
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
					animated_sprite_2d.flip_h = abs(velocity.angle()) > PI * 3 / 4;
	
	move_and_slide()

func _on_died():
	var item_type = item_drop.getItem();
	var droped_item = SKILL.instantiate();
	
	#droped_item.get_child(1).texture = item_type.texture;
	
	add_sibling(droped_item);
	droped_item.skill = item_type;
	print_rich("dropped: ", item_type)
	droped_item.position = position;
	droped_item.update();
	
	if(randf() < health_drop):
		print("ehart droped")
		var heart = HEART.instantiate();
		
		add_sibling(heart);
		heart.position = position;
	
	super._on_died()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.name == "player"):
		target = body;


func _on_area_2d_body_exited(body: Node2D) -> void:
	if(body.name == "player"):
		target = null;


func _on_animated_sprite_2d_animation_finished() -> void:
	if(animated_sprite_2d.animation == "dies"):
		queue_free();
	elif(hurting):
		hurting = false;
