extends KinematicBody

export var velocity = Vector3()
export var friction = 0.01
export var air_friction = Vector3(0.1,0.0,0.1)
export var gravity_scale = Vector3(1.0,1.0,1.0)

#movement vars
var floor_velocity = Vector3()
var on_ceiling = false
var on_wall = false
var on_floor = false
export var floor_direction = Vector3(0,1,0)

export var slope_stop_min_velocity = 0.05
export var max_slides = 4
export var floor_max_angle = 45

export var bounce = 0.0


func _physics_process(delta):
	move(delta)
	pass

func lock_linear_velocity():
	var axis_lock = [axis_lock_linear_x, axis_lock_linear_y, axis_lock_linear_z]
	for i in range(axis_lock.size()):
		if(axis_lock[i] == true):
			velocity[i] = 0
		
func move(delta):
	
	var state = PhysicsServer.body_get_direct_state(get_rid())
	
	var gravity = state.get_total_gravity() * gravity_scale
	
	#Apply Gravity
	velocity += gravity * delta
	velocity -= velocity * air_friction
	#Apply linear damp
	velocity -= velocity * state.get_total_linear_damp()
	#lock_linear_velocity()
	
	var motion = (floor_velocity + velocity) * delta
	
	floor_velocity = Vector3()
	on_wall = false
	on_floor = false
	on_ceiling = false
	
	var p_max_slides = max_slides
	var collision
	var _bounce = Vector3()
	
	while(p_max_slides > 0):
		collision = move_and_collide(motion)
		if(collision != null):
			
			if(collision.collider.has_method("apply_impulse")):
				collision.collider.apply_impulse(collision.position,motion * collision.normal.dot(motion))
			
			var b = collision.collider.bounce
			if(!b):
				b = 0
			b = max(b, bounce)
			var _b = ((motion) * -(b))/delta
			_bounce += (collision.normal * collision.normal.dot(_b))
			
			motion = collision.remainder
			
			if(floor_direction == Vector3()):
				on_wall = true
			else:
				if(collision.normal.dot(floor_direction) >= cos(deg2rad(floor_max_angle))):
					on_floor = true
					floor_velocity = collision.collider_velocity
					var relative_velocity = velocity - floor_velocity
					var h_vel = relative_velocity - floor_direction * floor_direction.dot(relative_velocity)
					
					if(collision.travel.length() < 0.05 && h_vel.length() < slope_stop_min_velocity):
						global_transform.origin -= collision.travel
						velocity = floor_velocity - floor_direction * floor_direction.dot(floor_velocity) + _bounce
						
						return velocity
				elif(collision.normal.dot(-floor_direction) >= cos(deg2rad(floor_max_angle))):
					on_ceiling = true
				else:
					on_wall = true
			
			motion = motion.slide(collision.normal)
			velocity = velocity.slide(collision.normal) + _bounce
			
			#apply friction
			if(collision.collider.friction != null):
				velocity -= (velocity * (collision.collider.friction * friction))
			#lock_linear_velocity()
			
			
			
		else:
			break;
			
		p_max_slides -= 1
		if(motion == Vector3()):
			break
	return velocity
	
	