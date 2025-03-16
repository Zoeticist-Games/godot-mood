@tool
@icon("res://addons/mood/icons/mood_question.png")
class_name MoodCondition extends MoodChild

## A class which represents an evaluation of state validity, used to determine
## whether a [Mood] transition on the [MoodMachine] should occur. There are
## two "modes" of transition:[br]
## [br]
## 1. [b]via [Mood] Evaluation[/b]: When [member MoodMachine.evaluate_moods_directly]
##   is [code]true[/code], all nodes which are [MoodCondition] children of each
##   [Mood] are evaluated according to the parameters on the [MoodMachine], and
##   then a [Mood] is selected amongst all [Mood]s which themselves evaluate to
##   [code]true[/code] for [member Mood.is_valid].[br]
## 2. [b] via [MoodTransition] children[/b]: When [member MoodMachine.evaluate_moods_directly]
##   is [code]false[/code], then each child on the [member MoodMachine.current_mood]
##   that is a [MoodTransition] will have its validity evaluated, and transition
##   occurs according to the parameters on the [MoodMachine].

#region Public Methods

## Used by the Plugin to skip fields which are represented in the [method get_editor] return.
func should_skip_property(field: String) -> bool:
	return false

## Returns whether or not an input is valid.[br] This [b]must[/b] be
## overridden in a child class.[br]
## [br]
## [param cache] allows assigning values arbitrarily to avoid recalculating
## potentially complex methods; its use is up to the inheriting class.
func is_valid(cache: Dictionary = {}) -> bool:
	return false

#endregion
