# playerData.gd
# central player data model with reactive signals.
# registered as an autoload so any scene can reference it.
extends Node

## Emitted when health changes.
signal health_changed(old_value: float, new_value: float, max_value: float)
## Emitted when the player dies.
signal player_died
## Emitted when a skill is added.
signal skill_added(skill_index: int, skill: Resource)
## Emitted when currency changes.
signal money_changed(old_value: float, new_value: float)
## Emitted when the level changes.
signal level_changed(old_level: int, new_level: int)

# ── Stats ───────────────────────────────────────────────────────────────────
var max_health: float = 3.0
var health: float = 3.0:
	set(value):
		var old = health
		health = clampf(value, 0.0, max_health)
		health_changed.emit(old, health, max_health)
		if health <= 0.0:
			player_died.emit()

var level: int = 1:
	set(value):
		var old = level
		level = value
		level_changed.emit(old, level)

var money: float = 0.0:
	set(value):
		var old = money
		money = value
		money_changed.emit(old, money)

# ── Inventory ───────────────────────────────────────────────────────────────
var current_skills: Array = []
var current_equipment: Array = []
var current_relics: Array = []

# max inventory slots
const MAX_SKILL_SLOTS: int = 4
const MAX_EQUIPMENT_SLOTS: int = 4
const MAX_RELIC_SLOTS: int = 4


# ── Public API ──────────────────────────────────────────────────────────────

## Apply damage to the player. Returns the actual damage dealt.
func take_damage(amount: float, source = null) -> float:
	var actual_damage = min(amount, health)
	health -= amount
	EventBus.emit_event(EventBus.PLAYER_DAMAGED, {
		"amount": actual_damage,
		"source": source,
		"remaining_health": health,
	})
	return actual_damage


## Heal the player. Returns the actual amount healed.
func heal(amount: float) -> float:
	var before = health
	health += amount
	var healed = health - before
	if healed > 0.0:
		EventBus.emit_event(EventBus.PLAYER_HEALED, {
			"amount": healed,
		})
	return healed


## Add a skill resource to the player's skill slots.
func add_skill(skill_resource) -> int:
	if current_skills.size() >= MAX_SKILL_SLOTS:
		return -1
	current_skills.append(skill_resource)
	var slot = current_skills.size() - 1
	skill_added.emit(slot, skill_resource)
	EventBus.emit_event(EventBus.PLAYER_SKILL_READY, {
		"slot": slot,
		"skill": skill_resource,
	})
	return slot


## Add an equipment item.
func add_equipment(item_resource) -> int:
	if current_equipment.size() >= MAX_EQUIPMENT_SLOTS:
		return -1
	current_equipment.append(item_resource)
	return current_equipment.size() - 1


## Add a relic.
func add_relic(relic_resource) -> int:
	if current_relics.size() >= MAX_RELIC_SLOTS:
		return -1
	current_relics.append(relic_resource)
	EventBus.emit_event(EventBus.RELIC_ACQUIRED, {
		"slot": current_relics.size() - 1,
		"relic": relic_resource,
	})
	return current_relics.size() - 1


## Reset all data for a new run.
func reset_for_new_run() -> void:
	health = max_health
	level = 1
	money = 0.0
	current_skills.clear()
	current_equipment.clear()
	current_relics.clear()
