extends Area2D

@onready var timer: Timer = $Timer

var active = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if active:
		visible = true;
		if(timer.is_stopped()):
			timer.start();
	else:
		visible = false;


func _on_timer_timeout() -> void:
	active = false;
