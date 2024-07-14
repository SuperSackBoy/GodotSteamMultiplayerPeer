extends Node

var useController = false
var controllerScheme := 0

var useSteam = true
var appID := str(480)


func _unhandled_input(event):
	if event.is_action_pressed("esc"): get_tree().quit()

func _input(event):
	if !useController:
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			useController = true
	else:
		if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventKey:
			useController = false


func _ready():
	if useSteam:
		OS.set_environment("SteamAppID", appID)
		OS.set_environment("SteamGameID", appID)
		Steam.steamInitEx()

func _process(delta):
	if useSteam:
		Steam.run_callbacks()
