extends Node2D
class_name CropFarm

@onready var crop_farm: CropFarm = %CropFarm

@export var farm_name : String


@export var spawn_area : Rect2
@export var grid_size : float = 2.0

@export var init_spawn_count : int = 2
var spawn_count : int = 2

var current_crop_pos : Dictionary[Vector2, Crop]

var crop_scene = preload("res://objects/crop.tscn")
var harvested_scene = preload("res://objects/harvested_crop.tscn")

@export var init_spawn_delay : float = 2.5
var spawn_delay : float = 2.5
var time_passed : float = 0.0

func _ready() -> void:
	if farm_name not in GameState.farms:
		GameState.farms[farm_name] = self
	reset()
	SignalBus.reset_run.connect(reset)

func reset():
	spawn_delay = init_spawn_delay
	spawn_count = init_spawn_count
	time_passed = 0
	for pos in current_crop_pos:
		var crop = current_crop_pos[pos]
		current_crop_pos.erase(pos)
		if is_instance_valid(crop):
			crop.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not multiplayer.is_server() or not MultiplayerManager.is_game_connected:
		return
	time_passed += delta
	if time_passed >= spawn_delay:
		spawn_crops()
		time_passed = 0

func _on_mult_spawn_rate(mult: float) -> void:
	spawn_delay /= mult

func spawn_crops():
	for i in range(spawn_count):
		var spawn_pos = _get_random_grid_point_in_shape(spawn_area)
		if spawn_pos in current_crop_pos:
			continue
		var crop = crop_scene.instantiate()
		crop.visible = false
		
		crop_farm.add_child(crop, true)
		crop.position = spawn_pos
		crop.visible = true
		
		current_crop_pos[spawn_pos] = crop

func _get_random_grid_point_in_shape(rect: Rect2) -> Vector2:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var max_attempts = 100
	for i in range(max_attempts):
		# 1. Generate a random point inside the bounding box
		var random_point = Vector2(
			rng.randf_range(rect.position.x, rect.position.x + rect.size.x),
			rng.randf_range(rect.position.y, rect.position.y + rect.size.y)
		)
		
		# 2. Snap the point to the grid using snapped()
		random_point = random_point.snapped(Vector2(grid_size, grid_size))
		
		# 3. Verify the snapped point falls inside the Shape2D
		if rect.has_point(random_point) and not current_crop_pos.has(random_point):
			return random_point
			
	return Vector2.ZERO # Fallback if no point is found

func on_crop_harvested(pos: Vector2, amount: int, was_adj: bool = false) -> void:
	if pos in current_crop_pos:
		current_crop_pos.erase(pos)
		
		for i in range(amount):
			var spawn_pos = pos + Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
			var harvested = harvested_scene.instantiate()
			harvested.position = spawn_pos
			harvested.start_pos = spawn_pos
			
			add_child(harvested, true)
	
	if not was_adj and GameState.better_farmers:
		for x in [-grid_size, 0, grid_size]:
			for y in [-grid_size, 0, grid_size]:
				var target = Vector2(pos.x + x, pos.y + y)
				if target in current_crop_pos:
					current_crop_pos[target]._on_harvest(amount, true)
