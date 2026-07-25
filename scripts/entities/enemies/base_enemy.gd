# base_enemy.gd
# base class for all enemy types. Provides health, movement, and combat components.
extends CharacterBody2D

enum Rating {MINION, EASY, MEDIUM, HARD, BOSS}

@onready var health_component: HealthComponent = $health_component
@onready var movement_component: MovementComponent = $movement_component

@export var speed: float = 50.0
@export var damage: float = 1.0

@export var enemyRating: Rating = Rating.MINION;

var knockback_power := 100.0;
var effects = {};
var animated_sprite_2d: AnimatedSprite2D;
var isDead := false;
var hurting := false;

func _ready() -> void:
	if health_component:
		health_component.died.connect(_on_died)
	if movement_component:
		movement_component.speed = speed
	
	EventBus.subscribe(EventBus.COMBAT_HIT, _on_combat_hit);

func _exit_tree() -> void:
	#if health_component and health_component.died.is_connected(_on_died):
	#	health_component.died.disconnect(_on_died)
	EventBus.unsubscribe(EventBus.COMBAT_HIT, _on_combat_hit);

func _on_combat_hit(data: Dictionary):
	if(data["target"] == self):
		for effect in data["effects"]:
			var effect_length := 5.0;
			if(effect.name == "Frozen"):
				effect_length = 10.0;
			effects.set(effect.name, [effect.strength, effect_length]);
			
		if(animated_sprite_2d):
			hurting = true;
			velocity = Vector2().from_angle(data["attacker"].get_angle_to(self.position)) * knockback_power;
			if(velocity.angle() > PI / 4 and velocity.angle() < PI * 3 / 4):
				animated_sprite_2d.play("hurt_up");
			elif(velocity.angle() < -PI / 4 and velocity.angle() > -PI * 3 / 4):
				animated_sprite_2d.play("hurt_down");
			else:
				animated_sprite_2d.play("hurt_side");
				animated_sprite_2d.flip_h = velocity.is_equal_approx(Vector2.LEFT);

func _on_died() -> void:
	
	dropGold();
	
	EventBus.emit_event(EventBus.ENEMY_KILLED, {
		"enemy": self,
		"position": global_position,
	})
	if(animated_sprite_2d):
		print(animated_sprite_2d)
		animated_sprite_2d.play("dies");
		isDead = true;
	else: queue_free()

func dropGold():
	match(enemyRating):
		Rating.EASY:
			PlayerData.gain_gold(10);
		Rating.MEDIUM:
			PlayerData.gain_gold(30);
		Rating.HARD:
			PlayerData.gain_gold(50);
		Rating.BOSS:
			PlayerData.gain_gold(50);

## Apply damage to this enemy.
#func take_damage(amount: float, source: Node = null) -> float:
#	if health_component:
#		print(amount);
#		return health_component.take_damage(amount, source)
#	return 0.0
