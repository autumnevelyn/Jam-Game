# gameManager.gd
# oversees the roguelike run lifecycle: room transitions, pause, game over.
extends Node2D

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

@onready var color_rect: ColorRect = get_tree().root.get_node("GameMain/CanvasLayer/ColorRect");
@onready var ui: Control = get_tree().root.get_node("GameMain/CanvasLayer/ui");

var current_run_state: RunState = RunState.MENU
var current_room: int = -1
var current_level: Node2D = null;
var total_rooms_in_run: int = 0
var is_paused: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	
	#current_level = get_tree().root.get_node("GameMain/level");
	EventBus.subscribe(EventBus.GAME_ROOM_CLEARED, _on_room_cleared);
	#EventBus.subscribe(EventBus.ENEMY_KILLED, current_level._on_enemy_killed)

func _process(delta: float) -> void:
	pass

## Start a new game run.
func start_run() -> void:
	current_room = -1
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
	if(current_run_state != RunState.ROOM_TRANSITION):
		current_room += 1
		_change_state(RunState.ROOM_TRANSITION)
		# after transition, set back to playing
		#_change_state(RunState.PLAYING)


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
	
	match(new_state):
		RunState.MENU:
			pass
		RunState.PLAYING:
			pass
		RunState.PAUSED:
			pass
		RunState.ROOM_TRANSITION:
			runstate_room_transition();
		RunState.GAME_OVER:
			pass
		RunState.VICTORY:
			pass


func runstate_room_transition():
	var tween = create_tween();
	tween.tween_property(color_rect, "color:a", 1.0, 1.0);
	
	await tween.finished;
	
	if(current_level != null):
		print(current_level)
		current_level.queue_free();
	
	var new_level = load("res://scenes/levels/level_" + str(current_room + 1) +".tscn").instantiate(); 
	current_level = new_level;
	add_child(current_level);
	
	EventBus.subscribe(EventBus.ENEMY_KILLED, current_level._on_enemy_killed)
	
	
	ui._on_enemy_killed({}, true);
	
	tween = create_tween();
	tween.tween_property(color_rect, "color:a", 0.0, 1.0);
	
	await tween.finished;
	
	_change_state(RunState.PLAYING)

func _on_room_cleared(data: Dictionary):
	
	advance_room();
