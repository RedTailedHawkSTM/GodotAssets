extends Node

#mouse controls TODO should move to a seperate script
var mouse_last = null;
var has_focus = false
var capture_mouse = false

func _init():
	var center = OS.get_window_size()/2
	Input.warp_mouse_position(center)
	
func _ready():
	has_focus = true
	grab_mouse()

func grab_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	capture_mouse = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	capture_mouse = false

func toggle_mouse():
	if(Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE):
		grab_mouse()
	else:
		release_mouse()
	
func _input(event):
	if(event is InputEventKey and event.scancode == KEY_ESCAPE and event.pressed):
		toggle_mouse()

func _notification(what):
	if(what == MainLoop.NOTIFICATION_WM_FOCUS_OUT):
		has_focus = false
	if(what == MainLoop.NOTIFICATION_WM_FOCUS_IN):
		has_focus = true
		
func is_captured():
	return has_focus == true && capture_mouse == true
	
func get_delta():
	var mouse_delta = Vector2()
	if(is_captured()):
		var viewport = get_viewport()
		var center = viewport.get_size()/2
		
		mouse_delta = viewport.get_mouse_position() - center
		
		if(mouse_delta.length_squared() < 4):
			mouse_delta = Vector2()
		
		Input.warp_mouse_position(center)
	return mouse_delta
