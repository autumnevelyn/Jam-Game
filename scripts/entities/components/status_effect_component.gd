# runtime component that manages active status effects on an entity
# handles tick-down, burn dot damage, freeze+burn cancel, and ui signals
class_name StatusEffectComponent
extends Node

class ActiveStatus:
	var type: int
	var strength: float
	var remaining_ticks: int
	var total_ticks: int
	
	func _init(p_type: int, p_strength: float, p_remaining: int, p_total: int) -> void:
		type = p_type
		strength = p_strength
		remaining_ticks = p_remaining
		total_ticks = p_total

signal statuses_changed

var _statuses: Dictionary = {}  # Effect.Type -> ActiveStatus

## apply a new effect — handles cancel logic (freeze + burn remove each other)
func apply_effect(effect: Effect) -> void:
	if not effect:
		return
	
	# cancel logic: freeze and burn cancel each other out
	if effect.type == Effect.Type.FREEZE and _statuses.has(Effect.Type.BURN):
		_statuses.erase(Effect.Type.BURN)
		statuses_changed.emit()
		return
	if effect.type == Effect.Type.BURN and _statuses.has(Effect.Type.FREEZE):
		_statuses.erase(Effect.Type.FREEZE)
		statuses_changed.emit()
		return
	
	# apply or refresh
	if _statuses.has(effect.type):
		_statuses[effect.type].remaining_ticks = max(_statuses[effect.type].remaining_ticks, effect.base_duration_ticks)
	else:
		_statuses[effect.type] = ActiveStatus.new(effect.type, effect.base_strength, effect.base_duration_ticks, effect.base_duration_ticks)
	print_rich(get_parent(), " gained status: ", Effect.Type.keys()[effect.type].to_lower())
	statuses_changed.emit()

# self-contained timer for consistent tick rate regardless of skill activity
var _tick_timer: Timer

func _ready() -> void:
	_setup_tick_timer()


func _setup_tick_timer() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = SkillSystem.TICK_DURATION
	_tick_timer.one_shot = false
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	_tick_timer.start()


func _on_tick() -> void:
	var expired: Array = []
	var changed := false
	for type in _statuses.keys():
		var status = _statuses[type]
		status.remaining_ticks -= 1
		changed = true
		if status.remaining_ticks <= 0:
			expired.append(type)
			continue
		
		match type:
			Effect.Type.BURN:
				_apply_burn_tick(status)
	
	for type in expired:
		print_rich(get_parent(), " lost status: ", Effect.Type.keys()[type].to_lower())
		_statuses.erase(type)
	
	if changed:
		statuses_changed.emit()

func has_status(type: int) -> bool:
	return _statuses.has(type)

## returns the slow multiplier (1.0 = normal, less = slower)
func get_slow_multiplier() -> float:
	if _statuses.has(Effect.Type.FREEZE):
		return 0.5
	return 1.0

## returns a snapshot of active statuses for ui
func get_active_statuses() -> Array:
	var result: Array = []
	for type in _statuses.keys():
		var s = _statuses[type]
		result.append({"type": type, "strength": s.strength, "remaining": s.remaining_ticks, "total": s.total_ticks})
	return result

func _apply_burn_tick(status: ActiveStatus) -> void:
	var health_comp = _find_health_component(get_parent())
	if health_comp:
		health_comp.take_damage(status.strength, null, true);

func _find_health_component(node: Node) -> HealthComponent:
	if not node:
		return null
	for child in node.get_children():
		if child is HealthComponent:
			return child
	if node is HealthComponent:
		return node
	return null

func get_damage_multiplier() -> float:
	if _statuses.has(Effect.Type.DAMAGE_UP):
		return 1.5;
	return 1.0
