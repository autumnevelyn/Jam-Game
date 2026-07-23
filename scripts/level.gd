# level.gd
# level controller — manages camera, room setup, and entity spawning.
extends Node2D

@onready var camera_2d: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $player


func _ready() -> void:
	# register this level with GameManager
	GameManager.current_room = 0

	# connect enemy kill events to room clearing logic
	EventBus.subscribe(EventBus.ENEMY_KILLED, _on_enemy_killed)


func _process(delta: float) -> void:
	# camera follows player with mouse offset (for aiming)
	if player and camera_2d:
		var target = (get_global_mouse_position() - player.position) / 10.0 + player.position
		camera_2d.position = target


func _on_enemy_killed(data: Dictionary) -> void:
	# check if all enemies are dead
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.size() == 0:
		EventBus.emit_event(EventBus.GAME_ROOM_CLEARED, {
			"room": GameManager.current_room,
		})
