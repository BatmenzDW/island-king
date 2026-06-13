extends Node2D
class_name Upgrade

@export var upgrade_name : String = "PLACEHOLDER"
var upgrade_cost : float = 0.0
var upgrade_cost_type : CostType = CostType.Coins
var upgrade_description : String = "PLACEHOLDER Description"

var purchase_lambda : Callable

@export var start_hidden : bool = false
@export var init_locked : bool = false
@export var locked : bool = false:
	set(val):
		locked = val
		if not val and not purchased and sprite != null:
			if ap_locked:
				sprite.play("locked")
			else:
				sprite.play("avalible")
		elif val and sprite != null:
			sprite.play("locked")

@export var prereq : String = ""

@export var ap_start_locked : bool = false
@export var ap_locked : bool = false

var upgrade_cost_description : String = "":
	get():
		return "%s %s" % [upgrade_cost, _get_cost_type_name(upgrade_cost_type)]

@export var is_funding : bool = false
@export var is_infinitly_fundable : bool = false
@export var funding_total : float = 0.0

var funding_rate : int = 1

@export var purchased : bool = false:
	set(val):
		purchased = val
		if val:
			sprite.play("info")

const SIGN_AVALIBLE = preload("uid://dmqanl8gk20gw")
const SIGN_INFO = preload("uid://b7e1g0eah1fup")
const SIGN_LOCKED = preload("uid://52k5t5517wt7")

enum CostType
{
	Coins,
	Gold,
	KingdomGold
}

func _get_cost_type_name(type: CostType) -> String:
	match type:
		CostType.Coins:
			return "Coins"
		CostType.Gold:
			return "Gold"
		CostType.KingdomGold:
			return "Town Gold"
		_:
			return "NULL"

@onready var area_2d: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D

const COOLDOWN : float = 0.1

var time : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset()
	SignalBus.reset_run.connect(reset)
	SignalBus.ap_reset.connect(ap_reset)
	SignalBus.upgrade_unlocked.connect(_on_upgrade_unlocked)
	SignalBus.disable_wall.connect(_remove_wall)
	SignalBus.reveal_upgrade.connect(_reveal_upgrade)
	SignalBus.sync_ap_items.connect(_sync_ap_items)
	if upgrade_name not in upgrades:
		push_warning("Upgrade %s is missing from data" % upgrade_name)
	else:
		var upgrade = upgrades[upgrade_name]
		upgrade_cost = upgrade.cost
		upgrade_cost_type = upgrade.cost_type
		upgrade_description = upgrade.description
		purchase_lambda = upgrade.lamda
		
		if upgrade_name not in GameState.upgrades:
			GameState.upgrades[upgrade_name] = self

func _sync_ap_items(items: Array[String]) -> void:
	if not ap_start_locked: return
	
	if upgrade_name in items:
		ap_locked = false
	else:
		ap_locked = true

func _remove_wall(wall_name: String) -> void:
	if wall_name == upgrade_name and wall_name not in ["The Button"]:
		hide()
		collision.disabled = true

func _reveal_upgrade(upgrade: String) -> void:
	if prereq != "" and upgrade != prereq:
		return
	
	if start_hidden:
		show()
		collision.disabled = false

func _on_upgrade_unlocked(upgrade: String) -> void:
	if upgrade != upgrade_name:
		return
	
	ap_locked = not _is_ap_unlocked()
	
	if ap_locked:
		sprite.play("locked")
		return
	
	if not locked and not purchased:
		sprite.play("avalible")

func reset() -> void:
	purchased = false
	locked = init_locked
	
	if locked or not _is_ap_unlocked():
		sprite.play("locked")
	else:
		sprite.play("avalible")
	
	if not start_hidden:
		show()
		collision.disabled = false
	else:
		hide()
		collision.disabled = true

func unlock() -> void:
	locked = false
	
	if _is_ap_unlocked() and not purchased:
		sprite.play("avalible")

func ap_reset() -> void:
	ap_locked = ap_start_locked

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not multiplayer.is_server() or purchased or locked:
		return
	
	if ap_locked:
		locked = true
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
		
			elif upgrade_cost_type == CostType.Gold:
				if not is_funding and player.spend_gold(upgrade_cost as int):
					on_upgrade_purchased()
				elif is_funding and player.spend_gold(funding_rate):
					funding_total += funding_rate
					if not is_infinitly_fundable and funding_total >= upgrade_cost:
						var refund = funding_total - upgrade_cost
						player.gold_count += refund
						on_upgrade_purchased()
					elif is_infinitly_fundable:
						purchase_lambda.call(funding_rate)
					
			on_hover_upgrade() # update upgrade display
			
			break

