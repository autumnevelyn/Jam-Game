# PlayerSkillOverlay.gd
# A Node2D child of the player that draws small timer-circle indicators
# above the player's head for each actively running skill timer.
# Shows a dimmed version when skills are queued (waiting for next tick).
# Includes per-frame fuse animation for the current tick.
extends Node2D

# ---- Per-timer data ----
class ActiveTimer:
	var skill: Skill
	var remaining_ticks: int
	var tick_start_msec: int  # time (ms) when the current tick began

	func _init(p_skill: Skill) -> void:
		skill = p_skill
		remaining_ticks = skill.ticks
		tick_start_msec = Time.get_ticks_msec()

# ---- State ----
var _active_timers: Dictionary = {}  # skill -> ActiveTimer
var _queued_skills: Array = []       # Skills queued but not yet running (ordered by queue)

# ---- Drawing constants (smaller than the original SkillCircleIcon) ----
var _outer_radius: float = 10.0
var _inner_radius: float = 8.0
var _icon_size: float = 13.0
var _segment_gap: float = 0.1

# ---- Colors ----
var _fuse_color_start: Color = Color(1.0, 0.8, 0.2)   # Bright gold
var _fuse_color_end: Color = Color(1.0, 0.3, 0.1)     # Red-orange
var _segment_done_color: Color = Color(0.3, 0.3, 0.3, 0.25)  # Greyed out
var _placeholder_circle: Color = Color(0.6, 0.6, 0.6, 0.5)
var _queued_segment_color: Color = Color(0.3, 0.3, 0.3, 0.3)  # Dim grey for queued

# ---- Spacing between multiple timer circles ----
const CIRCLE_SPACING: float = 22.0


# ---- Lifecycle ----
func _ready() -> void:
	EventBus.subscribe(EventBus.SKILL_TIMER_STARTED, _on_timer_started)
	EventBus.subscribe(EventBus.SKILL_TIMER_TICK, _on_timer_tick)
	EventBus.subscribe(EventBus.SKILL_TIMER_EXPIRED, _on_timer_expired)
	EventBus.subscribe(EventBus.PLAYER_SKILL_USED, _on_skill_queued)
	
	# add status indicator below the skill timer circles
	var status_indicator = EffectStatusIcon.new()
	status_indicator.name = "EffectStatusIcon"
	status_indicator._set_offset(Vector2(0, _outer_radius + 4.0))
	add_child(status_indicator)


func _exit_tree() -> void:
	if EventBus:
		EventBus.unsubscribe(EventBus.SKILL_TIMER_STARTED, _on_timer_started)
		EventBus.unsubscribe(EventBus.SKILL_TIMER_TICK, _on_timer_tick)
		EventBus.unsubscribe(EventBus.SKILL_TIMER_EXPIRED, _on_timer_expired)
		EventBus.unsubscribe(EventBus.PLAYER_SKILL_USED, _on_skill_queued)


func _process(_delta: float) -> void:
	if _active_timers.is_empty():
		return
	
	# Any active timer means we need to update per-frame for the fuse animation
	queue_redraw()


# ---- Event handlers ----

func _on_skill_queued(data: Dictionary) -> void:
	var skill: Skill = data.get("skill")
	
	if not skill:
		return
	
	# Avoid duplicates
	if _queued_skills.has(skill):
		return
	
	_queued_skills.append(skill)
	queue_redraw()


func _on_timer_started(data: Dictionary) -> void:
	var skill: Skill = data.get("skill")
	if not skill:
		return
	
	# Remove from queued if it was still there
	_queued_skills.erase(skill)
	
	_active_timers[skill] = ActiveTimer.new(skill)
	queue_redraw()


func _on_timer_tick(data: Dictionary) -> void:
	var skill: Skill = data.get("skill")
	var remaining = data.get("remaining", 0)
	
	if not _active_timers.has(skill):
		return
	
	var timer = _active_timers[skill]
	timer.remaining_ticks = remaining
	timer.tick_start_msec = Time.get_ticks_msec()


func _on_timer_expired(data: Dictionary) -> void:
	var skill: Skill = data.get("skill")
	
	if not _active_timers.has(skill):
		return
	
	_active_timers.erase(skill)
	queue_redraw()


# ---- Drawing ----

func _draw() -> void:
	if _active_timers.is_empty() and _queued_skills.is_empty():
		return
	
	# Gather all entries
	var all_entries: Array = []
	
	for skill in _queued_skills:
		if _active_timers.has(skill): continue
		all_entries.append({"skill": skill, "queued": true, "remaining": skill.ticks})
	
	for skill in _active_timers.keys():
		all_entries.append({"skill": skill, "queued": false, "remaining": skill.ticks})#_active_timers[skill].remaining_ticks})

	if all_entries.is_empty():
		return
	
	# Sort by remaining ticks descending (largest remaining first)
	all_entries.sort_custom(func(a, b):
		if a.remaining != b.remaining:
			return a.remaining > b.remaining
		return (a.skill != SkillSystem.slash_skill)
	)
	
	var count = all_entries.size()
	var total_width = (count - 1) * CIRCLE_SPACING
	
	for i in range(count):
		var entry = all_entries[i]
		var center_x = -total_width / 2.0 + i * CIRCLE_SPACING
		var center = Vector2(center_x, 0.0)
		
		if entry.queued:
			_draw_queued_indicator(center, entry.skill)
		else:
			_draw_timer_circle(center, _active_timers[entry.skill])


func _draw_queued_indicator(center: Vector2, skill: Skill) -> void:
	# Draw full circle dimmed — reuses the inactive/dim aesthetic
	var seg_count = 1
	if skill:
		seg_count = max(skill.ticks, 1)
	
	var seg_angle = (TAU - _segment_gap * seg_count) / seg_count
	var start_angle = -PI / 2
	
	for i in range(seg_count):
		var a0 = start_angle + i * (seg_angle + _segment_gap)
		var a1 = a0 + seg_angle
		_draw_segment(center, _outer_radius, _inner_radius, a0, a1, _queued_segment_color)
	
	# Draw skill icon dimmed
	if skill and skill.texture:
		var icon_rect = Rect2(
			center.x - _icon_size / 2,
			center.y - _icon_size / 2,
			_icon_size,
			_icon_size
		)
		draw_texture_rect(skill.texture, icon_rect, false, Color.WHITE * 0.4)


func _draw_timer_circle(center: Vector2, timer: ActiveTimer) -> void:
	var seg_count = max(timer.skill.ticks, 1)
	var seg_angle = (TAU - _segment_gap * seg_count) / seg_count
	var start_angle = -PI / 2  # start from top
	
	var elapsed_ticks = timer.skill.ticks - timer.remaining_ticks
	
	# Compute per-frame tick progress for fuse animation
	var now_msec = Time.get_ticks_msec()
	var elapsed_sec = (now_msec - timer.tick_start_msec) / 1000.0
	var tick_progress = clampf(elapsed_sec / SkillSystem.TICK_DURATION, 0.0, 1.0)
	
	for i in range(timer.skill.ticks):
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
		# Placeholder circle (no texture available)
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
