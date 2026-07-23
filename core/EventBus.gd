# eventBus.gd
# a decoupled pub/sub event system for cross-system communication.
# use: EventBus.emit_event("player_damaged", {"amount": 1, "source": enemy})
#       EventBus.subscribe("player_damaged", my_method)
extends Node

## Singleton autoload — enable in Project -> Autoload as "EventBus"

var _listeners: Dictionary = {}

# ── Public API ──────────────────────────────────────────────────────────────

func subscribe(event_name: String, callable: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	_listeners[event_name].append(callable)


func unsubscribe(event_name: String, callable: Callable) -> void:
	if _listeners.has(event_name):
		_listeners[event_name].erase(callable)


func emit_event(event_name: String, data: Dictionary = {}) -> void:
	if _listeners.has(event_name):
		for callable in _listeners[event_name]:
			callable.call(data)


func clear_all() -> void:
	_listeners.clear()


# ── Pre-defined event names (for discoverability) ──────────────────────────

const PLAYER_DAMAGED        := "player_damaged"
const PLAYER_HEALED         := "player_healed"
const PLAYER_DIED           := "player_died"
const PLAYER_MOVED          := "player_moved"
const PLAYER_SKILL_USED     := "player_skill_used"
const PLAYER_SKILL_READY    := "player_skill_ready"
const PLAYER_LEVEL_UP       := "player_level_up"

const ENEMY_DAMAGED         := "enemy_damaged"
const ENEMY_KILLED          := "enemy_killed"

const ITEM_PICKED_UP        := "item_picked_up"
const RELIC_ACQUIRED        := "relic_acquired"

const COMBAT_HIT            := "combat_hit"
const COMBAT_MISS           := "combat_miss"

const GAME_RUN_STARTED      := "game_run_started"
const GAME_RUN_ENDED        := "game_run_ended"
const GAME_ROOM_CLEARED     := "game_room_cleared"
const GAME_PAUSED           := "game_paused"
const GAME_UNPAUSED         := "game_unpaused"
