extends CharacterBody2D

@export var turningSpeed := 1.0
@export var forwardSpeed := 150.0

var forwardAxis := 0.0
var turningAxis := 0.0

var targetDir := 0.0



func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

#KEYBOARD CONTROLS
func handle_input_kb():
	if Globals.useController:
		forwardAxis = Input.get_axis("down_joypad","up_joypad")
		turningAxis = Input.get_axis("left_joypad","right_joypad")
	else:
		forwardAxis = Input.get_axis("down","up")
		turningAxis = Input.get_axis("left","right")

func handle_movement_kb(delta: float):
	rotate(turningSpeed * turningAxis * delta)
	velocity = Vector2(0, -forwardAxis).rotated(rotation).normalized() * forwardSpeed


#CONTROLLER CONTROLS
func handle_input_jp():
	targetDir = Vector2.ZERO.angle_to_point(Input.get_vector("left_joypad", "right_joypad", "up_joypad", "down_joypad"))
	if targetDir: targetDir += PI/2
	forwardAxis = Input.get_axis("backward_joypad","forward_joypad")
	
func handle_movement_jp(delta: float):
	if targetDir:
		rotation = rotate_toward(rotation, targetDir, turningSpeed * delta)
	velocity = Vector2(0, -forwardAxis).rotated(rotation).normalized() * forwardSpeed

func _physics_process(delta):
	if !is_multiplayer_authority(): return
	
	if Globals.useController && Globals.controllerScheme == 0:
		handle_input_jp()
		handle_movement_jp(delta)
	else:
		handle_input_kb()
		handle_movement_kb(delta)
	
	move_and_slide()

