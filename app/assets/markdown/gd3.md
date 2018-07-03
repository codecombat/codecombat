# Game Development 3

### Curriculum Summary

Recommended Prerequisites:

* Computer Science 3
* Game Development 2
* Optional: some knowledge of Physics and/or Geometry. The course provides guidance on enough to get the students by, but if your students have some exposure to these topics, this is a great opportunity to apply them, especially in the final project and in discussions.

#### Overview

The Game Development 3 course continues from Game Development 2, using the concepts learned in Computer Science 3 to build even more varied and creative games. Game Development 3 provides students with more open-ended tools, enabling a wider variety of games and programs to be built, while also seeing how basic Computer Science concepts are used in the context of making something to be shared with others.

This guide is written with Python-language classrooms in mind, but can easily be adapted for JavaScript.

### Scope and Sequence

1. [On Update and Setting Position](#on-update-and-setting-position)
2. [Animations](#animations)
3. [Runner Project Tutorial](#runner)
4. [Game Dev 3 Project](#game-development-3-project)

---

## On Update and Setting Position

### Summary

This module begins the process of giving students more fine-grained control of their games. Up until now, games built within CodeCombat will have used the basic structure of the game: there are units on a 2D plane with a certain basic set of physics, the units interact with one another, and you control one unit with mouse or keyboard. With more fine-grained control, students will later be able to create any sort of physical behavior or interaction, from gravity-less asteroid drifting, to Mario-style platform jumping.

### Introduction to the Game Loop

Start this module by teaching students about the game loop. This is a standard logical structure used in any game which includes animations, and it looks something like this:

```
while True:
  update state
  draw to screen
  wait until the next time to update (usually a few milliseconds)
```

Updating state means everything from updating a position based on gravity or collisions with other players, updating health or character state. Any logical state which changes over time or because of user input is affected here. Each update is for a specific, small amount of time, often fractions of a second.

Draw to screen simply means taking the current state of the game, such as how the world is structured or where the user is looking, and figures out how to transform that into a drawing on the screen. For 2D games, this often involves taking some sprite images, filtering or modifying them (such as scaling) and layering them on top of one another. For 3D games, this means drawing a series of polygons from furthest to nearest, only drawing those within the character’s view.

By waiting, the game will run at a steady, predictable pace. The game, at any time, will have more or less work to do, and so you need to wait a complementary amount of time so that updates happen steadily.

A single iteration of this loop is a “frame”.

#### Loop variant: paused

Demonstrate how pausing can be incorporated into this basic loop. If your game is paused, it won’t update the state, everything about the game is held constant. However, you still need to draw the game state, and often have animations going on in menu screens, and so you are still drawing and updating the screen. And so you can update the game loop to support pausing:

```
while True:
  if not game.paused:
    update state
  draw to screen
```

#### Loop variant: dropping frames

Often when discussing game performance, FPS, or frames per second, is discussed. This is the number of frames drawn to the screen per second of gameplay. With a sufficient machine, you can have a steady, high FPS, and the game runs smoothly. If the machine cannot keep up with everything it needs to do, however, it would gradually and erratically slow down. Depending on how much work it was doing to update the state or draw the screen, some loops will run over their allotted time.

For example, say your game is running at 30 frames per second. That means each frame is 33ms long. If updating the state takes 20ms and drawing to the screen takes 20ms on average, the game will not be able to keep up. It will be 7ms behind every frame, and so 231ms late every second, so about 23% slower than it should be going.

To deal with this, games will skip the draw step if execution is falling behind. This way, the game state updates remains steady. These are called dropped frames, and are reflected in the actual FPS of the game. If your game has a lower FPS than is targeted, this is what it is doing to keep gameplay smooth, if not smooth animations.

```
while True:
  update state
  if not falling behind:
    draw to screen
```

### Introduction to Resource Re-use

This module enables re-use of resources through clever manipulation of position. Games and programs in general will do this to improve performance. Discuss computer performance with students, particularly drawing on experiences they have had with sluggish machines:

* A computer running too many programs
* A browser with too many tabs open
* A phone running too many programs
* A newly released game that cannot run on an older machine

Games often require a good deal of computing resources, so game programmers regularly have to think about how to “optimize” so a wide array of machines can run the program reasonably well.

It takes time to create, track, and destroy resources, especially for languages like Python and JavaScript which automatically “clear” resources that are no longer in use (called Garbage Collection). Shen possible, it’s better to recycle virtual resources, rather than destroy and create anew. The following levels will demonstrate how to reuse resources by updating the position of objects to conserve precious computing power!

### Levels

Students should play the first four levels:

* The Rule of the Square
* The Big Guy
* Quantum Jump
* Looping Forest

#### The Rule of the Square

We recommend reviewing this level together as a class so that students understand what’s happening in the code. Here are some key points to review:

* The update event is a low-level event which happens each time the game loop updates the current state, giving the programmer an opportunity to update the scene once per frame.
* The update event can be run for each unit, or for the game in general. This level demonstrates both, with update events both for the units being spawned and the game.

To solve this level, the student must make sure each unit type has the update event set up:

<pre>
// Set the "update" event handler for "thrower" and "scout":
game.setActionFor("thrower", "update", onUpdateUnit);
game.setActionFor("scout", "update", onUpdateUnit);
// Set the "update" event handler for "archer" and "soldier":
<b>game.setActionFor("archer", "update", onUpdateUnit);
game.setActionFor("soldier", "update", onUpdateUnit);</b>
</pre>

And set up the game update command to periodically spawn thrower and scout units using the custom function spawnRandomUnit. It will be the same as the existing line that spawns archers and soldiers, as the `spawnRandomUnit` function has been set up to encompass the common functionality: random generation and a random y position, with a given x position. See the **discussion** question below for details on how these timers work to periodically run functions.

<pre>
function onUpdateGame(event) {
    if (game.time > game.spawnTime) {
        game.spawnTime += game.interval;
        spawnRandomUnit(2, "archer", "soldier");
        // Use spawnRandomUnit with parameters:
        // x is 78, type0 is "thrower", type1 is "scout":
        <b>spawnRandomUnit(78, 'thrower', 'scout');</b>
    }
}
</pre>

Lines to be added in **bold**.

#### The Big Guy

This level involves creating an automatic mechanism which keeps the player alive, gradually increasing their power and health until they overcome enough enemies. Every frame, the game will check if the player is becoming low in health, and increases their health, size, and attack damage.

To finish this level, students will use `player.on` and `game.on` to set up the existing event handlers, and call `checkTimers` and `checkGoals` inside `onUpdateGame`.

#### Quantum Jump

The focus of this level is that students can now directly set the position of a unit. This is different than the way they’ve previously had units move. With `moveXY`, `moveLeft` and alike, the units gradually move from one place to another over several frames, and are affected or stopped by obstacles. By setting the x or y position directly, the unit moves to the given place instantly. This can both be used for one-off “teleportation” behaviors, or fine-grained animation where the units behave according to some custom physics model. This level demonstrates the teleportation-like behavior. See the **discussion** question below for more details.

To solve this level, the user must set up the second stream of ogres to move instantly from the bottom of the screen to the top of the screen. That is, whenever an ogre reaches the bottom of the screen (where y is 0), their y position is set to 68 (the top of the screen). This is an example of resource re-use, as discussed earlier, which position setting enables. From the perspective of the end player, these are different ogres moving up and down the screen, but the game is using the same ogre “resource”. Magic!

<pre>
## This controls scout behavior.
def onUpdateScout(event):
    unit = event.target
    # Scouts always move down:
    unit.moveXY(unit.pos.x, unit.pos.y - 5)
    # If unit.pos.y is less than 0:
    <b>if unit.pos.y < 0:</b>
        # Set its pos.y property to 68:
        <b>unit.pos.y = 68</b>
</pre>

And set up the player to move over the fence when the player reaches the fence.

<pre>
def onCollide(event):
    unit = event.target
    other = event.other
    # If other.type is "munchkin" or "scout".
    if other.type == "munchkin" or other.type == "scout":
        # The enemy's stomped the player.
        unit.defeat()
    # If other.type is "fence":
    <b>if other.type == "fence":</b>
        # Use unit.pos.x to change the player x coordinate.
        # Add 6 to the player's x position:
        <b>unit.pos.x += 6</b>
</pre>

Lines to be added in **bold**.

#### Looping Forest

Having introduced the `update` event, the course moves to teaching setting position. Students must set up their code to prevent ogres from leaving a certain area. If an ogre is getting too far away, the game will reposition them closer to the center of the game.

To pass this level, students must finish the `onUpdate` logic. The forest edges are at x = 10, x = 70, y = 10 and y = 58\. They are provided with logic to teleport units from the left edge to the right side of the map. The rest of the if statements move the unit from right to left, top to bottom and bottom to top. The result should be that whenever a unit reaches any of these sides, the unit “jumps” to the opposite side. Make sure that the units are teleported to a position “inside” these bounds, otherwise they may jump around with every update!

### Discussion

**How do the timers work in The Big Guy and The Rule of the Square?**

We have seen these timers in previous levels. We set a property to the game which we use to track when is the next time to do something. Then the game constantly checks to see if game.time is equal to or greater than that value. When that happens, the action is triggered and the value is updated. Walk through some pseudocode to make sure students understand how this works.

```
game.triggerTime = 4
at regular intervals:
  if game.time >= game.triggerTime:
    doSomething()
    game.triggerTime += 4
```

This triggers `doSomething` every four seconds, when `game.time` is 4, 8, 12, etc.

**What happens if you don’t include the part which increases `game.triggerTime`?**

Then `doSomething` is called once every game update, which can happen dozens of times a second! Updating `game.triggerTime` is critical to properly throttling this event.

**How is moveXY different than setting pos?**

`moveXY` is one of several in-game “actions”. When `moveXY` or other game actions such as `attack` or `moveLeft` is called, the game engine updates the unit over several frames based on a number of factors, such as the unit’s speed, acceleration, and obstacles. This is a convenient high-level function, if that’s the sort of behavior you want for your game.

Setting `pos` is low level. It sets the unit’s position for that frame, directly, immediately, and without taking any other state into consideration. For example, you can move a unit on top of a forest that `moveXY` is designed not to allow.


---

## Animations

### Introduction to Animations

Before beginning the levels, walk the class through some mental exercises on how animations in code work.

First, review what was discussed the previous module: when setting position, the unit moves instantly to that position.

Then, talk about how animations work in film. A flipbook is a good example of how a string of images, when shown in rapid succession, display an animation. In claymation films of a given model, the operator goes back and forth between adjusting the model and taking a picture of the model. Computer animations work similarly.

By combining the update command and setting position, students can make all sorts of animations and unit behaviors. At this point, discuss different sorts of visual behaviors seen in games, and sketch how the logic in those games might look.

### Discussion

**What are some various examples of movement in games?**

That is to say, game physics. Games often model various combinations of gravity, momentum and friction. The goal is to come up with a few which are clearly different from one another, or to look at specific games and articulate how movement within them generally work.

Examples:

* Asteroids: a spaceship moves at constant speed across the field, and changes speed and direction with thrusters
* Platform game: character falls with gravity, stopping when they land on the ground, or reverses speed when they land on something bouncy.
  * Mario Bros 2 on NES and various Mario games since exemplify slight physical variants: Mario, Luigi, Toad and Peach have different running and jumping behaviors.
* Pong or Breakout: a ball bounces at constant speed, reversing direction whenever it hits a surface, changing direction and speed specifically depending on where it hits the paddle or how fast the paddle is moving.

**How would some of these behaviors look like in code?**

Having identified and generally described a few different types of game movement, now bring it closer to code by writing pseudocode for them.

A unit going at constant speed to the upper right

```
unit.xSpeed = 1
unit.ySpeed = 1
every frame:
  unit.pos.x += unit.xSpeed
  unit.pos.y += unit.ySpeed
```

A unit under the effect of gravity

```
every frame:
  decrease unit.ySpeed slightly
```

A unit that bounces when it reaches the “floor”

```
every frame:
  if the unit is below y position 0
    reverse the y direction by multiplying it by -1
```

An object moving clockwise in a circle with a central point of 20, 20 and radius 10

```
every frame:
  unit.pos.x = 20 + sine(game.time) * 10
  unit.pos.y = 20 + cosine(game.time) * 10
```

Along an arbitrary path, where each segment of the path is a line which is animated within a certain period of time. For example, this item moves right and then left.

```
if game.time > 0 and game.time < 1
  unit.speedX = 1
  unit.speedY = 0
if game.time > 1
  unit.speedX = 0
  unit.speedY = 1
```

It’s particularly important to discuss the bouncing effect, given that both levels use it. Discuss frame-by-frame what will happen in this example code:

```
unit.pos.y = 20
unit.speed = 10
every frame
  if unit.pos.y >= 40:
    unit.speed *= -1
  if unit.pos.y <= 0:
    unit.speed *= -1
  unit.pos.y += unit.speed
```

The state of `unit.pos.y` will be, from one frame to the next, 20, 30, 40, 30, 20, 10, 0, 10, 20, etc. This is because when `unit.pos.y` reaches 40, `unit.speed` is multiplied by -1, and becomes -10\. When this happens, with each interval, instead of adding 10 to the position, -10 is added, so the unit moves in the opposite direction. When it reaches 0, the speed is multiplied by -1 again, and the position starts increasing once more.

### Levels

#### Smooth Run

Now that students have been introduced to both the update event and the ability to set positions, they are now shown how to animate units, shifting them up and down and left to right continually.

The fire spewer serves as an example of how to animate something moving left to right, back and forth. You need to track speed, and what direction the unit is going. The speed is a number, the distance to be changed per frame, and the direction is either 1 or -1, to be multiplied by the speed. If the speed is multiplied by -1, it is now movement to the left, otherwise it’s movement to the right. The update event reverses the direction once the spewer has reached a certain position.

The fences move similar to the fire spewer, but up and down instead of side to side. It is up to the player to fill in the gaps of logic for the fences, based on how the animation is set up for the fire spewer.

<pre>
def onUpdateFence(event):
    fence = event.target
    # Multiply fenceSpeed and fence.dir to calculate the moving distance and direction.
    # Assign the result to the variable 'dist':
    <b>dist = fenceSpeed * fence.dir</b>
    # Add the value of the 'dist' variable to fence.pos.y:
    <b>fence.pos.y += dist</b>
    # If the fence's y position is less than 10 or greater than 56:
    if fence.pos.y > 56 or fence.pos.y < 10:
        # Multiply fence.dir by -1 and save it:
        <b>fence.dir *= -1</b>
</pre>

Lines to be added in **bold**.

#### Looney Gems

This takes animations to the next step: combining both x and y movement to demonstrate moving diagonally. This also uses the `dir` property, but now it can be set to 0, in which case the gem does not move on that axis at all.

To complete this levels, students will finish the `onUpdate` event function. First, they will update the item position by the given `diffX` and `diffY`, and then they will reverse `item.dirY` when the gem reaches either the top or bottom of the level. As in Smooth Run, the “edges” of the map are y = 10 and y = 58\. See the **discussion** above on how bouncing behaviors are implemented.

### Discussion

**What are some other animations that could be created with the update event and setting unit position?**

This is also a good time to discuss some of the examples listed in the earlier discussion.

**What are some other properties that you can adjust over time?**

Examples:

* Health, such as if a unit is affected by poison or health regeneration
* Scale, such that the unit gradually grows or shrinks over time
* Movement speed, such as being dependent on what surface the unit is moving through


---

## Runner

### Summary

This series of levels walks students step-by-step through creating a side-scrolling arcade game. This helps them see and practice integrating these concepts into a more complex project, and prepares them for doing the same sort of iterative process in this course’s final project.

### Levels

#### Runner Part 1

This level provides the basic structure for the runner game. To pass this level, students will finish the `onUpdateStatic` function which destroys fences which reach beyond the left side (x = -4) of the level, and re-uses the forest tiles. See the earlier discussion on resource re-use, and the Quantum Jump level for earlier examples of this behavior.

Students should also review the rest of the provided code:

* `spawnRandomY` creates the fence
* `spawnFences` creates a number of fences, increasing the number of fences as time goes on.
* `onCollide` has fences defeat the player when there is a collision
* `checkPlayer` keeps the player locked in one place
* `checkTimers` periodically calls `spawnFences`

#### Runner Part 2

This level introduces gems, top score saving and infinite play. The gems code is fairly similar to previous levels: the collect event (when completed by the player) adds to the game score whenever a gem is collected. The game property `topScore` is fetched from the db when the game is set up, and is updated when the game ends with `setTopScore`.

The `onDefeatPlayer` method, which the user completes, requires special attention. The way the CodeCombat game system works, the game is "over" when goals are completed, that is either succeeded or failed. However, this level allows the game to continue indefinitely, for however long the player can go without colliding with a fence. The game is "won" when the player survives for 20 seconds, but in order to allow the player to go further, this goal is not marked complete until the player is defeated, and is marked as successful or failed depending on the `game.time`. This is why the manual goal is set to success or failure in the player's `defeat` event handler.

#### Runner Part 3

This level adds ogres to the mix. The code comes with `onDefeatOgre`, which adds to the score when an ogre is defeated. The two functions that the user must finish are `onUpdateOgre` and `spawnOgre`. `spawnOgre` needs to set up the `update` and `defeat` events for the spawned ogre. `onUpdateOgre` is more complex and interesting to dissect; see discussion below for details.

#### Runner Part 4

This level is similar to Part 3, except that various values have been refactored to the top of the level as variables, and those values have been set to make the game challenging (though not impossible) to win. Like with Game of Coins, students are encouraged to experiment with the variables, making hypotheses about how changing them will affect the game and then testing them. They must at least make the values such that it's possible for them to win the game.

Group Activity: Have students group up and each adjust the level to various amounts of difficulty. For example, have one group make an easy difficulty, one medium, one hard, one impossible. Have the groups demonstrate and explain the games they built.

### Discussion

**Why is `onUpdateOgre` structured the way it is?**

This function is a hybrid of CodeCombat and user logic. Because the ogre `behavior` property is set to `”AttacksNearest”`, the ogre will move toward the player and attack when close enough. However, for this game we want the Ogre to move at a given pace to the right to a specific point (x = 18) and then stop moving further to the right. So, this update function runs after CodeCombat has moved the ogre some distance up or down and to the right in the direction of the player, and overrides whatever the game set to `unit.pos.x` with a value based on an independently tracked and updated `unit.baseX` property. So for example, in a single “frame”, the unit’s state will evolve like so:

Starting position: { x: 5, y: 5, baseX: 5 }

After game has moved unit slightly closer to the player: { x: 6, y: 6, baseX: 5 }

After the custom `onUpdateOgre` command has run: { x: 5.03, y: 6, baseX: 5.03 }

The game’s “y” change has been left intact, but the x position change has been overwritten.

**What would happen if `onUpdateOgre` ran for all ogres, not just the defeated and undefeated?**

Give students an opportunity to write down what they think will happen. They can then test out their assumptions by modifying the code from `if unit.health > 0` to `if unit.health > -100` or `if True`. When they play the game, the ogres will no longer “fall” to the left. They will keep up with the player!


---

## Game Development 3 Project

### Summary

Have students design and iteratively build their own projects, as in Game Development 2.
