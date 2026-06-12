extends CharacterBody2D
class_name MultiplayerController

@export var starting_speed = 75.0 
@export var SPEED = 75.0

const SPEED_MOD : float = 1.5

const REGEN_DELAY : float = -5.0
const REGEN_COOLDOWN : float = 0.5
var regen_timer : float = 0.0

const ATTACK_COOLDOWN : float = 0.75
var attack_timer : float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hud: Control = $"../../UI/HUD"
@onready var game: GameManager = $"../.."
@onready var crown: Sprite2D = $Sprite2D
@onready var cook: AudioStreamPlayer = $Cook
@onready var crop_break: AudioStreamPlayer = $CropBreak
@onready var sell: AudioStreamPlayer = $Sell
@onready var slice: AudioStreamPlayer = $Slice
@onready var hurt: AudioStreamPlayer = $Hurt
@onready var attack: AudioStreamPlayer = $Attack

var direction_hor : float = 0
var direction_vert : float = 0

@export var attack_use : float = 0

var is_using : bool :
	get():
		return attack_use > 0

var in_main_area : bool = true

var is_king : bool = false:
	set(val):
		is_king = val
		if val:
			crown.show()
		else:
			crown.hide()

var _is_local_player : bool = false:
	get():
		if multiplayer != null:
			return multiplayer.get_unique_id() == player_id
		return false

@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

@export var player_name : String = "Player":
	set(value):
		player_name = value
		$NameTag/Name.text = value
		if _is_local_player:
			GameState.player_name = value

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

const MAX_HEALTH : int = 20

@export var current_health : int = 20:
	set(count):
		current_health = count
		
		if _is_local_player and hud != null:
			hud.current_health = count

var drop_count_min : int:
	get():
		return GameState.drop_count_min
var drop_count_max : int:
	get():
		return GameState.drop_count_max

func _ready() -> void:
	SignalBus.reset_run.connect(_reset)
	SignalBus.mult_player_speed.connect(_mult_speed)
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false

func _reset() -> void:
	if multiplayer.is_server() and not in_main_area and not is_king:
		position = Vector2(0, 0)
	
	SPEED = starting_speed

func _mult_speed(speed: float) -> void:
	SPEED *= speed

func _apply_animations(_delta: float):
	if direction_hor == 0 and direction_vert == 0:
		return
	
	var vector = Vector2(-direction_vert, direction_hor)
	
	var rot = int(vector.angle() / TAU * 8) / 8.0 * TAU
	set_rotation(rot)
	$NameTag.set_rotation(-rot)
	
	if attack_use > 0:
		sprite.play("use")
	elif attack_use < 0:
		sprite.play("attack")
	else:
		sprite.play("idle")

func _apply_movement_from_input(_delta: float):
	attack_use = %InputSynchronizer.input_attack_use
	
	var sneak_sprint = %InputSynchronizer.input_sneak_sprint
	
	var speed = SPEED
	if sneak_sprint < 0:
		speed /= SPEED_MOD
	elif sneak_sprint > 0:
		speed *= SPEED_MOD
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction_hor = %InputSynchronizer.input_direction_hor
	if direction_hor:
		velocity.x = direction_hor * speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	direction_vert = %InputSynchronizer.input_direction_vert
	if direction_vert:
		velocity.y = direction_vert * speed
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	move_and_slide()

func _physics_process(delta: float) -> void:
	if (not multiplayer.is_server()) or MultiplayerManager.is_host:
		_apply_animations(delta)
	if multiplayer.is_server():
		_apply_movement_from_input(delta)

func _process(delta: float) -> void:
	if not multiplayer.is_server(): return
	
	regen_timer += delta
	attack_timer += delta
	
	if regen_timer >= REGEN_COOLDOWN and current_health < MAX_HEALTH:
		current_health += 1
		regen_timer = 0
	
	if attack_use < 0 and attack_timer >= ATTACK_COOLDOWN:
		attack_timer = 0
		var bodies = $AttackHitbox.get_overlapping_bodies()
		for body in bodies:
			if body is MultiplayerController and body != self:
				var player = body as MultiplayerController
				_deal_damage(player)

func _deal_damage(target: MultiplayerController) -> void:
	target.take_damage(1)
	_client_play_sound("attack")

func take_damage(amount: int) -> void:
	current_health -= amount
	regen_timer = REGEN_DELAY
	
	_client_play_sound("hurt")
	
	if current_health <= 0:
		_die()

func _die() -> void:
	crop_count = 0
	sliced_count = 0
	cooked_count = 0
	gold_count = 0
	current_health = 20
	position.x = 0; position.y = 0
	
	if is_king:
		SignalBus.reset_run.emit()

func harvest_crop() -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var amount = rng.randi_range(drop_count_min, drop_count_max)
	_client_play_sound("cropbreak")
	
	return amount

func collect_crop() -> void:
	crop_count += 1

func slice_crop() -> void:
	if crop_count >= 4:
		crop_count -= 4
		sliced_count += 1
		_client_play_sound("slice")

func cook_crop() -> void:
	if sliced_count >= 4:
		sliced_count -= 4
		cooked_count += 1
		_client_play_sound("cook")

func sell_crop() -> void:
	if cooked_count >= 1:
		cooked_count -= 1
		var amount = game.on_crop_sell()
		gold_count += amount
		_client_play_sound("sell")

func spend_gold(amount: int) -> bool:
	if gold_count >= amount:
		gold_count -= amount
		return true
	return false

func _client_play_sound(sound: String) -> void:
	_rpc_play_sound.rpc_id(player_id, sound)

@rpc()
func _rpc_play_sound(sound: String) -> void:
	match sound:
		"cook":
			cook.play()
		"cropbreak":
			crop_break.play()
		"sell":
			sell.play()
		"slice":
			slice.play()
		"hurt":
			hurt.play()
		"attack":
			attack.play()
