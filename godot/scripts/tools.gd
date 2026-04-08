extends Node
class_name _Tools


func find_parent_by_type(node: Node, clss_name: String, recursive: bool = true) -> Node:
	var parent: = node.get_parent()
	if parent != null:
		if parent.is_class(clss_name) || get_class_name(parent) == clss_name:
			return parent
		if recursive:
			return find_parent_by_type(parent, clss_name, true)
	return null

func get_class_name(object: Object) -> String:
	if not object:
		return type_string(TYPE_NIL)
	var script: Script = object.get_script()
	var object_name := script.get_global_name() as String if script else object.get_class()
	if object_name.is_empty():
		var script_path := script.resource_path
		if script_path.is_empty():
			push_error("Cannot get class name from inner classes")
		return script_path
	return object_name
