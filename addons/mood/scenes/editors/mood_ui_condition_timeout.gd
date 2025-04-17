@tool
extends VBoxContainer

#region Constants
## put your const vars here.
#endregion

#region Public Variables

@export var validation_mode_button: OptionButton
@export var trigger_valid_button: CheckButton
@export var reset_on_reentry_button: CheckButton
@export var time_secs_input: LineEdit

@export var condition: MoodConditionTimeout:
	set(val):
		if condition == val:
			return
		
		condition = val
		
		_refresh_data()

#endregion

#region Private Variables
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

func _refresh_data() -> void:
	validation_mode_button.select(condition.validation_mode)
	trigger_valid_button.button_pressed = condition.trigger_sets_valid_to
	reset_on_reentry_button.button_pressed = condition.reset_on_reentry
	time_secs_input.text = str(condition.time_sec)

#endregion

#region Signal Hooks

func _on_time_secs_text_changed(new_text: String) -> void:
	var re = RegEx.new()
	re.compile(r'[^0-9.-]')
	new_text = re.sub(new_text, "", true)
	time_secs_input.text = new_text
	time_secs_input.caret_column = len(new_text)

	condition.time_sec = float(new_text)

func _on_reset_on_re_entry_pressed() -> void:
	condition.reset_on_reentry = reset_on_reentry_button.button_pressed

func _on_trigger_sets_valid_to_pressed() -> void:
	condition.trigger_sets_valid_to = trigger_valid_button.button_pressed

func _on_option_button_item_selected(index: int) -> void:
	pass
	#match index:
		#0:
			#condition.validation_mode = MoodConditionTimeout.ValidationMode.VALID_ON_ENTRY
		#1:
			#condition.validation_mode = MoodConditionTimeout.ValidationMode.VALID_ON_EXIT
		#2:
			#condition.validation_mode = MoodConditionTimeout.ValidationMode.VALID_ON_ENTRY_UNBOUND
		#3:
			#condition.validation_mode = MoodConditionTimeout.ValidationMode.VALID_ON_EXIT_UNBOUND
