extends Node3D
class_name Box

@export var animation_player: AnimationPlayer

var opened: bool = false

func set_closed():
	animation_player.play(&"closed")
	opened = false;
	pass
	
func set_opened():
	animation_player.play(&"opened")
	opened = true;
	pass
	
func open():
	animation_player.play(&"open", -1, 2.0)
	opened = true;
	pass
	
func close():
	animation_player.play(&"open", -1, -2.0, true)
	opened = false;
	pass
