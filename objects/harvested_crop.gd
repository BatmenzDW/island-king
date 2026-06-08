extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_pos = position

const MAX_OFFSET = 1

@export var bounce_speed = 0.1
@export var pickup_delay = 0.1

var start_pos : Vector2

var direction : int = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	position.y += direction * bounce_speed * delta
	
	if abs(start_pos.y - position.y) > MAX_OFFSET:
		direction *= -1
	
	if pickup_delay > 0:
		pickup_delay -= delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	
	if pickup_delay > 0:
		return
	
	if body is MultiplayerController:
		var player = body as MultiplayerController
		player.collect_crop()
		queue_free()
