###### Last updated: 09/14/2016

##### Lesson Plans
# Computer Science 2

### Curriculum Summary
- Recommended Prerequisite: Introduction to Computer Science
- 6 x 45-60 minute coding sessions

#### Overview
Armed with basic knowledge of the structure and syntax of simple programs, students are ready to tackle more advanced topics. Conditionals, functions, and events, oh my! Computer Science 2 is where students move past the programming-toy stage into writing code similar to that they would use in the next major software or killer app!

In Computer Science 2, students will continue to learn the fundamentals, (basic syntax, arguments, strings, variables, and loops) as well as being introduced to a second level of concepts for them to master. If statements allow the student to perform different actions depending on the state of the battlefield. Functions let students organize their code into reusable pieces of logic, and once students can write basic functions, they can start writing code to handle events--which is the basis for lots of coding patterns in game development, web development, and app development.


_This guide is written with Python-language classrooms in mind, but can easily be adapted for JavaScript._

### Scope and Sequence

| Module                                                      | First Level           | Transfer Goals                     |
| ----------------------------------------------------------- | :-------------------- | :--------------------------------- |
| [5. Conditionals (if)](#conditionals-if-)                   | Defense of Plainswood | Check expression before executing  |
| [6. Conditionals (else)](#conditionals-else-)               | Back to Back          | Execute default code               |
| [7. Nested Conditionals](#nested-conditionals)              | Forest Fire Dancing   | Put one conditional inside another |
| [8. Functions](#functions)                                  | Village Rover         | Save code for later                |
| [9. Events](#events)                                        | Backwoods Buddy       | Listen for events and execute code |
| [10. Review - Multiplayer Arena](#review-multiplayer-arena) | Power Peak            | Design and implement algorithms    |

### Core Vocabulary
**Object** - a character or thing that can perform actions. Objects are the building blocks of Python. They are things or characters that can perform actions. Your `hero` is an object. It can perform the moving actions. In `hero.moveRight()`, the object is `hero`. In Course 2, students will also be using the `pet` object to perform actions.

**Function** - an action performed by an object. Functions are actions an object can do. `moveRight()` is a function. Function names are always followed by parentheses.

**Argument** - additional information for a function. Arguments are what we put inside the parentheses of a function. They tell the function more information about what it should do. In `hero.attack(enemy)`, `enemy` is the argument.

**Loop** - code that repeats. A loop is a way of repeating code. One way of writing loops uses the keyword `while`, followed by an expression that can be evaluated as `True` or `False`.

**Variable** - a holder for data. A variable holds your data for later. You create a variable by giving it a name, then saying what value it should hold.

**Conditional** - the building block of modern programming, the conditional. It’s named as such because of its ability to check the conditions at the moment and perform different actions depending on the expression. The player is no longer able to assume there will be an enemy to attack, or if there is a gem to grab. Now, they need to check whether it exists, check if their abilities are ready, and check if an enemy is close enough to attack.

**Event** - an object representing something that happened. Students can write code to respond to events: when this type of event happens, run this function. This is called event handling, and it's a very useful programming pattern and an alternative to an infinite while-loop.


#### Extra activities for students who finish Course 2 early:
- Help someone else
- Refine a multiplayer arena strategy in Power Peak
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
if student.arrivalTime > class.startTime:
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
if student.arrivalTime > class.startTime:
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

**What is elif? Is it an elf?**
>Elif means else if. You use it to do three things instead of two with if.  It’s like an elf because it’s tricky.

**Tell me about spaces.**
>You use four spaces to make code go inside a while True, if, else, or elif. If an if is inside another if, you have to use eight spaces. It’s important to count the spaces and get them exactly right, or else the computer thinks you mean something different. You have to be really careful.


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

**Why are functions useful? When would they not be useful?**
>They make it so you don’t have to write the same code over and over and they make your code easier to read. I don’t think it’s useful if you’re just going to put one line of code in your function. It would be easier just to write that one line every time.


##### Module 9
## Events
### Summary
An **event** is an object representing something that happened. Students can write code to respond to events: when this type of event happens, run this function. This is called event handling, and it's a very useful programming pattern and an alternative to an infinite while-loop.

### Transfer Goals
- Listen for events and execute code
- Use event handling to control a pet
- Write concurrent code mixing direct execution and event handling

### Instructive Activity: President Teacher (12 mins)
#### Explain (2 mins)
Up until now, you have been writing code that executes once, from top to bottom: *first do this, then do this, then do that*. You also learned how to write while loops, where you can say, *then do this forever*. Using event handling, you now have a way to say, * **when** this happens, **then** do that*. It's kind of like an if-statement, except events can happen at any time, not just when you are checking for them.

#### Interact (8 mins)
Explain to the class that you're waiting for an important call from the White House about whether you've been elected the next President. You're going to write a program to answer the phone when it rings using a while loop and an if statement, but with no events yet:

``` python
while True:
    if phone.isRinging:
        teacher.answer(phone)
```

But that's boring, since you're not doing anything else. So you're going to grade their homework while you wait:

``` python
while True:
    paper = teacher.findNextPaper()
    teacher.grade(paper)
    if phone.isRinging:
        teacher.answer(phone)
```


Say that each paper takes five minutes to grade. Ask the class what will likely happen if you are running this program and you get a phone call from the White House. (You will probably be in the middle of grading the paper and will only check if the phone is ringing every five minutes, thus you'll probably miss the call and won't get to be President.)

Now rewrite the program to use event handling, explaining how you **listen** for events so that when they happen, you can **handle** them by running a function:

``` python
def answerPhone():
    teacher.answer(phone)

phone.on("ring", answerPhone)
```

Explain that you pronounce this as, "On the `phone`'s `"ring"` event, run the `answerPhone` function." Now say you want to grade papers while you wait, you just add a while loop, and when the event happens, it will interrupt your grading so you can answer the phone and become President:

``` python
def answerPhone():
    teacher.answer(phone)

phone.on("ring", answerPhone)
while True:
    paper = teacher.findNextPaper()
    teacher.grade(paper)
```

Explain that the `phone.on("ring", answerPhone)` makes your code start listening for the `"ring"` event, and note that you **don't use parentheses** on the function you are listening with: `answerPhone`, not `answerPhone()`. This is because you are telling the code the name of the function to run, but you are **not running it yet**. (The parentheses would run the function immediately.)

Ask the class for more examples of events and functions that could respond to them, and write them on the board, something like this:

``` python
student.on("wake", goBackToSleep)
dog.on("hear", obeyMaster)
goal.on("touchBall", increaseScore)
bigRedButton.on("press", initiateSelfDestruct)
```


#### Reflect (2 mins)
**What do you use event handling for?** (To run a function when something happens.)
**What kind of data is an event name?** (The event name you listen to is a string.)
**Why don't you use function parentheses when you start listening to an event?** (The parentheses would make the function run now, and you want to run it later when the event happens.)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Make sure students are writing their functions above where they use them to start listening to events. It can be trick to keep track of what code is executing when events happen (your default program or the event handler function), so have students look at the white code execution highlights to see what line of code is being run at each time.


### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**Tell me about the cat.**
>I got a pet cat and it’s a cougar or a lioness. There was a function that said meow, and the cat waited until you talked to it and then it said meow. I think the cat should help protect you from enemies. You should be able to make it do other stuff by commands, like pouncing and biting.

**Events are really useful when developing games. Guess the names of at least three kinds of events you think might happen in code for games you like to play.**p
>In Minecraft there might be an "explosion" event when a creeper blows up. In chess there might be a "checkmate" event. In Bejeweled there could be a "combo" event.


##### Module 10
## Capstone Challenge - Multiplayer Arena
### Summary

The arena level is an opportunity for students to creatively apply all the concepts they have learned to develop a program that solves a problem. Students first develop an algorithm that will defeat a computer opponent, then they compete against classmates, refining their algorithm to beat the level as quickly as possible. The friendly competition in this level is intended to motivate students to apply an iterative development process, creating and testing multiple possible solutions. Students can also work collaboratively using a pair programming approach, which may make the competition more comfortable for some students.

#### Materials
- [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf)
- Optional: [Pair Programming Guide](https://codecombat.com/teachers/resources/pair-programming)
- Optional: [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)


#### Learning Objectives

- Use an iterative process to develop a program that solves a problem.
- Test and debug a program.

#### Standards

- **CSTA: 1B-AP-13** Use an iterative process to plan the development of a program by including others' perspectives and considering user preferences.
- **CSTA: 1B-AP-15** Test and debug (identify and fix errors) a program or algorithm to ensure it runs as intended.
- **CSTA: 3B-AP-09** Implement an artificial intelligence algorithm to play a game against a human opponent or solve a problem.
* **CCSS-Math: MP.1** Make sense of problems and persevere in solving them.
* **CCSS-Math: MP.2** Reason abstractly and quantitatively.
* **CCSS-Math: MP.6** Attend to precision.

### Opening Discussion (5 minutes): _Introduction to Arenas_

#### Explain

Tell students that they're going to put all their learning together today in a special activity called an Arena. Explain and demonstrate how the Arena works, making sure to cover the following points:

- They'll be writing an artificial intelligence program to beat a complicated level in a race against an opponent. They'll test and revise their program over and over the get the best time they can. Encourage them to submit code, observe the output, and look for places where revisions could help a goal to be achieved more quickly, help a player to stay alive longer, etc. Then they should make the changes and submit again, as many times as they like.
- First, they should click to select the Red (Human) or Blue (Ogre) team. (We suggest randomly assigning half of the students to each team.)
- The first time they play, they should choose "Warm-Up" to play against the computer. They should keep revising and improving their program until it is good enough to beat the computer.
- Once they beat the computer, they can choose "Easy" to play against their classmates.

#### Review the Engineering Cycle

Remind students that engineering is all about solving problems, and the first rule of engineering is that no one gets it right the first time. That’s where the Engineering Cycle comes in:

DECOMPOSE: Understand and break apart the problem. What is the goal of the level? What smaller goals do you see along the way?  
PLAN: Choose one part of the problem to solve first. What do you need the computer to do? Plan a solution in plain English or pseudocode. Use a flowchart or storyboard to stay organized.   
IMPLEMENT: Write the solution to each part of your problem in code. 
TEST: Run your code! Does it solve the problem the way you intended? If not, redesign. Does it work without errors? If not, trace through it to find and fix the bug(s), then test again. Once it works, move on to the planning and implementing the next part! 

Provide each student with a copy of the [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) that they can use to plan their program once they navigate to the level. 


#### Discuss
Use one or more of the following discussion questions to help prepare students for success:

**What steps will you follow to plan and create your program?**

Sample Responses:
> I'll use the Engineering Cycle. I'll decompose the problem by finding the big goal and breaking it into smaller subgoals. I'll choose one subgoal to start with and plan out an algorithm to solve it. Then I'll write my algorithm in code, and start testing and debugging until it works the way I want it to. 

**What will you do if your program doesn't beat the computer the first time?**

Sample Response:
> If it doesn't work, I'll rerun it and watch to see where it goes wrong, then I'll try to find a way to improve that part and resubmit the code. If it still doesn't work, I'll try it again!

### Coding Time (40-50 mins)

Have students navigate to the last level, **Power Peak**. They should take a few minutes to complete the Engineering Cycle Worksheet, then complete the level at their own pace.  Circulate and assist as they work.


#### Good to Know

- Some students may be uncomfortable with competition, especially given that the rankings are visible to the class. Consider using Pair Programming - competition is often more comfortable when you have a partner.
- Students will only compete against the AI and other students in the same CodeCombat class (not strangers).
- Once students have beaten one of the AIs, they will be put into the class rankings.
- Red teams only fight against blue teams, and there will be top rankings for each.
- Once students have submitted code, other students can click the “Fight” link next to any student in the ranking to challenge that student!
- If you leave your teacher account on the arena ladder page, it will simulate more matches between your students.

#### Look Out For:
- The Arena is more open-ended than the regular levels. If students are unsure of how to get started, remind them that programming is an iterative process and guide them toward decomposing the problem into simpler pieces, planning a solution for just one part of the level at a time.
- If a student is frustrated at losing, encourage them to analyze the winning player's strategy. What can they learn from it, and how can they use it to improve the next iteration of their own code?

### Closure (5 minutes)

Use one or more of the following questions to prompt reflection on the lesson. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**In CodeCombat, you have to plan all your hero's actions in advance, then let the hero carry them out all at once. This is  different from most video games, where you directly control the hero and make decisions as you go. How do you feel about the difference? For example, which is more fun? Which is harder? How does your strategy change? How do you handle mistakes?**

Sample Responses:
> CodeCombat is harder because I have to think so many steps ahead! It's a fun kind of hard!

> In this game, I get to look through the whole level first and plan out how I want to beat it. Then I get to design a way to make my plan work. It feels different than making it up as I go along in regular video games.

**What did you do when your code didn't beat your opponent? How did you decide what changes to make?**

Sample Response:

> I reran the code and watched to see if I could take any shortcuts. Then I changed the code and ran it again to see if it helped.

> I looked for ways to stay alive longer. I called more friends to help and picked up more potion. Adding those things to my program helped me make it to the end.
