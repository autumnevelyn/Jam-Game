extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var skill: Skill;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite_2d.texture = skill.texture;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		PlayerData.currentSkills.append(skill);
		queue_free();
