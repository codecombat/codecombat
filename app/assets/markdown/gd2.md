##### Lesson Plans
# Game Development 2

## Curriculum Summary

* Recommended Prerequisites: Computer Science 2, Game Development 1
* 8 x 45-60 minute coding sessions

### Overview

The Game Development 2 course applies skills students have learned from Computer Science 2 so they can build a full-fledged arcade-style game they’ll be excited to share with their friends and family. This is where the abstract concepts such as conditionals and functions show their purpose in a hands-on way, and enable students to create something their own.

The course begins by demonstrating some new game mechanics and techniques, which use basic syntax and logic structuring the students are familiar with from previous courses. Once they are comfortable with the new mechanics, students will go through a variety of exercises combining them into unique forms of gameplay, including a series of levels which iteratively build a Pac-Man-style arcade game. Finally, students are given an opportunity to create their own arcade game.

*This guide is written with Python-language classrooms in mind, but can easily be adapted for JavaScript.*

## Scope and Sequence

1. [Mechanics: Spawn and Goals](#mechanics-spawn-and-goals)
2. [Mechanics: Time, Randomness, Defeat](#mechanics-time-randomness-defeat)
3. [Mechanics: Manual Goals and More Events](#mechanics-manual-goals-and-more-events)
4. [Integration Practice](#integration-practice)
5. [Arcade Game](#arcade-game)
6. [Game Development 2 Project](#game-development-2-project)

# Mechanics: Spawn and Goals

## Summary

In order to expand the student’s options when building their own games, students will need to learn functions and methods that they can use. The mechanics modules introduce no new programming techniques but instead focus on novel ways to use functions and callbacks to support new gameplay mechanics.

## Discussion

**What are some ways that character behave in various sorts of games?**

Examples:

*   CodeCombat characters can attack nearest, defend, or run away
*   CodeCombat skeletons run away when the player is carrying a light orb
*   Minecraft animals will tend to be complacent until they are attacked
*   Minecraft enemies will tend to explore until they see the character. When close enough, the creeper will explode.

**How would some of these behaviors look like in code?**
This can be an opportunity to write pseudo-code, which is not necessarily “valid” code in a specific language but communicates the logic and general structure of code that students may later write.

Example of a Minecraft enemy:

```
if no player is nearby
  wander aimlessly
else
  if far away from player
    move closer
  else
    attack player
```

## Review

This set of levels explore two things:

*   Using the “spawn” event, which allows students to define their own behaviors for units in their games, and
*   Changing parameters for goals they learned in GD1.

Before beginning, students should be familiar with the following concepts:

*   Events (CS2)
*   Function parameters (CS2)
*   If statements (CS2)
*   Game goals (GD1)

## Levels

Students should play the first seven levels:

*   Guard Duty
*   Army Training 2
*   Standard Operating Procedure
*   Center Formation
*   Chokepoint
*   Jailbreak
*   Risk and Reward

## Discussion

*   When would you use the “spawn” event?
*   In a game, when would you want to specify how many enemies to defeat or items to collect?
  *   Example: a game where you want to allow players to both pass and excel. Players must defeat a certain number of enemies or collect a certain number of things to win the game, but they could go for more to get a high score?

# Mechanics: Time, Randomness, Defeat

## Discussion

**How do games behave based on time?**

There are two in particular: regular events (changing the game state based on time of day) or one-time events (the mission is unsuccessful if not completed in 5 minutes).

**When do games behave inconsistently, or randomly?**

Examples:

*   A deck of cards is shuffled
*   A character randomly moves about an area
*   A world is generated (such as Minecraft)

**What sorts of things can happen in a game when a character is defeated?**

Examples:

*   The score changes (up or down)
*   The win state changes (win or lose)
*   Areas are made made available, unavailable
*   Character behavior changes
*   Events happen

## Review

Concepts which can be reviewed to help students prepare for these levels:

*   Arithmetic (CS2)

## Levels

Students should play the next three levels:

*   Adventure Time
*   Random Riposte
*   Agony of Defeat

## Discussion

**Why must the time-checking loop in Adventure Time happen at the end of the code?**

Because it’s an infinite loop so any code underneath will never be executed.

**Aside from location, what else in the game can be set randomly, given a random integer?**

Examples:

*   Time: such as in conjunction with Adventure time, spawn enemies at random intervals
*   Type: if a random number between 1 and 2 is lower than 1, spawn a friend, otherwise an enemy

**How can randomness be paired with probability?**

If your students are in high school, this is an opportunity to incorporate mathematical concepts such as exponents or logarithms, and how they can affect probability. A simple way to incorporate probability in your code is a function such as:

```python
def randomResult():
  i = game.randomInteger(1, 10)
  if i < 10:
    return False
  else:
    return True
```

This function will have a 10% chance of returning `True`.

Another example of probability in code would be:

```python
def randomResult():
  i = game.randomInteger(0, 10)
  i = i**2 # this is Python’s notation for an exponential, JavaScript has a function Math.pow
  return i
```

This function returns between 0 and 1024\. Using Math, we can create algorithms which return all sorts of random results.

**What other things in CodeCombat can you do when an enemy is defeated?**

Examples:
*   Spawn more enemies
*   Have the player say something

# Mechanics: Manual Goals and More Events

## Discussion

**What are various ways that games are considered “won” or “lost”? How would that look in code?**

Encourage thinking about goals which don’t include the ones provided by CodeCombat so far (defeat enemies, survive, collect, get to a location).

Examples:
*   Complete a series of quests
*   Get a higher score or better time than an opponent
*   Solve a puzzle

**What are examples of things that are removed from the game environment during gameplay?**

Examples:

*   You navigate to a new area or room, everything that was in the old area or room should be removed
*   Some short time after an enemy is defeated, the enemy’s body should be removed.
*   After something is “consumed”, for example a health item, the item should be removed.
*   When something is “changed”, for example an equipped item, clothing or pet, the original item should be removed.

**When something is collected in a game, what sorts of things can happen?**

Examples:

*   Character behavior may change  (other characters in a game might say something if an item were stolen! Or they may give you a quest, or behave differently than before.)
*   Player attributes could change (speed, power, health, abilities, especially Mario games)
*   The way the player interacts with the environment could change (a key which enables opening a door, money which enables purchases).

**What things can happen when two things (characters, objects) collide in a game?**

Examples:

*   The player could lose the game(Flappy bird colliding with a wall, Pac-Man colliding with a ghost while not powered up)
*   Damage (if one character runs into something damaging, such as lava or spikes, they could lose health)
*   Speed

*   A character running into the wall will stop moving
*   A ball that hits a wall might keep moving but in another direction

## Levels

Students should play the next four levels:

*   Stick Shift
*   From Dust to Dust
*   Accounts Department
*   Berserker

## Discussion

**How can manual goals be used to recreate the built-in goal methods?**

* Defeat: use “defeat” event to track how many enemies are defeated, set goal success to true when high enough.
* Move: in a while true loop, check the player position, and when it’s close enough to the position, set goal success to true.
* Survive: If the player emits a “defeat” event, set goal success to false.
* Collect: use “collect” event to track how many items are collected, set goal success to true when high enough.

As an exercise, try writing out the code for these.

**What is the difference between defeat and destroy?**

Destroy completely removes the thing from the game. Defeat is for units and disables them, but they are still “in” the game.

**What else can happen when something is collected or collided with?**

Examples:

*   Spawn more enemies
*   Change the layout of the map (spawn, destroy)
*   Player attributes (health, speed, size)
*   The behavior of enemies (run away, run towards)

**For any given event, what is the “target” property? What is “other”?**

The target is whatever thing the event was attached to. The “other” is any other thing which is involved in the action. For example, if you set up an event handler for “collision” on the player, “target” is always the player, and “other” is always the thing or unit that the player collided with. If you set up an event handler for “collect” on the player, “target” is yet again always the player, and “other” is the item which the player has collected.

# Integration Practice

## Summary

Now that all the mechanics have been introduced, students will begin exploring and trying out more ways to combine these to form unique behaviors.

## Levels

Students should play these levels:

*   Run for Gold
*   Disintegration Arrow

## Code Breakdown

These levels are getting fairly complex. For each function in the code, have students, in groups or as individuals, discuss and explain:

*   What is the function doing
*   What mechanic or mechanics it is using (randomness, game time, etc)
*   How the function relates to the rest of the code (is calling, is being called by, is set up by)

## Discussion

**What is the benefit of breaking up code in these ways?**

Examples:

*   Code reuse
*   Explanatory: the names of functions explain what that block of code does

**How else could this code have been organized?**

*   How else could the functions have been named?
*   How else could the functions have been broken up?
*   What would they look like as one big function?

# Arcade Game

## Summary

This series of levels walks students step-by-step through creating a Pacman-style arcade game. This helps them see and practice integrating these concepts into a more complex project, and prepares them for doing the same sort of iterative process in this course’s final project.

## Levels

Students should play these levels:

*   Game of Coins Part 1: Layout
*   Game of Coins Part 2: Score
*   Game of Coins Part 3: Enemies
*   Game of Coins Part 4: Power Ups
*   Game of Coins Part 5: Balance

## Code Breakdown

As in the previous module, have students explain for each function:

*   What is the function doing?
*   What mechanic or mechanics it is using (randomness, game time, etc)?
*   How the function relates to the rest of the code (is calling, is being called by, is set up by)?

## Discussion

**What is the difference between building a program piece-by-piece vs all at once?**

This discussion serves to highlight how at each stage of development, this level was “playable”. It could be played, tested, and changed. Each stage focused on a different aspect of the game. The benefits to iterative development are many:

* The program is always usable. When you can run the program at any time, you can:
  * Demonstrate your work to others at any stage.
  * Stay flexible in terms of what ends up being the “final” version. In work or in school, you may run out of time, but partial work is always preferable to something that doesn’t work at all.
  * Test what you are building and adjust your plan as you go.
  * Always understand what state the program is in
* When testing continually, bugs tend to be the latest code addition. If you build the code all at once and then start testing, the issues will be many, compounded, and all over the place. It will be much harder.

In all likelihood, many students will still try to build their projects (such as Game Development 2) all in one go. This will likely lead to frustration when the game gets into a broken state and it takes a great deal of effort to get it out of that state. When this happens, reinforce the benefits of building iteratively by encouraging the student to start from a simpler place and build up gradually, piece by piece.

# Game Development 2 Project

## Summary

Have students design and iteratively build their own projects. There are many ways to run this module, but it should at least happen over several days, with time set aside for design, building, and sharing, for example:

*   Day 1: Brainstorm ideas for what to build, and plan how to implement it. Remind students of the mechanics they have learned in Game Development 1 and 2.
*   Day 2-4: Develop their game iteratively. Students should work on their projects and collaborate by testing each other’s projects and code, providing feedback for both how the game plays and how it’s built.
*   Day 5: Present. Have students reflect about the process of building their projects, what they built and how they built it, and presenting to the rest of the class.

On optional activity at the end: have students “code breakdown” each others’ projects. Encourage students to take time to organize their code, name their functions and variables, and include comments so that their classmates will be able to understand how the code works.

> “Programs must be written for people to read, and only incidentally for machines to execute.” - Harold Abelson
