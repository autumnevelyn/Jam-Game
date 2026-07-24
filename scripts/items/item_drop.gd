# skill.gd
# resource defining a skill/ability that can be equipped to a slot.
# tick-based timer system: each tick = 0.5s
class_name ItemDrop
extends Resource

@export var itemDropList = {
	"Common": [],
	"Uncommon": [],
	"Rare": [],
};

func getItem():
	var rarity = randf_range(0, 5);
	if(rarity < 2): # common
		var item = itemDropList["Common"][randi_range(0, itemDropList["Common"].size() - 1)];
		return item;
	elif(rarity < 4): # uncommon
		var item = itemDropList["Uncommon"][randi_range(0, itemDropList["Uncommon"].size() - 1)];
		return item;
	else: # rare
		var item = itemDropList["Rare"][randi_range(0, itemDropList["Rare"].size() - 1)];
		return item;
