# ui.gd
# main UI controller. Manages health display, skill icons, and inventory panels.
# updated to use reactive events instead of polling every frame.
extends Control

@onready var health_container: BoxContainer = $health_container
@onready var enemies_left_label: Label = $"enemies left_label"

# cached heart nodes
var _heart_nodes: Array = []


func _ready() -> void:
	# cache heart references
	for child in health_container.get_children():
		_heart_nodes.append(child)
		if child.has_method("set_id"):
			child.set_id(_heart_nodes.size() - 1)

	# connect to reactive events instead of polling
	PlayerData.health_changed.connect(_on_player_health_changed)
	PlayerData.player_died.connect(_on_player_died)

	EventBus.subscribe(EventBus.ENEMY_KILLED, _on_enemy_killed);
	# initial update
	_update_all_hearts();
	_on_enemy_killed({}, true);


## Called when the player's health changes.
func _on_player_health_changed(_old: float, _new: float, _max: float) -> void:
	_update_all_hearts()


## Called when the player dies.
func _on_player_died() -> void:
	# could show death screen here
	pass


## Update all heart icons based on current health.
func _update_all_hearts() -> void:
	for heart in _heart_nodes:
		if heart.has_method("health_changed"):
			heart.health_changed()

func _on_enemy_killed(data: Dictionary, loading := false):
	if(loading):
		enemies_left_label.text = str(get_tree().get_nodes_in_group("Enemy").size());
	else:
		enemies_left_label.text = str(get_tree().get_nodes_in_group("Enemy").size() - 1);
