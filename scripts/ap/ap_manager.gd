extends Node

var connection: ConnectionInfo:
	get():
		return Archipelago.conn

var server_archipelago: ServerArchipelago:
	get():
		return GameManager.server_archipelago

var is_deathlink : bool:
	get():
		return "deathlink" in connection.slot_data and (connection.slot_data["deathlink"] or connection.slot_data["deathlink"] == "true")

var is_ringlink : bool:
	get():
		return "ringlink" in connection.slot_data and (connection.slot_data["ringlink"] or connection.slot_data["ringlink"] == "true")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Archipelago.connected.connect(_on_connected)
	Archipelago.roominfo.connect(_on_roominfo)
	SignalBus.victory.connect(_on_victory)

func _on_roominfo(_conn: ConnectionInfo, _json: Dictionary) -> void:
	connection.bounce.connect(_on_bounce)
	connection.deathlink.connect(_on_deathlink)
	connection.setreply.connect(_on_setreply)
	connection.roomupdate.connect(_on_roomupdate)
	connection.obtained_item.connect(_on_obtained_item)
	#connection.obtained_items.connect(_on_obtained_items)
	connection.refresh_items.connect(_on_refresh_items)
	connection.traplink.connect(_on_traplink)
	connection.all_scout_cached.connect(_on_all_scout_cached)

func _on_connected(_conn: ConnectionInfo, _json: Dictionary) -> void:
	GameState.is_ap = true
	
	if not _collect_queue.is_empty():
		for item in _collect_queue:
			collect_location_by_name(item)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

var last_sent_ringlink_time : float

## Emitted when a `Bounce` packet is received.
func _on_bounce(json: Dictionary) -> void:
	var tags: Array = json.get("tags", [])
	if tags.has("RingLink") and is_ringlink:
		var tstamp: float = json.get("time", 0.0)
		if absf(tstamp - last_sent_ringlink_time) < 0.5:
			return # Skip traps from self
		var source: String = json.get("source", "")
		var amount: int = json.get("amount", 0)
		_on_rignlink(source, amount)

func _on_rignlink(source: String, amount: int) -> void:
	#server_archipelago.notify_server_receive_ringlink()
	var desc : String
	if amount >= 0:
		desc = "gained"
	else:
		desc = "lost"
	ChatController.print_text_to_chat("%s %s coins." % [desc, amount], "AP:RingLink][%s" % source)

func send_ringlink(amount: float) -> void:
	if not Archipelago.is_ap_connected() or not is_ringlink or amount == 0.0:
		return
	
	last_sent_ringlink_time = Time.get_unix_time_from_system()
	var data = {
		"source": connection.get_player_name(-1, false),
		"time": last_sent_ringlink_time,
		"amount": amount
	}
	connection.send_bounce(data, [], [], ["RingLink"])

## Emitted when a `Bounce` packet of type `DeathLink` is received, after the `bounce` signal.
func _on_deathlink(source: String, cause: String, json: Dictionary) -> void:
	server_archipelago.notify_server_receive_deathlink(source, cause, json)

## Emitted when a `SetReply` packet is received
func _on_setreply(_json: Dictionary) -> void:
	pass

## Emitted when a `RoomUpdate` packet is received
func _on_roomupdate(_json: Dictionary) -> void:
	pass

## Emitted for each item received
func _on_obtained_item(item: NetworkItem) -> void:
	print("Item obtained: %s" % item.get_name())
	server_archipelago.notify_server_item_received(item)

## Emitted for each item *packet* received
#func _on_obtained_items(items: Array[NetworkItem]) -> void:
	#for item in items:
		#print("Item obtained: %s" % item.get_name())
	#server_archipelago.notify_server_items_received(items)

## Emitted when the server re-sends ALL obtained items
func _on_refresh_items(_items: Array[NetworkItem]) -> void:
	pass

## Emitted when hints relevant to this client change
func _on_hint_update(_hints: Array[NetworkHint]) -> void:
	pass

## Emitted when a `Bounce` packet of type `TrapLink` is received, after the `bounce` signal.
## 'trap_name' will be the trap name AFTER resolving the received name through `TRAP_LINK_ALIASES`.
func _on_traplink(_source: String, _trap_name: String, _json: Dictionary) -> void:
	pass

## Emitted when a scout packet containing ALL locations is received (see `force_scout_all`)
func _on_all_scout_cached() -> void:
	pass

func get_location_by_name(_name: String) -> APLocation:
	if not Archipelago.is_ap_connected():
		push_warning("Not Connected")
		return null
	
	return connection.get_loc_by_name(_name)

func _send_bounce(data: Dictionary, target_games: Array[String], target_slots: Array[String], target_tags: Array[String]) -> void:
	if not Archipelago.is_ap_connected():
		push_warning("Not Connected")
		return
	connection.send_bounce(data, target_games, target_slots, target_tags)

func _on_goal() -> void:
	Archipelago.set_client_status(Archipelago.ClientStatus.CLIENT_GOAL)

func send_deathlink(cause: String = "") -> void:
	if not Archipelago.is_ap_connected():
		push_warning("Not Connected")
		return
	connection.send_deathlink(cause)

func send_traplink(trap_name: String):
	if not Archipelago.is_ap_connected():
		push_warning("Not Connected")
		return
	connection.send_traplink(trap_name)

var _collect_queue : Array[String] = []

func collect_location_by_name(_name: String) -> void:
	if not Archipelago.is_ap_connected():
		_collect_queue.append(_name)
		push_warning("Not Connected")
		return
	
	var loc = get_location_by_name(_name)
	if loc == null or loc.id < 1:
		push_error("No location with name '%s' found!" % _name)
		print(connection.locations.keys())
		print(connection.locs_by_name.values())
		return
	
	print("Collecting %s" % _name)
	Archipelago.collect_location(loc.id)

func _on_victory(ending: String) -> void:
	if ending == "True Urban": # TODO: add goal to slot_data and handle it here
		_on_goal()
