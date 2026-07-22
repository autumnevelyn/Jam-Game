extends CharacterBody2D


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

	move_and_slide()
	
	
func attack():
	pass
