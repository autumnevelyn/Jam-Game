# ui.gd
# main UI controller. Manages health display, skill bar, and inventory panels.
# Updated for the tick-based skill system with player-overlay timers.
extends Control

@onready var health_container: BoxContainer = $health_container
@onready var enemies_left_label: Label = $"enemies left_label"
@onready var money_label: Label = $money_label
@onready var skill_bar: Control = $skill_bar

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


func _exit_tree() -> void:
	# clean up subscriptions
	EventBus.unsubscribe(EventBus.ENEMY_KILLED, _on_enemy_killed)
	# disconnect signals
	if PlayerData.health_changed.is_connected(_on_player_health_changed):
		PlayerData.health_changed.disconnect(_on_player_health_changed)
	if PlayerData.player_died.is_connected(_on_player_died):
		PlayerData.player_died.disconnect(_on_player_died)


## Called when the player's health changes.
func _on_player_health_changed(_old: float, _new: float, _max: float) -> void:
	_update_all_hearts()


## Called when the player dies.
func _on_player_died() -> void:
	pass


## Update all heart icons based on current health.
func _update_all_hearts() -> void:
	for heart in _heart_nodes:
		if heart.has_method("health_changed"):
			heart.health_changed()

func _on_enemy_killed(_data: Dictionary, loading := false):
	money_label.text = "Money: " + str(int(PlayerData.money));
	if(loading):
		enemies_left_label.text = str(get_tree().get_nodes_in_group("Enemy").size());
	else:
		enemies_left_label.text = str(get_tree().get_nodes_in_group("Enemy").size() - 1);
