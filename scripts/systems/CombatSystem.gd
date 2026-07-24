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
	
	if not target or not is_instance_valid(target): return
	
	print_rich("dmg: %d" % damage, " | effects: ", effects)

	# try to find a HealthComponent on the target
	var health_comp = _find_health_component(target)
	if not health_comp:
		return

	var actual_damage = health_comp.take_damage(damage, attacker)
	#print(actual_damage);
	# track damage dealt
	GameData.damage_dealt += actual_damage

	# apply effects if any damage was dealt
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


## Apply effects to a target
## TODO implement
func _apply_effects(target: Node, effects: Array, attacker: Node) -> void:
	for effect in effects:
		var name = effect.get("name", "")
		var strength = effect.get("strength", 1.0)
		match name:
			"burn":
				_apply_burn(target, strength, attacker)
			"freeze":
				_apply_freeze(target, strength, attacker)
			_:
				# unknown -> ignore
				pass

func _apply_burn(target: Node, strength: float, attacker: Node) -> void:
	# dot?
	pass

func _apply_freeze(target: Node, strength: float, attacker: Node) -> void:
	# slow down movement? (burn immunity for X ticks if target self)
	pass


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
