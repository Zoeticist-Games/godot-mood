@tool
extends EditorScript

# this will fail if the plugin isn't enabled.
func _run():
	var class_paths := Mood.LocalClassFunctions.get_class_tree_for("MoodCondition").get_flat_data("path")
	Mood.Editors.registered_editors = {} as Dictionary[String, PackedScene]
	for klass: String in class_paths:
		var script_path: String = class_paths[klass]
		var klass_ref := load(script_path)
		if "Editor" in klass_ref and  klass not in Mood.Editors.registered_editors:
			print("Adding Editor for ", klass)
			Mood.Editors.register_type(klass, klass_ref.get("Editor"))
		else:
			print("No editor for ", klass)
