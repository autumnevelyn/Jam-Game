# attack_hitbox.gd
# hitbox area for player melee attacks.
extends Area2D

@onready var timer: Timer = $Timer

var parent: Node2D
var active: bool = false
var damage: float = 1.0


func _ready() -> void:
	parent = get_parent()
	visible = false


func _process(delta: float) -> void:
	if active:
		visible = true
		if timer.is_stopped():
			timer.start()
	else:
		visible = false


func _on_timer_timeout() -> void:
	active = false


func _on_area_entered(area: Area2D) -> void:
	if not active:
		return

	var target = area.get_parent()
	if not target:
		return

	# emit combat hit event for the CombatSystem to process
	EventBus.emit_event(EventBus.COMBAT_HIT, {
		"target": target,
		"attacker": parent,
		"damage": damage,
		"position": global_position,
	})

	active = false

	# for cuttable objects, destroy immediately
	if target.is_in_group("Cuttable"):
		target.queue_free()
