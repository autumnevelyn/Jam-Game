# player_states.gd
# extended state logic for the player. This file documents the convention:
# each state method follows the pattern `state_{name}_{action}`.
#
# states: idle, walk, stunned, slash1, slash2, slash3
# actions: enter, exit, physics_process(delta), process(delta), input(event)
#
# these methods live on the player node (owner of StateMachine).
# see player.gd for the full implementations.
#
# to add a new state:
#   1. Add it to the State enum in player.gd
#   2. Create the state_{name}_enter() and state_{name}_physics_process() methods
#   3. Set it as initial_state or transition to it
class_name PlayerStates
extends Node

# this is a marker/documentation class.
# the actual state methods are implemented directly in player.gd
# following the StateMachine convention.

func _ready() -> void:
	push_warning("PlayerStates is a documentation-only class. State methods live in player.gd.")
	queue_free()
