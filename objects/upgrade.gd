extends Node2D
class_name Upgrade

@export var upgrade_name : String = "PLACEHOLDER"
var upgrade_cost : float = 0.0
var upgrade_cost_type : CostType = CostType.Coins
var upgrade_description : String = "PLACEHOLDER Description"

var purchase_lambda : Callable

@export var init_locked : bool = false
var locked : bool

var upgrade_cost_description : String = "":
	get():
		return "%s %s" % [upgrade_cost, CostType.find_key(upgrade_cost_type)]

var purchased : bool = false

const SIGN_AVALIBLE = preload("uid://dmqanl8gk20gw")
const SIGN_INFO = preload("uid://b7e1g0eah1fup")
const SIGN_LOCKED = preload("uid://52k5t5517wt7")

enum CostType
{
	Coins,
	Gold,
	KingdomGold
}

@onready var area_2d: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

const COOLDOWN : float = 0.1

var time : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset()
	if upgrade_name not in upgrades:
		push_warning("Upgrade %s is missing from data")
	else:
		var upgrade = upgrades[upgrade_name]
		upgrade_cost = upgrade.cost
		upgrade_cost_type = upgrade.cost_type
		upgrade_description = upgrade.description
		purchase_lambda = upgrade.lamda
		
		if upgrade_name not in GameState.upgrades:
			GameState.upgrades[upgrade_name] = self

func reset() -> void:
	purchased = false
	locked = init_locked
	
	if locked:
		sprite.texture = SIGN_LOCKED
	else:
		sprite.texture = SIGN_AVALIBLE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not multiplayer.is_server() or purchased:
		return
	
	time += delta
	
	if time < COOLDOWN:
		return
	
	time = 0
	
	var overlaps = area_2d.get_overlapping_bodies()
	for body in overlaps:
		if body is MultiplayerController:
			var player = body as MultiplayerController
			if not player.is_using:
				continue
			
			if upgrade_cost_type == CostType.Coins and player.is_king:
				if GameState.kingdom_money >= upgrade_cost:
					print("%s purchased" % upgrade_name)
					GameState.kingdom_money -= upgrade_cost
					on_upgrade_purchased()
		
			elif upgrade_cost_type == CostType.Gold and player.spend_gold(upgrade_cost as int):
				on_upgrade_purchased()
			
			break

func on_upgrade_purchased() -> void:
	sprite.texture = SIGN_INFO
	purchase_lambda.call()
	purchased = true

func on_hover_upgrade() -> void:
	var name_text = upgrade_name
	var desc_text = upgrade_description
	
	if locked:
		name_text = "[color=red]Locked: %s[/color]" % upgrade_name
		desc_text = "[color=red]%s[/color]" % upgrade_description
	elif purchased:
		name_text = "[color=green]Purchased: %s[/color]" % upgrade_name
		desc_text = "[color=green]%s[/color]" % upgrade_description
	
	SignalBus.show_upgrade_text.emit(name_text, desc_text, upgrade_cost_description)

func on_unhover_upgrade() -> void:
	SignalBus.hide_upgrade_text.emit()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is MultiplayerController and body._is_local_player:
		on_hover_upgrade()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is MultiplayerController and body._is_local_player:
		on_unhover_upgrade()


var upgrades : Dictionary[String, UpgradeData] = {
	"Faster Crop Spawn Rate": UpgradeData.create(25.0, CostType.Coins, "Increases crop spawn rate 50%", func(): GameState.mult_main_farm_speed(1.5)),
	"Economics Room": UpgradeData.create(10.0, CostType.Coins, "Unlocks three other upgrades in the castle.", func(): SignalBus.disable_wall.emit("Economics Room")),
	"Faster Money Generation": UpgradeData.create(5.0, CostType.Coins, "Decreases the time it takes to automatically generate money by 67%.", func(): GameState.money_gen_delay *= (1.0/3.0)),
	"Better Sell Deals": UpgradeData.create(10.0, CostType.Coins, "Increases the crop sell price by 0.15.", func(): GameState.current_sell_value += 0.15),
}

class UpgradeData:
	var cost : float
	var cost_type : CostType
	var description : String
	var lamda : Callable
	
	static func create(_cost: float, _cost_type: CostType, _desc: String, _lambda: Callable) -> UpgradeData:
		var data = UpgradeData.new()
		data.cost = _cost
		data.cost_type = _cost_type
		data.description = _desc
		data.lamda = _lambda
		return data
