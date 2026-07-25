# player.gd
# thin player controller. Delegates movement, combat, and health to components.
# Uses the tick-based SkillSystem (autoload) for all attack/skill timers.
extends CharacterBody2D

# ---- Components ----
@onready var health_component: HealthComponent = $health_component
@onready var movement_component: MovementComponent = $movement_component
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $state_machine
@onready var attack_hitbox: Area2D = $attack_hitbox
@onready var hurtbox: Area2D = $hurtbox
@onready var stun_timer: Timer = $stun_timer

@onready var walk_audio: AudioStreamPlayer2D = $walkAudio
@onready var hit_audio: AudioStreamPlayer2D = $hitAudio
@onready var dash_audio: AudioStreamPlayer2D = $dashAudio

# ---- State ----
enum State { IDLE, WALK, STUNNED, SLASH, DASH }

var active_state: State = State.IDLE
var _slot_skills: Array = []  # 5-element: [0=slash, 1-4=equipped skills]
var _direction := Vector2(0, 1);

var knockback_force := 400.0;
var dead := false;

var effects = {};
var onSkill := false;

func _ready() -> void:
	state_machine.initial_state = "idle"
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	_refresh_skills()
	
	# Register this player with the SkillSystem autoload
	SkillSystem.set_player(self)
	
	# Listen for attack-fired events to spawn hitboxes
	EventBus.subscribe(EventBus.ATTACK_FIRED, _on_attack_fired);
	EventBus.subscribe(EventBus.SELF_BUFF_APPLIED, _on_self_buff_applied);


func _exit_tree() -> void:
	# clean up EventBus subscriptions
	EventBus.unsubscribe(EventBus.ATTACK_FIRED, _on_attack_fired)
	# disconnect component signals
	if health_component:
		if health_component.damaged.is_connected(_on_damaged):
			health_component.damaged.disconnect(_on_damaged)
		if health_component.died.is_connected(_on_died):
			health_component.died.disconnect(_on_died)
		if health_component.health_changed.is_connected(_on_health_changed):
			health_component.health_changed.disconnect(_on_health_changed)


func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)

# state methods — called by StateMachine via convention

func state_idle_enter() -> void:
	active_state = State.IDLE
	if(_direction == Vector2(0, 1)):
		animated_sprite_2d.play("down idle");
	elif(_direction == Vector2(0, -1)):
		animated_sprite_2d.play("up idle");
	else:
		animated_sprite_2d.play("side idle");
		animated_sprite_2d.flip_h = _direction == Vector2(-1, 0);
		
	if(walk_audio.playing):
		walk_audio.stop();


func state_idle_physics_process(delta: float) -> void:
	var direction = _get_input_direction()
	if direction != Vector2.ZERO:
		movement_component.process_movement(direction, delta)
		state_machine.transition("walk")
		return

	_handle_attack_input()
	_handle_skill_input()
	movement_component.process_movement(Vector2.ZERO, delta)


func state_walk_enter() -> void:
	active_state = State.WALK
	if(_direction == Vector2(0, 1)):
		animated_sprite_2d.play("down walk");
	elif(_direction == Vector2(0, -1)):
		animated_sprite_2d.play("up walk");
	else:
		animated_sprite_2d.play("side walk");
		animated_sprite_2d.flip_h = _direction.x < 0;


func state_walk_physics_process(delta: float) -> void:
	var direction = _get_input_direction()
	if direction == Vector2.ZERO:
		state_machine.transition("idle")
		return
	else: _direction = direction;
	_handle_attack_input()
	_handle_skill_input()
	movement_component.process_movement(direction, delta)
	if(_direction == Vector2(0, 1)):
		animated_sprite_2d.play("down walk");
	elif(_direction == Vector2(0, -1)):
		animated_sprite_2d.play("up walk");
	else:
		animated_sprite_2d.play("side walk");
		animated_sprite_2d.flip_h = _direction.x < 0;
		
	if(not walk_audio.playing):
		walk_audio.play();


func state_stunned_enter() -> void:
	active_state = State.STUNNED
	stun_timer.wait_time = 0.5
	stun_timer.start()
	
	hit_audio.pitch_scale = randf_range(0.8, 1.1);
	hit_audio.play();


