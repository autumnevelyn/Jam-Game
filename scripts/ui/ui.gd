# ui.gd
# main UI controller. Manages health display, skill icons with timer circles, and inventory panels.
# Updated for the tick-based skill system.
extends Control

@onready var health_container: BoxContainer = $health_container
@onready var enemies_left_label: Label = $"enemies left_label"
@onready var skill_container: VBoxContainer = $skill_container

# cached heart nodes
var _heart_nodes: Array = []

# skill icon instances keyed by slot index
var _skill_icons: Dictionary = {}


func _ready() -> void:
	# cache heart references
	for child in health_container.get_children():
		_heart_nodes.append(child)
		if child.has_method("set_id"):
			child.set_id(_heart_nodes.size() - 1)

	# connect to reactive events instead of polling
	PlayerData.health_changed.connect(_on_player_health_changed)
	PlayerData.player_died.connect(_on_player_died)
	PlayerData.skill_added.connect(_on_skill_added)

	EventBus.subscribe(EventBus.ENEMY_KILLED, _on_enemy_killed);
	# initial update
	_update_all_hearts();
	_on_enemy_killed({}, true);
	
	# Build skill icons for already-equipped skills
	_refresh_all_skill_icons()
	
	# Listen to skill timer events for UI updates
	EventBus.subscribe(EventBus.SKILL_TIMER_STARTED, _on_skill_timer_started)
	EventBus.subscribe(EventBus.SKILL_TIMER_TICK, _on_skill_timer_tick)
	EventBus.subscribe(EventBus.SKILL_TIMER_EXPIRED, _on_skill_timer_expired)
	EventBus.subscribe(EventBus.BASIC_ATTACK_STARTED, _on_basic_attack_started)


func _exit_tree() -> void:
	# clean up subscriptions
	EventBus.unsubscribe(EventBus.ENEMY_KILLED, _on_enemy_killed)
	EventBus.unsubscribe(EventBus.SKILL_TIMER_STARTED, _on_skill_timer_started)
	EventBus.unsubscribe(EventBus.SKILL_TIMER_TICK, _on_skill_timer_tick)
	EventBus.unsubscribe(EventBus.SKILL_TIMER_EXPIRED, _on_skill_timer_expired)
	EventBus.unsubscribe(EventBus.BASIC_ATTACK_STARTED, _on_basic_attack_started)
	# disconnect signals
	if PlayerData.health_changed.is_connected(_on_player_health_changed):
		PlayerData.health_changed.disconnect(_on_player_health_changed)
	if PlayerData.player_died.is_connected(_on_player_died):
		PlayerData.player_died.disconnect(_on_player_died)
	if PlayerData.skill_added.is_connected(_on_skill_added):
		PlayerData.skill_added.disconnect(_on_skill_added)


## Called when the player's health changes.
func _on_player_health_changed(_old: float, _new: float, _max: float) -> void:
	_update_all_hearts()


## Called when the player dies.
func _on_player_died() -> void:
	pass


## Called when a new skill is added to the player's inventory.
func _on_skill_added(slot_index: int, skill: Resource) -> void:
	# Refresh all icons (simple approach)
	_refresh_all_skill_icons()


## Build or rebuild the skill icon UI elements.
func _refresh_all_skill_icons() -> void:
	# Clear existing icons
	for icon in _skill_icons.values():
		if is_instance_valid(icon):
			icon.queue_free()
	_skill_icons.clear()
	
	# Create icons for each skill slot
	var skills = PlayerData.current_skills
	for i in range(skills.size()):
		var skill_res = skills[i]
		if not skill_res:
			continue
		
		#var icon = SkillCircleIcon.new()
		#icon.skill = skill_res
		#icon.slot_index = i
		#skill_container.add_child(icon)
		#_skill_icons[i] = icon


## Called when a skill timer starts.
func _on_skill_timer_started(data: Dictionary) -> void:
	var slot = data.get("slot", -1)
	var total_ticks = data.get("total_ticks", 1)
	if _skill_icons.has(slot):
		_skill_icons[slot].start_timer(total_ticks)


## Called each tick of a skill timer.
func _on_skill_timer_tick(data: Dictionary) -> void:
	var slot = data.get("slot", -1)
	var remaining = data.get("remaining", 0)
	var total = data.get("total", 1)
	if _skill_icons.has(slot):
		_skill_icons[slot].on_tick_elapsed(remaining)


## Called when a skill timer expires.
func _on_skill_timer_expired(data: Dictionary) -> void:
	var slot = data.get("slot", -1)
	if _skill_icons.has(slot):
		_skill_icons[slot].stop_timer()


## Called when basic attack timer starts (no dedicated icon for now).
func _on_basic_attack_started(_data: Dictionary) -> void:
	# Could flash a basic attack indicator
	pass


## Update all heart icons based on current health.
func _update_all_hearts() -> void:
	for heart in _heart_nodes:
		if heart.has_method("health_changed"):
			heart.health_changed()

func _on_enemy_killed(data: Dictionary, loading := false):
	if(loading):
		enemies_left_label.text = str(get_tree().get_nodes_in_group("Enemy").size());
	else:
		enemies_left_label.text = str(get_tree().get_nodes_in_group("Enemy").size() - 1);
