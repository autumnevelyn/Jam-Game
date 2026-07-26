extends Control

@onready var start_button = $BoxContainer/Button


func _ready() -> void:
	visibility_changed.connect(_on_visible_changed)


func _on_visible_changed() -> void:
	if not visible:
		return
	
	# switch button text based on whether a run is in progress
	if GameManager.current_run_state == GameManager.RunState.PLAYING or GameManager.current_run_state == GameManager.RunState.PAUSED:
		start_button.text = "Resume"
	else:
		start_button.text = "Start"


func _on_button_pressed() -> void:
	if start_button.text == "Start":
		GameManager.start_run()
	else:
		GameManager.toggle_pause()
	visible = false


func _on_button_3_pressed() -> void:
	get_tree().quit()
