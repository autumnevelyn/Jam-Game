# gameData.gd
# tracks run-level game state.
extends Node

var enemies_killed: int = 0
var rooms_cleared: int = 0
var items_collected: int = 0
var damage_dealt: float = 0.0
var damage_taken: float = 0.0
var time_elapsed: float = 0.0


func reset() -> void:
	enemies_killed = 0
	rooms_cleared = 0
	items_collected = 0
	damage_dealt = 0.0
	damage_taken = 0.0
	time_elapsed = 0.0


func _process(delta: float) -> void:
	if not GameManager.is_paused:
		time_elapsed += delta
