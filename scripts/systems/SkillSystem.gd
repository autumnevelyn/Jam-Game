# skillSystem.gd
# Tick-based skill timer & combo system.
# When multiple skill countdowns expire on the same tick, they combine into a single combo attack.
# Non-damage skills that expire alone on a tick are applied as self-buffs (if appliacable)
extends Node

## Duration of one tick in seconds.
const TICK_DURATION: float = 2
## Basic attack base damage
const BASIC_ATCK_DMG: float = 1.0
## Data for one running skill countdown.
class CountDown:
	var skill: Skill
	var remaining_ticks: int
	var slot: int
	
	func _init(p_slot: int, p_skill: Skill) -> void:
		slot = p_slot
		skill = p_skill
		remaining_ticks = p_skill.ticks if p_skill else 1
## running timers keyed by slot index (-1 = basic attack).
var _running_countdowns: Dictionary = {}
## player reference
var _player: Node2D = null

func _ready() -> void:
	EventBus.subscribe(EventBus.PLAYER_SKILL_USED, _on_skill_used)
	_setup_tick_timer()

func _setup_tick_timer() -> void:
	var tick_timer = Timer.new()
	tick_timer.wait_time = TICK_DURATION
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)
	tick_timer.start()

## set player node reference for attacks position
func set_player(player: Node2D) -> void:
	_player = player

# API
## start the basic attack timer (1 tick).
func start_basic_attack() -> void:
	if _running_countdowns.has(-1): return  # basic attack already counting down
	_running_countdowns[-1] = CountDown.new(-1, null)
	EventBus.emit_event(EventBus.BASIC_ATTACK_STARTED, {})

## start a skill timer for the given slot.
func start_skill(slot: int, skill: Skill) -> void:
	if _running_countdowns.has(slot):
		return  # skill already counting down
	_running_countdowns[slot] = CountDown.new(slot, skill)
	EventBus.emit_event(EventBus.SKILL_TIMER_STARTED, {
		"slot": slot,
		"skill": skill,
		"total_ticks": skill.ticks,
	})

## returns the remaining ticks for a timer, or -1 if not active.
func get_remaining_ticks(slot: int) -> int:
	if _running_countdowns.has(slot):
		return _running_countdowns[slot].remaining_ticks
	return -1


# -- Process ticks --
func _on_tick() -> void:
	var expiring: Array = []
	
	# tick all timers
	for slot in _running_countdowns.keys():
		var countdown = _running_countdowns[slot] as CountDown
		countdown.remaining_ticks -= 1
		
		# emit tick events for skill UI 
		if countdown.skill and countdown.skill.skill_type != Skill.SkillType.BASIC_ATTACK:
			EventBus.emit_event(EventBus.SKILL_TIMER_TICK, {
				"slot": slot,
				"remaining": countdown.remaining_ticks,
				"total": countdown.skill.ticks,
			})
		
		if countdown.remaining_ticks <= 0:
			expiring.append(slot)
	
	if expiring.is_empty():
		return
	
	# separate damage-dealing timers from buff/mod/util
	var damaging: Array = []
	var non_damaging: Array = []
	
	for slot in expiring:
		var countdown = _running_countdowns[slot]
		_running_countdowns.erase(slot)
		
		if slot == -1:
			# Basic attack
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
				total_damage += BASIC_ATCK_DMG;
		
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
	
	# -- non-damaging skills that expired alone --
	elif non_damaging.size() > 0:
		for countdown in non_damaging:
			EventBus.emit_event(EventBus.SELF_BUFF_APPLIED, {
				"skill": countdown.skill,
				"effect_name": countdown.skill.effect_name if countdown.skill else "",
				"effect_strength": countdown.skill.effect_strength if countdown.skill else 0.0,
			})
	
	# Emit expiry events for all expired timers
	for slot in expiring:
		EventBus.emit_event(EventBus.SKILL_TIMER_EXPIRED, {
			"slot": slot,
		})


# -- Helpers --------------------------------------------------

## Add an effect to the array, stacking strength if it already exists.
func _add_or_stack_effect(effects: Array, name: String, strength: float) -> void:
	for e in effects:
		if e.name == name:
			e.strength += strength
			return
	effects.append({"name": name, "strength": strength})

func _on_skill_used(data: Dictionary) -> void:
	var slot = data.get("slot", -1)
	var skill = data.get("skill")
	if slot < 0 or not skill:
		return
	start_skill(slot, skill)

func _get_mouse_direction() -> Vector2:
	if not _player:
		return Vector2.RIGHT
	return (_player.get_global_mouse_position() - _player.global_position).normalized()
