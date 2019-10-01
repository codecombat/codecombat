
###### Last updated: 03/06/2019

##### Lesson Plans
# Game Development 1

_Level: Beginner_

_Prerequisite: Introduction to Computer Science_

_Time: 4 x 55 minute (minimum) sessions_

###  Overview
This course is designed to introduce students to game design and development through classroom discussions and hands-on programming. Students will learn the specific commands needed to make a game while navigating through the game development levels. This will culminate in a final project in which each student designs and creates their own unique game and collects peer feedback for improvement.

_This guide is written with Python-language classrooms in mind, but can easily be adapted for JavaScript._

### Lessons

| Module                                                    | Levels                                          | Topics                       |
| ---------------------------------------------------------- | :-----------------                             | :--------------------------- |
| 1. Spawnables and Mechanics   |  1-5 ("Over the Garden Wall" -"Gemtacular")    | Spawning objects, mechanics  |
| 2. Goal Changes                          |  6-11 ("Vorpal Mouse" - "Hedge Magic")         | Goals, types of spawnables   |
| 3. Changing Properties                      |  12-16 ("Forest Incursion" - "Time to Live")   | Properties                   |
| 4. Final Project - Tabula Rasa           |  17 ("Tabula Rasa")                            | All course topics combined   |


### Key Terms

**Player** - The person who plays the game and controls the game piece (_example: In Tetris, the person who presses a button to drop the blocks into place._)

**Goal** - A task that a player must perform to win (or progress in) a game (_example: The player must collect all the gems before progressing to the next level._)

**Mechanic** - The rules that govern how a player interacts with a game and how the game interacts with a player (_example: In platform games, the player presses a button that makes the hero jump._)

**Spawnable** - An **object** in a game that a student can add to their game using the _spawn_ command. (_example: scenery, characters, and gems_)

**Property** - A characteristic of an object. (_example: The x-position of the gem that is being spawned._)

---

# Lesson 1
## Spawnables and Mechanics
_Levels "Over the Garden Wall" (1) - "Gemtacular" (5)_
### Summary

These levels provide students with the tools they need to add spawnable objects to their game and goals to the levels they design. Students will learn about basic game mechanics and designing levels with clear goals.

#### Materials
- Sticky Notes
- Markers

Optional Materials:
- [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf)
- [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)


#### Learning Objectives

- Use correct syntax when writing code.
- Use proper sequencing when writing code.
- Use arguments to input information into a method.
- Use suitable methods for spawning objects and defining game goals.
- Define basic vocabulary: _spawnable_, _mechanic_, and _goal_.

#### Standards

- **CSTA 1A-AP-10** Develop programs with sequences and simple loops, to express ideas or address a problem.
- **CSTA 1A-AP-15** Using correct terminology, describe steps taken and choices made during the iterative process of program development.

### Opening Activity (10 minutes): _Game Breakdown_

#### Explain

Define the terms goal, mechanic, and spawnable for students. (You can find definitions in the Key Terms section on page 1.) For each term, have students share out examples from their favorite games.

Tell students they'll have the opportunity in this unit to design a game with all these components. They'll start today by learning how to spawn objects.

#### Interact

Divide the class into groups of 3-4 students.

Find a simple online game on an education website (could be anything from a simple 2048-like game to a more complex adventure game). Project the game and play in front of the class while students watch.

Allow students time to discuss in their groups what they think the **goals**, **mechanics**, and **spawnables** are in the game.

Have students in groups write down on sticky notes their consensus about the **goals**, **mechanics**, and **spawnables** in the game. Students should post their sticky notes at the front of the class.

#### Discuss

As a full class, check whether most of the groups had the same thoughts on their sticky notes. Have students discuss and justify their answers if there were disagreements.

Then, use one or more of the following discussion questions to prompt reflection on the activity:

**What did the games that we looked at have in common?**

Sample Response:

> Each game had a clear goal that the player had to complete in order to advance to the next stage. Also, each game had a way that the player interacted with it and some objects that the player had to manipulate in some way.

