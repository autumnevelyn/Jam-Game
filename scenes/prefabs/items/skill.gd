class_name Skill
extends Resource

@export var texture: Texture2D;

@export var name: String = "";

@export var autoTrigger := false;
@export var cast_time := 1.0;
@export var cooldown_time := 1.0;

@export var damage := 1.0;
@export var hitbox_size: Shape2D;
@export var range := 1.0;
@export var homing := false;
