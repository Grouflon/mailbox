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

var current_state: State = State.NONE
var opened: bool = false

func set_locked():
	pass

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
