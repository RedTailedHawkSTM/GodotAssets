extends "res://Actors/KineMaticCharacterController.gd"

var look = Vector3()
var spring = {
		"stiffness": 0.25,
		"damping" : 0.6,
		"pos":Vector3()
	}
var look_velocity = Vector3()

var last_velocity
var last_friction = friction
var air_movement = 1.0


func _ready():
	last_velocity = velocity
	look = Vector3($Camera.rotation.x, $Camera.rotation.y, $Camera.rotation.z)
	spring.pos = Vector3($Camera.rotation.x, $Camera.rotation.y, $Camera.rotation.z)


func mouse_look(delta):
		var mouse_delta = Mouse.get_delta()
		
		look.x -= mouse_delta.y * delta * 0.1 #pitch
		look.y -= mouse_delta.x * delta * 0.1 #yaw
		look.x = clamp(look.x,deg2rad(-90.0),deg2rad(90.0))

func look_spring(delta):
	var diff = (spring.pos - look)
	var force = diff * -( spring.stiffness)
	force -= look_velocity * spring.damping
	look_velocity += force
	spring.pos += look_velocity
	
	var qbasis  = Quat(Vector3(0,1,0), spring.pos.y) * Quat(Vector3(1,0,0), spring.pos.x) * Quat(Vector3(0,0,1), spring.pos.z)
	$Camera.transform.basis = Basis(qbasis)

func _physics_process(delta):
	
	mouse_look(delta)
	
	if(velocity.y <= 0):
		gravity_scale.y = 2.5
	else:
		gravity_scale.y = 1.0
	
	#jumping and bouncy vision
	if(on_floor):
		air_movement = 1.0
		look_velocity.x += last_velocity.y * 0.01
		if(Input.is_key_pressed(KEY_SPACE)):
			velocity.y = 8.0
			look_velocity.x -= velocity.y * 0.01
	else:
		air_movement -= air_movement * 0.9 * delta
		
	#movement
	var dir = Vector3()
	if(Input.is_key_pressed(KEY_W)):
		dir -= $Camera.transform.basis[2]
		look_velocity.x -= 0.01
	if(Input.is_key_pressed(KEY_S)):
		dir += $Camera.transform.basis[2]
		look_velocity.x += 0.01
	if(Input.is_key_pressed(KEY_A)):
		dir -= $Camera.transform.basis[0]
		look_velocity.z += 0.01
	if(Input.is_key_pressed(KEY_D)):
		dir += $Camera.transform.basis[0]
		look_velocity.z -= 0.01
	dir.y = 0
	if(dir.length_squared() == 0):
		friction = 0.9
	else:
		friction = last_friction
	
	velocity += dir * air_movement
	
	#Rotational spring
	look_spring(delta)
	
	last_velocity = velocity
	
	