# skillSystem.gd
# Tick-based skill timer & combo system.
# When multiple skill countdowns expire on the same tick, they combine into a single combo attack.
# Non-damage skills that expire alone on a tick are applied as self-buffs (if appliacable)
extends Node

## Duration of one tick in seconds.
const TICK_DURATION: float = 2
## Slash base damage
const SLASH_DMG: float = 1.0

## Data for one running skill countdown.
class CountDown:
	var skill: Skill
	var remaining_ticks: int
	var slot: int
	
	func _init(p_slot: int, p_skill: Skill) -> void:
		slot = p_slot
		skill = p_skill
		remaining_ticks = p_skill.ticks if p_skill else 1

var tick_timer = Timer.new() 
## running timers; keyed by slot index (-1 = slash).
var _running_countdowns: Dictionary = {}
## countdowns to be run on next tick; keyed by slot index (-1 = slash).
var _queued_countdowns: Dictionary = {}
## player reference
var _player: Node2D = null

func _ready() -> void:
	_setup_tick_timer()

func _setup_tick_timer() -> void:
	tick_timer.wait_time = TICK_DURATION
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)
	tick_timer.start()
	
func _reset_tick_timer() -> void:
	tick_timer.start()
	_on_tick()

## set player node reference for attacks position
func set_player(player: Node2D) -> void:
	_player = player

# API
## queue the slash timer (1 tick).
func queue_slash() -> void:
	if _queued_countdowns.has(-1):
		return  # slash already queued (slash can be buffered)
	_queued_countdowns[-1] = CountDown.new(-1, null)
	EventBus.emit_event(EventBus.PLAYER_SLASH_USED, {})
	if _no_countdowns(): _reset_tick_timer()


## queue a skill timer for the given slot.
func queue_skill(slot: int, skill: Skill) -> void:
	if _running_countdowns.has(slot) or _queued_countdowns.has(slot):
		return  # skill already queued or counting down (no buffer)
	_queued_countdowns[slot] = CountDown.new(slot, skill)
	EventBus.emit_event(EventBus.PLAYER_SKILL_USED, {"slot": slot, "skill": skill})
	print_rich(skill.skill_name," [%d]"%slot )
	if _no_countdowns(): _reset_tick_timer()

## returns the remaining ticks for a timer, or -1 if not active.
func get_remaining_ticks(slot: int) -> int:
	if _running_countdowns.has(slot):
		return _running_countdowns[slot].remaining_ticks
	return -1


# ---- Process ticks ----
func _on_tick() -> void:
	var expiring: Array = []
	# tick all timers
	for slot in _running_countdowns.keys():
		var countdown = _running_countdowns[slot] as CountDown
		countdown.remaining_ticks -= 1
		
		# emit tick events for skill UI 
		if countdown.skill and countdown.skill.skill_type != Skill.SkillType.SLASH:
			EventBus.emit_event(EventBus.SKILL_TIMER_TICK, {
				"slot": slot,
				"remaining": countdown.remaining_ticks,
				"total": countdown.skill.ticks,
			})
		
		if countdown.remaining_ticks <= 0:
			expiring.append(slot)
	
	# deal with expiring timers
	# separate damage-dealing timers from buff/mod/util
	var damaging: Array = []
	var non_damaging: Array = []
	for slot in expiring:
		var countdown = _running_countdowns[slot]
		_running_countdowns.erase(slot)
		EventBus.emit_event(EventBus.SKILL_TIMER_EXPIRED, {
			"slot": slot,
		})
		
		if slot == -1:
			# slash
			damaging.append(countdown)
		elif countdown.skill.skill_type == Skill.SkillType.DAMAGE:
			damaging.append(countdown)
		else:
			non_damaging.append(countdown)
	
	# if anything damaging expires this tick, combine it all
	if damaging.size() > 0:
		var total_damage: float = 0.0
		var effects: Array = []
		var total_skills: int = damaging.size() + non_damaging.size()
		
		# sum damage from all damaging skills
		for countdown in damaging:
			if countdown.skill:
				total_damage += countdown.skill.base_damage
			else:
				total_damage += SLASH_DMG;
		
		# apply combo multiplier (damage multiplies per extra skill)
		total_damage *= 1.0 + 0.5 * (total_skills - 1) # TODO: probs needs refining
		
		# collect effects from damaging skills
		for countdown in damaging:
			if countdown.skill and countdown.skill.effect_name and countdown.skill.effect_name != "":
				_add_or_stack_effect(effects, countdown.skill.effect_name, countdown.skill.effect_strength)
		
		# non-damaging skills on this tick add their effects to the attack
		for countdown in non_damaging:
			if countdown.skill and countdown.skill.effect_name and countdown.skill.effect_name != "":
				_add_or_stack_effect(effects, countdown.skill.effect_name, countdown.skill.effect_strength)
		
		EventBus.emit_event(EventBus.ATTACK_FIRED, {
			"damage": total_damage,
			"effects": effects,
			"combo_count": total_skills,
			"position": _player.global_position if _player else Vector2.ZERO,
			"direction": _get_mouse_direction(),
		})
	
	# non-damaging skills that expired alone
	elif non_damaging.size() > 0:
		for countdown in non_damaging:
			EventBus.emit_event(EventBus.SELF_BUFF_APPLIED, {
				"skill": countdown.skill,
				"effect_name": countdown.skill.effect_name if countdown.skill else "",
				"effect_strength": countdown.skill.effect_strength if countdown.skill else 0.0,
			})
	
	_start_queued_timers() # moves timers from queue array to running array


# ---- Helpers ----

## Add an effect to the array, stacking strength if it already exists.
func _add_or_stack_effect(effects: Array, name: String, strength: float) -> void:
	for e in effects:
		if e.name == name:
			e.strength += strength
			return
	effects.append({"name": name, "strength": strength})

func _get_mouse_direction() -> Vector2:
	if not _player:
		return Vector2.RIGHT
	return (_player.get_global_mouse_position() - _player.global_position).normalized()

func _start_queued_timers() -> void:
	for slot in _queued_countdowns.keys():
		var countdown = _queued_countdowns[slot] as CountDown
		_running_countdowns[slot] = countdown
		if countdown.slot == -1:
			EventBus.emit_event(EventBus.SLASH_STARTED, {})
		else:
			EventBus.emit_event(EventBus.SKILL_TIMER_STARTED, {
				"slot": slot,
				"skill": countdown.skill,
				"total_ticks": countdown.skill.ticks,
			})
			print_rich( countdown.skill.skill_name," [%d]"%slot )
	_queued_countdowns.clear()

func _no_countdowns() -> bool:
	return _queued_countdowns.size() >= 1 and _running_countdowns.is_empty()
