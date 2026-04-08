extends Node3D
class_name Mailbox

@export var animation_player: AnimationPlayer
@export var content_parent: Node3D
@export var closed_collider: CollisionShape3D
@export var opened_collider: CollisionShape3D

var opened: bool = false

func set_closed():
	animation_player.play(&"closed")
	opened = false;
	closed_collider.disabled = false
	opened_collider.disabled = true
	pass
	
func set_opened():
	animation_player.play(&"opened")
	opened = true;
	closed_collider.disabled = true
	opened_collider.disabled = false
	pass
	
func open():
	animation_player.play(&"open", -1, 2.0)
	opened = true;
	closed_collider.disabled = true
	opened_collider.disabled = false
	pass
	
func close():
	animation_player.play(&"open", -1, -2.0, true)
	opened = false;
	closed_collider.disabled = false
	opened_collider.disabled = true
	pass