**What was different about the games that we looked at?**

Sample Response:

> The goals, mechanics, and spawnables in the games were different and therefore changed the player's experience completely.

### Coding Time (40 minutes)

Tell students they will be playing levels 1 - 5 ("Over the Garden Wall" - "Gemtacular") today.

Recall for students that they used commands like `hero.moveRight()` in the Introduction to Computer Science levels. Explain that instead of programming the hero to work through the levels of a game, they will be designing those levels themselves. Therefore, for many of the methods they will be using, they will use **game** instead of **hero**.

_Example_: `game.spawnXY("gem", 20, 34)`

Allow students to move through these levels at their own pace. Circulate and assist as they work, calling attention to the Hints button in the top right corner of each level as needed.

_We recommend stopping students after Level 5 ("Gemtacular") and using the next lesson plan to introduce the next set of concepts before beginning Level 6 ("Vorpal Mouse")._

**Look Out For**:
- Students may have trouble with the X/Y coordinates initially. You may want to do a brief review of that concept if students seem to be struggling with placing objects onto the screen where they want them. Remind them that the (0,0) coordinate corresponds to the bottom lefthand corner of the screen, and that they can see the coordinates for a given point if they hover over it with their mouse.

### Closure (5 mins)

Use one or more of the following questions to prompt reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**Explain the parts of a game in your own words.**

Sample Response:

> Games have goals, mechanics, and spawnables. Goals tell the player what they should do to win. Mechanics are anything the player interacts with in the game world (like picking up coins to buy things at a store). Spawnables are things that show up on the screen that the player may interact with.

**Explain the difference between a mechanic and a goal.**

Sample Response:

> Mechanics just tell the player how they can play the game, and these could change depending on the design. Goals are specific and tell the player how they can win.

### Differentiation

**Additional Supports**:
- Show students how to find the hints, methods reference cards, error messages, and sample code provided within each level.
- Students struggling with a given level will be automatically directed to additional practice levels within the game.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If student struggle with breaking down problems, you can use the printable [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) to reinforce a step-by-step problem solving approach.
- If students struggle to follow correct syntax, provide a copy of the printable [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)

**Extension Activities**:

- Have students try different types of spawnables in their "Gemtacular" (Level 5) code, like adding to the forest or setting up fences to make the maze more difficult.
- Have students draw out a maze on paper that they would like to build later on in the Game Development course.

******

# Lesson 2
## Goal Changes 
_Levels "Vorpal Mouse" (6) - "Hedge Magic" (11)_
### Summary

These levels provide students with practice modifying goals and spawning different types of objects needed in order to meet those goals.

#### Materials

Optional Materials:
- [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf)
- [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)


#### Learning Objectives

- Use correct syntax when writing code.
- Use proper sequencing when writing code.
- Use arguments to input information into a method.
- Differentiate between different kinds of goals and spawnable objects.

#### Standards

- **CSTA 1A-AP-15** Using correct terminology, describe steps taken and choices made during the iterative process of program development.

### Opening Activity (10 minutes): _Arguments Throwback_

### Review

Discuss **arguments** as they were seen in Introduction to Computer Science. Have students give examples of when they may have used arguments in the past.

Sample Response:

> In Introduction to Computer Science when I used the `hero.moveRight(5)` command and could change the number of steps I moved.

Ask students where they have used **arguments** in the Game Development course.

Sample Response:

> When I use the `game.spawnXY("chest", 8, 14)` command and I can change all the arguments like `game.spawnXY("forest", 26, 51)`. This changes the type of thing that I spawn and the place where it is spawned on the screen.

#### Interact

Draw the following chart on the board, and have students sketch it in their notebooks.

Goal              | Move Goal                  | Collect Goal                | Defeat Goal                  | Survive Goal                |
----------------- | -------------------------- | --------------------------- | ---------------------------  | --------------------------- |
Description       |                            |                             |                              |                             |
|           |            |             |            |
Spawnables Needed |                            |                             |                              |                             |
 |          |           |             |                    |
