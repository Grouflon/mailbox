extends Node
class_name GameInput

#const TOUCH_TIME_THRESHOLD = 0.05

var is_dragging: bool
var drag_delta: Vector2
var is_just_touched: bool

var drag_duration: float
var is_touch_down: bool
var mouse_position: Vector2
var last_mouse_position: Vector2

func _input(event):
	if event is InputEventScreenTouch:
		pass
	elif event is InputEventMouse && (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		pass
	else:
		return
		
	mouse_position = event.position
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	is_just_touched = false
	
	var touch_just_pressed = Input.is_action_just_pressed(&"touch") # This works for mouse and touch apparently
	var touch_just_released = Input.is_action_just_released(&"touch") 
	
	if is_touch_down:
		drag_duration += delta
		drag_delta = mouse_position - last_mouse_position
		if last_mouse_position != mouse_position:
			is_dragging = true
		
		#if drag_duration >= TOUCH_TIME_THRESHOLD:
			#print("drog")
			#is_dragging = true
	
	if touch_just_pressed:
		drag_duration = 0
		is_touch_down = true
		
	if touch_just_released:
		if not is_dragging:
			is_just_touched = true
		is_touch_down = false
		is_dragging = false
		drag_delta = Vector2(0,0)
		
	last_mouse_position = mouse_position
	pass
