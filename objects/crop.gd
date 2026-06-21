extends Node2D
class_name Crop

@onready var crop_farm : CropFarm = $".."

@onready var area_2d: Area2D = $Area2D
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	var overlaps = area_2d.get_overlapping_bodies()
	for body in overlaps:
		if body is MultiplayerController:
			var player = body as MultiplayerController
			if player.is_using:
				var amount = player.harvest_crop()
				_on_harvest(amount)
				queue_free()

func _on_harvest(amount: int, was_adj: bool = false) -> void:
	crop_farm.on_crop_harvested(position, amount, was_adj)
