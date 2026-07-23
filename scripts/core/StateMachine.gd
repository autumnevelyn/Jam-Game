# stateMachine.gd
# a generic finite state machine that delegates to convention-based methods
# on its parent/owner node.
#
# convention: state_{name}_{enter|exit|process|physics_process|input}
#   e.g. state_idle_enter(), state_walk_physics_process(delta)
#
# usage: Add as a child of any Node. Set initial_state in the inspector.
class_name StateMachine
extends Node

## Emitted when the active state changes.
signal state_changed(old_state: String, new_state: String)

## The state to start in when the scene is ready.
@export var initial_state: String = ""

## Current active state name.
var current_state: String = "":
	set(value):
		if value != current_state:
			var old = current_state
			current_state = value
			state_changed.emit(old, current_state)

var _parent: Node = null


func _ready() -> void:
	# use get_parent() instead of owner — get_parent() always returns the
	# direct parent in the scene tree, which is what we want.
	_parent = get_parent()
	if not _parent:
		push_warning("StateMachine has no parent — states will not work.")
		return

	# defer initial state entry so the parent has finished _ready().
	call_deferred("_enter_initial_state")


func _enter_initial_state() -> void:
	if not _parent or not is_instance_valid(_parent):
		return
	if initial_state.is_empty():
		return
	# set current_state FIRST so _method_name() uses the correct state name.
	current_state = initial_state
	if _parent.has_method(_method_name("enter")):
		_call_state_method("enter")


## Transition to a new state.
func transition(new_state: String) -> void:
	if new_state.is_empty() or new_state == current_state:
		return
	_call_state_method("exit")
	current_state = new_state
	_call_state_method("enter")


## Call the current state's process method. Call from parent _process.
func process(delta: float) -> void:
	_call_state_method("process", delta)


## Call the current state's physics_process method. Call from parent _physics_process.
func physics_process(delta: float) -> void:
	_call_state_method("physics_process", delta)


## Call the current state's input method. Call from parent _input.
func input(event: InputEvent) -> void:
	_call_state_method("input", event)


# -- Internal ----------------------------------------------------------------

func _method_name(suffix: String) -> String:
	return "state_%s_%s" % [current_state.to_lower(), suffix]


# returns true if the method was found and called.
func _call_state_method(method: String, arg = null) -> bool:
	var func_name = _method_name(method)
	if _parent and _parent.has_method(func_name):
		if arg != null:
			_parent.call(func_name, arg)
		else:
			_parent.call(func_name)
		return true
	return false
