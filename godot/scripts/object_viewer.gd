extends Node
class_name ObjectViewer

@export var target: Node3D
@export var camera: Camera3D
@export var drag_speed: Vector2 = Vector2(1,1);
@export var drag_smooth: float = 0.05;

var smoothed_drag_input: Vector2

func update(delta: float, is_dragging: bool, input: Vector2):
	if target == null: return
	if camera == null: return
	
	smoothed_drag_input = lerp(smoothed_drag_input, Vector2.ZERO, drag_smooth)
	if is_dragging:
		smoothed_drag_input = input
		
	var x_axis = camera.get_camera_transform().basis.y
	var y_axis = camera.get_camera_transform().basis.x
	target.rotate(x_axis, smoothed_drag_input.x * drag_speed.x)
	target.rotate(y_axis, smoothed_drag_input.y * drag_speed.y)

func reset():
	smoothed_drag_input = Vector2.ZERO
