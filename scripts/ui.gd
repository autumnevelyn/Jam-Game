extends Control

@onready var health_container: BoxContainer = $health_container

# called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(health_container.get_children().size()):
		health_container.get_child(i).id = i;
		
	for child in health_container.get_children():
		child.healthChanged();
		
	


# called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	for child in health_container.get_children():
		child.healthChanged();
