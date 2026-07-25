# inventorySystem.gd
# manages item pickup, equipment, and relic interactions.
extends Node

func _ready() -> void:
	EventBus.subscribe(EventBus.ITEM_PICKED_UP, _on_item_picked_up)


func _on_item_picked_up(data: Dictionary) -> void:
	var item = data.get("item")

	if not item: return

	GameData.items_collected += 1
	var slot = -1;
	# handle different item types
	if item is Skill:
		slot = PlayerData.add_skill(item)
	elif item.name.begins_with("relic"):
		slot = PlayerData.add_relic(item)
	else:
		slot = PlayerData.add_equipment(item)
		
	if (slot >= 0):
		print_rich(item)
	elif slot == -1:
		print_rich("inventory full")
	else:
		print_rich("cannot be picked up")