Syntax            |                            |                             |                              |                             |



Have students work in groups to briefly complete the graphic organizer comparing the different types of goals. Notify students that there are some goals that they have not yet encountered in the game -- they can fill out these columns later when they do encounter them.

### Coding Time (40 minutes)

Tell students they will be playing levels 6 ("Vorpal Mouse") - 11 ("Hedge Magic") today. Allow students to move through these levels at their own pace. Circulate and assist as they work, calling attention to the Hints button in the top right corner of each level as needed.

_We recommend stopping students after Level 11 ("Vorpal Mouse") and using the next lesson plan to introduce the next set of concepts before beginning Level 12 ("Forest Incursion")._

**Look Out For**:
- Students may struggle with knowing what is required for a given goal. For example, a level will not be able to be completed if there is a collect goal and no gems to collect. Help them to use their graphic organizers to apply what is required for a given goal.

### Closure (5 mins)

Use one or more of the following questions to prompt reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**How can you change the location of the spawnable that you are putting on the screen?**

Sample Response:
> I can edit the arguments for the x-position and y-position in the `game.spawnXY(type, x, y)` command to place them where I want to.

**What makes the survive goal unique from the other goals?**

Sample Response:
> In the other goals, you have to complete some task. In the survive goal, you just have to stay alive until the time runs out.

### Differentiation

**Additional Supports**:
- Show students how to find the hints, methods reference cards, error messages, and sample code provided within each level.
- Students struggling with a given level will be automatically directed to additional practice levels within the game.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If student struggle with breaking down problems, you can use the printable [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) to reinforce a step-by-step problem solving approach.
- If students struggle to follow correct syntax, provide a copy of the printable [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)

**Extension Activities**:

- Have students add onto their "Hedge Magic" (Level 11) code to include two goals and the ability to win the level.

******

# Lesson 3
## Changing Properties 
_Levels "Forest Incursion" (12) - "Time to Live" (16)_
### Summary

These levels allow students to apply their knowledge of objects from Introduction to Computer Science in the context of game development. They also introduce students to the concept of properties.

#### Materials

Optional Materials:
- [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf)
- [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)


#### Learning Objectives

- Apply knowledge of object properties to game development.
- Change properties in order to modify game behavior for desired goal.

#### Standards

- **CSTA 1A-AP-15** Using correct terminology, describe steps taken and choices made during the iterative process of program development.

### Opening Activity (10 minutes): _Objects and Properties_

### Review

Discuss **objects** as they were seen in Introduction to Computer Science. Have students give examples of what objects they have encountered so far.

Sample Response:

> In Introduction to Computer Science I used the `hero` object and in this class I use the `game` object.

### Explain

Explain the term **property** to your students.

- **Properties** are characteristics of objects. This could be any data related to an object, like the max health of the hero or the direction that the fire travels from the fire-spewer.

Have students identify the **properties** of different **objects** in the classroom. For example, have students list the **properties** of the desks or tables where they're sitting. Note that the **properties** they are identifying, like the size, shape, and color of the **object** are **values** that correspond to **keys**. Identify that each property will have this kind of **key**, **value** pair, with the **property** **key** being **size** and the **value** being **3 feet**.


### Coding Time (40 minutes)

Tell students they will be playing levels 12 - 16 ("Forest Incursion" - "Time to Live") today. Allow students to move through these levels at their own pace. Circulate and assist as they work, calling attention to the Hints button in the top right corner of each level as needed.

_We recommend stopping students after Level 16 ("Time to Live") and using the next lesson plan to introduce the final project before beginning Level 17 ("Tabula Rasa")._

**Look Out For**:
- Students may be able to change properties effectively in code, but be sure to check that students understand the significance of these changes. Students should be able to explain what changing properties does practically in the game.

### Closure (5 mins)

Use one or more of the following questions to prompt reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**Why is it helpful to be able to change the properties of different objects?**

Sample Response:

> When developing my game, I can control the way characters look and how they are able to interact with each other.

**How is changing an object's properties different from using a method like `hero.moveRight()`?**

