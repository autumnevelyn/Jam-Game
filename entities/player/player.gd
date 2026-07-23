# player.gd
# thin player controller. Delegates movement, combat, and health to components.
# state logic lives in convention-based methods (see state_* methods below).
extends CharacterBody2D

# -- Components --
@onready var health_component: HealthComponent = $health_component
@onready var movement_component: MovementComponent = $movement_component
@onready var combat_component: CombatComponent = $combat_component
@onready var state_machine: StateMachine = $state_machine
@onready var attack_hitbox: Area2D = $attack_hitbox
@onready var cooldown_bar: TextureProgressBar = $cooldown_bar
@onready var slash_timer: Timer = $slash_timer
@onready var hurtbox: Area2D = $hurtbox

# -- State --
enum State { IDLE, WALK, STUNNED, SLASH1, SLASH2, SLASH3 }

var active_state: State = State.IDLE
var buffer_slash: bool = false
var combo_step: int = 0
var _skills: Array = []


func _ready() -> void:
	state_machine.initial_state = "idle"
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	_refresh_skills()


func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)
	_update_cooldown_bar()


# state methods — called by StateMachine via convention

func state_idle_enter() -> void:
	buffer_slash = false
	active_state = State.IDLE


func state_idle_physics_process(delta: float) -> void:
	var direction = _get_input_direction()
	if direction != Vector2.ZERO:
		movement_component.process_movement(direction, delta)
		state_machine.transition("walk")
		return

	if not attack_hitbox.active:
		attack_hitbox.position = Vector2.ZERO

	_handle_attack_input()
	_handle_skill_input()
	movement_component.process_movement(Vector2.ZERO, delta)


func state_walk_enter() -> void:
	active_state = State.WALK


func state_walk_physics_process(delta: float) -> void:
	var direction = _get_input_direction()
	if direction == Vector2.ZERO:
		state_machine.transition("idle")
		return

	if not attack_hitbox.active:
		attack_hitbox.position = Vector2.ZERO

	_handle_attack_input()
	_handle_skill_input()
	movement_component.process_movement(direction, delta)


func state_stunned_enter() -> void:
	active_state = State.STUNNED
	slash_timer.wait_time = 0.5
	slash_timer.start()


func state_stunned_physics_process(delta: float) -> void:
	movement_component.process_movement(Vector2.ZERO, delta)


func state_slash1_enter() -> void:
	active_state = State.SLASH1
	buffer_slash = false
	combo_step = 1
	velocity = Vector2.ZERO
	slash_timer.wait_time = 0.5
	slash_timer.start()
	_perform_attack()


func state_slash1_physics_process(delta: float) -> void:
	_handle_slash_combo_buffer()


func state_slash2_enter() -> void:
	active_state = State.SLASH2
	buffer_slash = false
	combo_step = 2
	velocity = Vector2.ZERO
	_perform_attack()


func state_slash2_physics_process(delta: float) -> void:
	_handle_slash_combo_buffer()


func state_slash3_enter() -> void:
	active_state = State.SLASH3
	buffer_slash = false
	combo_step = 3
	velocity = Vector2.ZERO
	slash_timer.wait_time = 1.0
	slash_timer.start()
	_perform_attack()


func state_slash3_physics_process(delta: float) -> void:
	_handle_slash_combo_buffer()


# input helpers

func _get_input_direction() -> Vector2:
	var x = Input.get_axis("left", "right")
	var y = Input.get_axis("up", "down")
	return Vector2(x, y).normalized()


func _handle_attack_input() -> void:
	if Input.is_action_just_pressed("leftClick") and not buffer_slash:
		_start_attack_combo()


func _handle_slash_combo_buffer() -> void:
	if Input.is_action_just_pressed("leftClick") and not buffer_slash:
		buffer_slash = true


func _handle_skill_input() -> void:
	if Input.is_action_just_pressed("skill 1"):
		_try_use_skill(0)
	if Input.is_action_just_pressed("skill 2"):
		_try_use_skill(1)
	if Input.is_action_just_pressed("skill 3"):
		_try_use_skill(2)
	if Input.is_action_just_pressed("skill4"):
		_try_use_skill(3)


func _start_attack_combo() -> void:
	buffer_slash = true
	state_machine.transition("slash1")


func _perform_attack() -> void:
	var mouse_dir = _get_mouse_direction()
	attack_hitbox.active = true
	attack_hitbox.position = mouse_dir * 16.0


func _get_mouse_direction() -> Vector2:
	return Vector2.from_angle(attack_hitbox.get_angle_to(get_global_mouse_position()))


func _try_use_skill(slot: int) -> void:
	if slot >= _skills.size():
		return
	var skill_resource = _skills[slot]
	if not skill_resource:
		return
	EventBus.emit_event(EventBus.PLAYER_SKILL_USED, {
		"slot": slot,
		"skill": skill_resource,
	})


# signal handlers

func _on_damaged(amount: float, source: Node) -> void:
	PlayerData.health -= amount
	state_machine.transition("stunned")
	if source:
		var knockback_dir = Vector2.from_angle(source.get_angle_to(position))
		movement_component.apply_knockback(knockback_dir * 200.0)


func _on_died() -> void:
	EventBus.emit_event(EventBus.PLAYER_DIED, {
		"position": global_position,
	})
	GameManager.end_run(false)


func _on_health_changed(old_value: float, new_value: float, max_value: float) -> void:
	if new_value < old_value:
		var tween = create_tween()
		cooldown_bar.tint_progress = Color(1.0, 0.0, 0.0)
		tween.tween_property(cooldown_bar, "tint_progress", Color(1.0, 1.0, 1.0), 1.0)


func _on_slash_timer_timeout() -> void:
	match active_state:
		State.STUNNED:
			state_machine.transition("idle")
		State.SLASH1:
			if buffer_slash:
				state_machine.transition("slash2")
			else:
				state_machine.transition("idle")
		State.SLASH2:
			if buffer_slash:
				state_machine.transition("slash3")
			else:
				state_machine.transition("idle")
		State.SLASH3:
			state_machine.transition("idle")


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		health_component.take_damage(1.0, body)


# helpers

func _update_cooldown_bar() -> void:
	if slash_timer.is_stopped():
		cooldown_bar.value = 0.0
	else:
		cooldown_bar.value = (slash_timer.time_left / slash_timer.wait_time) * 100.0


func _refresh_skills() -> void:
	_skills = PlayerData.current_skills.duplicate()
