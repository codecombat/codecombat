###### Last updated: 07/25/2017

##### Lesson Plans
# Game Development 1 Course Guide
- Recommended Prerequisite: Introduction to Computer Science
- 5 x 45 - 60 minute coding sessions

#### Welcome to the Game Development 1 course!

In Game Development 1, students will learn how to think about games and game design through classroom discussions. They will then take that knowledge into CodeCombat game dev levels, where they'll learn the specific commands used to build a game. This will lead up to a final project where each student designs and creates their own unique game, and then collects feedback from their peers in order to make improvements.


### Prerequisites
- Teachers must have paid [Starter or Full Licenses](https://codecombat.com/teachers/licenses) in order to assign Game Development 1.
- All students should have completed Introduction to Computer Science.


### Setup
1. Navigate to the class page.
2. Select students to whom you want to assign Game Development 1.
3. Select Game Development 1 from the "Select Course" dropdown, then click “Assign Course”.
4. Students will be able to see Game Development 1 from their student dashboard.

### Course Overview

During the Game Development 1 course, the students will learn how to create their own games using PIECES, MECHANICS, and GOALS.

- Day 1 - 3: learn the basic concepts of game design, and the commands used to create a game inside CodeCombat.
- Day 4: students will design and implement their own game!
- Day 5: Show and Tell - students will share their games with the entire class.

### Game Dev Vocabulary Reference

- **Goal:** A task that a player must perform to win (or progress) in a game.
- **Mechanic:** The rules that govern how a player interacts with a game, and how the game interacts with the player.
    - *For example, a mechanic in Super Mario is that the player presses a button that makes Mario jump.*
- **Piece:** The specific elements that make up a game.
- **Player:** Refers to the person who plays the game, as well as the game piece that the player controls.
- **Spawnable:** A type of game piece that the student can "spawn" into their game.
- **Student:** Refers to the person who creates the game.


## Day 1

### Introduction

**Discussion Question #0a: Do you play games? What are your favorite games?**

This could be board games, or video games, or sports. Games come in many forms!

**Discussion Question #0b: What is a game?**

Games have:

- **Goals**
- **Mechanics** (also known as Rules)
- **Pieces** (dice, cards, digital assets, sports equipment)
- **Fun** (or a challenge!)

#### Game Development Levels

Game Development levels have a few important differences from Computer Science levels:

- The students use **game** instead of **hero**.
    - Example: `game.spawnXY("gem", 20, 34)`
    - There is a "Test" button instead of the "Run" button.
    - Each level introduces new **MECHANICS**, **PIECES**, or **GOALS** that the students can use in their final projects.

### Level 1: "Over The Garden Wall"

**Discussion Question #1a: What do we mean by game "pieces"?**

- A game has various elements that are part of the game. In a board game, this is  usually things like dice, or tokens, or cards. Video games also have virtual pieces: the levels, the weapons, the power-ups, and the enemies.

**Discussion Question #1b: What are the pieces in your favorite games?**

- We provide a variety of *spawnable* pieces for the students to add to their games.
- The piece that the player controls is special - we refer to this piece as "the player", or just "player".

#### Playing the Level

This level introduces the `game.spawnXY(type, x, y)` command.

- This command creates ("spawns") a new piece at a certain location in the level.
- `type` is a *string* that names the type of piece to spawn. In this level, the students spawn a `"fence"`.
- `x` and `y` are *numbers*. This is the horizontal and vertical coordinates where the piece should appear.
- Remember:
    - x starts at zero on the left and gets higher to the right.
    - y starts at zero on the bottom and gets higher towards the top
- Future levels will introduce more spawnable types.

#### Reflection

    - New Command:
        - `spawnXY`
    - New Spawnable:
        - `"fence"`

### Level 2: "Click Gait"

**Discussion Question #2a: What do we mean by "mechanics" or "rules"?**

- MECHANICS define how the player interacts with the game, and how the game responds to the player.

**Discussion Question #2b: What are some of the MECHANICS of your favorite games?**

- Some examples might be:
    - Press X to jump.
    - Click the left mouse button to shoot.
    - An enemy will attack if it sees the player.
- In Game Development 1, the students will not be creating new mechanics. They need to move on to Computer Science 2 and Game Development 2 to learn that!
- CodeCombat provides some basic mechanics that the students can use and configure in their games.

#### Playing the Level

This level introduces our first basic game **mechanic**:

  **Mechanic #1: Click the mouse to move the player.**

- The students don't have to write any code in this level, just click "Test" to play the level. However, it's useful to point out the `spawnPlayerXY` command here.
- The `player` is a special game piece that the player controls.
- Spawn the player with `game.spawnPlayerXY(type, x, y)`
    - `type` is a *string* that names the player type to spawn
    - `x` and `y` are *numbers* representing a location on the map
- **Common Mistake:** students can spawn a player piece using `game.spawnXY` but if they do, the player won't be controllable! Be sure to use `game.spawnPlayerXY`! This command takes the extra step of attaching the movement mechanics to the player piece.
- This level also shows the command `addMoveGoal(x, y)`, but we will look more closely at that in the next level.

#### Reflection

- New Mechanic:
    - Click to move.
- New Command:
    - `spawnPlayerXY`
- New Spawnable:
    - `"knight"`

### Level 3: "Hero's Journey"

**Discussion Question #3a: What do we mean by "goals"?**

- The player is required to complete certain tasks in order to win or progress in the game.

**Discussion Question #3b: What are some of the GOALS of your favorite games?**

- Some typical examples:
    - Collect as many coins as you can before running out of time.
    - Defeat the enemies.
    - Pick up the flag and return it to your home base.
    - Throw the ball into the hoop.
- When you design your games in CodeCombat, we provide some basic goals you can use. In advanced courses students will create custom goals!

#### Playing the Level

This level focuses on our first basic **goal**: movement.

**Goal #1: Move to the red X.**

- Use `game.addMoveGoalXY(x, y)` to add a movement goal.
- `x` and `y` are *numbers*, representing the location of the goal on the level map.
- A movement goal is represented on the map by a red X mark. The X mark will disappear when the player has moved to that spot on the map.
- There will be more goal types in future Game Development 1 levels.

#### Reflection
- New commands:
    - `addMoveGoalXY`
- New spawnables:
    - `"captain"`


### Level 4: "A-maze-ing"

**Discussion:**

This level introduces a new type of **goal**: collecting.

**Goal #2: Collect all the gems and chests.**

- Add a collecting goal with the `game.addCollectGoal()` command.
- Two new spawnable pieces: `"forest"` and `"chest"`
- `"forest"` pieces can be used to create mazes and obstacles.
- `"chest"`s are collectable pieces.

#### Reflection

- New goal:
    - `addCollectGoal`
- New spawnables:
    - `"forest"`
    - `"chest"`

### Level 5: "Gemtacular"

#### Discussion:

**What are the things you need to do before your game is playable?**

- Spawn a player.
- Add a goal.

Create a simple gem collecting game using using the `addCollectGoal` command.

#### Reflection

- New spawnable:
    - `"gem"`


### Level 6: "Vorpal Mouse"

#### Discussion

This level introduces three new MECHANICS:

**Mechanic #2: Click an ENEMY to attack!**

**Mechanic #3: Enemies will attack if they see the player.**

**Mechanic #4: Some pieces block "line of sight".**

This level also uses two new goal types, but we'll go into those more in the next level.

#### Playing the Level

- Defeat the munchkins.
- The students don't have to write any code for this level,  but it's helpful to examine the sample code we've given. Note that there are:
    - New spawnable types: `"munchkin"` and `"guardian"`
    - Munchkins are enemies!
        - Enemies are types of game pieces that the player can attack.
        - In Game Development 1, enemies come with simple behavior (mechanics) already attached to them. They will attack if they see the player.
        - Notice how the two "munchkin"s near the bottom of the map can't see the player at first.
    - We used `spawnXY` to create a maze of `"forest"` pieces. The `"forest"` pieces block the **line-of-sight** between the `"munchkin"`s and the `"guardian"`.

#### Reflection

- New mechanics:
    - Click to attack.
    - Enemies attack if they see the player.
    - Line of Sight.
- New Spawnables:
    - `"munchkin"`
    - `"guardian"`

## Day 2

### Review
- Last time we learned how to:
    - Spawn game PIECES with `spawnXY`.
    - Spawn the player with `spawnPlayerXY`.
    - The player can move by clicking on the map.
    - Add a GOAL with `addMoveGoalXY` and `addCollectGoal`

### Level 7: "Crushing It"

#### Discussion

This level focuses on two new GOAL types:

**Goal #3: Defeat the enemies.**

**Goal #4: Survive until other goals are complete.**

Goal #4 is a little different from other goals. Move, collect, and defeat goals are all actions that the player must complete to win. Survive flips this - it will cause the player to lose and end the game if the player is defeated.

#### Playing the Level

- Add a defeat goal with the `game.addDefeatGoal()` command.
- Add a survive goal with the `game.addSurviveGoal()` command.
- Spawn at least 3 `"munchkin"` enemies, in addition to the one that was spawned in the given sample code (for a total of at least 4 munchkins).

#### Reflection

- New Commands:
    - `addDefeatGoal`
    - `addSurviveGoal`

### Level 8: "Give and Take"

#### Discussion

This level adds new spawnable pieces, with new mechanics attached to them.

- A `"fire-trap"` damages the player when they get too close!
- A `"potion-small"` heals the player 150 health when the player moves onto it.
- Introduces the `"samurai"` player piece.

- The students need to spawn at least two `"potion-small"` pieces to complete the level.
- The movement points are trapped. After setting off the `"fire-trap"`s, the player must heal up using a potion, and go back to the red X.
- Remember, if the red X is still on the map, you haven't completed that movement goal yet!

#### Reflection

- New spawnables:
    - `"samurai"`
    - `"fire-trap"`
    - `"potion-small"`

### Level 9: "Army Training"

#### Discussion

This level adds new spawnable units.
- "thrower"s, are enemies with a ranged spear-throwing attack.
- "soldier"s are allies to the player, with a melee attack.
- "archer"s are allies with ranged attacks.

#### Reflection

- New spawnables:
    - `"thrower"`
    - `"soldier"`
    - `"archer"`


### Level 10: "Ranger Danger"

#### Discussion

When making your own games, finding the right balance between allies and enemies can take some experimentation.

- Ranged units typically do more damage, but have less health.
- "soldier"s are stronger than munchkins, but slower.
- Later, students will be able to modify the stats of the player and units.

#### Playing the Level

- There is no player in this level.
- The level code starts out with too many soldiers and not enough archers to defeat the giant Ogre Brawler.
- The student should replace two of the "soldier"s with "archer"s, then click the "Test Level" button to see how the battle plays out!
- In this level, it's okay if some of your allies are defeated, as long as the ogre is defeated.

#### Reflection

- Sometimes it takes a bit of trial and error to find the right **game balance**.

### Level 11: "Hedge Magic"


#### Discussion

This level introduces the `"duelist"` player type and the `game.spawnMaze(seed)` command.

- Building an entire maze out of `"forest"` pieces can take a while, so we've given you a command to generate a random maze.
- The seed parameter can be any number. It is called a "seed" because it initializes the randomness used to create the maze. If you change the seed, the generated maze will change.
- Experiment with putting different numbers as arguments to the spawnMaze command until you find a maze you like! For example:
    - `game.spawnMaze(42)`
    - `game.spawnMaze(1337)`

#### Reflection

- New command:
    - `spawnMaze(seed)

### Level 12: Forest Incursion

#### Discussion

Game objects have **properties**. Properties are like variables that are specific to that particular object. This level also introduces the `"goaliath"` player type.

- In this level, we learn about three properties of units.
- `maxSpeed` is a number representing how fast a unit can move.
- `maxHealth` is a number representing how much health a unit starts with.
- `attackDamage` is a number representing how much damage the unit does in a single attack.
- Changing the properties of the player or other units can dramatically affect the game balance.
- Properties are commonly accessed using a dot `.` between the object and the property, like: `object.propertyName`
- Notice that all the game commands are properties of the `game` object, and you access those commands using the same dot notation!

#### Playing the Level

- Notice that the sample code saves the result of the `spawnPlayerXY` command in the `player` variable.
- This way, students can use the `player` variable to modify the player's properties, like we do with `player.maxSpeed = 25`, which assigns a value of `25` to the `maxSpeed` property of the `player` object.
- Changing unit properties is a special super power the students have in Game Development levels. They are restricted from directly modifying most unit properties in the CS course levels!

#### Reflection

- New spawnables
    - `"goliath"`
- New unit properties
    - `maxSpeed`
    - `maxHealth`
    - `attackDamage`


### Level 13: Throwing Fire

#### Discussion

In Game Dev 1 levels, some objects have **mechanics** that can be configured by changing the values of their properties.

- This level introduces the `"fire-spewer"` spawnable.
- Students can use the `direction` property of a `"fire-spewer`" to configure it to shoot fire in a `"vertical"` (up and down) direction or a `"horizontal"` (left and right) direction.
- In Game Dev 2, students will learn how to give game objects custom mechanics, but they need to complete Computer Science 2 before they can do that.  For now we have provided some configurable mechanics to make things a bit simpler.

#### Playing the Level

- Notice that the sample code assigns the result of the `spawnXY` command to a variable, so that later code can access the properties of the spawned object.
- The `direction` property can only be set to a **string**, either `"horizontal"` or `"vertical"`.

#### Reflection

- New configurable game object
    - `"fire-spewer"`
        - `direction` property

### Level 14: Them Bones

#### Discussion

This level introduces the `"generator"`, `"skeleton"`, and `"lightstone"` spawnables, as well as the `"champion"` player.

- A `"generator"` spawns a `"skeleton"` unit every `5` seconds.
- Units have different teams. Human units see ogre units as enemies, and ogre units see human units as enemies.
- `"skeleton"`s are neutral, so they will attack both ogres and humans!
- `"skeleton"`s are afraid of `"lightstone"`s. When the player carries a lightstone, the skeletons will stay away!
- `"generator"`s can be configured to spawn different types of units, which we will see in future levels.

#### Playing the Level

- The generator will continue to spawn skeletons until it is destroyed.
- Use the lightstone to keep the skeletons away, giving you time to destroy the generator.
- The lightstone doesn't last forever, so use it wisely!

#### Reflection

- New spawnables:
    - `"generator"`
    - `"skeleton"`
    - `"lightstone"`
    - `"champion"`

## Day 3

### Review

What types of goals are available for building our games?

- Move
- Collect
- Defeat
- Survive

What types of spawnable pieces are available?

- Obstacles:
    - `"fence"`
    - `"forest"`
- Collectables:
    - `"gem"`
    - `"chest"`
- Enemies:
    - `"munchkin"`
    - `"thrower"`
    - `"skeleton"`
- Players:
    - `"knight"`
    - `"captain"`
    - `"guardian"`
    - `"samurai"`
    - `"duelist"`
    - `"goliath"`
    - `"champion"`
- Allies
    - `"soldier"`
    - `"archer"`
- Misc:
    - `"fire-trap"`
    - `"potion-small"`
    - `"fire-spewer"`
    - `"generator"`
    - `"lightstone"`

Remember, students can see properties of these spawnable objects by clicking on them in the Spawnable section of the middle pane of the game window.

### Level 15: Behavior Driven Development

#### Discussion

This level introduces the `"ogre"` spawnable, as well as the unit property `behavior`, which allows students to modify the mechanics attached to a unit, and make them behave differently.

- All units (allies and enemies) can be configured with different **mechanics** using the `behavior` property.
- The `behavior` property must be assigned a **string**, which can be one of the following:
    - `"AttacksNearest"` configures the unit to attack its nearest enemy.
    - `"Scampers"` configures the unit to move around randomly.
    - `"Defends"` configures the unit to stay in place and attack any enemy that comes within range.
- In Game Dev 2, students will learn to customize units' behavior in more complex ways.

#### Playing the Level


- This level is a little trickier than most to win - just like a real game might be!
- One strategy is to use the lightstones to drive the skeletons away from one ogre, and lure the ogre away from the others, back to where your archer ally is waiting to help you defeat the ogre. This takes some careful movement of your player to achieve.
- Be sure to drink a health potion when your health is low!
- It may take a few tries to beat the game - don't give up!
- If you're really stuck, you can always give your player more `attackDamage` to make things easier.

#### Reflection

- New spawnable:
    - `"ogre"`
- New unit property:
    - `behavior`


### Level 16: Time To Live

#### Discussion

This level introduces using an argument to configure a timed survival goal, and configuring a generator to spawn `"munchkin"`s.

- Previously, students used `addSurviveGoal()` with no argument (nothing between the parenthesis). This means the player must survive until all other goals are met.
- Now, the students can use `addSurviveGoal(seconds)` to configure a goal that succeeds as long as the player survives for a given number of seconds.
- The argument `seconds` must be a number, such as `addSurviveGoal(20)` for `20` seconds.
- `"generator"`s have a property named `spawnType`, which can be set to a string of any type of spawnable unit.

#### Playing the Level

- Be sure to configure the generator and player as instructed in the sample code's comments, or the goals will not be met.

#### Reflection

- New goal configuration:
    - `addSurviveGoal(seconds)`

- New generator configuration:
    - `spawnType`

### Level 17: Seeing Is Believing

#### Discussion

This level introduces UI elements, allowing the game to show interesting information to the player. It also introduces the `game.time` property.

- Students can use the `ui.track(object, propertyName)` command to show information to the player.
- The `object` argument is an object you want to show the property of, like `game`.
- The `propertyName` argument is a **string** that is the same as the name of a property to show, like `"time"`.
- So, to show the `game.time` property, students should use `ui.track(game, "time")`.
- The `game.defeated` property is a special helper property in this level to make things simpler. In Game Dev 2, the students will learn to track how many enemies are defeated themselves.

#### Playing the Level

- Don't destroy the generators until you have defeated at least 10 munchkins!

#### Reflection

- New command:
    - `ui.track`

- New property:
    - `game.time`


### Level 18: Persistence Pays

#### Discussion

This level introduces the `db.add(key, value)` command. Until now, every time a student loads and plays a level, the game is reset. In real games, programmers use databases like Amazon DynamoDB to store **persistent** information, which is tracked between plays of the game, even by different players.

- `db.add` takes two arguments, a `key` and a `value`.
- The `key` is a string, which is used like a variable, it's a name in the database to store the `value` under.
- The `value`, for `db.add`, is a number.
- The `db.add` command increments, or adds to, the existing value stored under the `key`. So if the student called `db.add("plays", 1)` twice, the value stored at the `"plays"` key in the database would be `2`.
- Later levels will show how to store other types of data in the database.

#### Playing the Level

- At the bottom of the code for this level is some complicated code you haven't learned about yet. We define a **function** called `onVictory` and then assign that function as a **handler** for the `"victory"` event.
- Don't worry if this is confusing! It's a preview of what students will learn in Game Dev 2. For now, just put your `db.add(game, "defeated")` code inside the `onVictory` function, where the comments tell you to!

#### Reflection

- New command:
    - `db.add`

### Level 19: "Tabula Rasa"

#### The FINAL PROJECT!

This level is a blank slate. To pass the level, the only requirements are to spawn a player, and add a goal - but really, that's only the beginning. Encourage the students to get creative with all the techniques they've learned throughout the course!

There is a new "GAME" button above the code editor window. Clicking GAME loads the shareable version of the student's game, and provides a link that the student can give out to their friends.

The students should each design a game, combining the game PIECES, GOALS, and MECHANICS they've learned in creative ways.

Every game should, at least:

1. Spawn a player piece.
2. Add one or more goals for the player to complete.
3. Use some combination of obstacles, enemies, collectables, and other pieces to create a fun challenge for the player.

In addition, students can use the `db.add` command to track how many people have played their game. They can also use the `game.defeated` property if they want to track how many enemies have been defeated by their players in total! In the Game Dev 2 course, students will learn how to react to events as they occur in the game, and will be able to use the database to track even more interesting statistics about their games.

Students should go through the following steps to create their games:

1. **Design.** This can be done on paper. Describe the idea, sketch the map, list the goals.
2. **Build.** Take the initial design, and build it in the game engine (in this case, use the level Tabula Rasa to build the game).
3. **Test.** As the students build their game, they should always be testing it by playing the game themselves to make sure it's working out the way they imagined.
4. **Feedback.** The students should share their game link with friends and gather feedback about what makes the game fun or frustrating.
5. **Improvements.** Based on the feedback, the students go back to the building phase and make improvements to the game!

For the remainder of Day 3, focus on steps 1, 2, and 3.

## Day 4

#### Finish work on final projects.

Focus the first part of Day 4 on having the students pair up with a friend.

Each student should use the GAME button to get the shareable link, and give that link to their partner.

In each pair, one student first plays the other's game, while the game's creator observes. Ask the observers to think about the following questions:

- Did your partner play the game in the way you expected it to be played? Did they come up with a surprising way to play?
- Did they seem to have fun? Did they seem frustrated?
- Did they break the game, or did it work as you intended?

Then, ask the player for their thoughts on the game. The creator should take notes about this feedback.

Next, switch roles and repeat the process of testing and giving feedback for the partner's game.

After this exercise, go back and individually work on your game again. Are there any improvements you can make based on what you observed?

If there's time, have the students pair up again, this time with a different partner, and see if the results are different.

## Day 5

#### Show and Tell Day

This day wraps up the week of Game Development 1.

Each student should have a few minutes to show off their game to the class. Encourage each student to talk about things like:

- What was your original idea for the game?
- What changed from the original idea as you were building the game?
- Did anything surprise you when playtesters were playing your game?
- Did you make any changes after watching playtesters play your game?

Encourage the students to share links to their final projects with family and friends!

We'd love to hear about your best projects! Feel free to email us at team@codecombat.com with a link, or better yet, tweet us [@CodeCombat](https://twitter.com/CodeCombat)

---
