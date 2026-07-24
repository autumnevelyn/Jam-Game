extends Control

func _on_button_pressed() -> void:
	GameManager.start_run();
	visible = false;


func _on_button_3_pressed() -> void:
	get_tree().quit();
