extends Node3D

@export var notification_button: BaseButton;
@export var permissions_button: BaseButton;
@export var app_page_button: BaseButton;
@export var hello_world_button: BaseButton;
@export var text: Label;

@export var delay_label: Label;
@export var delay_slider: HSlider;
@export var box: Box;
@export var camera: Camera3D;
@export var input: GameInput;
@export var drag_speed: Vector2 = Vector2(1,1);
@export var drag_smooth: float = 0.05;

var smoothed_drag_input: Vector2

const ANDROID_PLUGIN_NAME: = "MailboxAndroidPlugin"

var android_plugin: Object;

#var pending_click: bool
#var pending_click_position: Vector2

func _ready() -> void:
	if Engine.has_singleton(ANDROID_PLUGIN_NAME):
		android_plugin = Engine.get_singleton(ANDROID_PLUGIN_NAME)
		android_plugin.connect("post_notifications_permission_result_received", on_post_notifications_permission_result_received)
	
	if android_plugin == null:
		notification_button.disabled = true;
		permissions_button.disabled = true;
		app_page_button.disabled = true;
		hello_world_button.disabled = true;
		delay_slider.editable = false;
	
	text.text = "uninitialized"
	notification_button.pressed.connect(on_notification_button_pressed)
	permissions_button.pressed.connect(on_permissions_button_pressed)
	app_page_button.pressed.connect(on_app_page_button_pressed)
	hello_world_button.pressed.connect(on_hello_world_button_pressed)
	
	update_delay_label()
	delay_slider.value_changed.connect(on_delay_value_changed)
	
	text.text = "initialiazing"
	box.set_closed()
	
#func _input(event: InputEvent) -> void:
	#return
	#if event is InputEventScreenDrag:
		#print(event as InputEventScreenDrag)
		#return
	#
	#if event is InputEventScreenTouch:
		#pass
	#elif event is InputEventMouse && (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		#pass
	#else:
		#return
		#
	##print("p:", event.position, event.is_pressed(), event.is_released())
		#
	#event.is_released()
	#if not event.is_pressed():
		#return
	#
	#pending_click_position = event.position
	#pending_click = true
	
func _process(delta: float) -> void:
	smoothed_drag_input = lerp(smoothed_drag_input, Vector2.ZERO, drag_smooth)
	if input.is_touch_down:
		smoothed_drag_input = input.drag_delta
		
	var x_axis = camera.get_camera_transform().basis.y
	var y_axis = camera.get_camera_transform().basis.x
	box.rotate(x_axis, smoothed_drag_input.x * drag_speed.x)
	box.rotate(y_axis, smoothed_drag_input.y * drag_speed.y)
		#box.rotation.z = 0
		
		#var box_basis = box.get_global_transform_interpolated().basis
		#var front_axis = box_basis.z.normalized()
		#var left_axis = box_basis.x.normalized()
		#var up_axis = box_basis.y.normalized()
		#left_axis.y = 0
		#left_axis = left_axis.normalized()
		#print(left_axis)
		#up_axis = front_axis.cross(left_axis)
		#left_axis = up_axis.cross(front_axis)
			
		#DebugDraw3D.draw_line(box.position, box.position + left_axis * 3, Color.RED)
		#DebugDraw3D.draw_line(box.position, box.position + up_axis * 3, Color.GREEN)
		#DebugDraw3D.draw_line(box.position, box.position + front_axis * 3, Color.BLUE)
		#box.quaternion = Quaternion(Basis(left_axis, up_axis, front_axis).orthonormalized())
		
		#var box_basis = box.get_global_transform_interpolated().basis
		#var right_axis = box_basis.x
		#right_axis.y = 0
		#right_axis = right_axis.normalized()
		#var up_axis = box_basis.z.cross(right_axis)
		#right_axis = up_axis.cross(box_basis.z)
		
		
		
		#box.quaternion = Quaternion(Basis(right_axis, up_axis, box_basis.x).orthonormalized())
		#box.look_at(box.position + box.get_global_transform_interpolated().basis.z, Vector3(0,1,0))
	
	if input.is_just_touched:
		var ray_origin: = camera.project_ray_origin(input.mouse_position)
		var ray_normal: = camera.project_ray_normal(input.mouse_position)
		#print("o:", ray_origin, "n:", ray_normal)
		
		var query: = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 100.0)
		query.collide_with_areas = true
		var result: = get_world_3d().direct_space_state.intersect_ray(query)
		#print("r:", result)
		#
		#if result:
			#print("Hit at point: ", result.position)
			
		var collider = result.get("collider") as Area3D
		if collider != null: 
			var hit_box: = collider.get_parent() as Box
			if hit_box != null:
				if hit_box.opened:
					hit_box.close()
				else:
					hit_box.open()
	
	pass

func on_notification_button_pressed() -> void:
	android_plugin.test_notifications()
	pass

func on_permissions_button_pressed() -> void:
	var result: bool = android_plugin.request_notifications_permission()
	print(result)
	pass

func on_app_page_button_pressed() -> void:
	android_plugin.open_app_info_settings()
	pass
	
func on_delay_value_changed(value: float):
	update_delay_label()
	pass
	
func update_delay_label():
	delay_label.text = "Delay: %d" % delay_slider.value
	
func on_hello_world_button_pressed():
	android_plugin.hello_world()
	pass
	
func on_post_notifications_permission_result_received(result: bool):
	print("Permission: %s" % result)
	pass
