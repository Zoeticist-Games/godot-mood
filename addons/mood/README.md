# Mood

# Overview
## What is Mood?

`Mood` is a configurable, node-and-component implementation of the **Finite State Machine** pattern.
## What do you mean by "configurable node-and-component"?

A Finite State Machine is a **node** -- a `MoodMachine`, specifically.

A state is a **node** -- a `Mood`.

The secret sauce to making the FSM pattern work is how you implement identifying the correct state to be in. In `Mood`, those are -- you guessed it -- **nodes**. They're `MoodCondition`-inheriting nodes!

There are two main design patterns for state-switching: either you identify the correct state for a machine by evaluating the conditions for that state, or you identify the correct state for a machine by determining whether there exists a valid _transition_ from the current state to the next.

I say **configurable** because both designs are implemented here: you can set `MoodMachine#evaluate_moods_directly` to true and assign a `Mood#root_condition` to evaluate the rightful-ness of each `Mood`, **or** you can have `MoodMachine#evaluate_moods_directly` set to false and then transitions are -- you guessed it -- **nodes**. The `MoodTransition` node specifies the condition evaluation for transitioning nodes.

In *general*, my goal for this addon is to support flexibility *wherever* possible by providing lots of flags and controls and nodes to allow you to use the FSM pattern in the way that works best for each individual use-case.

The **component pattern** means that behaviors are encapsulated in individual components -- `MoodScript`-inheriting **nodes**, specifically, although strictly speaking literally _any_ node type will work.

## Any node type? How does this actually implement the component pattern?

The idea is extremely simple (to me, and hopefully you too):

1. The Current Mood is considered **enabled**, and it runs `process`, `physics_process`, `input`, and `unhandled_input` like normal.
2. **so do its children**.
3. other Moods are **disabled**, and don't run at all. It's like they don't even exist!
4. the `MoodScript` provides access to a `target`, typically the parent of the `MoodMachine` itself, although in some cases it can be overridden.
5. This means you can build a script which performs a generic behavior on a Variant target as a **component** of behavior, which can then be placed in every context where it's relevant.

## I'm still confused. Can you make it simpler?

You can slap a `ClampToWorld` script node that calls `target.position = target.position.clamp(world_bounds.top_left, world_bounds.bottom_right)` and then just place that script node under any `Mood` which also updates the `target.position` -- that way, you don't have to explicitly clamp to world bounds everywhere position is updated, nor do you have to special-case anything for anywhere -- and that script won't ever be evaluated unless your `MoodMachine` is in the relevant `Mood`, so you have no worries about performance, either! 

# Installation

## Via Asset Library

This will be filled out once it is approved for the Asset Library.

## Via GitHub

1. Go to the [Releases](https://github.com/Zoeticist-Games/godot-mood/releases) page.
2. download the Source Code of the latest release.
3. unzip it.
4. ???
5. profit!

# How To Use

Before beginning, read through the inline Editor documentation thoroughly. Also take a look at the `examples` folder for some basic examples.

1. Add a `MoodMachine` .
2. add one or more `Mood`s as children to your `MoodMachine` (if there's only one I don't see the point, but you do you).
3. determine how you want to evaluate the current Mood -- by establishing per-Mood conditions, or by defining transitions. Set `evaluate_moods_directly` on your `MoodMachine` appropriately.
4. Set up your conditions.
	1. **If `evaluate_moods_directly` is true**:
		1. add at least one `MoodCondition` to every Mood (this is optional for the Initial Mood if the `mood_fallback_mode` of the Machine falls back to the Initial Mood).
		2. a `MoodConditionGroup` is recommended, as that lets you expand to multiple conditions.
		3. set the `root_condition` on the Mood to your main `MoodCondition`.
	2. **If `evaluate_moods_directly` is false**:
		1. add `MoodTransition` nodes under each Mood for the Moods you want to to be able to transition to.
		2. add `MoodCondition` children under the `MoodTransition` nodes to indicate when to transition to those Moods.
5. add nodes under the Mood that you want to be evaluated only when that Mood is the current mood.
	1. nodes inheriting `MoodScript` have extra bits of flexibility to streamline behavior; check out the inline Editor documentation for more details.
6. that's it!

# Inheriting `MoodScript`

As noted several times, the best way to use `Mood` is to create **component** nodes that inherit `MoodScript` and handle `_process`, `_physics_process`, `_input`, and `_unhandled_input` as appropriate.

There is an important caveat about children `MoodScript`s that needs to be noted, though:

**Even if a `MoodScript` sits in a disabled Mood, it will still receive and respond to signals!**

Wiring signals to run even when not in that mood can be a great way to boost performance or set flags to help handle transition conditions and the like, but if you are expecting the "disabling" of a Mood and its children to also disable signals, you will be very disappointed and probably run into bugs.
