extends Node3D

# UI
@export var notification_button: BaseButton;
@export var permissions_button: BaseButton;
@export var app_page_button: BaseButton;
@export var hello_world_button: BaseButton;
@export var reset_button: BaseButton;
@export var text: Label;
@export var delay_label: Label;
@export var delay_slider: HSlider;

@export var world: Node3D
@export var mailbox: Mailbox;
@export var box: Box;
@export var camera: Camera3D;
@export var input: GameInput;
@export var object_viewer: ObjectViewer
@export var parcel_viewing_parent: Node3D

# Game state
enum GameState
{
	NONE,
	MAILBOX,
	PARCEL,
	OBJECT,
}
var current_state: GameState = GameState.NONE
var current_object: Node3D;

# Android
const ANDROID_PLUGIN_NAME: = "MailboxAndroidPlugin"
var android_plugin: Object;

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
	reset_button.pressed.connect(on_reset_button_pressed)
	
	update_delay_label()
	delay_slider.value_changed.connect(on_delay_value_changed)
	
	text.text = "initialiazing"
	
	mailbox.visible = false
	box.visible = false
	set_state(GameState.MAILBOX)
	
func set_state(state: GameState):
	if state == current_state: return
	
	# Exit
	match current_state:
		GameState.MAILBOX:
			mailbox.visible = false
			box.visible = true
			
		GameState.PARCEL:
			box.visible = false
			object_viewer.target = null
			box.set_closed()
			
		GameState.OBJECT:
			# hack until objects are handled generically
			current_object.reparent(box.content_parent, false)
			current_object.transform = Transform3D.IDENTITY
			
			current_object = null
			object_viewer.target = null
	
	current_state = state
	
	# Enter
	match current_state:
		GameState.MAILBOX:
			mailbox.visible = true
			mailbox.set_closed()
			
			box.visible = true
			box.reparent(mailbox.content_parent, false)
			box.transform = Transform3D.IDENTITY
			box.set_closed()
			
		GameState.PARCEL:
			box.visible = true
			
			object_viewer.target = box
			
			box.reparent(world, false)
			box.transform = parcel_viewing_parent.transform
			box.set_closed()
			
		GameState.OBJECT:
			assert(current_object != null)
			
			current_object.reparent(world, false)
			current_object.transform = parcel_viewing_parent.transform
			
			object_viewer.target = current_object
	
func get_area_under_screen_position(position: Vector2, collision_mask: int = 0xFFFFFFFF) -> Area3D:
	var ray_origin: = camera.project_ray_origin(position)
	var ray_normal: = camera.project_ray_normal(position)
	var query: = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 100.0, collision_mask)
	query.collide_with_areas = true
	var result: = get_world_3d().direct_space_state.intersect_ray(query)
	return result.get("collider") as Area3D
	
func _process(delta: float) -> void:
	
	object_viewer.update(delta, input.is_dragging, input.drag_delta)
	
	# Update state
	match current_state:
		GameState.MAILBOX:
			if input.has_just_tapped:
				var area = get_area_under_screen_position(input.tap_position, 0b0000_0011) # mailbox + box
				if area != null: 
					var hit_box: = Tools.find_parent_by_type(area, "Box") as Box
					if hit_box != null:
						set_state(GameState.PARCEL)
					else:
						var hit_mailbox: = Tools.find_parent_by_type(area, "Mailbox") as Mailbox
						if hit_mailbox != null:
							if hit_mailbox.opened:
								hit_mailbox.close()
							else:
								hit_mailbox.open()
						
							
		GameState.PARCEL:
			if input.has_just_tapped:
				if box.opened:
					var object_area = get_area_under_screen_position(input.tap_position, 0b0000_0100)
					if object_area != null:
						current_object = object_area.get_parent_node_3d()
						set_state(GameState.OBJECT)
						return
				
				var box_area = get_area_under_screen_position(input.tap_position, 0b0000_0001)
				if box_area != null: 
					var hit_box: = Tools.find_parent_by_type(box_area, "Box") as Box
					if hit_box != null:
						if hit_box.opened:
							hit_box.close()
						else:
							hit_box.open()

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
	
func on_reset_button_pressed():
	set_state(GameState.NONE)
	set_state(GameState.MAILBOX)
	
func on_post_notifications_permission_result_received(result: bool):
	print("Permission: %s" % result)
	pass
