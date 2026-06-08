extends Node

signal money_changed(value: float)

var kingdom_money : float = 0:
	set(value):
		kingdom_money = value
		money_changed.emit(value)

var current_sell_value : float = 0.25
var money_gen_delay : float = 10.0

var farms : Dictionary[String, CropFarm] = {}
var upgrades : Dictionary[String, Upgrade] = {}


func mult_main_farm_speed(mult: float) -> void:
	if "main" not in farms:
		return
	
	farms["main"]._on_mult_spawn_rate(mult)
