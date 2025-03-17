These are general plans for future improvements -- basically a worksheet for guiding future development. Please submit an issue to GitHub if what you would like is not listed here. If it is listed here, honestly, feel free to submit an issue anyways.

# Core Functionality

* add Graph-based UI tab for managing states for both Transition-mode and Mood-Evaluation-Mode.
* Provide helper Debug nodes to track Mood changes, etc.
* finish writing unit + integration tests.
* build benchmarks comparing this to some other common solutions and ensure performance is acceptable.
* I think there might be some issues with the `template_script`s.
* undo-redo support for node tree changes (e.g. created/deleted nodes).

# Node-Specific Functionality

* `Mood`
	* allow overriding of `target`.
	* provide a flag to prevent a machine's `fallback` mechanism from executing while in this mood.
	* provide a flag preventing transition to this node.
* `MoodCondition`
	* allow overriding of `target`.
	* revisit/revamp `cache` -- the idea feels half-baked  and half-implemented.
	* allow providing an easy flag to indicate if a condition only works or makes sense in one selection mode or another.
* `MoodConditionProperty`
	* support more property types.
	* better support (and TEST!) for nodes/nodepath criterion.
* `MoodConditionSignal`
	* support handling signals with arbitrary method signatures/parameters.
	* find ways to manage those signatures/parameters.
		* support for flagging validity tied to parameter criteria (like `MoodConditionProperty`).
			* e.g. "if an Area2D signal target receives a `area_entered` signal with an `Area2D` that has a `health` property `<=` to `10`, become valid"
	* replace `Timer` `@export`s with time configuration to use scene timers instead.
	* add an `invert_validity` `@export`
* `MoodConditionInput`
	* support other input-handling mechanisms -- `GUIDEINput` or raw inputs instead of keypress, remove/replace `InputTracker` as it feels fragile,  etc.
* `MoodConditionTimeout`
	* feels like it needs some cleanup and refactoring.

# Configuration

* provide a config flag to not hide fields from the UI.
* provide a config flag when not hiding fields to hide the Condition Editor.
*  in general, it is non-intuitive how signals are handled in `MoodScript`, so some implementation which makes this configurable and manageable would be ideal.
	* perhaps signal deny/allow-lists which guard against processing those signals?
	* alternately, a basic flag that says "allow signals through when disabled" on Mood + MoodChild?

# UI

* get input from an actual designer and redo the Editor UI to be better.
	* differentiate colors better.
	* clean the border layout and margins
	* prevent the inspector from being too wide by allowing for narrower inputs
		* especially for `Mood` when using transitions!
	* improve color usage and make it clearer when things are temporary, locally modified, changed, etc.

# Developer Functionality

* streamline the `Editor`/`SubEditor` pattern to make it easier for people writing their own `MoodCondition` and `MoodScript` tools to integrate them into said UI.
* improve and clarify the autoload functions as they seem generally useful.
* write docs on the scripts/ensure the scripts work.
