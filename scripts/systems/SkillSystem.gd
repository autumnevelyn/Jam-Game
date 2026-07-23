# skillSystem.gd
# Tick-based skill timer & combo system.
# Each tick = 0.5 seconds. Skills have durations in ticks.
# When multiple timers expire on the same tick, they combine into a combo attack.
# Non-damage skills that expire without an outgoing attack are applied as self-buffs.
extends Node

## Duration of one tick in seconds.
const TICK_DURATION: float = 0.5

## Data for one running skill timer.
class TimerData:
	var skill: Skill
	var remaining_ticks: int
	var slot: int
	
	func _init(p_slot: int, p_skill: Skill) -> void:
		slot = p_slot
		skill = p_skill
		remaining_ticks = p_skill.ticks if p_skill else 1

# ── State ────────────────────────────────────────────────────
## Running timers keyed by slot index (-1 = basic attack).
var _timers: Dictionary = {}

## Currently active attack hitbox (if any). Used for combo chaining.
var _active_attack: Dictionary = {}

## Reference to the player node (set externally).
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


## Set the player node reference so we can spawn attacks at the right position.
func set_player(player: Node2D) -> void:
	_player = player

# ── Public API ───────────────────────────────────────────────

## Start the basic attack timer (1 tick).
func start_basic_attack() -> void:
	if _timers.has(-1):
		return  # basic attack already counting down
	_timers[-1] = TimerData.new(-1, null)
	_timers[-1].remaining_ticks = 1
	EventBus.emit_event(EventBus.BASIC_ATTACK_STARTED, {})


## Start a skill timer for the given slot.
func start_skill(slot: int, skill: Skill) -> void:
	if _timers.has(slot):
		return  # skill already counting down
	_timers[slot] = TimerData.new(slot, skill)
	EventBus.emit_event(EventBus.SKILL_TIMER_STARTED, {
		"slot": slot,
		"skill": skill,
		"total_ticks": skill.ticks,
	})


## Returns the remaining ticks for a timer, or -1 if not active.
func get_remaining_ticks(slot: int) -> int:
	if _timers.has(slot):
		return _timers[slot].remaining_ticks
	return -1


## Returns the total ticks for a timer, or -1 if not active.
func get_total_ticks(slot: int) -> int:
	if _timers.has(slot):
		var td = _timers[slot]
		if td.skill:
			return td.skill.ticks
		return 1  # basic attack
	return -1


## Returns true if the given slot has an active timer.
func is_timer_active(slot: int) -> bool:
	return _timers.has(slot)


## Returns true if there is an active outgoing attack (hitbox).
func has_active_attack() -> bool:
	return _active_attack.has("active") and _active_attack.active == true


## Called when the attack hitbox deactivates (clears combo anchor).
func on_attack_resolved() -> void:
	_active_attack = {}


# ── Tick Processing ──────────────────────────────────────────

func _on_tick() -> void:
	var expiring: Array = []
	
	# Tick all timers
	for slot in _timers.keys():
		var td = _timers[slot] as TimerData
		td.remaining_ticks -= 1
		
		if td.skill and td.skill.skill_type != Skill.SkillType.BASIC_ATTACK:
			EventBus.emit_event(EventBus.SKILL_TIMER_TICK, {
				"slot": slot,
				"remaining": td.remaining_ticks,
				"total": td.skill.ticks,
			})
		
		if td.remaining_ticks <= 0:
			expiring.append(slot)
	
	# Nothing expiring this tick — done
	if expiring.is_empty():
		return
	
	# Separate damage-dealing timers from non-damage timers
	var damaging: Array = []    # TimerData entries that deal damage
	var non_damaging: Array = []  # TimerData entries that are buff/mod/util
	
	for slot in expiring:
		var td = _timers[slot]
		_timers.erase(slot)
		
		if slot == -1:
			# Basic attack
			damaging.append(td)
		elif td.skill.skill_type == Skill.SkillType.DAMAGE:
			damaging.append(td)
		else:
			non_damaging.append(td)
	
	# Process damaging + basic attack
	_process_damaging(damaging)
	# Process non-damaging skills
	_process_non_damaging(non_damaging)
	
	# Emit expiry events for all expired timers
	for slot in expiring:
		EventBus.emit_event(EventBus.SKILL_TIMER_EXPIRED, {
			"slot": slot,
		})


# ── Damage Processing ────────────────────────────────────────

func _process_damaging(damaging: Array) -> void:
	if damaging.is_empty():
		return
	
	var total_damage: float = 0.0
	var effects: Array = []
	var combo_count: int = 0
	
	for td in damaging:
		if td.skill:
			total_damage += td.skill.base_damage
			if td.skill.effect_name and td.skill.effect_name != "":
				effects.append({"name": td.skill.effect_name, "strength": td.skill.effect_strength})
		else:
			total_damage += 1.0
		combo_count += 1
	
	var existing_damage: float = 0.0
	var existing_effects: Array = []
	if has_active_attack():
		existing_damage = _active_attack.get("damage", 0.0)
		existing_effects = _active_attack.get("effects", []).duplicate()
		combo_count += _active_attack.get("combo_count", 1)
	
	if combo_count > 1:
		total_damage = (existing_damage + total_damage) * (1.0 + 0.5 * (combo_count - 1))
	else:
		total_damage += existing_damage
	
	var all_effects: Array = existing_effects.duplicate()
	for e in effects:
		var found = false
		for existing in all_effects:
			if existing.name == e.name:
				existing.strength += e.strength
				found = true
				break
		if not found:
			all_effects.append(e)
	
	_active_attack = {
		"active": true,
		"damage": total_damage,
		"effects": all_effects,
		"combo_count": combo_count,
	}
	
	EventBus.emit_event(EventBus.ATTACK_FIRED, {
		"damage": total_damage,
		"effects": all_effects,
		"combo_count": combo_count,
		"position": _player.global_position if _player else Vector2.ZERO,
		"direction": _get_mouse_direction(),
	})


func _process_non_damaging(non_damaging: Array) -> void:
	if non_damaging.is_empty():
		return
	
	if has_active_attack():
		for td in non_damaging:
			if td.skill and td.skill.effect_name and td.skill.effect_name != "":
				var e = {"name": td.skill.effect_name, "strength": td.skill.effect_strength}
				var found = false
				for existing in _active_attack.get("effects", []):
					if existing.name == e.name:
						existing.strength += e.strength
						found = true
						break
				if not found:
					_active_attack["effects"].append(e)
			_active_attack["combo_count"] = _active_attack.get("combo_count", 1) + 1
		
		EventBus.emit_event(EventBus.ATTACK_FIRED, {
			"damage": _active_attack["damage"],
			"effects": _active_attack["effects"],
			"combo_count": _active_attack["combo_count"],
			"position": _player.global_position if _player else Vector2.ZERO,
			"direction": _get_mouse_direction(),
		})
	else:
		for td in non_damaging:
			EventBus.emit_event(EventBus.SELF_BUFF_APPLIED, {
				"skill": td.skill,
				"effect_name": td.skill.effect_name if td.skill else "",
				"effect_strength": td.skill.effect_strength if td.skill else 0.0,
			})


func _on_skill_used(data: Dictionary) -> void:
	var slot = data.get("slot", -1)
	var skill_resource = data.get("skill")
	if slot < 0 or not skill_resource:
		return
	start_skill(slot, skill_resource)


func _get_mouse_direction() -> Vector2:
	if not _player:
		return Vector2.RIGHT
	return (_player.get_global_mouse_position() - _player.global_position).normalized()
