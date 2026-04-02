extends Node

@export var notification_button: BaseButton;
@export var permissions_button: BaseButton;
@export var app_page_button: BaseButton;
@export var hello_world_button: BaseButton;
@export var text: Label;

@export var delay_label: Label;
@export var delay_slider: HSlider;

const ANDROID_PLUGIN_NAME: = "MailboxAndroidPlugin"

var android_plugin: Object;

func _ready() -> void:
	if Engine.has_singleton(ANDROID_PLUGIN_NAME):
		android_plugin = Engine.get_singleton(ANDROID_PLUGIN_NAME)
		android_plugin.connect("post_notifications_permission_result_received", on_post_notifications_permission_result_received)
	
	text.text = "uninitialized"
	#notification_button.disabled = true;
	#permissions_button.disabled = true;
	#app_page_button.disabled = true;
	notification_button.pressed.connect(on_notification_button_pressed)
	permissions_button.pressed.connect(on_permissions_button_pressed)
	app_page_button.pressed.connect(on_app_page_button_pressed)
	hello_world_button.pressed.connect(on_hello_world_button_pressed)
	
	update_delay_label()
	delay_slider.value_changed.connect(on_delay_value_changed)
	
	text.text = "initialiazing"
	

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
