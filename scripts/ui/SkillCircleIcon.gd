# skillCircleIcon.gd
# UI control for a skill icon with a surrounding circular tick timer.
# The circle is split into N segments (one per tick of the skill's timer).
# When activated, all segments light up. Each segment fuses from one end,
# and when the current tick expires, the whole segment goes transparent/greyed out.
class_name SkillCircleIcon
extends Control

## The skill resource to display.
var skill: Skill = null:
	set(value):
		skill = value
		queue_redraw()

## The slot index this icon represents.
var slot_index: int = -1

## Whether a timer is currently running for this skill.
var _is_active: bool = false

## Total ticks for the current timer.
var _total_ticks: int = 1

## Remaining ticks.
var _remaining_ticks: int = 0

## Fuse progress within the current tick (0.0 to 1.0).
var _tick_progress: float = 0.0

# -- Colors --------------------------------------------------─
var _fuse_color_start: Color = Color(1.0, 0.8, 0.2)   # Bright gold
var _fuse_color_end: Color = Color(1.0, 0.3, 0.1)     # Red-orange
var _segment_done_color: Color = Color(0.3, 0.3, 0.3, 0.15)  # Very faint grey
var _inactive_color: Color = Color(0.4, 0.4, 0.4, 0.3)  # Dim grey

## Icon draw size (square side).
var _icon_size: float = 36.0
## Outer radius of the circle segments.
var _outer_radius: float = 26.0
## Inner radius of the circle segments (donut hole).
var _inner_radius: float = 20.0
## Gap between segments in radians.
var _segment_gap: float = 0.04

##constuctor

func _init(skill_res:Skill = null, slot: int = -1):
	skill = skill_res
	slot_index = slot

func _ready() -> void:
	custom_minimum_size = Vector2(_outer_radius * 2, _outer_radius * 2)
	mouse_filter = MOUSE_FILTER_IGNORE


## Start the timer display.
func start_timer(total_ticks: int) -> void:
	_is_active = true
	_total_ticks = total_ticks
	_remaining_ticks = total_ticks
	_tick_progress = 0.0
	queue_redraw()


## Advance the fuse animation by a tick-progress delta (0..1 per tick).
func update_tick_progress(progress: float) -> void:
	_tick_progress = progress
	queue_redraw()


## Called when one tick elapses.
func on_tick_elapsed(remaining: int) -> void:
	_remaining_ticks = remaining
	_tick_progress = 0.0
	queue_redraw()


## Called when the timer expires or is cancelled.
func stop_timer() -> void:
	_is_active = false
	_remaining_ticks = 0
	_tick_progress = 0.0
	queue_redraw()


func _draw() -> void:
	if not skill and not _is_active:
		return
	
	var center = Vector2(_outer_radius, _outer_radius)
	var seg_count = max(_total_ticks, 1)
	var seg_angle = (TAU - _segment_gap * seg_count) / seg_count
	var start_angle = -PI / 2  # start from top
	
	if _is_active and _remaining_ticks > 0:
		var elapsed_ticks = _total_ticks - _remaining_ticks
		
		for i in range(_total_ticks):
			var a0 = start_angle + i * (seg_angle + _segment_gap)
			var a1 = a0 + seg_angle
			
			if i < elapsed_ticks:
				# Already-expired segment: fully transparent/greyed
				_draw_segment(center, _outer_radius, _inner_radius, a0, a1, _segment_done_color)
			elif i == elapsed_ticks:
				# Current segment: fuse effect (gradient from start to end)
				var fuse_angle = seg_angle * _tick_progress
				# Part that's already burned (grey)
				if _tick_progress > 0.0:
					_draw_segment(center, _outer_radius, _inner_radius, a0, a0 + fuse_angle, _segment_done_color)
				# Part that's still fusing (gradient)
				var remaining_a = a0 + fuse_angle
				var burn_color = _fuse_color_start.lerp(_fuse_color_end, _tick_progress)
				_draw_segment(center, _outer_radius, _inner_radius, remaining_a, a1, burn_color)
			else:
				# Future segments: fully lit with base fuse color
				_draw_segment(center, _outer_radius, _inner_radius, a0, a1, _fuse_color_start)
	else:
		# Inactive: dim segments
		if _total_ticks > 0:
			for i in range(_total_ticks):
				var a0 = start_angle + i * (seg_angle + _segment_gap)
				var a1 = a0 + seg_angle
				_draw_segment(center, _outer_radius, _inner_radius, a0, a1, _inactive_color)
	
	# Draw the icon in the center
	if skill and skill.texture:
		var icon_rect = Rect2(
			center.x - _icon_size / 2,
			center.y - _icon_size / 2,
			_icon_size,
			_icon_size
		)
		draw_texture_rect(skill.texture, icon_rect, false, Color.WHITE * (0.4 if not _is_active else 1.0))
	elif _is_active:
		# Draw placeholder circle
		draw_circle(center, _icon_size / 2, Color(0.6, 0.6, 0.6, 0.5))


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
