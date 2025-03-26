@tool
extends ConfirmationDialog

@export var item_list: ItemList
@export var action_search: LineEdit
@export var custom_action_input: LineEdit
@export var selected_items: Array[StringName]

signal on_actions_selected(actions: Array[StringName])

func select_items_by_text(texts: Array[StringName]) -> void:
	self.selected_items = texts
	_refresh_items()

func _on_confirmed() -> void:
	var indices = item_list.get_selected_items()
	var actions := [] as Array[StringName]

	for id in indices:
		var txt = item_list.get_item_text(id)
		actions.append(StringName(txt))

	on_actions_selected.emit(actions)

func _ready() -> void:
	add_button("Unset", false, "unset")

func _refresh_items() -> void:
	item_list.clear()
	InputMap.load_from_project_settings() # reload to pick custom actions.
	
	var filter: String = ""
	if is_instance_valid(action_search):
		filter = action_search.text

	var needs_adding := selected_items.duplicate()

	for action: StringName in InputMap.get_actions():
		if len(filter) > 0 and not action.begins_with(filter):
			continue

		var idx := item_list.add_item(String(action))

		if String(action) in selected_items:
			item_list.select(idx, false)
			needs_adding.erase(action)

	# always add selected actions at the end if they were not added.
	for remainder: StringName in needs_adding:
		var idx := item_list.add_item(String(remainder))
		item_list.select(idx, false)
	
	item_list.sort_items_by_text()

func _on_canceled() -> void:
	pass # Replace with function body.

func _on_custom_action(action: StringName) -> void:
	on_actions_selected.emit([] as Array[StringName])
	queue_free()

func _on_action_search_text_changed(_new_text: String) -> void:
	_refresh_items()

func _on_item_list_multi_selected(index: int, selected: bool) -> void:
	var action: String = item_list.get_item_text(index)

	var sn_action := StringName(action)

	if sn_action in selected_items and not selected:
		selected_items.erase(sn_action)
	elif sn_action not in selected_items and selected:
		selected_items.append(sn_action)


func _on_add_action_button_pressed() -> void:
	if is_instance_valid(custom_action_input):
		var sn_action := StringName(custom_action_input.text)
		if sn_action not in selected_items:
			selected_items.append(sn_action)
			_refresh_items()
			custom_action_input.text = ""
