@tool
extends HBoxContainer

#region Constants

# TODO: remove copy-paste
const COLOR_SELECTED := Color(0x55F3E3FF)
const COLOR_DESELECTED := Color(0x7F7F7FFF)

#endregion

#region Public Variables

@export var target_mood_label: Label
@export var save_to_tree_button: Button
@export var condition_container: Container

@export var from_mood: Mood
@export var transition: MoodTransition:
	set(val):
		if transition == val:
			return

		if _editor:
			_editor.queue_free()

		transition = val

		if is_instance_valid(target_mood_label) and transition.to_mood != null:
			target_mood_label.text = transition.to_mood.name

		if is_instance_valid(transition.get_parent()): # this transition already exists
			target_mood_label.add_theme_color_override("font_color", COLOR_SELECTED)
			save_to_tree_button.hide()
		else:
			target_mood_label.add_theme_color_override("font_color", COLOR_DESELECTED)
			save_to_tree_button.show()

		_editor = Mood.Editors.get_editor(transition)
		_editor.condition = transition
		condition_container.add_child(_editor)

## put your @exports here.
##
## then put your var foo, var bar (variables you might touch from elsewhere) here.
#endregion

#region Private Variables
var _editor: CanvasItem
## put variables you won't touch here, prefixed by an underscore (`var _foo`).
#endregion

#region Signals
## put your signal definitions here.
#endregion

#region Overrides
## virtual override methods here, e.g.
## _init, _ready
## _process, _physics_process
## _enter_tree, _exit_tree
#endregion

#region Public Methods
## put your methods here.
#endregion

#region Private Methods
## put methods you use only internally here, prefixed with an underscore.
#endregion

#region Signal Hooks
## put methods used as responses to signals here.
## we don't put #endregion here because this is the last block and when we use the
## UI to add signal hooks they always get concatenated at the end of the file.

func _on_save_to_tree_pressed() -> void:
	var name := transition.name
	from_mood.add_child(transition)
	var owner := from_mood.owner
	transition.owner = owner
	transition.name = name # re-assigning necessary
	Mood.Recursion.recurse(transition, (func(n): n.owner = owner), [], true)
	transition.notify_property_list_changed()
	#transition.owner = from_mood.owner
	save_to_tree_button.hide()