func on_upgrade_purchased() -> void:
	if not multiplayer.is_server():
		return
	#sprite.texture = SIGN_INFO
	purchase_lambda.call()
	purchased = true
	SignalBus.upgrade_purchased.emit(upgrade_name)

func on_hover_upgrade() -> void:
	if multiplayer.is_server():
		return
	
	var name_text = upgrade_name
	var desc_text = upgrade_description
	var cost_text = upgrade_cost_description
	
	if locked or ap_locked:
		name_text = "[color=red]Locked: %s[/color]" % upgrade_name
		desc_text = "[color=red]%s[/color]" % upgrade_description
	elif purchased:
		name_text = "[color=green]Purchased: %s[/color]" % upgrade_name
		desc_text = "[color=green]%s[/color]" % upgrade_description
	
	var cost_color = "green"
	
	if upgrade_cost_type in [CostType.Gold, CostType.KingdomGold]:
		cost_color = "gold"
	
	if is_funding:
		cost_text = "[color=%s]%s" % [cost_color, funding_total]
		if not is_infinitly_fundable:
			cost_text += "/ %s" % upgrade_cost
		cost_text += " %s[/color]" % _get_cost_type_name(upgrade_cost_type)
	
	SignalBus.show_upgrade_text.emit(name_text, desc_text, cost_text)

func on_unhover_upgrade() -> void:
	SignalBus.hide_upgrade_text.emit()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is MultiplayerController and body._is_local_player:
		on_hover_upgrade()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is MultiplayerController and body._is_local_player:
		on_unhover_upgrade()

func _is_ap_unlocked() -> bool:
	if not GameState.is_ap:
		return true
	if not ap_start_locked:
		return true
	if upgrade_name in ServerArchipelago.server_received_items:
		return true
	
	return false

