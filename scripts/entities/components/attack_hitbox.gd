# attack_hitbox.gd
# hitbox area for player attacks. Supports combined effects from skill combos.
extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

var parent: Node2D
var active: bool = false
var damage: float = 1.0
var effects: Array = []


func _ready() -> void:
	parent = get_parent()
	visible = false
	
	EventBus.subscribe(EventBus.SKILL_TIMER_EXPIRED, _on_skill_timer_expired);


func _process(delta: float) -> void:
	if active:
		visible = true
		collision_shape_2d.disabled = false;
		if timer.is_stopped():
			timer.start()
	#else:
		#visible = false

func _exit_tree() -> void:
	EventBus.unsubscribe(EventBus.SKILL_TIMER_EXPIRED, _on_skill_timer_expired);

func _on_timer_timeout() -> void:
	active = false
	collision_shape_2d.disabled = true;


func _on_skill_timer_expired(data: Dictionary):
	if data["slot"] == -1:
		animated_sprite_2d.play("slash");
		animated_sprite_2d.scale = Vector2(0.5, 0.5);
	else:
		match(PlayerData.current_skills[data["slot"]].skill_name):
			"Fire Punch":
				animated_sprite_2d.play("fire punch");
				animated_sprite_2d.scale = Vector2(0.5, 0.5);
			"Freeze Breeze":
				animated_sprite_2d.play("freeze breeze");
				animated_sprite_2d.scale = Vector2(1, 1);
				
		
	animated_sprite_2d.rotation = parent.get_angle_to(global_position) + PI / 4;

func _on_area_entered(area: Area2D) -> void:
	if not active:
		return

	var target = area.get_parent()
	if not target:
		return

	# emit combat hit event for the CombatSystem to process
	EventBus.emit_event(EventBus.COMBAT_HIT, {
		"target": target,
		"attacker": parent,
		"damage": damage,
		"effects": effects.duplicate(),
		"position": global_position,
	})

	active = false

	# for cuttable objects, destroy immediately
	if target.is_in_group("Cuttable"):
		target.queue_free()


func _on_animated_sprite_2d_animation_finished() -> void:
	visible = false;
	position = Vector2.ZERO;
