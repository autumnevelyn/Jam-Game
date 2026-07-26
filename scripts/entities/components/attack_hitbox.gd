# attack_hitbox.gd
# hitbox area for player attacks. Supports combined effects from skill combos.
extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var node_2d: Node2D = $Node2D
@onready var timer: Timer = $Timer

var parent: Node2D
var active: bool = false
var damage: float = 1.0

var effects: Array = []


func _ready() -> void:
	parent = get_parent()
	visible = false
	
	EventBus.subscribe(EventBus.SKILL_TIMER_EXPIRED, _on_skill_timer_expired);
	EventBus.subscribe(EventBus.ATTACK_FIRED, _on_attack_fired);


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
	EventBus.unsubscribe(EventBus.ATTACK_FIRED, _on_attack_fired);

func _on_timer_timeout() -> void:
	active = false
	collision_shape_2d.disabled = true;


func _on_skill_timer_expired(data: Dictionary):
	var skill: Skill = data.get("skill")
	print("SKILLLL")
	print(skill);
	if not skill:
		return
	
	if skill.skill_type == Skill.SkillType.SLASH:
		# Slash — always plays the default slash animation
		animated_sprite_2d.play("slash");
		scale = Vector2(1, 1);
		animated_sprite_2d.scale = Vector2(0.5, 0.5);
		collision_shape_2d.shape = RectangleShape2D.new();
		collision_shape_2d.shape.size = Vector2(15, 15);
	else:
		match(skill.skill_name):
			"Fire Punch":
				animated_sprite_2d.play("fire punch");
				scale = Vector2(1, 1);
				animated_sprite_2d.scale = Vector2(0.5, 0.5);
			"Freeze Breeze":
				animated_sprite_2d.play("freeze breeze");
				scale = Vector2(1, 1);
				animated_sprite_2d.scale = Vector2(1, 1);
		if(skill.skill_type == Skill.SkillType.DAMAGE):
			collision_shape_2d.shape = skill.hitbox_size;
			
	rotation = parent.get_angle_to(get_global_mouse_position()) + PI / 2;

func _on_attack_fired(data: Dictionary):
	effects = data["effects"];

	#var skill: Skill = data.get("skill")
	print("SKILLLL")
	#print(skill);
	#if not skill:
	#	return
	
	if data["main_type"] == Skill.SkillType.SLASH: # NEVER HAPPENS
		# Slash — always plays the default slash animation
		print("aaaaaaaaaaaaaaaaaaaaaaa")
		animated_sprite_2d.play("slash");
		scale = Vector2(1, 1);
		collision_shape_2d.shape = RectangleShape2D.new();
		collision_shape_2d.shape.size = Vector2(15, 15);
	else:
		if(data["main_type"] == Skill.SkillType.DAMAGE and data["combo_count"] > 1):
			for effect in data["effects"]:
				if(effect.type == Effect.Type.BURN):
					animated_sprite_2d.play("slash_fire");
					scale = Vector2(1, 1);
					collision_shape_2d.shape = CapsuleShape2D.new();
					collision_shape_2d.shape.radius = 8.0;
					collision_shape_2d.shape.height = 32.0;
				elif(effect.type == Effect.Type.FREEZE):
					animated_sprite_2d.play("slash_frozen");
					scale = Vector2(2, 2);
					collision_shape_2d.shape = CircleShape2D.new();
					collision_shape_2d.shape.radius = 8;
		#match(skill.skill_name):
		#	"Fire Punch":
		#		animated_sprite_2d.play("fire punch");
		#		animated_sprite_2d.scale = Vector2(0.5, 0.5);
		#	"Freeze Breeze":
		#		animated_sprite_2d.play("freeze breeze");
		#		animated_sprite_2d.scale = Vector2(1, 1);
		#if(skill.skill_type == Skill.SkillType.DAMAGE):
		#	collision_shape_2d.shape = skill.hitbox_size;
		#	
	rotation = parent.get_angle_to(get_global_mouse_position()) + PI / 2;

func _on_area_entered(area: Area2D) -> void:
	#print_debug(active);
	if not active:
		return

	var target = area.get_parent()
	#print_debug(target);
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
