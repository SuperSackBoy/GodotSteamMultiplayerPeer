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
	multiplayer.connection_failed.connect(connection_failed.bind())
	multiplayer.server_disconnected.connect(connection_disconnected.bind())
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
		Steam.lobby_joined.connect(_on_lobby_joined.bind())
		Steam.joinLobby(id)

	else:
		enet_peer.create_client("localhost", PORT)
		multiplayer.multiplayer_peer = enet_peer

func _on_lobby_joined(lobby: int, permissions: int, locked: bool, response: int):
	print("on lobby joined")
	
	if response == 1:
		var id = Steam.getLobbyOwner(lobby)
		if id != Steam.getSteamID():
			print("Connecting client to socket")
			connect_socket(id)
			print("connected")
	else:
		var fail = ""
		match response:
			2: fail = "lobby no longer exists"
			3: fail = "you dont have perms to join"
			4: fail = "lobby is full"
			5: fail = "man idk panic"
			6: fail = "banned"
			7: fail = "you cannot join due to having a limited account"
			8: fail = "lobby is locked"
			9: fail = "lobby is community locked"
			10: fail = "a user in the lobby has blocked you from joining"
			11: fail = "a user you have blocked is in the lobby"
		print(fail)

func connect_socket(steamID: int):
	var err = steam_peer.create_client(steamID, PORT, [])
	if err == OK:
		multiplayer.multiplayer_peer = steam_peer
	else:
		print("error creating client &s" % str(err))

func add_player(peer_id):
	var player = Player.instantiate()
	players[peer_id] = player
	player.name = str(peer_id)
	var pos = Vector2(randf_range(0,1000), randf_range(0,500))
	
	get_parent().add_child(player)
	
	if peer_id == multiplayer.get_unique_id():
		player.position = pos
	else:
		player.init.rpc_id(peer_id, pos)

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

func connection_failed():
	JoinMenu.display_message("Connection Failed")
	JoinMenu.show()

func connection_disconnected():
	JoinMenu.display_message("Disconnected from Server")
	JoinMenu.show()
