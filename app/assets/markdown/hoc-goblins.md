###### Last updated: 11/10/2022

##### Lesson Plans
# Goblins 'n Glory

### Curriculum Summary
- Level: Beginner
- 2 x 45-60 minute coding sessions

#### Overview
With the right environment, learning the basics of formal syntax and typing code can be fun and intuitive for students as early as 3rd grade. Instead of block-based visual programming languages that hinder a student’s proper understanding of code, CodeCombat introduces real coding from the very first level. By strengthening their typing, syntax and debugging skills, we empower students to feel capable of building real programs successfully.

_This guide is written with Python-language classrooms in mind, but can easily be adapted for JavaScript._

### Scope and Sequence

| Module                                 | Levels | Transfer Goals                                       |
|----------------------------------------|:-------|:-----------------------------------------------------|
| [1. Basic Syntax](#basic-syntax)       | 1-6    | Call methods in order with  arguments                |
| [2. Enter the Arena](#enter-the-arena) | 7      | Apply coding skills to compete in an AI League arena |

### Solution Guide

Here are solution guides for levels 1-6 in [Python](/teachers/campaign-solution/goblins-hoc/python) and [JavaScript](/teachers/campaign-solution/goblins-hoc/javascript).


### Core Vocabulary

**Basic Syntax** - the basic spelling and grammar of a language, and must be carefully paid attention to in order for code to properly execute. For example, while Python and JavaScript are used to do similar things in Course 1, the syntax for them is noticeably different, because they are different programming languages.

**Object** - a character or thing that can perform actions.

**String** - a type of programming data that represents text. In both Python and JavaScript, strings are represented by text inside quotes. In Course 1, strings are used to identify objects for the hero to attack.

**Method** - an action performed by an object.

**Argument** - extra information passed into a method in order to modify what the method does. In both Python and JavaScript, arguments are represented by code that is inside the parentheses after a method. In Course 1, arguments must be used to define enemies before the hero can attack them, and can also be used to move multiple times without writing new lines of code.

**Property** - data about or belonging to an object.

##### Module 1
## Basic Syntax 
### Summary

The puzzles in these levels are framed as mazes for students to solve using Computational Thinking and computer programming. They are designed to be a gentle introduction to Python syntax through a relatable medium. 

The hero starts at a particular place and has to navigate to the goal while stopping by different target locations.

Some students may want to delete their code every time and only type the next step. Explain to them that the code must contain all the instructions from start to finish, like a story: it has a beginning, a middle, and an end. Every time you click Start, the hero returns to the beginning.

### Transfer goals

- Use Python syntax
- Call methods
- Understand that order matters

### Standards 

**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.  
**CCSS.Math.Practice.MP6** Attend to precision.

### Instructive Activity: Basic Syntax (10 mins)

#### Explain (3 mins)

**Syntax** is how we write code. Just like spelling and grammar are important in writing prose, syntax is important when writing code. Humans are good at figuring out what something means, even if it isn’t exactly correct, but computers aren’t that smart, and they need you to write with no mistakes. 

code example: `hero.moveTo(3)`

vocabulary:   (object) (method) (argument)

read aloud: “hero dot move to 3”

**Objects** are the building blocks of Python. They are things or characters that can perform actions. Your hero is an object. It can perform a `moveTo` and a `use` action.

**Methods** are actions an object can do. `moveTo()` is a method. Method names are always followed by parentheses. The order of methods matters!

**Arguments** are ways we can customize a method. You can place a word or number inside the parentheses. For example,  `moveTo(3)` customizes the `moveTo` method so that the hero moves to the location `3`. `hero.use("lever")` customizes the `use` method so that the hero uses the object named `"lever"`.

#### Interact (5 mins): Recycling Robot

Practice giving written instructions using Python methods in order.

**Materials**: Desk or table, recycling bin, pieces of labeled paper (each with a different number: 1, 2, 3, 4, etc), balls of different colored paper to recycle (blue, red, etc)

You (the teacher) are going to be the robot that the class controls using methods. The goal of this exercise is for the class to collectively write a program like this: 

```python
teacher.moveTo(1)
teacher.pickUpBall("blue")
teacher.moveTo(2)
teacher.pickUpBall("red")
teacher.moveTo("recycling bin")
teacher.dropBall("blue")
teacher.dropBall("red")
```

The experience should introduce them to Python syntax (including the dot between the object and method, and the parentheses at the end) and the importance of order in a sequence of instructions. 

At the front of the class, set some scrunched up paper balls on a flat surface. Then label each ball with a number. Place the recycling bin a few steps away. Explain that you are a recycling robot, and the class's job is to program you.

The robot is a Python object. What is your name in Python? Whatever you choose, make sure it starts with a lower-case letter. Write it on the board.

`teacher`

To make the robot perform an action, you have to call a method. Write a dot after your object name, then decide as a class what the first two actions should be. After the dot, write the method name followed by empty parentheses. Decide if you want to add an argument to the method as well. Off to one side, draw a “Run” button.

```python
teacher.moveTo(1)
teacher.pickUpBall("blue")
```

Have a volunteer press the “Run” button to run the program and test that it works. 

_It is important that you reset yourself and the paper balls every time the code is changed, and run the whole program from the beginning._

Invite students to add code to the program one at a time. If there is an error in the syntax, make a funny beeping sound and stop. Have the class work together to write and rewrite the program until you successfully get a ball in the recycling bin. 

#### Reflect (2 mins)

**Why is syntax important?** (It lets you be specific about exactly what you want to happen.)

**Does order matter?** (yes)

**Can a human understand the directions even if there’s a mistake in the syntax?** (sometimes)

**Can a computer?** (no)

### Coding Time (30-45 mins)

**First time students will need to create accounts**
For additional information on helping students create account, see our [Teacher Getting Started Guide](https://codecombat.zendesk.com/hc/en-us/articles/1500009108962-CodeCombat-Teacher-Getting-Started-Guide).

Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](https://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips.

If student have trouble breaking the problem down, refer to the [Engineering Cycle Worksheet [PDF]](https://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) to reinforce the steps to solving each puzzle.

### Written reflection (5 mins)

Select appropriate prompt(s) for the students to respond to, referring to their notes.

**Tell me how to play CodeCombat.**

>You need to move the hero and use objects to save the town from the goblins. I learned that you have to type "hero." then the moving code. You have to spell it right and put () at the end. But it shows you the things you can type and you can click on them instead. You click RUN to make it go. You can try as many times as you need.

**What’s the difference between an object and a method?**

>The object is the hero and she has methods that are things she can do. The object has a dot after it and the method has ().

**How can you tell when you’ve made a mistake in your code? How do you fix it?**

>Sometimes the code doesn’t won’t run because there is a mistake in it. They put a red ! next to the mistake and try to help you. You have to read the code to figure out what’s wrong.

##### Module 2
## Enter the Arena
### Summary 

The arena level is a reward for completing the required work. Students who have fallen behind in the levels or who have not completed their written reflections should use this time to finish. As students turn in their work, they can enter the AI League arena and attempt multiple solutions until time is called. 

See the [AI League Educators Getting Started Guide](https://docs.google.com/presentation/d/1ouDOu2k-pOxkWswUKuik7CbrUCkYXF7N_jNjGO0II6o/edit?usp=sharing) for more details.

### Transfer Goals
- Write accurate Python syntax
- Debug Python programs
- Refine solutions based on observations

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.  
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.  
**CCSS.Math.Practice.MP6** Attend to precision.

### Coding Time (40-55 mins)

Have students navigate to the last level, **Goblins and Glory**, and complete it at their own pace. 

#### **Rankings**

In the warm up round, students will only compete against the computer. Once students beat the default computer they can create an account to compete with other coders around the world. You can learn about the CodeCombat AI League [here](https://codecombat.com/league).

If some students are intimidated by competition or being publicly ranked, give them the option of a writing exercise instead: 

- Write a walkthrough or guide to your favorite level
- Write a review of the game
- Design a new level

#### Refining the Code

Code for the arena can be submitted more than once. Encourage your students to submit code, observe how it fares against the computer or other competitors, and then make improvements and resubmit.

### Reflect (5 mins)

**Why is your hero in Goblins and Glory? What is your quest?**

>I went into the Goblins and Glory to collect more gold than the other player. I also need to collect glory to level up my hero. You can find gold in the chests and glory in the statues. I can also defeat goblins to get more goblin and glory.

**How does coding help you complete the quest?**

>I use code to move my hero to different places on the map and explore if there's gold or glory. I can also make my hero wait at a place and then check if a statue or chest shows up.

**What will your Knight do if they win or lose?** *(write your own backstory)*

>I think my Knight will go back to the town and help guard it more. I might use the gold to buy more gear for my Knight. Maybe I'll get a horse or another pet for my Knight.

**Class discussion: How is coding a solution different from controlling a hero in real time?**

You have been playing a game that requires you to think about a whole plan in advance, then let the hero carry out your instructions without intervention. This differs dramatically from the traditional way of playing video games by directly controlling the hero and making decisions while the game is running. Talk about how these differences feel. Which is more fun? Which is harder? How does your strategy change? How do you deal with mistakes? 
