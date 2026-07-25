# simple node2d that draws small colored circles for each active status effect
# can be added as a child of any entity (player or enemy)
# listens to the parent's StatusEffectComponent for changes
extends Node2D
class_name EffectStatusIcon

## offset from parent's center/pivot
var _offset: Vector2 = Vector2.ZERO
var _status_comp: StatusEffectComponent = null

var _indicator_radius: float = 3.0
var _indicator_gap: float = 1.5

var _active_statuses: Array = []

func _ready() -> void:
	_status_comp = _find_status_effect_component(get_parent())
	if _status_comp:
		_status_comp.statuses_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if _status_comp:
		_active_statuses = _status_comp.get_active_statuses()
	else:
		_active_statuses.clear()
	queue_redraw()


func _set_offset(new_offset: Vector2) -> void:
	_offset = new_offset
	queue_redraw()


func _draw() -> void:
	if _active_statuses.is_empty():
		return
	
	var total_width = (_active_statuses.size() - 1) * (_indicator_radius * 2 + _indicator_gap)
	var start_x = -total_width / 2.0 + _offset.x
	var y = _offset.y
	
	for i in range(_active_statuses.size()):
		var status = _active_statuses[i]
		var x = start_x + i * (_indicator_radius * 2 + _indicator_gap)
		var center = Vector2(x, y)
		
		var color = _get_status_color(status.type)
		draw_circle(center, _indicator_radius, color)


func _get_status_color(type: int) -> Color:
	match type:
		Effect.Type.BURN:
			return Color(1.0, 0.3, 0.1, 0.9)  # orange-red
		Effect.Type.FREEZE:
			return Color(0.3, 0.6, 1.0, 0.9)  # light blue
		_:
			return Color.WHITE


func _find_status_effect_component(node: Node) -> StatusEffectComponent:
	if not node:
		return null
	for child in node.get_children():
		if child is StatusEffectComponent:
			return child
	if node is StatusEffectComponent:
		return node
	return null
