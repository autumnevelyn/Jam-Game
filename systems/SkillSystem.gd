# skillSystem.gd
# manages skill activation, cooldowns, and effects.
# listens to player skill use events from EventBus.
extends Node

# tracks cooldowns per skill slot: slot -> time remaining
var _cooldowns: Dictionary = {}


func _ready() -> void:
	EventBus.subscribe(EventBus.PLAYER_SKILL_USED, _on_skill_used)


func _process(delta: float) -> void:
	# tick cooldowns
	var to_remove: Array = []
	for slot in _cooldowns:
		_cooldowns[slot] -= delta
		if _cooldowns[slot] <= 0.0:
			to_remove.append(slot)

	for slot in to_remove:
		_cooldowns.erase(slot)
		EventBus.emit_event(EventBus.PLAYER_SKILL_READY, {
			"slot": slot,
		})


## Called when the player attempts to use a skill.
func _on_skill_used(data: Dictionary) -> void:
	var slot = data.get("slot", -1)
	var skill_resource = data.get("skill")

	if slot < 0 or not skill_resource:
		return

	# check if skill is on cooldown
	if _cooldowns.has(slot):
		return  # Still on cooldown

	# activate the skill
	var cooldown = skill_resource.get("cooldown_time", 1.0)
	_cooldowns[slot] = cooldown

	# emit the effect (could be picked up by a VFX system, etc.)
	EventBus.emit_event("skill_activated", {
		"slot": slot,
		"skill": skill_resource,
		"cooldown": cooldown,
	})


## Returns the cooldown progress for a slot (0.0 = ready, 1.0 = just used).
func get_cooldown_progress(slot: int) -> float:
	if not _cooldowns.has(slot):
		return 0.0
	return _cooldowns[slot]
