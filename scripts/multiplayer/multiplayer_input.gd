extends MultiplayerSynchronizer

@onready var player = $".."

var input_direction_hor : float
var input_direction_vert : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	input_direction_hor = Input.get_axis("ui_left", "ui_right")
	input_direction_vert = Input.get_axis("ui_down", "ui_up")

func _physics_process(_delta: float) -> void:
	input_direction_hor = Input.get_axis("ui_left", "ui_right")
	input_direction_vert = Input.get_axis("ui_up", "ui_down")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Attack"):
		attack.rpc()
	
	if Input.is_action_just_pressed("Use"):
		start_use.rpc()
	elif Input.is_action_just_released("Use"):
		stop_use.rpc()

@rpc("call_local")
func attack():
	if multiplayer.is_server():
		player.do_attack = true

@rpc("call_local")
func start_use():
	if multiplayer.is_server():
		player.is_using = true

@rpc("call_local")
func stop_use():
	if multiplayer.is_server():
		player.is_using = false
