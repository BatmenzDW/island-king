extends Node

signal money_changed(value: float)

var is_ap : bool = false

var _kingdom_money : float
var kingdom_money : float = 0:
	set(value):
		set_kingdom_money(value)
	get():
		return _kingdom_money

func set_kingdom_money(value: float, ringlink: bool = false) -> void:
	if not ringlink:
		ringlink_accumulation += value - _kingdom_money
	
	_kingdom_money = snappedf(value, 0.1)
	money_changed.emit(kingdom_money)

var ringlink_accumulation : float = 0
var time_since_money_changed : float = 0.0
const RINGLINK_ACCUM_TIME : float = 10.0

var current_sell_value : float = 0.25
var money_gen_delay : float = 10.0
var gold_return_rate : float = 0.5

var drop_count_min : int
var drop_count_max : int

var better_farmers : bool = false

var farms : Dictionary[String, CropFarm] = {}
var upgrades : Dictionary[String, Upgrade] = {}

var player_name : String

func mult_farms_speed(mult: float, _farms: Array[String] = []) -> void:
	if len(_farms) == 0:
		_farms = ["main"]
	
	for farm in _farms:
		if farm not in farms:
			return
		
		farms[farm]._on_mult_spawn_rate(mult)

var chat_open : bool = false

var is_server : bool = false
var ap: bool = false
var web: bool = false

func _ready() -> void:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""
	
	if OS.has_feature("web") or "web" in arguments:
		web = true
		return
	
	if OS.has_feature("server") or "server" in arguments:
		is_server = true
		MultiplayerManager.become_host()
	if OS.has_feature("ap") or "ap" in arguments:
		ap = true

func _process(delta: float) -> void:
	time_since_money_changed += delta
	
	if time_since_money_changed >= RINGLINK_ACCUM_TIME:
		time_since_money_changed = 0
		ApManager.send_ringlink(ringlink_accumulation)
		ringlink_accumulation = 0
