@tool
extends ConfirmationDialog

@export var item_list: ItemList

@export var target_node: Node:
	set(val):
		if target_node == val:
			return

		target_node = val
		_refresh_items()

signal on_signals_selected(signals: Array[String])

func select_items_by_text(texts: Array[String]) -> void:
	if !is_instance_valid(target_node):
		return

	var idx := 0
	for sig in target_node.get_signal_list():
		if len(sig["args"]) > 0:
			continue

		if sig["name"] in texts:
			item_list.select(idx, false)
		idx += 1

func _on_confirmed() -> void:
	if !is_instance_valid(target_node):
		on_signals_selected.emit([] as Array[String])
		return

	var indices = item_list.get_selected_items()
	var signal_names: Array[String] = []
	for id in indices:
		var txt = item_list.get_item_text(id)
		signal_names.append(txt)
	
	on_signals_selected.emit(signal_names)

func _ready() -> void:
	add_button("Unset", false, "unset")

func _refresh_items() -> void:
	item_list.clear()

	if not target_node:
		return
	
	title = "Select Signals From %s" % target_node.name

	for sig in target_node.get_signal_list():
		if len(sig["args"]) > 0:
			continue

		item_list.add_item(sig["name"])

func _on_canceled() -> void:
	pass # Replace with function body.

func _on_custom_action(action: StringName) -> void:
	on_signals_selected.emit([] as Array[String])
	queue_free()
