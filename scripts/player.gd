extends CharacterBody2D

@onready var timer: Timer = $Timer
@onready var stun_timer: Timer = $stunTimer
@onready var attack_hitbox: Area2D = $attack_hitbox
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

const movement_speed = 100;

var direction = Vector2(1, 0);
var knockback = Vector2.ZERO;
var stunned = false;


func _physics_process(delta: float) -> void:
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var directionX := Input.get_axis("ui_left", "ui_right")
	var directionY := Input.get_axis("ui_up", "ui_down")
	if(not stunned):
		if directionX:
			velocity.x = directionX * movement_speed
			direction.x = directionX;
		else:
			velocity.x = move_toward(velocity.x, 0, movement_speed)
			if(directionY != 0):
				direction.x = 0;
		if directionY:
			velocity.y = directionY * movement_speed
			direction.y = directionY;
		else:
			velocity.y = move_toward(velocity.y, 0, movement_speed)
			if(directionX != 0):
				direction.y = 0;
		
	if(not knockback.is_zero_approx()):
		velocity += knockback;
		knockback *= 0.5;
		velocity *= 0.8
	
	
	if(attack_hitbox.active):
		attack_hitbox.position = direction * 16;
	else: attack_hitbox.position = Vector2(0, 0);
	
	if Input.is_action_just_pressed("ui_accept"):
		tryAttack();
		
		
	texture_progress_bar.value = (timer.time_left / timer.wait_time) * 100;

	move_and_slide()
	
func tryAttack():
	if(PlayerData.currentSkills.size() > 0):
		if(timer.is_stopped() and not stunned):
			timer.start();
		else:
			var tween = create_tween();
			texture_progress_bar.tint_progress = Color(1.0, 0.0, 0.0);
			tween.tween_property(texture_progress_bar, "tint_progress", Color(1.0, 1.0, 1.0), 1.0);
		
	
func attack():
	attack_hitbox.active = true;


func _on_timer_timeout() -> void:
	attack();
	


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if(body.is_in_group("Enemy")):
		PlayerData.health -= 1;
		
		stunned = true;
		stun_timer.start();
		knockback = Vector2.from_angle(body.get_angle_to(position)) * 200;
		print(knockback);


func _on_stun_timer_timeout() -> void:
	stunned = false;
