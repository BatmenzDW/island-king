extends Node
class_name ServerArchipelago

signal upgrade_purchased(upgrade: String)

var current_ap_target_player : int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.upgrade_purchased.connect(_upgrade_purchased_server)
	upgrade_purchased.connect(ApManager.collect_location_by_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _upgrade_purchased_server(upgrade: String) -> void:
	_upgrade_purchased_text(upgrade)
	if current_ap_target_player < 0:
		return
	_upgrade_purchased.rpc_id(current_ap_target_player, upgrade)

@rpc()
func _upgrade_purchased(upgrade: String) -> void:
	upgrade_purchased.emit(upgrade)

func _upgrade_purchased_text(upgrade: String) -> void:
	var text = "[color=gold]" + Upgrade.get_upgrade_bought_text(upgrade) + "[/color]"
	ChatController._send_chat_to_client(text)

static var server_slot_data : Dictionary
static var server_slot_locations: Dictionary[int, bool]
static var server_received_items : Array[String]

static var is_deathlink : bool:
	get():
		return "deathlink" in server_slot_data and server_slot_data["deathlink"] == 1.0

static var is_ringlink : bool:
	get():
		return "ringlink" in server_slot_data and server_slot_data["ringlink"] == 1.0

func notify_server_item_received(item: NetworkItem) -> void:
	if GameState.is_server:
		push_warning("notify_server_item_received called from server")
		return
	if multiplayer.get_unique_id() == 1:
		return
	_rpc_item_recieved.rpc_id(1, item.get_name())

#func notify_server_items_received(items: Array[NetworkItem]) -> void:
	#if GameState.is_server:
		#push_warning("notify_server_items_received called from server")
		#return
	#var items_names : Array[String] = items.map(func(item): return item.get_name())
	#_rpc_items_recieved.rpc_id(1, items_names)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_item_recieved(item: String) -> void:
	server_received_items.append(item)
	SignalBus.upgrade_unlocked.emit(item)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_items_recieved(items: Array[String]) -> void:
	for item in items:
		server_received_items.append(item)
		SignalBus.upgrade_unlocked.emit(item)

func notify_server_receive_deathlink(source: String, cause: String, json: Dictionary) -> void:
	ChatController.print_text_to_chat(cause, "AP:Deathlink][%s" % source)
	_rpc_receive_deathlink.rpc_id(1, source, cause, json)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_receive_deathlink(_source: String, _cause: String, _json: Dictionary) -> void:
	if multiplayer.get_remote_sender_id() != current_ap_target_player:
		print("Received deathlink from player %s while they were not king" % multiplayer.get_remote_sender_id())
		return
	
	if not is_deathlink:
		print("Received deathlink while deathlink was off.")
		return
	
	do_receive_deathlink()

func do_receive_deathlink() -> void:
	if current_ap_target_player not in MultiplayerManager.players:
		print("Couldn't find king player to kill.")
		return
	
	MultiplayerManager.players[current_ap_target_player]._die(true)

func do_send_deathlink() -> void:
	if not is_deathlink:
		return
	var k_name = MultiplayerManager.player_names[current_ap_target_player]
	
	_rpc_send_deathlink.rpc_id(current_ap_target_player, "The rein of %s was violently ended." % k_name)

@rpc("authority")
func _rpc_send_deathlink(cause: String) -> void:
	Archipelago.conn.send_deathlink(cause)

func notify_server_receive_bounce() -> void:
	pass

func notify_server_recieve_ringlink(amount: int) -> void:
	_rpc_notify_server_ringlink.rpc_id(1, amount)

func on_new_king(player_id: int) -> void:
	current_ap_target_player = player_id
	_request_sync_slot.rpc_id(player_id)

@rpc("any_peer")
func _rpc_notify_server_ringlink(amount: int) -> void:
	if not is_ringlink:
		return
	
	GameState.kingdom_money += amount

@rpc("authority")
func _request_sync_slot() -> void:
	var conn = Archipelago.conn
	if conn == null:
		_refuse_sync_slot.rpc_id(1)
		return
	var encoded_items : Array[String] = []
	for item in conn.received_items:
		encoded_items.append(item.get_name())
	
	_sync_slot.rpc_id(1, conn.slot_data, conn.slot_locations, encoded_items)

@rpc("any_peer", "call_remote", "reliable")
func _refuse_sync_slot() -> void:
	current_ap_target_player = -1

@rpc("any_peer", "call_remote", "reliable")
func _sync_slot(slot_data: Dictionary, slot_locations: Dictionary[int, bool], received_items: Array[String]) -> void:
	if multiplayer.get_remote_sender_id() != current_ap_target_player:
		return
	
	server_slot_data = slot_data
	server_slot_locations = slot_locations
	server_received_items = received_items
	
	SignalBus.sync_ap_items.emit(server_received_items)
	
	print("Slot synced: %s, %s, %s" % [server_slot_data, server_slot_locations, server_received_items])
