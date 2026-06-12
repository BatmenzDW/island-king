extends MultiplayerSynchronizer

@onready var player = $".."

var input_direction_hor : float
var input_direction_vert : float
var input_attack_use : float
var input_sneak_sprint : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	input_direction_hor = Input.get_axis("ui_left", "ui_right")
	input_direction_vert = Input.get_axis("ui_down", "ui_up")
	input_attack_use = Input.get_axis("Attack", "Use")
	input_sneak_sprint = Input.get_axis("Sprint", "Sneak")

func _physics_process(_delta: float) -> void:
	if GameState.chat_open:
		input_direction_hor = 0
		input_direction_vert = 0
		input_attack_use = 0
		input_sneak_sprint = 0
		return
	
	input_direction_hor = Input.get_axis("ui_left", "ui_right")
	input_direction_vert = Input.get_axis("ui_up", "ui_down")
	input_attack_use = Input.get_axis("Attack", "Use")
	input_sneak_sprint = Input.get_axis("Sprint", "Sneak")
