extends Node2D

@onready var parent = get_parent()
@export var rotationSpeed := 5.0
var target := 0.0

var tPos = 0

func _input(event):
	if Globals.useController:
		if event is InputEventJoypadMotion:
			if (event.get_axis() == 2 or event.get_axis() == 3):
				var t = Vector2.ZERO.angle_to_point(Input.get_vector("r_left_joypad", "r_right_joypad", "r_up_joypad", "r_down_joypad"))
				if t != 0.0: tPos = t
				return
	if event.is_action_pressed("fire"):
		print("FIRE")

func _process(delta):
	if !is_multiplayer_authority(): return
	if !Globals.useController:
		tPos = global_position.angle_to_point(get_global_mouse_position())
	
	
	target = tPos + PI/2 + PI/4 - parent.rotation
	#print(rad_to_deg(target))
	if target > TAU: target -= TAU
	target = clamp(target,0,PI/2) - PI/4
	
	rotation = target
