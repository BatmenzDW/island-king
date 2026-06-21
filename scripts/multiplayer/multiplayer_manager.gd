extends Node

signal toggle_menu_camera(on: bool)

var multiplayer_scene = preload("res://objects/multiplayer_player.tscn")

var _players_spawn_node : Node2D
var is_host : bool = false
var is_game_connected : bool = false

var SERVER_PORT = 8080
var SERVER_IP = "18.217.56.223"

var GAME_VERSION : String = ProjectSettings.get_setting("application/config/version", "0.0.0")

func _ready() -> void:
	print("Island King v" + GAME_VERSION)

func become_host():
	print("Become host called")
	
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	
	is_host = true
	is_game_connected = true
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	
	if not GameState.is_server:
		_add_player_to_game(1)
	#toggle_menu_camera.emit(false)
	multiplayer.peer_connected.connect(_on_client_connected)

static var players : Dictionary[int, MultiplayerController] = {}

var pl_name : String

func join_lobby(p_name: String):
	print("Join called")
	
	is_host = false
	is_game_connected = true
	
	var client_peer = ENetMultiplayerPeer.new()
	var err = client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	if err != OK:
		is_game_connected = false
		push_warning("Couldn't connect to server")
		return
	
	multiplayer.multiplayer_peer = client_peer
	toggle_menu_camera.emit(false)
	
	pl_name = p_name
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func _on_connected_to_server() -> void:
	_rpc_player_version.rpc_id(1, multiplayer.get_unique_id(), GAME_VERSION)
	_rpc_player_name.rpc_id(1, multiplayer.get_unique_id(), pl_name)

func _on_client_connected(_id: int) -> void:
	if $"../GameController/Players".get_child_count() == 1:
		SignalBus.reset_run.emit()
	else:
		for player in $"../GameController/Players".get_children(): # Check if king is still on
			if player.is_king and player.player_id != _id:
				return
		
		SignalBus.reset_run.emit()

func _add_player_to_game(id: int):
	print("Player %s joined the game" % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	
	players[id] = player_to_add
	
	if id == 1 and is_host:
		player_to_add.is_king = true

func _del_player(id: int):
	print("Player %s left the game" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	
	_players_spawn_node.get_node(str(id)).queue_free()

@rpc("any_peer")
func _rpc_player_name(p_id: int, p_name: String) -> void:
	var plyrs = $"../GameController/Players".get_children()
	for p in plyrs:
		if p.player_id != p_id:
			continue
		
		p.player_name = p_name
		break
	
	print("%s joined" % p_name)
	
	player_names[p_id] = p_name

@rpc("any_peer")
func _rpc_player_version(p_id: int, ver: String) -> void:
	if ver != GAME_VERSION:
		_print_disconnect_reason.rpc_id(p_id, "Incorrect game version. Server is on version %s" % GAME_VERSION)
		await get_tree().create_timer(1.0).timeout # make sure player gets the disconnect msg before disconnecting them
		multiplayer.multiplayer_peer.disconnect_peer(p_id)

@rpc()
func _print_disconnect_reason(reason: String) -> void:
	ChatController.print_text_to_chat(reason, "[Server]")

static var player_names : Dictionary = {}
