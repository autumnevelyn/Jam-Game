# cuttable_object.gd
# destructible object that can be destroyed by the player's attack hitbox.
extends StaticBody2D

@onready var health_component: HealthComponent = $health_component


func _ready() -> void:
	if health_component:
		health_component.died.connect(_on_destroyed)


func _exit_tree() -> void:
	if health_component and health_component.died.is_connected(_on_destroyed):
		health_component.died.disconnect(_on_destroyed)


func _on_destroyed() -> void:
	queue_free()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	# handled by attack_hitbox -> EventBus -> CombatSystem
	pass
