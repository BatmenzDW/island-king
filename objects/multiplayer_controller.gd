extends CharacterBody2D
class_name MultiplayerController

const SPEED = 75.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hud: Control = $"../../UI/HUD"
@onready var game: GameManager = $"../.."

var direction_hor : float = 0
var direction_vert : float = 0

var do_attack : bool = false
var anim_attack: bool = false

var is_using : bool = false:
	set(val):
		is_using = val

var is_king : bool = false

var _is_local_player : bool = false:
	get():
		if multiplayer != null:
			return multiplayer.get_unique_id() == player_id
		return false

@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

@export var crop_count : int = 0:
	set(count):
		crop_count = count
		
		if _is_local_player and hud != null:
			hud.crop_count = count

@export var sliced_count : int = 0:
	set(count):
		sliced_count = count
		
		if _is_local_player  and hud != null:
			hud.sliced_count = count

@export var cooked_count : int = 0:
	set(count):
		cooked_count = count
		
		if _is_local_player and hud != null:
			hud.cooked_count = count

@export var gold_count : int = 0:
	set(count):
		gold_count = count
		
		if _is_local_player and hud != null:
			hud.gold_count = count

@export var drop_count_min : int = 1
@export var drop_count_max : int = 1

func _ready() -> void:
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false

func _apply_animations(_delta: float):
	if direction_hor == 0 and direction_vert == 0:
		return
	
	var vector = Vector2(-direction_vert, direction_hor)
	
	set_rotation(int(vector.angle() / TAU * 8) / 8.0 * TAU)
	
	if is_using:
		sprite.play("use")
	elif anim_attack:
		sprite.play("attack")
		anim_attack = true
	else:
		sprite.play("idle")

func _apply_movement_from_input(_delta: float):
	if do_attack:
		do_attack = false
		anim_attack = true
		pass
		# TODO
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction_hor = %InputSynchronizer.input_direction_hor
	if direction_hor:
		velocity.x = direction_hor * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	direction_vert = %InputSynchronizer.input_direction_vert
	if direction_vert:
		velocity.y = direction_vert * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	move_and_slide()

func _physics_process(delta: float) -> void:
	if (not multiplayer.is_server()) or MultiplayerManager.is_host:
		_apply_animations(delta)
	if multiplayer.is_server():
		_apply_movement_from_input(delta)

func harvest_crop() -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var amount = rng.randi_range(drop_count_min, drop_count_max)
	
	return amount

func collect_crop() -> void:
	crop_count += 1

func slice_crop() -> void:
	if crop_count >= 4:
		crop_count -= 4
		sliced_count += 1

func cook_crop() -> void:
	if sliced_count >= 4:
		sliced_count -= 4
		cooked_count += 1

func sell_crop() -> void:
	if cooked_count >= 1:
		cooked_count -= 1
		var amount = game.on_crop_sell()
		gold_count += amount

func spend_gold(amount: int) -> bool:
	if gold_count >= amount:
		gold_count -= amount
		return true
	return false
