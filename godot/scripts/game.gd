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
@export var viewer: ObjectViewer
@export var viewing_parent: Node3D

# Game state
enum GameState
{
	NONE,
	MAILBOX,
	PARCEL,
	OBJECT,
}
var current_state: GameState = GameState.NONE
var current_item: Item
var transition_tween: Tween = null

var mailbox_base_transform: Transform3D

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
	
	mailbox_base_transform = mailbox.transform
	
	# remove child of viewing_parent. They are useful to tune transforms in editor but they may fuck up raycasts and stuff runtime
	for n in viewing_parent.get_children():
		n.queue_free()
	
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
			if transition_tween != null:
				transition_tween.kill()
				transition_tween = null
			
		GameState.PARCEL:
			box.visible = false
			viewer.target = null
			box.set_locked()
			if transition_tween != null:
				transition_tween.kill()
				transition_tween = null
			
		GameState.OBJECT:
			# hack until objects are handled generically
			current_item.reparent(box.content_parent, false)
			current_item.transform = Transform3D.IDENTITY
			
			current_item = null
			viewer.target = null
	
	current_state = state
	
	# Enter
	match current_state:
		GameState.MAILBOX:
			mailbox.visible = true
			mailbox.set_closed()
			
			mailbox.transform = mailbox_base_transform
			
			box.visible = true
			box.reparent(mailbox.content_parent, false)
			box.transform = Transform3D.IDENTITY
			box.set_locked()
			
		GameState.PARCEL:
			box.visible = true
			
			viewer.target = box
			
			box.reparent(world, false)
			box.transform = viewing_parent.transform * box.get_base_viewing_transform()
			box.set_locked()
			
		GameState.OBJECT:
			assert(current_item != null)
			
			current_item.reparent(world, false)
			current_item.transform = viewing_parent.transform * current_item.get_base_viewing_transform()
			
			viewer.target = current_item
	
func get_area_under_screen_position(pos: Vector2, collision_mask: int = 0xFFFFFFFF) -> Area3D:
	var ray_origin: = camera.project_ray_origin(pos)
	var ray_normal: = camera.project_ray_normal(pos)
	var query: = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 100.0, collision_mask)
	query.collide_with_areas = true
	var result: = get_world_3d().direct_space_state.intersect_ray(query)
	return result.get("collider") as Area3D
	
func _process(delta: float) -> void:
	
	# Update state
	match current_state:
		GameState.MAILBOX:
			if transition_tween != null: return
			
			if GameInput.has_just_tapped:
				var area = get_area_under_screen_position(GameInput.tap_position, 0b0000_0011) # mailbox + box
				if area != null: 
					var hit_box: = Tools.find_parent_by_type(area, "Box") as Box
					if hit_box != null:
						
						# Mailbox to parcel transition
						var mailbox_target_transform: = mailbox.transform\
							.translated(Vector3(0,0,-200))\
							.scaled(Vector3(0.0001,0.0001,0.0001))
							
						transition_tween = get_tree().create_tween()
						transition_tween.tween_property(mailbox, "transform", mailbox_target_transform, 0.4)\
							.set_ease(Tween.EASE_IN)\
							.set_trans(Tween.TRANS_BACK)
						
						box.reparent(world)
						
						transition_tween.parallel().tween_property(box, "transform", viewing_parent.transform * box.get_base_viewing_transform(), 0.7)\
							.set_ease(Tween.EASE_OUT)\
							.set_trans(Tween.TRANS_ELASTIC)\
							.set_delay(0.4)
							
						transition_tween.tween_callback(on_transition_over)
						return
						
					else:
						var hit_mailbox: = Tools.find_parent_by_type(area, "Mailbox") as Mailbox
						if hit_mailbox != null:
							if hit_mailbox.opened:
								hit_mailbox.close()
							else:
								hit_mailbox.open()
						
							
		GameState.PARCEL:
			if transition_tween != null: return
			
			if box.unlocking_touch_index < 0:
				viewer.update(delta, GameInput.is_dragging, GameInput.drag_delta)
			
			if GameInput.has_just_tapped:
				if box.current_state == Box.State.OPENED:
					var item_area = get_area_under_screen_position(GameInput.tap_position, 0b0000_0100)
					if item_area != null:
						var item = Tools.find_parent_by_type(item_area, "Item") as Item
						if item == null: return
						current_item = item
						
						# Parcel to object transition
						var parcel_target_transform: = box.transform\
							.translated(mailbox.position - Vector3(0,0,-200))\
							.scaled(Vector3(0.0001,0.0001,0.0001))
							
						transition_tween = get_tree().create_tween()
						transition_tween.tween_property(box, "transform", parcel_target_transform, 0.4)\
							.set_ease(Tween.EASE_IN)\
							.set_trans(Tween.TRANS_BACK)
						
						current_item.reparent(world)
						transition_tween.parallel().tween_property(current_item, "transform", viewing_parent.transform * current_item.get_base_viewing_transform(), 1)\
							.set_ease(Tween.EASE_OUT)\
							.set_trans(Tween.TRANS_ELASTIC)\
							.set_delay(0.3)
							
						transition_tween.tween_callback(on_transition_over)
						return
				
				var box_area = get_area_under_screen_position(GameInput.tap_position, 0b0000_0001)
				if box_area != null: 
					var hit_box: = Tools.find_parent_by_type(box_area, "Box") as Box
					if hit_box != null:
						if hit_box.current_state == Box.State.OPENED:
							hit_box.close()
						elif hit_box.current_state == Box.State.UNLOCKED:
							hit_box.open()
							
		GameState.OBJECT:
			viewer.update(delta, GameInput.is_dragging, GameInput.drag_delta)
			

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

func on_transition_over():
	match current_state:
		GameState.MAILBOX:
			set_state(GameState.PARCEL)
		
		GameState.PARCEL:
			set_state(GameState.OBJECT)
	
