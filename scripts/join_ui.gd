extends Control

@onready var addressEntry = $PanelContainer/MarginContainer/VBoxContainer/AddressEntry
@onready var upnpBox = $PanelContainer/MarginContainer/VBoxContainer/CheckBox

signal HostButtonPressed
signal JoinButtonPressed

signal LobbyButtonPressed

func _ready():
	if Globals.useSteam:
		open_lobby_list()
		Steam.lobby_match_list.connect(on_lobby_match_list)
	else:
		$LobbyList.hide()


func get_ip():
	return addressEntry.text

func get_UPNP():
	return upnpBox.button_pressed


func _on_host_button_pressed():
	HostButtonPressed.emit()


func _on_join_button_pressed():
	JoinButtonPressed.emit()


func open_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func on_lobby_match_list(lobbies):
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var mem_count = Steam.getNumLobbyMembers(lobby)
		
		
		var but = Button.new()
		but.set_text(str(lobby_name)+" | "+str(mem_count))
		but.set_size(Vector2(200,5))
		but.connect("pressed", func(): LobbyButtonPressed.emit(lobby))
		
		$LobbyList/VBoxContainer/LobbyContainer/Lobbies.add_child(but)

func _on_refresh_lobbies_pressed():
	if $LobbyList/VBoxContainer/LobbyContainer/Lobbies.get_child_count() > 0:
		for n in $LobbyList/VBoxContainer/LobbyContainer/Lobbies.get_children():
			n.queue_free()
	open_lobby_list()
	
