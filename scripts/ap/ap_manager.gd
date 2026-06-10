extends Node

var connection: ConnectionInfo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Archipelago.connected.connect(_on_connected)
	SignalBus.upgrade_purchased.connect(collect_location_by_name)

func _on_connected(conn: ConnectionInfo, _json: Dictionary) -> void:
	conn.bounce.connect(_on_bounce)
	conn.deathlink.connect(_on_deathlink)
	conn.setreply.connect(_on_setreply)
	conn.roomupdate.connect(_on_roomupdate)
	conn.obtained_item.connect(_on_obtained_item)
	conn.obtained_items.connect(_on_obtained_items)
	conn.refresh_items.connect(_on_refresh_items)
	conn.on_hint_update.connect(_on_hint_update)
	conn.traplink.connect(_on_traplink)
	conn.all_scout_cached.connect(_on_all_scout_cached)
	connection = conn
	GameState.is_ap = true
	SignalBus.ap_reset.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

## Emitted when a `Bounce` packet is received.
func _on_bounce(_json: Dictionary) -> void:
	pass

## Emitted when a `Bounce` packet of type `DeathLink` is received, after the `bounce` signal.
func _on_deathlink(_source: String, _cause: String, _json: Dictionary) -> void:
	pass

## Emitted when a `SetReply` packet is received
func _on_setreply(_json: Dictionary) -> void:
	pass

## Emitted when a `RoomUpdate` packet is received
func _on_roomupdate(_json: Dictionary) -> void:
	pass

## Emitted for each item received
func _on_obtained_item(_item: NetworkItem) -> void:
	SignalBus.upgrade_unlocked.emit(_item.get_name())

## Emitted for each item *packet* received
func _on_obtained_items(_items: Array[NetworkItem]) -> void:
	pass

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
	if connection == null:
		push_warning("Not Connected")
		return null
	return connection.get_location_by_name(_name)

func _send_bounce(data: Dictionary, target_games: Array[String], target_slots: Array[String], target_tags: Array[String]) -> void:
	if connection == null:
		push_warning("Not Connected")
		return
	connection.send_bounce(data, target_games, target_slots, target_tags)

func send_deathlink(cause: String = "") -> void:
	if connection == null:
		push_warning("Not Connected")
		return
	connection.send_deathlink(cause)

func send_traplink(trap_name: String):
	if connection == null:
		push_warning("Not Connected")
		return
	connection.send_traplink(trap_name)

func collect_location_by_name(_name: String) -> void:
	if connection == null:
		push_warning("Not Connected")
		return
	var loc = get_location_by_name(_name)
	if loc == null:
		push_error("No location with name '%s' found!" % _name)
		return
	if loc.collected:
		push_warning("Location '%s' already collected!" % _name)
		return
	
	Archipelago.collect_location(loc.id)
