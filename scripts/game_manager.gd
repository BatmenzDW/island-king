extends Node
class_name GameManager

@onready var hud: Control = $UI/HUD
@onready var players: Node2D = $Players
@onready var king_spawn: Node2D = $KingSpawn

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

@export var init_gen_amount : float = 0.5
var money_gen_amount : float = 0.5

@export var init_gold_return_rate : float = 0.5
var gold_return_rate : float = 0.5:
	set(value):
		GameState.gold_return_rate = value
	get():
		return GameState.gold_return_rate

@export var init_drop_count_min : int = 2
@export var init_drop_count_max : int = 5

var drop_count_min : int:
	set(value):
		GameState.drop_count_min = value
	get():
		return GameState.drop_count_min
var drop_count_max : int:
	set(value):
		GameState.drop_count_max = value
	get():
		return GameState.drop_count_max


var time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset()
	SignalBus.reset_run.connect(_reset_run)

func _filler_recieved(filler: String) -> void:
	if filler not in filler_items:
		return
	
	filler_items[filler].call()

func _reset_run() -> void:
	reset()
	var plyrs = players.get_children()
	if len(plyrs) == 1:
		plyrs[0].global_position = king_spawn.global_position
	else:
		plyrs.pick_random()

func reset() -> void:
	kingdom_money = init_money
	current_sell_value = init_sell_value
	money_gen_delay = init_gen_delay
	money_gen_amount = init_gen_amount
	gold_return_rate = init_gold_return_rate
	drop_count_max = init_drop_count_max
	drop_count_min = init_drop_count_min
	GameState.better_farmers = false

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
	if gold_return_rate - int(gold_return_rate) == 0:
		return gold_return_rate as int
	
	var rtrn = int(gold_return_rate)
	var bonus = gold_return_rate - int(gold_return_rate)
	if randf_range(0, 1) <= bonus:
		rtrn += 1
	
	return rtrn


var filler_items : Dictionary[String, Callable] = {
	
}
