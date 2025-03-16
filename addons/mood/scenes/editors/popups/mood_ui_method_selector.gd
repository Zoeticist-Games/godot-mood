@tool
extends ConfirmationDialog

#region Public Variables

@export var item_list: ItemList
@export var target_node: Node:
	set(val):
		if target_node == val:
			return

		target_node = val
		_refresh_items()


const VALID_TYPES = [
	TYPE_STRING, TYPE_STRING_NAME, TYPE_INT, TYPE_FLOAT, TYPE_BOOL
]

#endregion

#region Signals

signal on_method_selected(method: String)

#endregion

#region Overrides

func _ready() -> void:
	add_button("Unset", false, "unset")

func _on_confirmed() -> void:
	if !is_instance_valid(target_node):
		on_method_selected.emit("")
		return

	for id in item_list.get_selected_items():
		var txt = item_list.get_item_text(id)
		on_method_selected.emit(txt)
		break

func _on_canceled() -> void:
	pass # Replace with function body.

func _on_custom_action(action: StringName) -> void:
	match action:
		"unset":
			on_method_selected.emit("")
			hide()

#endregion

#region Public Methods

func select_item_by_text(text: String) -> void:
	if !is_instance_valid(target_node):
		return

	var idx := 0
	for sig in target_node.get_method_list():
		if len(sig["args"]) - len(sig["default_args"]) != 0:
			continue

		if sig["name"] == text:
			item_list.select(idx)
			break

		idx += 1

#endregion

#region Private Methods

func _refresh_items() -> void:
	item_list.clear()

	if not target_node:
		return
	
	title = "Select Methods From %s" % target_node.name
	
	var methods := target_node.get_method_list()
	methods.sort_custom(func(l, r): return l["name"] < r["name"])
	
	var filter = %MethodSearch.text

	for meth in methods:
		if len(meth["args"]) - len(meth["default_args"]) > 0:
			continue

		if meth["return"]["type"] not in VALID_TYPES:
			continue
		
		if len(filter) > 0 and not meth["name"].begins_with(filter):
			continue

		item_list.add_item(meth["name"])

#endregion

#region Signal Hooks

func _on_text_edit_text_changed() -> void:
	_refresh_items()
