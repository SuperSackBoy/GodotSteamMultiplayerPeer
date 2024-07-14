extends Node

@onready var JoinMenu = $"../CanvasLayer/JoinUI"


const Player = preload("res://scenes/tank.tscn")

const PORT = 10483
var enet_peer = ENetMultiplayerPeer.new()
var steam_peer = SteamMultiplayerPeer.new()

var lobby_id

var players := Dictionary()


func _ready():
	JoinMenu.HostButtonPressed.connect(host_button_pressed.bind())
	JoinMenu.JoinButtonPressed.connect(join_button_pressed.bind())
	JoinMenu.LobbyButtonPressed.connect(join_button_pressed.bind())
	if Globals.useSteam:
		Steam.lobby_created.connect(_on_lobby_created)

func host_button_pressed():
	print("HOST")
	JoinMenu.hide()
	
	if Globals.useSteam:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)
		steam_peer.create_host(PORT, [])
		multiplayer.multiplayer_peer = steam_peer
	else:
		enet_peer.create_server(PORT)
		multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	if JoinMenu.get_UPNP() && !Globals.useSteam:
		upnp_setup()

func _on_lobby_created(connect, id):
	if connect:
		lobby_id = id
		Steam.setLobbyData(lobby_id,"name",str(Steam.getPersonaName()+"'s Lobby"))
		Steam.setLobbyJoinable(lobby_id, true)
		print(lobby_id)

func join_button_pressed(id = null):
	print("CLIENT", " ID: ", id)
	JoinMenu.hide()
	
	if Globals.useSteam:
		Steam.joinLobby(id)
		steam_peer.create_client(id, PORT, [])
		multiplayer.multiplayer_peer = steam_peer
	else:
		enet_peer.create_client("localhost", PORT)
		multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	players[peer_id] = player
	player.name = str(peer_id)
	player.position = Vector2(randf_range(0,500), randf_range(0,500))
	get_parent().add_child(player)

func remove_player(peer_id):
	var player = players[peer_id]
	if player: 
		player.queue_free()
		players.erase(peer_id)

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())

