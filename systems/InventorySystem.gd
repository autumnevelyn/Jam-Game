# inventorySystem.gd
# manages item pickup, equipment, and relic interactions.
extends Node

func _ready() -> void:
	EventBus.subscribe(EventBus.ITEM_PICKED_UP, _on_item_picked_up)


func _on_item_picked_up(data: Dictionary) -> void:
	var item = data.get("item")
	var slot = data.get("slot", -1)

	if not item:
		return

	GameData.items_collected += 1

	# handle different item types
	if item is Skill:
		PlayerData.add_skill(item)
	elif item.name.begins_with("relic"):
		PlayerData.add_relic(item)
	else:
		PlayerData.add_equipment(item)