Sample Response:

> Changing an object's properties changes the data that is stored as part of an object. Using a method allows the object to do something, but doesn't necessarily change the data associated with the object.

### Differentiation

**Additional Supports**:
- Show students how to find the hints, methods reference cards, error messages, and sample code provided within each level.
- Students struggling with a given level will be automatically directed to additional practice levels within the game.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If student struggle with breaking down problems, you can use the printable [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) to reinforce a step-by-step problem solving approach.
- If students struggle to follow correct syntax, provide a copy of the printable [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)

**Extension Activities**:

- Have students who finished early play through each other's Level 16 ("Time to Survive") games and give each other feedback on how they could make the level more difficult.

******

# Lesson 4
## Changing Properties 
_Levels "Tabula Rasa" (17)_
### Summary

This level is a blank slate. Encourage students to get creative with all the techniques they've learned throughout the course! The students should each design a game combining the game objects, goals, and mechanics they've learned in creative ways. The game should at least:

1. Spawn a player.
2. Add one or more goals for the player to complete.
3. Use some combination of obstacles, enemies, collectables, and other pieces to create a fun challenge for the player.

#### Materials
- Sticky notes (3 different colors)
- Wall space / poster boards / flip charts

Optional Materials:
- [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf)
- [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)


#### Learning Objectives

- Apply the tools and concepts introduced throughout the Game Development 1 Course to a creative game.
- Explain in words the design decisions that led them to their specific program and game.

#### Standards

- **CSTA 1A-AP-15** Using correct terminology, describe steps taken and choices made during the iterative process of program development.
- **CSTA 3A-AP-23** Document design decisions using text, graphics, presentations, and/or demonstrations in the development of complex programs.

### Opening Activity (10 minutes): _Project Planning_

### Explain

Explain the following steps that students should work through to create their games:

  1. **Design.** This can be done on paper. Describe the idea, sketch the map, list the goals.
  2. **Plan.** Take the design and write a flowchart or plain-English plan for how students will code the project in the game engine.
  3. **Build.** Take the initial design, and build it in the game engine (in this case, use the level Tabula Rasa to build the game).
  4. **Test.** As the students build their game, they should always be testing it by playing the game.
  5. **Feedback.** The students should share their game link with friends and gather feedback about what makes the game fun or frustrating.
  6. **Improvements.** Based on the feedback, the students go back to the building phase and make improvements to the game.

### Work Time (50-100 minutes)

Tell students they will be playing Level 17 ("Tabula Rasa") for the next few days, creating their own game. Emphasize that the first two steps of the process do not require their computers and can be done in their notebooks or on the white board. Do not allow students to jump straight into code.

**Look Out For**:
- Many students may be able to achieve the basic goals to beat the level very early. Encourage students to add additional elements to their game to make it interesting and challenging.
- Many students may want to skip over or rush through the design and planning phases. Encourage them to take these steps seriously and spend a minimum of 15 minutes on them. Point out that real game designers always start with a plan before jumping in because it helps them anticipate sticky spots where things might not work as they originally thought.


### Closure (5 mins)

Use one or more of the following questions to prompt reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**Did your original idea for the game change once you started programming? Why or why not?**

Sample Response:

>Once I started programming, I realized that I couldn't include all the different goals that I had planned for at the very beginning. I changed my code so that there was one goal first, then I was able to add on after that.

**Did anything surprise you when your classmates were playing your game? Did you make any changes after watching them play your game?**
Sample Response:
>My game was easier to beat than I thought it would be. I want to make it more challenging.

### Differentiation

**Additional Supports**:
- Show students how to find the hints, methods reference cards, error messages, and sample code provided within each level.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If student struggle with breaking down problems, you can use the printable [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) to reinforce a step-by-step problem solving approach.
- If students struggle to follow correct syntax, provide a copy of the printable [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)


## Encourage the students to share links to their final projects with family and friends!
## We'd love to hear about your best projects! Feel free to e-mail us at team@codecombat.com with a link, or better yet, tweet us @CodeCombat.
