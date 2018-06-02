tool
extends Node2D

export(bool) var emitting = true
#export(int) var count = 30 #plan to add optimizations to limit the count
export(float) var life = 1.0

export(Texture) var texture
export(Texture) var normal_map
export(Gradient) var color

export(Vector2) var uv_offset = Vector2(0.0,0.0)
export(Vector2) var uv_scale = Vector2(1.0,1.0)
export(float,-360.0,360.0) var uv_rotation = 0.0

export(float) var width = 50.0
export(Curve) var width_curve
export(float,0.0,1.0) var uv_width_factor = 1.0

export(float) var maximum_point_distance = 10.0

var points = PoolVector2Array()
#(life,rotation)
var points_data = []

onready var last_position = global_position
var bounds = Rect2()
var uv_center = Transform2D(0,Vector2(0.5,0.5))

func _ready():
	set_notify_transform(true)

func _notification(what):
	if(what == NOTIFICATION_TRANSFORM_CHANGED):
		last_position = global_position

func _process(delta):
	# look for dead points, searching from the back of the array to avoid issues with removing
	for i in range(points.size()-1,-1,-1):
		
		points_data[i][0] += delta
		if(points_data[i][0] > life):
			points.remove(i)
			points_data.remove(i)
	
	update()
	
	if(emitting == false):
		return

	if(points.size() == 0):
		points.append(global_position)
		points_data.append([0.0,0.0])

	var last_point = points[points.size()-1]
	var square_distance_from_last_point = last_point.distance_squared_to(global_position)

	if( square_distance_from_last_point > (maximum_point_distance*maximum_point_distance) ):
		points.append(global_position)
		var angle = (last_point - global_position).angle()
		points_data.append([0,angle])


func draw_section(a, a_data, b, b_data):
	
	var a_life = a_data[0] / life
	var b_life = b_data[0] / life

	var a_transform = Transform2D(a_data[1],a)
	var b_transform = Transform2D(b_data[1],b)

	var a_color = Color(1.0,1.0,1.0)
	var b_color = a_color
	if(color):
		a_color = color.interpolate(a_life)
		b_color = color.interpolate(b_life)

	var a_width = width
	var b_width = width
	if(width_curve):
		a_width = width_curve.interpolate_baked(1.0-a_life)*width
		b_width = width_curve.interpolate_baked(1.0-b_life)*width
		
	var a_width_ratio = 1.0-(a_width/width)
	var b_width_ratio = 1.0-(b_width/width)
	
	var a_final_width = (1.0 - uv_width_factor) * a_width_ratio
	var b_final_width = (1.0 - uv_width_factor) * b_width_ratio
		
	var a_v1 = a_transform.xform(Vector2(0.0,a_width/2))
	var a_v2 = a_transform.xform(Vector2(0.0,-a_width/2))
	
	var b_v1 = b_transform.xform(Vector2(0.0,b_width/2))
	var b_v2 = b_transform.xform(Vector2(0.0,-b_width/2))
	
	var uv_transform = uv_center * Transform2D(deg2rad(uv_rotation),uv_offset).scaled(uv_scale) * uv_center.inverse()
	
	var a_uv1 = uv_transform.xform(Vector2(a_life, a_final_width*0.5))
	var a_uv2 = uv_transform.xform(Vector2(a_life, 1.0 - a_final_width*0.5))
	
	var b_uv1 = uv_transform.xform(Vector2(b_life, b_final_width*0.5))
	var b_uv2 = uv_transform.xform(Vector2(b_life, 1.0 - b_final_width*0.5))
	
	bounds = bounds.expand(global_transform.affine_inverse().xform(a_v1))
	bounds = bounds.expand(global_transform.affine_inverse().xform(a_v2))
	
	bounds = bounds.expand(global_transform.affine_inverse().xform(b_v1))
	bounds = bounds.expand(global_transform.affine_inverse().xform(b_v2))

	draw_primitive([
		a_v1,
		a_v2,
		b_v1,
	],[a_color,a_color,b_color],[
		a_uv1,
		a_uv2,
		b_uv1
	],texture,0.0,normal_map)
	draw_primitive([
		a_v2,
		b_v2,
		b_v1
	],[a_color,b_color,b_color],[
		a_uv2,
		b_uv2,
		b_uv1
	],texture,0.0,normal_map)


func _get_point(i):
	var s = points.size()+1
	i = fmod(fmod(i,s)+s,s)
	if(i == s-1):
		return {
			"position":global_position,
			"data":[0,(points[i-1]-global_position).normalized().angle()]
		}
	return {
		"position":points[i],
		"data":points_data[i]
	}

func _draw():
	bounds.position.x = 0.0
	bounds.position.y = 0.0
	bounds.size.x = 0.0
	bounds.size.y = 0.0
	
	if(points.size() >= 2):
		
		draw_set_transform_matrix(global_transform.affine_inverse())
		var a
		var b
		var c
		var s = points.size()
		if(emitting == false):
			s -= 1
		for i in range(s):
			a = _get_point(i)
			b = _get_point(i+1)
			draw_section(a.position,a.data,b.position,b.data)
	
	VisualServer.canvas_item_set_custom_rect(get_canvas_item(),true,bounds)
