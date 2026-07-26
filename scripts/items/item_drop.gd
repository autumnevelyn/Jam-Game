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

var all_skills = [
	preload("res://scenes/prefabs/items/fire_punch.tres"),
	preload("res://scenes/prefabs/items/freeze breeze.tres"),
	preload("res://scenes/prefabs/items/burn up.tres"),
	preload("res://scenes/prefabs/items/dash.tres"),
]

func getItem():
	if(itemDropList["Common"].size() == 0 and itemDropList["Uncommon"].size() == 0 and itemDropList["Rare"].size() == 0):
		#var rarity = randf_range(0, 5);
		return all_skills.pick_random();
		
	else:
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
