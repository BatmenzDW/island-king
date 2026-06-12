extends Node

var connection: ConnectionInfo:
	get():
		return Archipelago.conn

var server_archipelago: ServerArchipelago:
	get():
		return GameManager.server_archipelago

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
	connection.obtained_items.connect(_on_obtained_items)
	connection.refresh_items.connect(_on_refresh_items)
	connection.on_hint_update.connect(_on_hint_update)
	connection.traplink.connect(_on_traplink)
	connection.all_scout_cached.connect(_on_all_scout_cached)
	connection.locations_loaded.connect(_on_locations_loaded)

func _on_connected(_conn: ConnectionInfo, _json: Dictionary) -> void:
	GameState.is_ap = true
	
	if not _collect_queue.is_empty():
		for item in _collect_queue:
			collect_location_by_name(item)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

var _locs_loaded : bool = false

# this is probably not needed, but I'm going to leave it as an extra fallback case
func _on_locations_loaded() -> void:
	_locs_loaded = true
	print("Locations Loaded")
	for to_collect in _collect_queue:
		collect_location_by_name(to_collect)
	
	_collect_queue.clear()

## Emitted when a `Bounce` packet is received.
func _on_bounce(_json: Dictionary) -> void:
	pass

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
func _on_obtained_items(items: Array[NetworkItem]) -> void:
	for item in items:
		print("Item obtained: %s" % item.get_name())
	server_archipelago.notify_server_items_received(items)

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
	
	if not _locs_loaded:
		push_warning("Locations not loaded yet.")
		_collect_queue.append(_name)
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
