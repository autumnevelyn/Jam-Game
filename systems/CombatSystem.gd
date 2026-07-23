# combatSystem.gd
# handles combat interactions: damage calculation, hit validation, death handling.
# listens to EventBus events and updates game data.
extends Node

func _ready() -> void:
	EventBus.subscribe(EventBus.COMBAT_HIT, _on_combat_hit)


## Validate and process a combat hit.
func _on_combat_hit(data: Dictionary) -> void:
	var target = data.get("target") as Node
	var attacker = data.get("attacker") as Node
	var damage = data.get("damage", 1.0)
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

	# if target died
	if health_comp.health <= 0.0:
		if target.is_in_group("Enemy"):
			GameData.enemies_killed += 1
			EventBus.emit_event(EventBus.ENEMY_KILLED, {
				"enemy": target,
				"position": target.global_position,
			})
			target.queue_free()


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
