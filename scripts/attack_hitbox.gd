extends Area2D

@onready var timer: Timer = $Timer

var parent: CharacterBody2D;
var active = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent();


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


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("Cuttable") and active:
		active = false;
		area.take_damage(1.0, parent);
