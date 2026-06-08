extends Area2D


@onready var teleport_location: Node2D = $TeleportLocation

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	
	if body is MultiplayerController:
		body.global_position = teleport_location.global_position
