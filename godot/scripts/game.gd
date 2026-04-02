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

const ANDROID_PLUGIN_NAME: = "MailboxAndroidPlugin"

var android_plugin: Object;

var pending_click: bool
var pending_click_position: Vector2

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
	
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		pass
	elif event is InputEventMouse && (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		pass
	else:
		return
	if not event.is_pressed():
		return
	
	pending_click_position = event.position
	pending_click = true
	
func _physics_process(delta: float) -> void:
	
	if pending_click:
		var ray_origin: = camera.project_ray_origin(pending_click_position)
		var ray_normal: = camera.project_ray_normal(pending_click_position)
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
			var box: = collider.get_parent() as Box
			if box != null:
				if box.opened:
					box.close()
				else:
					box.open()
	
	pending_click = false
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
