extends Node

signal money_changed(value: float)

var is_ap : bool = false

var kingdom_money : float = 0:
	set(value):
		kingdom_money = snappedf(value, 0.1)
		money_changed.emit(kingdom_money)

var current_sell_value : float = 0.25
var money_gen_delay : float = 10.0
var gold_return_rate : float = 0.5

var drop_count_min : int
var drop_count_max : int

var better_farmers : bool = false

var farms : Dictionary[String, CropFarm] = {}
var upgrades : Dictionary[String, Upgrade] = {}


func mult_farms_speed(mult: float, _farms: Array[String] = []) -> void:
	if len(_farms) == 0:
		_farms = ["main"]
	
	for farm in _farms:
		if farm not in farms:
			return
		
		farms[farm]._on_mult_spawn_rate(mult)