func state_stunned_physics_process(delta: float) -> void:
	movement_component.process_movement(Vector2.ZERO, delta)

func state_dash_enter() -> void:
	active_state = State.DASH;
	dash_audio.pitch_scale = randf_range(0.8, 1.1);
	dash_audio.play()

func state_dash_physics_process(delta: float) -> void:
	move_and_slide()


# input helpers

func _get_input_direction() -> Vector2:
	var x = Input.get_axis("left", "right")
	var y = Input.get_axis("up", "down")
	return Vector2(x, y).normalized()


func _handle_attack_input() -> void:
	if Input.is_action_just_pressed("leftClick"):
		if _slot_skills.size() > 0 and _slot_skills[0]:
			SkillSystem.queue_skill(0, _slot_skills[0])


func _handle_skill_input() -> void:
	#if(not onSkill):
	if Input.is_action_just_pressed("skill 1"):
		_try_use_skill(1)
	if Input.is_action_just_pressed("skill 2"):
		_try_use_skill(2)
	if Input.is_action_just_pressed("skill 3"):
		_try_use_skill(3)
	if Input.is_action_just_pressed("skill 4"):
		_try_use_skill(4)


func _start_attack_combo() -> void:
	state_machine.transition("slash")


func _perform_attack() -> void:
	var mouse_dir = _get_mouse_direction()
	attack_hitbox.active = true
	attack_hitbox.position = mouse_dir * 16.0


func _get_mouse_direction() -> Vector2:
	return Vector2.from_angle(get_angle_to(get_global_mouse_position())).normalized()
#func _get_mouse_direction() -> Vector2:
	#return (get_global_mouse_position() - global_position).normalized()

func _try_use_skill(slot: int) -> void:
	_refresh_skills();
	if slot >= _slot_skills.size():
		return
	var skill_resource = _slot_skills[slot]
	if not skill_resource:
		return
	SkillSystem.queue_skill(slot, skill_resource)


# ---- Attack Fired Handler ----

func _on_attack_fired(data: Dictionary) -> void:
	# Spawn the attack hitbox in the direction of the mouse
	var mouse_dir = _get_mouse_direction()
	attack_hitbox.active = true
	print(data)
	
	attack_hitbox.position = mouse_dir * data["range"] * 16.0;
	attack_hitbox.damage = data.get("damage", 1.0)
	attack_hitbox.effects = data.get("effects", [])

# signal handlers

func _on_damaged(amount: float, source: Node) -> void:
	PlayerData.health -= amount
	state_machine.transition("stunned")
	animated_sprite_2d.play("die");
	if source:
		var knockback_dir = Vector2.from_angle(source.get_angle_to(position))
		movement_component.apply_knockback(knockback_dir * knockback_force)

func _on_self_buff_applied(data: Dictionary):
	if(data["skill"].skill_type == 2):
		pass
	if(data["skill"].skill_type == 3):
		match(data["skill"].skill_name):
			"Dash":
				state_machine.transition("dash");
				velocity = _get_mouse_direction() * data["skill"].range * 16 * 10;
				stun_timer.wait_time = 0.1;
				stun_timer.start();
				

func _on_died() -> void:
	EventBus.emit_event(EventBus.PLAYER_DIED, {
		"position": global_position,
	})
	GameManager.end_run(false)
	
	dead = true;


func _on_health_changed(old_value: float, new_value: float, max_value: float) -> void:
	pass
	#if new_value < old_value:
	#	var tween = create_tween()
	#	cooldown_bar.tint_progress = Color(1.0, 0.0, 0.0)
	#	tween.tween_property(cooldown_bar, "tint_progress", Color(1.0, 1.0, 1.0), 1.0)


func _on_stun_timer_timeout() -> void:
	print(active_state)
	match active_state:
		State.STUNNED:
			if(not dead):
				state_machine.transition("idle")
				print("stand up")
		State.SLASH:
			state_machine.transition("idle")
		State.DASH:
			state_machine.transition("idle")

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		health_component.take_damage(1.0, body)

func _refresh_skills() -> void:
	_slot_skills = [SkillSystem.slash_skill] + PlayerData.current_skills.duplicate()
