###### Last updated: 08/23/2016

##### Lesson Plans
# Computer Science 2

### Curriculum Summary

- Target grades: 5-6
- Recommended Prerequisite: Introduction to Computer Science
- 7 x 45-60 minute coding sessions

#### Overview
Armed with basic knowledge of the structure and syntax of simple programs, students are ready to tackle more advanced topics. Conditionals, arithmetic, input handling, oh my! Computer Science 2 is where students move past the programming-toy stage into writing code similar to that they would use in the next major software or killer app!

In Computer Science 2, students will continue to learn the fundamentals, (basic syntax, arguments, strings, variables, and loops) as well as being introduced to a second level of concepts for them to master. If statements allow the student to perform different actions depending on the state of the battlefield. Arithmetic will help players become more comfortable with using math in programming. All things in CodeCombat are objects, (that's the ‘object’ part of object-oriented programming,) and these things have accessible attributes, such as a Munchkin's position or a coin's value; both  are important to begin visualizing the internal structure of the objects that make up their game world. Near the end of the Course there are some levels dedicated to input handling so the students can get introduced to the basic concept of events, and, well, it's just great fun, too!


_This guide is written with Python-language classrooms in mind, but can easily be adapted for JavaScript._

### Scope and Sequence

| Module                                                | Levels           |  Transfer Goals  |
| ----------------------------------------------------- |:-----------------|:-----------------|
| [5. Conditionals (if)](#conditionals-if-)             | 1-9              |Check expression before executing|
| [6. Conditionals (else)](#conditionals-else-)         | 10-17            |Execute default code|
| [7. Nested Conditionals](#nested-conditionals)        | 18-20            |Put one conditional inside another|
| [8. Functions](#functions)                            | 21-30            |Save code for later|
| [9. Properties](#properties)                          | 31-33            |Access information about objects|
| [10. Review and Synthesis](#review-and-synthesis)     | 34-36            |Use appropriate vocabulary|
| [11. Code Challenge](#code-challenge)                 | 37               |Design and implement algorithms|

### Core Vocabulary
**Object** - a character or thing that can perform actions. Objects are the building blocks of Python. They are things or characters that can perform actions. Your `hero` is an object. It can perform the moving actions. In `hero.moveRight()`, the object is `hero`. In Course 2, students will also be using the `pet` object to perform actions.

**Function** - an action performed by an object. Functions are actions an object can do. `moveRight()` is a function. Function names are always followed by parentheses.

**Argument** - additional information for a function. Arguments are what we put inside the parentheses of a function. They tell the function more information about what it should do. In `hero.attack(enemy)`, `enemy` is the argument.

**Property** - data about or belonging to an object. You get to it by specifying the object, then a dot, then the name of the property.

**Loop** - code that repeats. A loop is a way of repeating code. One way of writing loops uses the keyword `while`, followed by an expression that can be evaluated as `True` or `False`.

**Variable** - a holder for data. A variable holds your data for later. You create a variable by giving it a name, then saying what value it should hold.

**Conditional** - the building block of modern programming, the conditional. It’s named as such because of its ability to check the conditions at the moment and perform different actions depending on the expression. The player is no longer able to assume there will be an enemy to attack, or if there is a gem to grab. Now, they need to check whether it exists, check if their abilities are ready, and check if an enemy is close enough to attack.

**Arithmetic** - Course 2 begins to ease the player into using math while coding. Levels catering to basic arithmetic address how to use math as needed in order to perform different actions effectively.

**Input Handling** - Input handling allows players to finally interact with their hero in real-time. After submitting their code, the player will be able to dynamically add flags to the battlefield to assist their hero in solving tough challenges. It helps teach simple event handling as well as being quite fun!



#### Extra activities for students who finish Course 2 early:
- Help someone else
- Write a walkthrough
- Write a review of the game
- Write a guide to their favorite level
- Design a new level

##### Module 5
## Conditionals (If)

### Summary

Course 2 introduces more advanced programming concepts, so the progress through the levels should be slower. Pay careful attention to the directions, so you know what the goal of the level is, and to the in-line comments (denoted with a `#`) so you know what code is missing.

### Transfer Goals
- Construct a conditional
- Choose appropriate expressions
- Evaluate expressions

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.
**CCSS.Math.Practice.MP4** Model with mathematics.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Conditionals (10 mins)
#### Explain (2 mins)
Conditionals carry out code depending on the state of the game. They start by evaluating a statement as `True` or `False`, then they carry out the code only if the statement is `True`. Notice that the syntax is similar to a loop, since it needs a colon and a four-space indent.

`if` is the keyword, and `==` is the expression
``` python
if enemy == “Kratt”:
    attack(enemy)  # This is the action
```

The keyword for a conditional is `if`. A conditional on its own will only happen once, but if you want it to keep checking, you have to put it inside a loop. Notice how the indentation works.


``` python
while true:
    if enemy == “Kratt”:
        attack(enemy)
```

#### Interact (5 mins)
Rewrite your classroom rules as conditionals using Python syntax.

Identify some school or classroom rules, and write them on the board, e.g.
- Raise your hand to ask a question.
- You get a detention if you’re late.
- Stop talking when the teacher claps twice.

Reformulate them in English to start with the word “If”, e.g.
- **If** you have a question, then raise your hand.
- **If** you’re late, then you get a detention.
- **If** the teacher claps twice, then stop talking.

Now reformulate again using Python syntax, e.g.

``` python
if student.hasQuestion():
    student.raise(hand)
```
``` python
if student.ArrivalTime > class.startTime:
    teacher.giveDetention(student)
```
``` python
if teacher.claps == 2:
    class.volume = 0
```

Label each of the parts of the conditionals: *keyword*, *expression*, *action*.

#### Explain (1 min)
Code is called code because we’re encoding our ideas into a language the computer can understand.  You can use this three-step process of reformulating your ideas any time you’re writing code. As long as you know the syntax of the programming language, you know what the encoded idea should look like!

#### Reflect (2 mins)
**Why do we need conditionals?** (Not all actions happen all the time)
**What is the part that comes between the if and the colon?** (an expression)
**What’s important about expressions?** (They have to be True or False)


### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Students will need to use (x,y) coordinates to specify locations. Exact coordinates can be found by placing the mouse pointer over the target position. Students will also have to use a conditional to check if a condition is met before taking an action.

### Written Reflection (5 mins)
**What does if mean? What kinds of things did you write after if?**
>If does the code only if it’s true. You can see if all kinds of things are true, like if your weapon is ready or if the enemy is close. Sometimes you need == or >, but sometimes you only need the ().

**If you could design a CodeCombat level, what would it look like?**
>There would be lots of ogres and you have to attack them, but not the humans. And you would protect the village by building walls and fires.


##### Module 6
## Conditionals (Else)
### Summary

These levels have two things going on at once. Students have to decide under which condition to do each action. This is a good point to have a tips & tricks discussion, where any student who wants to share a discovery or shortcut with the class may present their advice.

### Transfer Goals
- Construct an if-else conditional.
- Identify different actions taking place in different circumstances.
- Define `else` as the opposite of `if`.

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.
**CCSS.Math.Practice.MP7** Look for and make use of structure.
**CCSS.Math.Practice.MP8** Look for and express regularity in repeated reasoning.

### Instructive Activity: Conditionals (Else) (10 mins)

#### Explain (2 mins)
We’re used to using conditionals to do something if the expression is `True`, but what if it’s `False`? That’s where `else` comes in. `else` means “if not” or “otherwise” or “the opposite”.

Notice that `else` must be indented the same number of spaces as the if it goes with. And it also needs a colon `:` just like `if`.

Below, `if` and `else` are keywords, and `==` is the expression
``` python
if today == weekday:
    goToSchool() # action
else:  # keyword
    watchCartoons() # action
```


#### Interact (6 mins)
Revisit the classroom rules from the previous lesson and see if any need else statements, e.g.

``` python
if student.hasQuestion():
    student.raise(hand)
else:
    student.payAttention()
```

``` python
if student.ArrivalTime > class.startTime:
    teacher.giveDetention(student)
else:
    teacher.markPresent(student)
```

``` python
if teacher.claps == 2:
    class.volume = 0
# this doesn’t need an else because no action is taken if the teacher doesn't clap
```

Label the parts of these conditionals: _keywords_ (`if` and `else`), _expression_, _actions_

#### Reflect (2 mins)
**What does else mean?** (if not)
**Why doesn’t else come with another expression?** (the expression is implied-- it’s the opposite of the if, or when the if is False)
**Do you always need an else?** (no, it depends on the situation)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. The crux of these levels is in deciding what should happen and when it should happen. Students have to entertain multiple possibilities to figure out what the best course of action is under every condition.  

### Written Reflection (5 mins)
**Do you know more code now than in the beginning? What powers do you have now that you couldn’t do before?**
>In the beginning I could just walk around. Now I can attack enemies and see who is closest. I can also put my mouse on the screen and see the coordinates of where to go. I can use if and else to do two different things. And I can use a loop to make my code repeat.

**What advice can you give to someone just starting out the game?**
>Read the directions. First figure out what you want to do and then worry about the code. You have to put : after while True and if. And you have to use four spaces every time. Most of the time the level will tell you what to do in blue writing and you just have to do it. You can use your gems to buy stuff.

**What do you do when you’re stuck?**
>I ask the person next to me if they have done this level. If I am ahead, I look at it some more until they catch up. Then we work on it together. Or I ask the teacher. Sometimes the answer is in the help or in the blue text.

##### Module 7
## Nested Conditionals
### Summary

Serious coding starts now. Students will have to remember how to construct conditionals and expressions, or refer to the tips below the code editor. These levels have three or more actions to control, so they require complex thinking and planning. Up to three levels of indentation are used, so checking spaces is vital to writing code that runs.

### Transfer Goals
- Construct a nested conditional
- Read and understand a nested conditional
- Attend to indentation

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Nested Conditionals (10 mins)

#### Explain (3 mins)
We started out with conditionals checking one thing before we took an action. Then we had two actions to do and had to decide which one to do when. But sometimes you have more than two things you want to do. That’s when you want to put a conditional inside another conditional.

The first conditional below is `if it's a weekend`, the second (nested) conditional is `if I have a soccer game`.
``` python
if it’s a weekend:
    if I have a soccer game:
        Wake up at 6
    else:
        Sleep in
else:
    Wake up at 7
```

Indentation starts to matter a lot now. We indent four spaces to put code inside a loop or conditional, and that includes other conditionals. The code inside the second conditional is indented a total of eight spaces.

#### Activity (5 mins)
Have students write the rules of their wake-up times, bedtimes, or recess times as nested conditionals. Do at least three different actions, so you have to use a nested conditional.

When they have finished, trade papers with a partner. Read each other’s schedules and discuss them. Check for syntax and indentation.

Invite volunteers to share their finished schedules with the class.

#### Reflect (2 mins)
**Why do we need nested conditionals?** (Because sometimes more than two different actions are possible)
**Why do we indent the second conditional by 4 spaces?** (To show that it is inside the first conditional.)
**What does it mean when an action is indented by 8 spaces?** (It depends on two expressions being True or False)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Make sure students are reading all the comments in the starter code before they start making changes. The goals are complex, so understanding each sub-goal is important. Encourage collaboration and allow students to help each other.

### Written Reflection (5 mins)
**Tell me about cleave.**
>Cleave smashes a bunch of enemies all around you. You do it by saying hero.cleave(). You have to put (), but you don’t need to say cleave(enemy). It just does it to everyone. Cleave takes a while to warm up, so you can check if it’s ready with the watch, and if it’s not ready yet just do a normal attack.

**Debate: Is your hero a good guy or a bad guy?**
>My hero is sort of a good guy and sort of a bad guy. He is a good guy because he protects the villagers from getting hurt. But he is a bad guy because he stole the gems from the ogres in the dungeon. And he kills people. Maybe he should protect the people without killing and not steal.

### Writing Checkpoint: Conditionals

**What is a conditional? How many different ways can you write a conditional? Give an example.**
>A conditional asks “if.” You can say if something is true, then do something. You can use else if you want to do something if that first thing was not true. Elif is for if you want to do three things, like if it’s raining wear a jacket elif it’s snowing wear a hat else wear a t-shirt. You can put ifs inside other ifs but you have to remember the right number of spaces.


##### Module 8
## Functions
### Summary
These levels give students the chance to take some shortcuts. Just like loops gave them the power to write more code quickly, functions enable reuse of code. Syntax remains vital; so check that colons and indentation are in the right place, and remember to read and understand the directions for each level before starting to code a solution.

### Transfer Goals
- Identify functions.
- Construct a function definition.
- Call a function.

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Functions (10 mins)
#### Explain
You’ve been using functions already! When you type `hero.cleave()`, `cleave()` is a function. So far you’ve only been using built-in functions, but you can also write your own. First, you need to define the function using `def`.

``` python
def getReady():
    hero.wash(face)
    hero.brush(teeth)
    hero.putOn(armor)
```

Then you need to call the function.

``` python
getReady()
```

**What is the difference between defining and calling?** (Defining needs def before, and a colon after. Then it has some code indented under it. They both have parentheses.)

Programmers use functions to make their code easy to read and quick to write. It’s sort of like a set play in basketball: you know how to shoot, dribble, and pass, so you can make up a function that combines those parts and give it a name.

``` python
def out-over-up():
    p1.dribble()
    p1.pass(p2)
    p2.shoot()
```

Then when the coach wants this sequence of actions to happen, she just calls out the name of the play: “Out-over-up!”

### Interact (5 mins)
**Simon Says.**

As a class, write your own functions for complicated Simon Says moves on the board using Python syntax. Here are some examples to get you started:

``` python
def pogo():
    student.handsOn(hips)
    student.jump()
```

``` python
def popcorn():
    if student.sittingDown():
        student.standUp()
    else:
        student.sitDown()
```

Then, play Simon Says by calling the functions, e.g.
- Simon says raise your hand!
- Simon says popcorn!
- Pogo! (Simon didn’t say)

### Reflect (2 mins)
**Why do functions make coding easier?** (Because you don’t have to say the complicated steps every time; you can just use the function name.)
**Why is it important to give your functions good names?** (So you can remember what they’re for later.)
**What does the keyword def stand for?** (define, or make)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips.
These levels are all about writing good code. The helper code that is given to you may have the word `pass` in it. This is just so the sample code doesn’t show any errors.   Once the students fill in their code, they should delete `pass`. When you help debug their code, look for `pass` first.

### Written Reflection (5 mins)

**Tell me about the cat.**
>I got a pet cat and it’s a cougar or a lioness. There was a function that said meow, and the cat waited until you talked to it and then it said meow. I think the cat should help protect you from enemies. You should be able to make it do other stuff by commands, like pouncing and biting.

**Why are functions useful? When would they not be useful?**
>They make it so you don’t have to write the same code over and over and they make your code easier to read. I don’t think it’s useful if you’re just going to put one line of code in your function. It would be easier just to write that one line every time.


##### Module 9
## Properties
### Summary
Flags give the game a real-time element. Players may place flags on the game screen, and have their hero respond to them. Either click on the flag color, or use the first letter of the color, then click on the screen to place the flag. Use `hero.pickUpFlag()` to make the hero go to the flag and clear it.

### Transfer Goals
- Access a property using dot notation.
- Save a property in a variable.
- Tell the difference between a property and a function.

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.
**CCSS.Math.Practice.MP4** Model with mathematics.

### Instructive Activity: Properties (10 mins)
#### Explain (3 mins)
A property is something about an object. You get to it by specifying the object, then a dot, then the name of the property. To get the position of a flag, type:

`flag.pos`

This is similar to functions, because both functions and properties are things that belong to the object. Functions are like actions or verbs and properties are like aspects (adjectives) or possessions (nouns).

Properties can have properties! Access them by adding another dot and another property.

`flag.pos.x`

Once you can get to a property, you can find out its value. Different flags have the same way of accessing their position properties, but those properties may have different values.

#### Interact (5 mins)
Property interview: Give each student a turn to ask something about another student by querying one of their properties. Write the object name and property on the board using Python syntax (dot notation), e.g.

  `amy.age`
  `victor.favoriteMovie`
  `marcia.height`
  `francisco.sister.name`

When the syntax is correct, the queried student should should out the value of that property, e.g.
	`12`
  `“Die Hard”`
  `4.5 feet`
  `“Diana”`

Note that everyone has an age property, and the same way of accessing it, but the values of that property are not the same for everyone!

#### Reflect (2 mins)
**What’s a property?** (Something about an object)
**How can you tell the difference between a function and a property?** Functions have parentheses (), properties do not.
**Can two objects have the same property?** (yes)
**Do two objects’ properties always have the same value?** (no)


### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Flags can be tricky for some students, so allow them to pair up to beat the levels. Each student should write their own code, but it’s ok for another student to place the flags for them.

###Written Reflection (5 mins)
**How did you use properties today?**
>I had to see where the flag was and the flag has a property called pos. Then inside that it has two more properties, x and y. You use a dot to get inside the object, or inside the property.

**Tell me about flags.**
>You use flags to tell the hero what to do when the game is running. You can write code to say if there’s a flag, then go to it. Flags have a pos that has x and y. X is right-left and y is up-down.

##### Module 10
## Review and Synthesis
###Summary
Read the instructions! Remember the hints! Sit and think about how to solve the problem and how you’ll be able to tell it’s solved. All the habits of mind of a good programmer come to bear on these levels: defining the problem, breaking the problem down into parts, making a plan, syntax and debugging, sticking to it, and asking for help.

### Transfer Goals
- Use appropriate vocabulary
- Persist in solving a problem

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.
**CCSS.Math.Practice.MP8** Look for and express regularity in repeated reasoning.

### Instructive Activity: Review & Synthesis (10 mins)

#### Interact (10 mins)
Review! As a class, try to remember all the new vocabulary words you learned so far. Decide on a definition and an example. Have students write these on the board and correct each other’s work. Consult the game where there are disputes.

**Object** - a character or thing can can do actions, hero
**Function** - an action that an object can do, hero.cleave()
**Argument** - additional information for a function, hero.attack(enemy)
**Loop** - code that repeats, while True:
**Variable** - a holder for a value, enemy = ...
**Conditional** - code that checks if, if hero.isReady():
**Property** - something about an object, flag.pos


### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Students will need to call on everything they have learned so far. It’s important they understand the instructions in the comments. If they are stuck, have them read the comment out loud and explain what it means in their own words. That way, you can identify which part is giving them trouble.

### Written Reflection (5 mins)

**What is elif? Is it an elf?**
>Elif means else if. You use it to do three things instead of two with if.  It’s like an elf because it’s tricky.

**Tell me about spaces.**
>You use four spaces to make code go inside a while True, if, else, or elif. If an if is inside another if, you have to use eight spaces. It’s important to count the spaces and get them exactly right, or else the computer thinks you mean something different. You have to be really careful.


##### Module 11
## Code Challenge
### Summary
This is a boss level! It will take all your ingenuity and collaboration to solve it. Have students work in pairs and share their tips with other teams. Make observations about the level on scratch paper, and then use them to make a plan. The goal of the level is to defeat the main boss, but you also have to collect coins, hire mercenaries, and heal your champion. The player area is in the bottom left, and the tents may be obscured by the status bar. Press SUBMIT to see the full screen.

### Transfer Goals
- Design an algorithm to solve a problem.
- Implement an algorithm in Python.
- Debug a Python program.

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.  
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.  
**CCSS.Math.Practice.MP3** Construct viable arguments and critique the reasoning of others.  
**CCSS.Math.Practice.MP5** Use appropriate tools strategically.  
**CCSS.Math.Practice.MP6** Attend to precision.  

### Instructive Activity: Engineering Cycle (10 mins)
#### Explain (5 mins)
Engineering is all about solving problems, but the first rule of engineering is that no one gets it right the first time. That’s where the Engineering Cycle comes in:

First, we DESIGN a solution to our problem. This includes figuring out what the problem is, and breaking it down into smaller parts. Then we IMPLEMENT this design, which putting our ideas into action with code. Third, we TEST our implementation. Does it work? Does it solve the problem? If our test fails, we have to decide if it was because of the DESIGN or the IMPLEMENTATION.

Then we keep designing, implementing, and testing until it the problem is solved!

#### Reflect (2 mins)
**What are the steps of the Engineering Cycle?** (Design, implement, test)
**When does the Engineering Cycle stop?** (When the problem is solved, or you run out of time)

#### Interact (5 mins)
As a class, make a list of all the things your hero can do (functions). Use appropriate vocabulary. Annotate with any tips or code snippets the students deem useful.
`moveUp()`, `moveDown()`, `moveLeft()`, `moveRight()`
`moveToXY(x,y)`
`attack(something)`

### Coding Time (30-45 mins)
Break into small campaign groups to solve the last level.

**DESIGN**: In teams, make observations about the level. Make a list of requirements. Decide what part of the problem you will start with.
**IMPLEMENT**: Write the solution to that part of your problem in code. Tip: Use a different function to solve each part of the problem!
**TEST**: Does your code work? If not, fix your code. If it does, does it solve the right part of the problem? If not, redesign. If so, move on to the next part!

### Written Reflection (5 mins)

**Write a chronicle of your epic battle from the point of view of either the hero or the boss.**
>I am Tharin Thunderfist, the great hero of the battle of Cross Bones. Together with my guardian, Okar Stompfoot, I attacked the ogres and freed the valley from their tyranny. I gathered coins to pay archers and fighters to join the battle. Then I cured Okar when he was injured.

**How did you break down the problem? What challenges did you come up against? How did you solve them? How did you work together?**
>First we saw that the code already did collecting coins. So we made it go to the tents when we could afford to hire fighters. Then we had to get the potion, but we messed up the code. The teacher helped us fix it. But we still didn’t win, so we asked another team for help and they showed us how to defeat the enemy. We worked well together. It was fun and hard.

### Writing Checkpoint: What is code?
>Code is when you type instructions to make the computer do things. Sometimes it gives you hints and completes the words for you. You have to spell everything right and indent the right number of spaces. Sometimes the puzzles are easy and sometimes they are hard. You have to make a plan for how to solve it, and then write the code exactly to make it work. The language we used is called Python. It has while True: to make your code repeat and if, else, and elif to make different things happen at different times.
