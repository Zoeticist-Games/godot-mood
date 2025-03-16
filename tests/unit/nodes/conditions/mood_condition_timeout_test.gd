extends GutTest

class TestTriggerSetsValidTo:
	extends GutTest

	var _obj: MoodConditionTimeout

	func before_each() -> void:
		_obj = MoodConditionTimeout.new()
		_obj.time_sec = 0.1 # any lower than this and the test fails
		add_child_autoqfree(_obj)

	func test_is_not_valid_on_ready_by_default() -> void:
		_obj._ready()
		assert_false(_obj.is_valid())

	func test_is_valid_on_ready_when_trigger_sets_valid_to_is_false() -> void:
		_obj.trigger_sets_valid_to = false
		_obj._ready()
		assert_true(_obj.is_valid())

	func test_is_valid_sets_as_false_on_enter_mood() -> void:
		_obj.trigger_sets_valid_to = false
		_obj._ready()
		_obj._enter_mood(null)
		assert_false(_obj.is_valid())
		assert_not_null(_obj._timer)

	func test_is_valid_resets_on_timeout() -> void:
		_obj.trigger_sets_valid_to = false
		_obj._ready()
		_obj._enter_mood(null)
		assert_false(_obj.is_valid())
		assert_not_null(_obj._timer)


class TestValidationTypeValidOnEntry:
	extends GutTest

	var _obj: MoodConditionTimeout

	func before_each() -> void:
		_obj = MoodConditionTimeout.new()
		_obj.time_sec = 0.1 # any lower than this and the test fails
		add_child_autoqfree(_obj)
		_obj._ready()

	func test_is_not_valid_on_ready() -> void:
		assert_false(_obj.is_valid())

	func test_is_valid_on_mood_entry() -> void:
		_obj._enter_mood(null)
		assert_true(_obj.is_valid())

	func test_is_valid_reverts_on_timeout() -> void:
		_obj._enter_mood(null)
		assert_true(_obj.is_valid())
		await wait_seconds(_obj.time_sec + 0.1)
		assert_false(_obj.is_valid())

	func test_is_valid_reverts_on_exit() -> void:
		_obj.time_sec = 2 # just for illustration purposes, to have enough time
		_obj._enter_mood(null)
		assert_not_null(_obj._timer)
		_obj._exit_mood(null)
		assert_false(_obj.is_valid())
		assert_null(_obj._timer)

class TestValidationTypeValidOnEntryUnbound:
	extends GutTest

	var _obj: MoodConditionTimeout

	func before_each() -> void:
		_obj = MoodConditionTimeout.new()
		_obj.validation_mode = MoodConditionTimeout.ValidationMode.VALID_ON_ENTRY_UNBOUND
		_obj.time_sec = 0.1 # any lower than this and the test fails
		add_child_autoqfree(_obj)
		_obj._ready()

	func test_is_not_valid_on_ready() -> void:
		assert_false(_obj.is_valid())

	func test_is_valid_on_mood_entry() -> void:
		_obj._enter_mood(null)
		assert_true(_obj.is_valid())

	func test_is_valid_reverts_on_timeout() -> void:
		_obj._enter_mood(null)
		assert_true(_obj.is_valid())
		await wait_seconds(_obj.time_sec + 0.1)
		assert_false(_obj.is_valid())

	func test_is_valid_does_not_revert_on_exit() -> void:
		_obj.time_sec = 2 # just for illustration purposes, to have enough time
		_obj._enter_mood(null)
		_obj._exit_mood(null)
		assert_true(_obj.is_valid())
		assert_not_null(_obj._timer)

class TestValidationTypeValidOnExit:
	extends GutTest

	var _obj: MoodConditionTimeout

	func before_each() -> void:
		_obj = MoodConditionTimeout.new()
		_obj.validation_mode = MoodConditionTimeout.ValidationMode.VALID_ON_EXIT
		_obj.time_sec = 0.1 # any lower than this and the test fails
		add_child_autoqfree(_obj)
		_obj._ready()

	func test_is_not_valid_on_mood_entry() -> void:
		_obj._enter_mood(null)
		assert_false(_obj.is_valid())

	func test_is_valid_on_mood_exit() -> void:
		_obj._enter_mood(null)
		_obj._exit_mood(null)
		assert_true(_obj.is_valid())

	func test_is_valid_reverts_on_timeout() -> void:
		_obj._enter_mood(null)
		_obj._exit_mood(null)
		await wait_seconds(_obj.time_sec + 0.1)
		assert_false(_obj.is_valid())

	func test_is_valid_reverts_on_entry() -> void:
		_obj.time_sec = 2 # just for illustration purposes, to have enough time
		_obj._enter_mood(null)
		_obj._exit_mood(null)
		assert_not_null(_obj._timer)
		_obj._enter_mood(null)
		assert_false(_obj.is_valid())
		assert_null(_obj._timer)

class TestValidationTypeValidOnExitUnbound:
	extends GutTest

	var _obj: MoodConditionTimeout

	func before_each() -> void:
		_obj = MoodConditionTimeout.new()
		_obj.validation_mode = MoodConditionTimeout.ValidationMode.VALID_ON_EXIT_UNBOUND
		_obj.time_sec = 0.1 # any lower than this and the test fails
		add_child_autoqfree(_obj)
		_obj._ready()

	func test_is_not_valid_on_mood_entry() -> void:
		_obj._enter_mood(null)
		assert_false(_obj.is_valid())

	func test_is_valid_on_mood_exit() -> void:
		_obj._enter_mood(null)
		_obj._exit_mood(null)
		assert_true(_obj.is_valid())

	func test_is_valid_reverts_on_timeout() -> void:
		_obj._enter_mood(null)
		_obj._exit_mood(null)
		await wait_seconds(_obj.time_sec + 0.1)
		assert_false(_obj.is_valid())

	func test_is_valid_does_not_revert_on_entry() -> void:
		_obj.time_sec = 2 # just for illustration purposes, to have enough time
		_obj._enter_mood(null) # get into mood so we can exit
		_obj._exit_mood(null) # exit mood
		_obj._enter_mood(null) # re-enter to illustrate non-revert
		assert_true(_obj.is_valid())
		assert_not_null(_obj._timer)
