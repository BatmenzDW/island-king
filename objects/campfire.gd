extends Node2D

@onready var area_2d: Area2D = $Area2D

@export var init_cooldown : float = 0.1
var COOLDOWN : float = 0.1

var time : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.reset_run.connect(_reset)
	SignalBus.mult_processing_speed.connect(_mult_speed)

func _reset() -> void:
	COOLDOWN = init_cooldown

func _mult_speed(speed: float) -> void:
	COOLDOWN /= speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	time += delta
	
	if time < COOLDOWN:
		return
	
	time = 0
	
	var overlaps = area_2d.get_overlapping_bodies()
	for body in overlaps:
		if body is MultiplayerController:
			var player = body as MultiplayerController
			if player.is_using:
				player.cook_crop()
