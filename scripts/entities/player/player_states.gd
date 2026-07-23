# player_states.gd
# extended state logic for the player. This file documents the convention:
# each state method follows the pattern `state_{name}_{action}`.
#
# states: idle, walk, stunned
# actions: enter, exit, physics_process(delta), process(delta), input(event)
#
# these methods live on the player node (owner of StateMachine).
# see player.gd for the full implementations.
#
# Attacks and skills are now handled via the tick-based SkillSystem.
# Basic attack: left click starts a 1-tick (0.5s) timer -> fires basic attack
# Skills: keys 1-4 start skill timers -> combo on same-tick expiry
class_name PlayerStates
extends Node

# this is a marker/documentation class.
# the actual state methods are implemented directly in player.gd
# following the StateMachine convention.

func _ready() -> void:
	push_warning("PlayerStates is a documentation-only class. State methods live in player.gd.")
	queue_free()