var upgrades : Dictionary[String, UpgradeData] = {
	"Faster Crop Spawn Rate": UpgradeData.create(25.0, CostType.Coins, "Increases crop spawn rate 50%", func(): GameState.mult_farms_speed(1.5)),
	"Economics Room": UpgradeData.create(10.0, CostType.Coins, "Unlocks two other upgrades in the castle.", func(): SignalBus.disable_wall.emit("Economics Room")),
	"Faster Money Generation": UpgradeData.create(5.0, CostType.Coins, "Decreases the time it takes to automatically generate money by 67%.", func(): GameState.money_gen_delay *= (1.0/3.0)),
	"Better Sell Deals": UpgradeData.create(10.0, CostType.Coins, "Increases the crop sell price by 0.15.", func(): GameState.current_sell_value += 0.15),
	"Unlock Backyard": UpgradeData.create(12.0, CostType.Coins, "Opens the side of the castle.", func(): self.hide(); collision.disabled = true; SignalBus.enable_door.emit("Castle Backyard"); SignalBus.reveal_upgrade.emit("Castle Backyard")),
	"Unlock Basement": UpgradeData.create(24.0, CostType.Coins, "Adds a basement to the backyard.", func(): self.hide(); collision.disabled = true; SignalBus.enable_door.emit("Castle Basement")),
	"Town Center Upgrade": UpgradeData.create(40.0, CostType.Coins, "Adds 3 new buildings to the town.", func(): SignalBus.build_building.emit("Town Center")),
	"Open Shop (King)": UpgradeData.create(5.0, CostType.Coins, "Unlocks the shop.", func(): self.hide(); collision.disabled = true; SignalBus.enable_door.emit("Shop")),
	"Open Shop": UpgradeData.create(100.0, CostType.Gold, "Unlocks the shop.", func(): self.hide(); collision.disabled = true; SignalBus.enable_door.emit("Shop")),
	"Crop Fertilizer": UpgradeData.create(24.0, CostType.Coins, "Increases crop spawn rate by 50%.", func(): GameState.mult_farms_speed(1.5)),
	"Faster Processing": UpgradeData.create(25.0, CostType.Coins, "Quintuples max processing speeds.", func(): SignalBus.mult_processing_speed.emit(4.0)),
	"Intensive Research": UpgradeData.create(45.0, CostType.Coins, "Adds three additional upgrades to one of the houses.", func(): SignalBus.reveal_upgrade.emit("Intensive Research")),
	"Significantly Cropier Crops": UpgradeData.create(15.0, CostType.Coins, "Increases the crop sell price by 0.2", func(): GameState.current_sell_value += 0.2),
	"Extreme Economy": UpgradeData.create(40.0, CostType.Coins, "Increases the crop sell price by 0.15, crop spawn rate by 25%, and indoor crop spawn rate by 100%.", func(): GameState.current_sell_value += 0.15; GameState.mult_farms_speed(1.25); GameState.mult_farms_speed(2.0, ["town center"])),
	"Better Return Rates": UpgradeData.create(25.0, CostType.Coins, "Citizens are 16.67% more likely to get gold from selling to the merchant.", func(): GameState.gold_return_rate += 1.0/6.0),
	"Crop Harvesting Technology": UpgradeData.create(25.0, CostType.Coins, "Increases crops per crop from 2-5 to 3-7.", func(): GameState.drop_count_min += 1; GameState.drop_count_max += 2),
	"The Button": UpgradeData.create(180.0, CostType.Coins, "Expands the merchant house and basement, adding 3 new areas to get upgrades in.", func(): SignalBus.disable_wall.emit("The Button"); SignalBus.reveal_upgrade.emit("The Button"); SignalBus.enable_door.emit("The Button")),
	"A Dollar A Dime": UpgradeData.create(80.0, CostType.Coins, "Increases the crop sell price by 0.25.", func(): GameState.current_sell_value += 0.25),
	"Double City Funding": UpgradeData.create(150.0, CostType.Coins, "Gold put into the town bank is now doubled. [color=red](WIP)[/color]", func(): pass),
	"Guaranteed Returns": UpgradeData.create(80.0, CostType.Coins, "Citizens are guaranteed to get gold from selling to the merchant, as well as getting more gold than usual.", func(): GameState.gold_return_rate += 1.0),
	"Better Farmers": UpgradeData.create(125.0, CostType.Coins, "Breaking crops will break all adjacent crops.", func(): GameState.better_farmers = true),
	"Incredibly Fast Growth": UpgradeData.create(125.0, CostType.Coins, "Increases crop spawn rate by 100%.", func(): GameState.mult_farms_speed(2.0)),
	"Bigger Bunker": UpgradeData.create(75.0, CostType.Coins, "Expands the underground bunker, also adding another area to get upgrades in.", func(): SignalBus.disable_wall.emit("Bigger Bunker")),
	"Expansion Island": UpgradeData.create(350.0, CostType.Coins, "Adds a teleporter to a new island.", func(): SignalBus.enable_door.emit("Expansion Island")),
	"Morale Boost": UpgradeData.create(200.0, CostType.Coins, "Increases everyone's speed by 20%.", func(): SignalBus.mult_player_speed.emit(1.2)),
	"Lower Shipping Taxes": UpgradeData.create(200.0, CostType.Coins, "Increases the melon sell price by 0.3.", func(): GameState.current_sell_value += 0.3),
	"Even Better Harvesting": UpgradeData.create(200.0, CostType.Coins, "Increases melons per melon from 3-7 to 5-9.", func(): GameState.drop_count_min += 2; GameState.drop_count_max += 2),
	"Faster Selling": UpgradeData.create(150.0, CostType.Coins, "Quintuples crop sell speed.", func(): SignalBus.mult_sell_speed.emit(4.0)),
	"Farming Island": UpgradeData.create(400.0, CostType.Coins, "Adds a teleporter to a new farming island.", func(): SignalBus.enable_door.emit("Farming Island")),
	
	"Deluxe Farm": UpgradeData.create(300.0, CostType.Coins, "Increases this island's crop spawn rate by 150%.", func(): GameState.mult_farms_speed(2.5, ["deluxe"])),
	"Quality Control": UpgradeData.create(300.0, CostType.Coins, "Increases the crop sell price by 0.5.", func(): GameState.current_sell_value += 0.5),
	"Better Filters": UpgradeData.create(225.0, CostType.Coins, "Increases the crop sell price by 0.2.", func(): GameState.current_sell_value += 0.2),
	"Fortified Island": UpgradeData.create(600.0, CostType.Coins, "Unlocks the third island, this one containing a small castle.", func(): SignalBus.enable_door.emit("Fortified Island")),
	
	"Mysterious Island": UpgradeData.create(800.0, CostType.Coins, "Unlocks the fourth island.", func(): SignalBus.enable_door.emit("Mysterious Island")),
	"The Grand Finale": UpgradeData.create(0.0, CostType.Coins, "It has all come to this...", func(): SignalBus.victory.emit("True Urban")),
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
