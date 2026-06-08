extends Node
class_name GameManager

@onready var hud: Control = $UI/HUD

@export var init_money : float = 25.0
var kingdom_money : float = 0:
	set(value):
		GameState.kingdom_money = value
	get():
		return GameState.kingdom_money

@export var init_sell_value : float = 0.25
var current_sell_value : float = 0.25:
	set(value):
		GameState.current_sell_value = value
	get():
		return GameState.current_sell_value

@export var init_gen_delay : float = 10
var money_gen_delay : float = 10:
	set(value):
		GameState.money_gen_delay = value
	get():
		return GameState.money_gen_delay

@export var money_gen_amount : float = 0.5

var time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset()
	pass # Replace with function body.

func reset() -> void:
	kingdom_money = init_money
	current_sell_value = init_sell_value
	money_gen_delay = init_gen_delay

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	time += _delta
	if time >= money_gen_delay:
		time = 0
		kingdom_money += money_gen_amount

func become_host():
	print("Become host pressed")
	%MultiplayerHUD.hide()
	MultiplayerManager.become_host()

func join_lobby():
	print("Join pressed")
	%MultiplayerHUD.hide()
	MultiplayerManager.join_lobby()


func on_crop_sell() -> int:
	kingdom_money += current_sell_value
	return _calculate_gold_return()

func _calculate_gold_return() -> int:
	return 1
