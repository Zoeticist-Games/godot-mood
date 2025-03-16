@tool
class_name MoodConditionGroupInspectorPlugin extends EditorInspectorPlugin

var _condition_container: CanvasItem

func _can_handle(object: Object) -> bool:
	return Mood.Editors.has_editor(object)

func _parse_begin(object: Object) -> void:
	if is_instance_valid(_condition_container):
		_condition_container.queue_free()
		await _condition_container.tree_exited
		_condition_container = null

	var editor: CanvasItem = Mood.Editors.get_editor(object)

	if not editor:
		return

	# if it's a top-level property we should not remove it.
	if "remove_button" in editor and is_instance_valid(editor.remove_button):
		editor.remove_button.hide()

	# we can't go to ourselves!
	if "go_to_node_button" in editor and is_instance_valid(editor.go_to_node_button):
		editor.go_to_node_button.hide()

	_condition_container = editor
	add_custom_control(_condition_container)

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if object.has_method("should_skip_property"):
		return object.should_skip_property(name)
		
	return false
