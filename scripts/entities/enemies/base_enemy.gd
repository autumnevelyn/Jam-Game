# base_enemy.gd
# base class for all enemy types. Provides health, movement, and combat components.
extends CharacterBody2D

@onready var health_component: HealthComponent = $health_component
@onready var movement_component: MovementComponent = $movement_component

@export var speed: float = 50.0
@export var damage: float = 1.0

func _ready() -> void:
	if health_component:
		health_component.died.connect(_on_died)
	if movement_component:
		movement_component.speed = speed


func _exit_tree() -> void:
	if health_component and health_component.died.is_connected(_on_died):
		health_component.died.disconnect(_on_died)


func _on_died() -> void:
	EventBus.emit_event(EventBus.ENEMY_KILLED, {
		"enemy": self,
		"position": global_position,
	})
	queue_free()


## Apply damage to this enemy.
#func take_damage(amount: float, source: Node = null) -> float:
#	if health_component:
#		print(amount);
#		return health_component.take_damage(amount, source)
#	return 0.0
