extends CharacterBody2D

enum STATE {IDLE, WALK, STUNNED, SLASH1, SLASH2, SLASH3}

@onready var timer: Timer = $Timer
@onready var timer_2: Timer = $timer2
@onready var attack_hitbox: Area2D = $attack_hitbox
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

const skills = [preload("res://scenes/prefabs/items/sword.tres")]

const movement_speed = 100;

var knockback = Vector2.ZERO;
var buffer_slash := false;

var active_state := STATE.IDLE;

func _physics_process(delta: float) -> void:
	
	if(not knockback.is_zero_approx()):
		velocity += knockback;
		knockback *= 0.5;
		velocity *= 0.8
		
	update_state();
	#print(active_state)
	print(buffer_slash)
		
	texture_progress_bar.value = (timer.time_left / timer.wait_time) * 100;
	
	move_and_slide()

func switch_state(new_state: STATE):
	match(new_state):
		STATE.IDLE:
			buffer_slash = false;
		STATE.WALK:
			pass
		STATE.STUNNED:
			pass
		STATE.SLASH1:
			velocity = Vector2(0,0);
		STATE.SLASH2:
			buffer_slash = false;
			velocity = Vector2(0,0);
		STATE.SLASH3:
			buffer_slash = false;
			velocity = Vector2(0,0);
	active_state = new_state;

func update_state():
	match(active_state):
		STATE.IDLE:
			var directionX := Input.get_axis("left", "right")
			var directionY := Input.get_axis("up", "down")
			
			if(directionX or directionY):
				velocity = Vector2(directionX, directionY) * movement_speed;
				switch_state(STATE.WALK);
				
			if(not attack_hitbox.active): attack_hitbox.position = Vector2(0, 0);
			
			if Input.is_action_just_pressed("leftClick") and not buffer_slash:
				slash();
			
			if Input.is_action_just_pressed("skill 1"):
				tryUseSkill(1);
			if Input.is_action_just_pressed("skill 2"):
				tryUseSkill(2);
			
		STATE.WALK:
			var directionX := Input.get_axis("left", "right")
			var directionY := Input.get_axis("up", "down")
			
			if(directionX or directionY):
				velocity = Vector2(directionX, directionY) * movement_speed;
			else:
				velocity = Vector2(0, 0); 
				switch_state(STATE.IDLE)
			
			if(not attack_hitbox.active): attack_hitbox.position = Vector2(0, 0);
			
			if Input.is_action_just_pressed("leftClick") and not buffer_slash:
				slash();
			
			if Input.is_action_just_pressed("skill 1"):
				tryUseSkill(1);
			if Input.is_action_just_pressed("skill 2"):
				tryUseSkill(2);
			
		STATE.STUNNED:
			pass
		STATE.SLASH1:
			if Input.is_action_just_pressed("leftClick") and not buffer_slash:
				slash();
		STATE.SLASH2:
			if Input.is_action_just_pressed("leftClick") and not buffer_slash:
				slash();
		STATE.SLASH3:
			if Input.is_action_just_pressed("leftClick") and not buffer_slash:
				slash();

func tryUseSkill(skill: int):
	if(timer.is_stopped()):
		match(PlayerData.currentSkills[skill]):
			skills[0]:
				pass
	else:
		var tween = create_tween();
		texture_progress_bar.tint_progress = Color(1.0, 0.0, 0.0);
		tween.tween_property(texture_progress_bar, "tint_progress", Color(1.0, 1.0, 1.0), 1.0);
		

func skill():
	attack_hitbox.active = true;
	attack_hitbox.position = Vector2.from_angle(attack_hitbox.get_angle_to(get_global_mouse_position())) * 16;

func slash():
	if(active_state == STATE.SLASH1): # COMBO 1
		buffer_slash = true;
	elif(active_state == STATE.SLASH2): # COMBO 2
		buffer_slash = true;
	elif(active_state == STATE.SLASH3): # FINAL COMBO
		buffer_slash = true;
		timer_2.wait_time = 1;
	else: #STARTING LOOP
		buffer_slash = true;
		switch_state(STATE.SLASH1);
		timer_2.wait_time = 0.5;
		
	attack_hitbox.active = true;
	attack_hitbox.position = Vector2.from_angle(attack_hitbox.get_angle_to(get_global_mouse_position())) * 16;
	
	timer_2.start();

func _on_timer_timeout() -> void:
	skill();

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if(body.is_in_group("Enemy")):
		PlayerData.health -= 1;
		
		switch_state(STATE.STUNNED);
		timer_2.wait_time = 0.5;
		timer_2.start();
		knockback = Vector2.from_angle(body.get_angle_to(position)) * 200;
		print(knockback);

func _on_timer_2_timeout() -> void:
	if(active_state == STATE.STUNNED):
		switch_state(STATE.IDLE);
	elif(active_state == STATE.SLASH1):
		if(buffer_slash):
			switch_state(STATE.SLASH2);
		else:
			switch_state(STATE.IDLE);
	elif(active_state == STATE.SLASH2 and buffer_slash):
		switch_state(STATE.SLASH3);
	elif(active_state == STATE.SLASH3):
		switch_state(STATE.IDLE);
