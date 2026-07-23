# combatSystem.gd
# handles combat interactions: damage calculation, hit validation, death handling.
# Listens to EventBus events and supports combined effects from skill combos.
extends Node

func _ready() -> void:
	EventBus.subscribe(EventBus.COMBAT_HIT, _on_combat_hit)


## Validate and process a combat hit.
func _on_combat_hit(data: Dictionary) -> void:
	var target = data.get("target") as Node
	var attacker = data.get("attacker") as Node
	var damage = data.get("damage", 1.0)
	var effects = data.get("effects", [])
	var hit_position = data.get("position", Vector2.ZERO)

	if not target or not is_instance_valid(target):
		return

	# try to find a HealthComponent on the target
	var health_comp = _find_health_component(target)
	if not health_comp:
		return

	var actual_damage = health_comp.take_damage(damage, attacker)

	# track damage dealt
	GameData.damage_dealt += actual_damage

	# Apply effects if any damage was dealt
	if actual_damage > 0.0 and effects.size() > 0:
		_apply_effects(target, effects, attacker)

	# if target died
	if health_comp.health <= 0.0:
		if target.is_in_group("Enemy"):
			GameData.enemies_killed += 1
			EventBus.emit_event(EventBus.ENEMY_KILLED, {
				"enemy": target,
				"position": target.global_position,
			})
			target.queue_free()


## Apply effect dictionaries to a target. Effects are defined by name + strength.
## Extend this with specific effect implementations.
func _apply_effects(target: Node, effects: Array, attacker: Node) -> void:
	for effect in effects:
		var name = effect.get("name", "")
		var strength = effect.get("strength", 1.0)
		match name:
			"burn":
				# Example: apply a burning DoT
				_apply_burn(target, strength, attacker)
			"freeze":
				# Example: slow or freeze the target
				_apply_freeze(target, strength, attacker)
			"stun":
				# Example: stun the target
				_apply_stun(target, strength, attacker)
			"poison":
				# Example: poison damage over time
				_apply_poison(target, strength, attacker)
			_:
				# Unknown effects are ignored
				pass


func _apply_burn(target: Node, strength: float, attacker: Node) -> void:
	# Simple burn: deal extra damage after a delay
	var burn_timer = Timer.new()
	burn_timer.wait_time = 1.0
	burn_timer.one_shot = true
	target.add_child(burn_timer)
	burn_timer.timeout.connect(func():
		if is_instance_valid(target):
			var health_comp = _find_health_component(target)
			if health_comp:
				health_comp.take_damage(strength * 0.5, attacker)
		burn_timer.queue_free()
	)
	burn_timer.start()


func _apply_freeze(target: Node, strength: float, attacker: Node) -> void:
	# Simple freeze: slow down movement (if the target has a MovementComponent)
	var move_comp = _find_movement_component(target)
	if move_comp:
		move_comp.speed *= (1.0 - strength * 0.3)
		# Restore after a short time
		var thaw_timer = Timer.new()
		thaw_timer.wait_time = 1.0 * strength
		thaw_timer.one_shot = true
		target.add_child(thaw_timer)
		var original_speed = move_comp.speed / (1.0 - strength * 0.3)
		thaw_timer.timeout.connect(func():
			if is_instance_valid(target) and move_comp:
				move_comp.speed = original_speed
			thaw_timer.queue_free()
		)
		thaw_timer.start()


func _apply_stun(target: Node, strength: float, attacker: Node) -> void:
	# Simple stun: disable the enemy temporarily
	if target.has_method("stun"):
		target.call("stun", strength * 0.5)


func _apply_poison(target: Node, strength: float, attacker: Node) -> void:
	# Simple poison: damage over time
	var ticks = int(strength * 2)
	for i in range(ticks):
		var poison_timer = Timer.new()
		poison_timer.wait_time = 1.0 + i * 0.5
		poison_timer.one_shot = true
		target.add_child(poison_timer)
		poison_timer.timeout.connect(func():
			if is_instance_valid(target):
				var health_comp = _find_health_component(target)
				if health_comp:
					health_comp.take_damage(strength * 0.3, attacker)
			poison_timer.queue_free()
		)
		poison_timer.start()


## Walk up the tree to find a HealthComponent on the target or its children.
func _find_health_component(node: Node) -> HealthComponent:
	if not node:
		return null
	# check direct children first
	for child in node.get_children():
		if child is HealthComponent:
			return child
	# check the node itself
	if node is HealthComponent:
		return node
	return null


## Find a MovementComponent on the node or its children.
func _find_movement_component(node: Node) -> MovementComponent:
	if not node:
		return null
	for child in node.get_children():
		if child is MovementComponent:
			return child
	if node is MovementComponent:
		return node
	return null
