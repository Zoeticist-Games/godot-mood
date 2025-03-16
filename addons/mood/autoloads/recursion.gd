@tool
extends Node

static func __get_fn(t: Object, m: Variant) -> Callable:
	if m is Callable:
		return m
	if m is String and t.has_method(m):
		return Callable(t, m)

	return func(): pass
	
static func __execute_fn(fn: Callable, varargs: Array, deferred: bool) -> void:
	if fn == null:
		return

	if deferred:
		# @TODO: is the bindv reverse correct or what?
		fn.bindv(varargs).call_deferred()
	else:
		fn.callv(varargs)

## Find a parent of a specific class type.
static func find_parent_recursively(node: Node, parent_class: Variant) -> Node:
	var parent = node.get_parent()

	while parent != null:
		if is_instance_of(parent, parent_class):
			return parent 
		parent = parent.get_parent()

	return null

## Run a method on a node and all its children recursively.
## @TODO: threading?
static func recurse(node: Node, method: Variant = null, varargs: Variant = [], deferred: bool = false, depth_first: bool = true) -> void:
	if varargs is not Array:
		varargs = [varargs]

	if deferred:
		varargs = varargs.reverse()

	# depth first = call on self, then call on children
	# breadth first = call on children, then call on self
	if depth_first:
		__execute_fn(__get_fn(node, method), varargs, deferred)

	for child in node.get_children():
		recurse(child, method, varargs, deferred, depth_first)

	if not depth_first:
		__execute_fn(__get_fn(node, method), varargs, deferred)
