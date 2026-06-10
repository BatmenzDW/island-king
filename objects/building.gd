extends Sprite2D

@export var building_name : String

@export var start_hidden : bool = false

@onready var collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var door: Area2D = $Door

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	door.start_disabled = start_hidden
	door.door_name = building_name
	_reset()
	SignalBus.reset_run.connect(_reset)
	SignalBus.build_building.connect(_build)

func _reset() -> void:
	if start_hidden:
		hide()
		collision.disabled = true

func _build(building: String) -> void:
	if building != building_name:
		return
	
	if start_hidden:
		show()
		collision.disabled = false
		
		door._on_door_enabled(door.door_name)
