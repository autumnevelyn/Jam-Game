# health_icon.gd
# individual heart/life icon that updates based on PlayerData health.
extends Control

@onready var heart_texture: TextureRect = $heart_texture

var _id: int = -1


func _ready() -> void:
	# connect to health changes
	PlayerData.health_changed.connect(_on_health_changed)


func _exit_tree() -> void:
	if PlayerData.health_changed.is_connected(_on_health_changed):
		PlayerData.health_changed.disconnect(_on_health_changed)


func set_id(value: int) -> void:
	_id = value


## Called when PlayerData health changes.
func _on_health_changed(_old: float, _new: float, _max: float) -> void:
	health_changed()


## Update visibility based on current health threshold.
func health_changed() -> void:
	if _id < 0:
		return
	heart_texture.visible = PlayerData.health >= _id + 1
