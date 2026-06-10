extends StaticBody2D

@export var wall_name : String

@onready var collision: CollisionShape2D = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.disable_wall.connect(_on_remove_wall)
	SignalBus.reset_run.connect(_reset_run)

func _on_remove_wall(_wall_name: String) -> void:
	if _wall_name == wall_name:
		hide()
		collision.disabled = true

func _reset_run() -> void:
	show()
	collision.disabled = false
