# cuttable_object.gd
# destructible object that can be destroyed by the player's attack hitbox.
extends StaticBody2D

@onready var health_component: HealthComponent = $health_component
const HEART = preload("res://scenes/prefabs/heart.tscn")
const MONEY_PILE = preload("res://scenes/prefabs/money_pile.tscn")

@export var heartDrop := true;

func _ready() -> void:
	if health_component:
		health_component.died.connect(_on_destroyed)


func _exit_tree() -> void:
	if health_component and health_component.died.is_connected(_on_destroyed):
		health_component.died.disconnect(_on_destroyed)


func _on_destroyed() -> void:
	
	if(heartDrop):
		var heart = HEART.instantiate();
		add_sibling(heart);
		heart.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10));
		if(randf() < 0.5):
			heart = HEART.instantiate();
			add_sibling(heart);
			heart.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10));
	else:
		var random = randf();
		if(random < 0.33):
			var heart = HEART.instantiate();
			add_sibling(heart);
			heart.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10));
		elif(random < 0.67):
			var money = MONEY_PILE.instantiate();
			add_sibling(money);
			money.position = position + Vector2(randf_range(-10, 10), randf_range(-10, 10));
	
	queue_free()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	# handled by attack_hitbox -> EventBus -> CombatSystem
	pass
