# base_enemy.gd
# base class for all enemy types. Provides health, movement, and combat components.
extends CharacterBody2D

enum Rating {MINION, EASY, MEDIUM, HARD, BOSS}

@onready var health_component: HealthComponent = $health_component
@onready var movement_component: MovementComponent = $movement_component

@export var speed: float = 50.0
@export var damage: float = 1.0

@export var enemyRating: Rating = Rating.MINION;

var status_effects: StatusEffectComponent
var knockback_power := 100.0;
var animated_sprite_2d: AnimatedSprite2D;
var isDead := false;
var hurting := false;

func _ready() -> void:
	if health_component:
		health_component.died.connect(_on_died)
	if movement_component:
		movement_component.speed = speed
	
	status_effects = StatusEffectComponent.new()
	add_child(status_effects)
	
	var status_indicator = EffectStatusIcon.new()
	status_indicator.name = "EffectStatusIcon"
	# position above the enemy (adjust as needed for different sprites)
	status_indicator._set_offset(Vector2(0, -24.0))
	add_child(status_indicator)
	
	EventBus.subscribe(EventBus.COMBAT_HIT, _on_combat_hit);

func _exit_tree() -> void:
	#if health_component and health_component.died.is_connected(_on_died):
	#	health_component.died.disconnect(_on_died)
	EventBus.unsubscribe(EventBus.COMBAT_HIT, _on_combat_hit);

func _on_combat_hit(data: Dictionary):
		if(animated_sprite_2d):
			hurting = true;
			if(enemyRating != Rating.BOSS):
				velocity = Vector2().from_angle(data["attacker"].get_angle_to(self.position)) * knockback_power;
			if(velocity.angle() > PI / 4 and velocity.angle() < PI * 3 / 4):
				animated_sprite_2d.play("hurt_up");
			elif(velocity.angle() < -PI / 4 and velocity.angle() > -PI * 3 / 4):
				animated_sprite_2d.play("hurt_down");
			else:
				animated_sprite_2d.play("hurt_side");
				animated_sprite_2d.flip_h = velocity.is_equal_approx(Vector2.LEFT);
	if data["target"] == self:
		# don't apply effects if already dying or dead
		if health_component and health_component.health <= 0.0:
			return
		var eff_list = data.get("effects", [])
		for effect in eff_list:
			if effect is Effect:
				status_effects.apply_effect(effect)
		# knockback + hurt animation
		var damage = data.get("damage", 0.0)
		if damage > 0.0 and not hurting and not isDead:
			_hurt(data)

func _on_died() -> void:
	isDead = true;
	if animated_sprite_2d:
		animated_sprite_2d.play("dies");
	
	dropGold();
	
	EventBus.emit_event(EventBus.ENEMY_KILLED, {
		"enemy": self,
		"position": global_position,
	})
	# queue_free handled by animation_finished for death anims


func _hurt(data: Dictionary) -> void:
	hurting = true
	var attacker = data.get("attacker")
	if attacker:
		var knockback_dir = global_position.direction_to(attacker.global_position) * -1
		movement_component.apply_knockback(knockback_dir * knockback_power)

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
