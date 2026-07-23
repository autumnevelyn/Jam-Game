extends Control

@onready var hearts: TextureRect = $hearts

var id = -1;

# called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func healthChanged():
	if(PlayerData.health >= id + 1):
		hearts.visible = true;
	else: 
		hearts.visible = false;
