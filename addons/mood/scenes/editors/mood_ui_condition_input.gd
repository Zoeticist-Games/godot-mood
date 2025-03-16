@tool
extends VBoxContainer

@export var item_container: VBoxContainer
@export var action_list_container: HBoxContainer

@export var condition: MoodConditionInput:
	set(val):
		if condition == val:
			return

		if condition:
			if condition.property_list_changed.is_connected(_refresh_selection):
				condition.property_list_changed.disconnect(_refresh_selection)

		condition = val

		if condition:
			condition.property_list_changed.connect(_refresh_selection)
			_refresh_selection()

var _action_selector

const ActionSelectorScene: PackedScene = preload("res://addons/mood/scenes/editors/popups/mood_ui_action_selector.tscn")

#region Private Functions

#endregion

#region action Hooks

func _on_popup_button_pressed() -> void:
	print("pressed")
	if _action_selector:
		_action_selector.queue_free()

	_action_selector = ActionSelectorScene.instantiate()
	ActionSelectorScene
	_action_selector.select_items_by_text(condition.actions)
	_action_selector.on_actions_selected.connect(_update_action_list)
	_action_selector.popup_exclusive(EditorInterface.get_editor_main_screen())

func _update_action_list(actions: Array[StringName]) -> void:
	print("updating")
	condition.actions = actions
	condition.notify_property_list_changed()
	_action_selector.queue_free()
	_action_selector = null
	_refresh_selection()

func _refresh_selection() -> void:
	for child in item_container.get_children():
		child.free()

	if len(condition.actions) > 0:
		for action: StringName in condition.actions:
			var lbl := Label.new()
			lbl.text = String(action)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_container.add_child(lbl)
		action_list_container.show()
	else:
		action_list_container.hide()
