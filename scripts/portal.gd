extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2

var open := false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.subscribe(EventBus.GAME_ROOM_CLEARED, _on_game_room_cleared);
	
func _exit_tree() -> void:
	EventBus.unsubscribe(EventBus.GAME_ROOM_CLEARED, _on_game_room_cleared);

func _on_game_room_cleared(data: Dictionary):
	open = true;
	
	animated_sprite_2d.modulate = Color(1.0, 1.0, 1.0, 1.0);
	animated_sprite_2d_2.modulate = Color(1.0, 1.0, 1.0, 1.0);
	animated_sprite_2d.play("default");
	animated_sprite_2d_2.play("default");


func _on_body_entered(body: Node2D) -> void:
	if(body.name == "player"):
		if(open):
			GameManager.advance_room();
