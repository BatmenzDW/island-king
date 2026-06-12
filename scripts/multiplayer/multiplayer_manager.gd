extends Node

signal toggle_menu_camera(on: bool)

var multiplayer_scene = preload("res://objects/multiplayer_player.tscn")

var _players_spawn_node : Node2D
var is_host : bool = false
var is_game_connected : bool = false

var SERVER_PORT = 8080
var SERVER_IP = "18.217.56.223"

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

var pl_name : String

func join_lobby(p_name: String):
	print("Join called")
	
	is_host = false
	is_game_connected = true
	
	var client_peer = ENetMultiplayerPeer.new()
	var err = client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	if err != OK:
		is_game_connected = false
		return
	
	multiplayer.multiplayer_peer = client_peer
	toggle_menu_camera.emit(false)
	
	pl_name = p_name
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func _on_connected_to_server() -> void:
	_rpc_player_name.rpc_id(1, multiplayer.get_unique_id(), pl_name)

func _on_client_connected(_id: int) -> void:
	if $"../GameController/Players".get_child_count() == 1:
		SignalBus.reset_run.emit()

func _add_player_to_game(id: int):
	print("Player %s joined the game" % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	
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
	
	player_names[p_id] = p_name

static var player_names : Dictionary = {}
