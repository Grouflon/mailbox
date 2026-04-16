extends Node3D
class_name Box

enum State
{
	NONE,
	LOCKED,
	UNLOCKING,
	UNLOCKED,
	OPENING,
	CLOSING,
	OPENED
}

@export var animation_player: AnimationPlayer
@export var content_parent: Node3D
@export var unlock_path: Path3D
@export var unlock_area: Area3D

@export var unlocking_touch_index: int = -1

var unlock_ratio: float = 0.0

var current_state: State = State.NONE

func _ready():
	animation_player.animation_finished.connect(on_animation_finished)

func _process(dt: float):
	
	match current_state:
		State.LOCKED:
			
			if GameInput.touch_stack.size() == 0: return
			var touch: = GameInput.touch_stack[0]
			
			var l: = unlock_path.curve.get_baked_length()
			var path_begin: = unlock_path.global_transform * unlock_path.curve.get_point_position(0);
			var path_end: = unlock_path.global_transform * unlock_path.curve.get_point_position(unlock_path.curve.point_count-1);
			#unlock_area.position = unlock_path.curve.sample_baked(l * unlock_ratio)
				
			var camera: Camera3D = get_viewport().get_camera_3d()
			var ray_origin: = camera.project_ray_origin(touch.position)
			var ray_normal: = camera.project_ray_normal(touch.position) * 100
			
			DebugDraw3D.draw_line(path_begin, path_end)
			
			var result: = Tools.line_line_shortest_route(ray_origin, ray_origin + ray_normal, path_begin, path_end)
			if !result.success: return # what to do?
			
			DebugDraw3D.draw_sphere(result.result_B)
				
			#if unlocking_touch_index < 0:
				#if touch.just_pressed:
					#touch.position	
			
			
	

func set_state(state: State):
	if current_state == state: return
	
	match current_state:
		_:
			animation_player.stop(true);
		
	current_state = state
	
	match current_state:
		State.LOCKED:
			unlock_ratio = 0.0
			animation_player.play(&"locked")
			
		State.UNLOCKING:
			unlock_ratio = 0.05
			animation_player.play(&"locked")
			
		State.UNLOCKED:
			animation_player.play(&"unlocked")
			
		State.OPENING:
			animation_player.play(&"open", -1, 2.0)
			
		State.CLOSING:
			animation_player.play(&"open", -1, -2.0, true)
			
		State.OPENED:
			animation_player.play(&"opened", -1, 2.0)
			
		pass

func set_locked():
	set_state(State.LOCKED)
	pass

func set_unlocked():
	set_state(State.UNLOCKED)
	
func set_opened():
	set_state(State.OPENED)
	
func open():
	if current_state == State.OPENED: return
	set_state(State.OPENING)
	
func close():
	if current_state <= State.UNLOCKED: return
	set_state(State.CLOSING)

func on_animation_finished(anim_name: StringName):
	match current_state:
		State.OPENING:
			set_state(State.OPENED)
		State.CLOSING:
			set_state(State.UNLOCKED)
