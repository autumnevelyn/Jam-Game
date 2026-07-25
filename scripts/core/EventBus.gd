# eventBus.gd
# a decoupled pub/sub event system for cross-system communication.
# use: EventBus.emit_event("player_damaged", {"amount": 1, "source": enemy})
#       EventBus.subscribe("player_damaged", my_method)
extends Node

## Singleton autoload — enable in Project -> Autoload as "EventBus"

var _listeners: Dictionary = {}

# ---- Public API ----

func subscribe(event_name: String, callable: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	_listeners[event_name].append(callable)


func unsubscribe(event_name: String, callable: Callable) -> void:
	if _listeners.has(event_name):
		_listeners[event_name].erase(callable)


func emit_event(event_name: String, data: Dictionary = {}) -> void:
	print_rich("[color=#0086ce]%s[/color]" %event_name)
	if not _listeners.has(event_name):
		print_rich("\t[color=#545454]no listeners[/color]")
		return
	var n = _listeners[event_name].size()
	print_rich("\t[color=#545454]",n ," listener%s"%("" if n==1 else "s"), "[/color]")
	for callable in _listeners[event_name]:
		#print_rich("\t[color=#545454]listening: ", callable, "[/color]")
		callable.call(data)


func clear_all() -> void:
	_listeners.clear()


# ---- Pre-defined event names (for discoverability) ----

# ---- Player events ----
const PLAYER_DAMAGED        := "player_damaged"
const PLAYER_HEALED         := "player_healed"
const PLAYER_DIED           := "player_died"
const PLAYER_MOVED          := "player_moved"
const PLAYER_SKILL_USED     := "player_skill_used"
const PLAYER_LEVEL_UP       := "player_level_up"

# ---- Enemy events ----
const ENEMY_DAMAGED         := "enemy_damaged"
const ENEMY_KILLED          := "enemy_killed"

# ---- Item events ----
const ITEM_PICKED_UP        := "item_picked_up"
const RELIC_ACQUIRED        := "relic_acquired"

# ---- Combat events ----
const COMBAT_HIT            := "combat_hit"
const COMBAT_MISS           := "combat_miss"

# ---- Tick-based skill timer events ----
const SKILL_TIMER_STARTED   := "skill_timer_started"
const SKILL_TIMER_TICK      := "skill_timer_tick"
const SKILL_TIMER_EXPIRED   := "skill_timer_expired"
const ATTACK_FIRED          := "attack_fired" 
const SELF_BUFF_APPLIED     := "self_buff_applied"

# ---- Game states ----
const GAME_RUN_STARTED      := "game_run_started"
const GAME_RUN_ENDED        := "game_run_ended"
const GAME_ROOM_CLEARED     := "game_room_cleared"
const GAME_PAUSED           := "game_paused"
const GAME_UNPAUSED         := "game_unpaused"
