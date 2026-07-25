# skill_pickup.gd
# pickup area for skill items. When the player enters, the skill is added.
extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

## The skill resource this pickup grants.
@export var skill: Skill = null;

var all_skills = [
	preload("res://scenes/prefabs/items/dash.tres"), 
	preload("res://scenes/prefabs/items/fire_punch.tres"), 
	preload("res://scenes/prefabs/items/freeze breeze.tres"), 
];
var playerOn := false;

func _ready() -> void:
	if skill == null:
		skill = all_skills.pick_random();
	
	update();
	
func _process(delta: float) -> void:
	if(playerOn):
		if(Input.is_action_just_pressed("skill 1")):
			skill = PlayerData.swap_skill(skill, 0);
			update();
		if(Input.is_action_just_pressed("skill 2")):
			skill = PlayerData.swap_skill(skill, 1);
			update();
		
func update():
	if skill and sprite_2d:
		sprite_2d.texture = skill.texture


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "player":
		if(PlayerData.current_skills.size() < 2):
			EventBus.emit_event(EventBus.ITEM_PICKED_UP, {
				"item": skill
			})
			queue_free()
		else:
			playerOn = true;
			body.onSkill = true;
			


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "player":
		if(PlayerData.current_skills.size() >= 2):
			playerOn = false;
			body.onSkill = false;
