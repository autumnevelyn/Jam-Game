# PlayerSkillOverlay.gd
# A Node2D child of the player that draws small timer-circle indicators
# above the player's head for each actively running skill/basic-attack timer.
# Shows only when timers are active (no dimmed/inactive state).
# Includes per-frame fuse animation for the current tick.
extends Node2D

## Matches SkillSystem.TICK_DURATION
const TICK_DURATION: float = 2.0

# ---- Per-timer data ----
class ActiveTimer:
	var slot: int
	var skill: Skill  # null for basic attack
	var total_ticks: int
	var remaining_ticks: int
	var tick_start_msec: int  # time (ms) when the current tick began

	func _init(p_slot: int, p_skill: Skill, p_total: int, p_remaining: int) -> void:
		slot = p_slot
		skill = p_skill
		total_ticks = p_total
		remaining_ticks = p_remaining
		tick_start_msec = Time.get_ticks_msec()

# ---- State ----
var _active_timers: Dictionary = {}  # slot -> ActiveTimer

# ---- Drawing constants (smaller than the original SkillCircleIcon) ----
var _outer_radius: float = 10.0
var _inner_radius: float = 8.0
var _icon_size: float = 13.0
var _segment_gap: float = 0.04

# ---- Colors ----
var _fuse_color_start: Color = Color(1.0, 0.8, 0.2)   # Bright gold
var _fuse_color_end: Color = Color(1.0, 0.3, 0.1)     # Red-orange
var _segment_done_color: Color = Color(0.3, 0.3, 0.3, 0.25)  # Greyed out
var _placeholder_circle: Color = Color(0.6, 0.6, 0.6, 0.5)

# ---- Spacing between multiple timer circles ----
const CIRCLE_SPACING: float = 22.0


# ---- Lifecycle ----
func _ready() -> void:
	EventBus.subscribe(EventBus.SKILL_TIMER_STARTED, _on_timer_started)
	EventBus.subscribe(EventBus.SKILL_TIMER_TICK, _on_timer_tick)
	EventBus.subscribe(EventBus.SKILL_TIMER_EXPIRED, _on_timer_expired)
	EventBus.subscribe(EventBus.BASIC_ATTACK_STARTED, _on_basic_attack_started)


func _exit_tree() -> void:
	if EventBus:
		EventBus.unsubscribe(EventBus.SKILL_TIMER_STARTED, _on_timer_started)
		EventBus.unsubscribe(EventBus.SKILL_TIMER_TICK, _on_timer_tick)
		EventBus.unsubscribe(EventBus.SKILL_TIMER_EXPIRED, _on_timer_expired)
		EventBus.unsubscribe(EventBus.BASIC_ATTACK_STARTED, _on_basic_attack_started)


func _process(_delta: float) -> void:
	if _active_timers.is_empty():
		return
	
	# Any active timer means we need to update per-frame for the fuse animation
	queue_redraw()


# ---- Event handlers ----

func _on_timer_started(data: Dictionary) -> void:
	var slot = data.get("slot", -1)
	var skill: Skill = data.get("skill")
	var total = data.get("total_ticks", 1)
	
	if slot < 0:
		return
	
	_active_timers[slot] = ActiveTimer.new(slot, skill, total, total)
	queue_redraw()


func _on_timer_tick(data: Dictionary) -> void:
	var slot = data.get("slot", -1)
	var remaining = data.get("remaining", 0)
	
	if not _active_timers.has(slot):
		return
	
	var timer = _active_timers[slot]
	timer.remaining_ticks = remaining
	timer.tick_start_msec = Time.get_ticks_msec()


func _on_timer_expired(data: Dictionary) -> void:
	var slot = data.get("slot", -1)
	
	if not _active_timers.has(slot):
		return
	
	_active_timers.erase(slot)
	queue_redraw()


func _on_basic_attack_started(_data: Dictionary) -> void:
	# Basic attack has 1 tick, no skill resource
	var slot = -1
	_active_timers[slot] = ActiveTimer.new(slot, null, 1, 1)
	queue_redraw()


# ---- Drawing ----

func _draw() -> void:
	if _active_timers.is_empty():
		return
	
	# Sort timers by slot for consistent left-to-right ordering
	var sorted_slots = _active_timers.keys()
	sorted_slots.sort()
	
	var count = sorted_slots.size()
	var total_width = (count - 1) * CIRCLE_SPACING
	
	for i in range(count):
		var slot = sorted_slots[i]
		var timer = _active_timers[slot]
		var center_x = -total_width / 2.0 + i * CIRCLE_SPACING
		var center = Vector2(center_x, 0.0)
		
		_draw_timer_circle(center, timer)


func _draw_timer_circle(center: Vector2, timer: ActiveTimer) -> void:
	var seg_count = max(timer.total_ticks, 1)
	var seg_angle = (TAU - _segment_gap * seg_count) / seg_count
	var start_angle = -PI / 2  # start from top
	
	var elapsed_ticks = timer.total_ticks - timer.remaining_ticks
	
	# Compute per-frame tick progress for fuse animation
	var now_msec = Time.get_ticks_msec()
	var elapsed_sec = (now_msec - timer.tick_start_msec) / 1000.0
	var tick_progress = clampf(elapsed_sec / TICK_DURATION, 0.0, 1.0)
	
	for i in range(timer.total_ticks):
		var a0 = start_angle + i * (seg_angle + _segment_gap)
		var a1 = a0 + seg_angle
		
		if i < elapsed_ticks:
			# Already-expired segment: fully greyed
			_draw_segment(center, _outer_radius, _inner_radius, a0, a1, _segment_done_color)
		elif i == elapsed_ticks:
			# Current segment: fuse effect with per-frame progress
			var fuse_angle = seg_angle * tick_progress
			# Burned part (grey)
			if tick_progress > 0.0:
				_draw_segment(center, _outer_radius, _inner_radius, a0, a0 + fuse_angle, _segment_done_color)
			# Remaining burning part (gradient)
			var remaining_a = a0 + fuse_angle
			var burn_color = _fuse_color_start.lerp(_fuse_color_end, tick_progress)
			_draw_segment(center, _outer_radius, _inner_radius, remaining_a, a1, burn_color)
		else:
			# Future segments: fully lit
			_draw_segment(center, _outer_radius, _inner_radius, a0, a1, _fuse_color_start)
	
	# Draw skill icon or placeholder in the center
	if timer.skill and timer.skill.texture:
		var icon_rect = Rect2(
			center.x - _icon_size / 2,
			center.y - _icon_size / 2,
			_icon_size,
			_icon_size
		)
		draw_texture_rect(timer.skill.texture, icon_rect, false, Color.WHITE)
	else:
		# Placeholder circle for basic attack
		draw_circle(center, _icon_size / 2, _placeholder_circle)


func _draw_segment(center: Vector2, outer_r: float, inner_r: float, a0: float, a1: float, color: Color) -> void:
	if a1 <= a0:
		return
	
	var steps = max(8, int((a1 - a0) * 8))
	var points: PackedVector2Array = []
	
	# Outer arc
	for i in range(steps + 1):
		var a = a0 + (a1 - a0) * (float(i) / steps)
		points.append(center + Vector2(cos(a), sin(a)) * outer_r)
	# Inner arc (reverse)
	for i in range(steps, -1, -1):
		var a = a0 + (a1 - a0) * (float(i) / steps)
		points.append(center + Vector2(cos(a), sin(a)) * inner_r)
	
	draw_colored_polygon(points, color)
