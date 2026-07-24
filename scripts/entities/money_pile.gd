extends Area2D

@export var money := 10;


func _on_body_entered(body: Node2D) -> void:
	PlayerData.gain_gold(money);
	get_tree().root.get_node("GameMain/CanvasLayer/ui").money_label.text = "Money: " + str(int(PlayerData.money));
	queue_free();
