@tool
extends Node

## An autoload which allows for interrogating locally defined (i.e. script
## with `class_name`) classes for metadata, similar to ClassDB.

#region Constants

## A specialized tree node for representing the inheritance tree of local classes.
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

	func get_flat_data(field: String, recursive := true, result: Dictionary[String, Variant] = {} as Dictionary[String, Variant]) -> Dictionary[String, Variant]:
		if field in content:
			result[name] = content[field]

		if recursive:
			for child: LocalTreeItem in children:
				child.get_flat_data(field, true, result)
		else:
			for child: LocalTreeItem in children:
				if field in child.content:
					result[child.name] = child.content[field]

		return result

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
			var instance := LocalTreeItem.new(input as String)
			instance.parent = self
			children.append(instance)
			return instance
		else:
			return null

	func print_tree(depth: int = 0) -> String:
		var str := ""
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
				var found_child := child.find_in_tree(child_name)
				if found_child:
					return found_child
			
		return null

#endregion
#region Private Variables

## The tree of local classes, starting at [Object]. Classes which are built-in
## but are ancestors of a local class are represented as nodes unerneath [Object],
## regardless of their real representation.
static var _class_tree: LocalTreeItem
## A quick dictionary cache of local classes mapped to their icon paths if defined.
static var _icon_map: Dictionary[String, String]

#endregion

#region Public Methods

static func get_class_tree_for(klass: String) -> LocalTreeItem:
	refresh_tree()
	return _class_tree.find_in_tree(klass)

## Given a class name, return the icon path if it exists in the
## [member _icon_path_map].
static func get_icon_path(klass: String) -> String:
	refresh_tree()
	
	return _icon_map.get(klass)

static func global_class_exists(klass: String) -> bool:
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if String(entry["base"]) == klass:
			return true

	return false

## Load all local (amusingly enough called "global") classes into the [member _clas_tree]
## and populate the [member _icon_path_map].
static func refresh_tree() -> void:
	var class_list := ProjectSettings.get_global_class_list()
	if _class_tree == null:
		_class_tree = LocalTreeItem.new("Object")

	for entry: Dictionary in class_list:
		if _class_tree.find_in_tree(entry["class"]): # already added!
			continue

		var parent := entry["base"] as String
		var parent_tree_node := _class_tree.find_in_tree(parent)

		if parent_tree_node == null: # parent does not yet exist
			var local_entry_idx := class_list.find_custom(func(e: Dictionary) -> bool: return e["class"] == parent)
			var local_entry: Variant

			if local_entry_idx == -1: # must be built-in
				parent_tree_node = _class_tree.add_child(parent)
			else: # must be local
				local_entry = class_list[local_entry_idx]
				# we must reconstruct all parents
				var intermediaries_to_add := []
				var i := 0

				while local_entry_idx != -1 or i < 500:
					i += 1
					local_entry = class_list[local_entry_idx]
					intermediaries_to_add.push_front(local_entry)

					parent_tree_node = _class_tree.find_in_tree(local_entry["base"])
					if parent_tree_node != null: # found an anchor already existing
						break

					if local_entry in intermediaries_to_add:
						break

					var new_parent := local_entry["base"] as String

					local_entry_idx = class_list.find_custom(func(e: Dictionary) -> bool: return e["class"] == new_parent)

				if i == 500:
					print("infinite loop")

				for intermediary: Variant in intermediaries_to_add:
					if parent_tree_node == null:
						parent_tree_node = _class_tree.add_child(intermediary["base"]) # global root
					if intermediary["icon"]:
						_icon_map[intermediary["class"]] = intermediary["icon"]
					parent_tree_node = parent_tree_node.add_child(intermediary)

		if entry["icon"]:
			_icon_map[entry["class"]] = entry["icon"]
		parent_tree_node.add_child(entry)

#endregion
