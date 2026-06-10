extends Area2D

@export var door_name : String

@export var start_disabled : bool = false

@export var exits_main_area: bool = false
@export var enters_main_area: bool = false

@onready var teleport_location: Node2D = $TeleportLocation
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_reset()
	SignalBus.enable_door.connect(_on_door_enabled)
	SignalBus.reset_run.connect(_reset)

func _reset() -> void:
	if start_disabled:
		hide()
		collision.disabled = true
	else:
		show()
		collision.disabled = false

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	
	if body is MultiplayerController:
		body.global_position = teleport_location.global_position
		if exits_main_area:
			body.in_main_area = false
		elif enters_main_area:
			body.in_main_area = true

func _on_door_enabled(door: String) -> void:
	if door != door_name:
		return
	
	show()
	collision.disabled = false
