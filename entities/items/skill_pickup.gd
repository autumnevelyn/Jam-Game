# skill_pickup.gd
# pickup area for skill items. When the player enters, the skill is added.
extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

## The skill resource this pickup grants.
@export var skill: Skill


func _ready() -> void:
	if skill and sprite_2d:
		sprite_2d.texture = skill.texture


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "player":
		var slot = PlayerData.add_skill(skill)
		if slot >= 0:
			EventBus.emit_event(EventBus.ITEM_PICKED_UP, {
				"item": skill,
				"slot": slot,
			})
			queue_free()
