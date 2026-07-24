extends Control

const MENU = preload("res://scenes/levels/menu.tscn")

@onready var color_rect: ColorRect = $ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	EventBus.subscribe(EventBus.PLAYER_DIED, _on_player_died);
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_died(data: Dictionary):
	var tween = create_tween();
	tween.tween_property(self, "modulate:a", 1.0, 1.0);
	

func _on_button_pressed() -> void:
	GameManager.start_run();
	var tween = create_tween();
	tween.tween_property(self, "modulate:a", 0.0, 1.0);


func _on_button_3_pressed() -> void:
	var tween = create_tween();
	tween.tween_property(color_rect, "color:a", 1.0, 1.0);
	
	await tween.finished;
	
	GameManager.current_level.queue_free();
	GameManager.current_level = null;
	
	get_tree().root.get_node("GameMain/CanvasLayer/Menu").visible = true;
	#var menu = MENU.instantiate();
	#get_tree().root.get_node("GameMain/CanvasLayer").add_child(menu);
	
	tween = create_tween();
	tween.tween_property(self, "modulate:a", 0.0, 1.0);
