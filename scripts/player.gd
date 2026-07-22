extends CharacterBody2D

@onready var timer: Timer = $Timer
@onready var attack_hitbox: Area2D = $attack_hitbox
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

const movement_speed = 150;


func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var directionX := Input.get_axis("ui_left", "ui_right")
	var directionY := Input.get_axis("ui_up", "ui_down")
	if directionX:
		velocity.x = directionX * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed)
	if directionY:
		velocity.y = directionY * movement_speed
	else:
		velocity.y = move_toward(velocity.y, 0, movement_speed)
	
	
	if(directionX != 0):
		attack_hitbox.position.x = directionX * 16;
	elif(directionY != 0): attack_hitbox.position.x = 0;
	if(directionY != 0):
		attack_hitbox.position.y = directionY * 16; 
	elif(directionX != 0): attack_hitbox.position.y = 0;
	if Input.is_action_just_pressed("ui_accept"):
		tryAttack();
		
		
	texture_progress_bar.value = (timer.time_left / timer.wait_time) * 100;

	move_and_slide()
	
func tryAttack():
	if(timer.is_stopped()):
		timer.start();
	else:
		var tween = create_tween();
		texture_progress_bar.tint_progress = Color(1.0, 0.0, 0.0);
		tween.tween_property(texture_progress_bar, "tint_progress", Color(1.0, 1.0, 1.0), 1.0);
		
	
func attack():
	attack_hitbox.active = true;


func _on_timer_timeout() -> void:
	attack();
	
