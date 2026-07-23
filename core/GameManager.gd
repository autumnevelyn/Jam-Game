# gameManager.gd
# oversees the roguelike run lifecycle: room transitions, pause, game over.
extends Node

## Emitted when the run state changes.
signal run_state_changed(new_state: String)

enum RunState {
	MENU,
	PLAYING,
	PAUSED,
	ROOM_TRANSITION,
	GAME_OVER,
	VICTORY,
}

var current_run_state: RunState = RunState.MENU
var current_room: int = 0
var total_rooms_in_run: int = 0
var is_paused: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS


## Start a new game run.
func start_run() -> void:
	current_room = 0
	total_rooms_in_run = 0
	_change_state(RunState.PLAYING)
	EventBus.emit_event(EventBus.GAME_RUN_STARTED, {
		"room": current_room,
	})


## End the current run (death or quit).
func end_run(victory: bool = false) -> void:
	_change_state(RunState.GAME_OVER if not victory else RunState.VICTORY)
	EventBus.emit_event(EventBus.GAME_RUN_ENDED, {
		"victory": victory,
		"room": current_room,
	})


## Advance to the next room.
func advance_room() -> void:
	current_room += 1
	_change_state(RunState.ROOM_TRANSITION)
	# after transition, set back to playing
	_change_state(RunState.PLAYING)


## Toggle pause state.
func toggle_pause() -> void:
	if current_run_state == RunState.PLAYING:
		_change_state(RunState.PAUSED)
		EventBus.emit_event(EventBus.GAME_PAUSED)
	elif current_run_state == RunState.PAUSED:
		_change_state(RunState.PLAYING)
		EventBus.emit_event(EventBus.GAME_UNPAUSED)


func _change_state(new_state: RunState) -> void:
	if new_state == current_run_state:
		return
	current_run_state = new_state
	is_paused = current_run_state == RunState.PAUSED
	get_tree().paused = is_paused
	run_state_changed.emit(RunState.keys()[new_state])
