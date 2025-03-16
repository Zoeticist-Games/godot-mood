@tool
extends EditorScript

class LocalTreeItem:
	var parent: LocalTreeItem
	var children: Array[LocalTreeItem]
	var name: String
	var content: Variant

	func _init(_name: String, _content: Variant = null) -> void:
		self.name = _name
		self.content = _content
		
	func set_content(_content: Variant) -> void:
		self.content = _content

	func add_child(input: Variant) -> LocalTreeItem:
		if input is LocalTreeItem:
			children.append(input)
			input.parent = self
			return input
		elif input is Dictionary:
			var instance := LocalTreeItem.new(input["class"], input)
			instance.parent = self
			children.append(instance)
			return instance
		elif input is String or input is StringName:
			var instance := LocalTreeItem.new(input)
			instance.parent = self
			children.append(instance)
			return instance
		else:
			return null

	func print_tree(depth: int = 0) -> String:
		var str = ""
		if depth > 0:
			for i in range(depth):
				str += "  "
			str += "* "
		str += name
		str += "\n"
		for child in children:
			str += child.print_tree(depth + 1)

		return str

	# depth-first search
	func find_in_tree(child_name: String) -> LocalTreeItem:
		for child in children:
			if child.name == child_name:
				return child
			else:
				var found_child = child.find_in_tree(child_name)
				if found_child:
					return found_child
			
		return null
	
func _run():
	var class_list := ProjectSettings.get_global_class_list()
	var class_tree := LocalTreeItem.new("Object")

	for entry in ProjectSettings.get_global_class_list():
		if class_tree.find_in_tree(entry["class"]): # already added!
			continue

		var parent := entry["base"] as StringName
		var parent_tree_node = class_tree.find_in_tree(parent)

		if parent_tree_node == null: # parent does not yet exist
			var local_entry_idx = class_list.find_custom(func(e): return e["class"] == parent)
			var local_entry

			if local_entry_idx == -1: # must be built-in
				parent_tree_node = class_tree.add_child(parent)
			else: # must be local
				local_entry = class_list[local_entry_idx]
				# we must reconstruct all parents
				var intermediaries_to_add = []
				var i = 0

				while local_entry_idx != -1 or i < 500:
					i += 1
					local_entry = class_list[local_entry_idx]
					intermediaries_to_add.push_front(local_entry)

					parent_tree_node = class_tree.find_in_tree(local_entry["base"])
					if parent_tree_node != null: # found an anchor already existing
						break

					if local_entry in intermediaries_to_add:
						break

					var new_parent = local_entry["base"] as StringName

					local_entry_idx = class_list.find_custom(func(e): return e["class"] == new_parent)

				if i == 500:
					print("infinite loop")

				for intermediary in intermediaries_to_add:
					if parent_tree_node == null:
						parent_tree_node = class_tree.add_child(intermediary["base"]) # global root
					parent_tree_node = parent_tree_node.add_child(intermediary)

		parent_tree_node.add_child(entry)
		
	print(class_tree.print_tree())
