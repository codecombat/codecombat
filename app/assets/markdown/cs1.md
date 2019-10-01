
###### Last updated: 08/27/18

##### Lesson Plans
# Introduction to Computer Science

_Level: Beginner_  
_Time: 4 x 50 to 60-minute sessions_

###  Overview
This course is designed to be a gentle introduction to basic programming concepts, such as algorithms, syntax, loops, and variables, through the engaging and familiar experience of a video game. In each level, players use computational thinking and computer programming to navigate the hero to the goal without running into spikes or being spotted by ogres.

_This guide is written with Python-language classrooms in mind, but can easily be adapted for JavaScript._

### Lessons
| Module                                                     | Levels             | Objectives                                         | 
|------------------------------------------------------------|--------------------|----------------------------------------------------|
| [1. Basic Syntax](#lesson-1-basic-syntax)                           |                1-8 | Sequencing, syntax, strings, comments, arguments   |
| [2. Loops](#lesson-2-loops)                                         |               9-14 | Repeat code sequences using while-true loops       |
| [3. Variables](#lesson-3-variables)                                 |              15-17 | Save and access data using variables               |
| [4. Capstone Challenge - Multiplayer Arena](#capstone-challenge-multiplayer-arena) |                 18 | Master course concepts                             |


### Key Terms

**Algorithm** - a step-by-step set of instructions for completing a task. When algorithms are written using code, computers can follow them.

**Basic Syntax** - the rules for correct spelling, grammar, and punctuation in a programming language. The syntax must be exactly right for code to execute properly. The syntax is language-specific; for example, while Python and JavaScript are used to do similar things in Course 1, the syntax for them is noticeably different.

**Object** - a character or thing that can perform actions.

**Property** - data about or belonging to an object.

**Method** - an action performed by an object.

**Argument** - extra information passed into a method to modify what the method does. In both Python and JavaScript, arguments are represented by code that is inside the parentheses after a method. For example, in the method `hero.moveLeft(3)`, the argument _3_ is a number that tells how many spaces the hero should move. In the method `hero.Attack("Brak")`, the argument _"Brak"_ is a string that tells the name of the character that should be attacked. 

**String** - a type of data that represents text. In both Python and JavaScript, strings are represented by text inside quotes. In Course 1, strings are used to identify objects for the hero to attack.

**Loop** - a programming structure used to repeat actions without the player needing to write the same lines of code over and over. In Python, the code that loops must be indented. In JavaScript, the code that loops must be enclosed by curly brackets {}. There are different kinds of loops:
- **For Loops** repeat a block of code a certain number of times.
- **While Loops** repeat a block of code while a certain condition is true, such as ` while gems < 4 `. In Course 1, a type of while loop called a **while True loop** is used to repeat a block of code infinitely until the level is complete.

**Variable** - a symbol that represents data. The value of a variable can be modified over the course of the program. In Course 1, variables are used to name enemies, then passed along as arguments to the attack method so that the hero can attack the correct enemy.

******
## Lesson 1 - Basic Syntax
#### _(Levels 1-8)_
### Summary

These levels introduce basic concepts and vocabulary, including syntax, strings, and arguments. Students find that sequencing is critical to coding because when a computer runs a program, it executes every command in the order it is given, from start to finish. Students are also introduced to commenting code, a common practice used by programmers to document and communicate about their work.

The opening classroom activity introduces Python syntax and the importance of order in a sequence of instructions, or algorithm.  As the teacher, you will imitate a robot that executes the commands given by the class. By the end of the activity, the class will collaboratively write a program something like this: 

``` python
teacher.pickUpBall()
teacher.turnRight()
teacher.moveForward()
teacher.moveForward()
teacher.turnLeft()
teacher.moveForward()
teacher.dropBall()
```

#### Materials
- Desk or table
- Recycling bin
- Balls of paper to recycle
- Optional: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- Optional: [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf)
- Optional: [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)

#### Learning Objectives

- Use correct syntax when writing code.
- Use proper sequencing when writing code.
- Use arguments to input information into a method.
- Use strings to input text data.
- Use comments to document code.
- Understand and use basic vocabulary: algorithm, argument, code, method, program, sequence, syntax, string

#### Standards

- **CSTA: 1A-AP-10** Develop programs with sequences and simple loops, to express ideas or address a problem.
- **CCSS-Math: MP.1** Make sense of problems and persevere in solving them.
- **CCSS-Math: MP.6** Attend to precision.

### Opening Activity (15 minutes): _Recycling Robot_
#### Explain

Explain the following terms to students:
- **Syntax** is how we write code. Just as spelling and grammar are important in writing narratives and essays, syntax is important when writing code. Humans are good at figuring out what something means, even if it isn’t exactly correct, but computers aren’t that smart, and they need you to write very precisely. 
- **Sequence** is the order of the commands in a program. Computers follow commands in exactly the order they are written.
- **Objects** are the building blocks of Python. They are things or characters that can perform actions. In the game, your hero is an object. The actions an object performs are called **methods**. For example, `moveRight()` is a method. Method names are always followed by parentheses.

Write the sample code `hero.moveRight()` on the board, and describe the components:
* This is read aloud as “hero dot move right”, where `hero` is the object, and `moveRight` is the method.
* The period, capitalization, and parentheses are essential parts of the syntax that must be exactly right:
    * Period: separates the object from the method
    * Capital letters: used to show the start of a new word when a period or space can't be used (this is called "camel case")
    * Parentheses: create a place where a programmer could add extra details, or **arguments** to a method.

#### Interact

At the front of the class, set some scrunched up paper balls on a flat surface. Place the recycling bin a few steps away. Explain that you are a recycling robot, and the class’s job is to program you. 

The robot is a Python object. Choose a name for yourself and write it on the board, beginning with a lowercase letter. For example:

`teacher`

To make the robot perform an action, students have to call a method. Write a dot after your object name, then have the class decide what the first action should be. After the dot, write the method name using camel case followed by empty parentheses. For example:

`teacher.pickUpBall()`

Off to one side, draw a “Run” button and have a volunteer press it. As a robot, execute the program _precisely_ as the students have written it.

Invite students to work together to add commands to the program one at a time until you can successfully get a ball into the recycling bin. They can test the program at any time by pressing the "Run" button. Each time they press "Run", you should execute every command from start to finish exactly as written. If there is an error in the syntax, make a funny beeping sound and stop. After each test, reset yourself and have the class revise, or _debug_, the program until it works.

#### Discuss

Use one or more of the following discussion questions to prompt a brief reflection:

**Why are sequence and syntax important?**

Sample Response:
> Computers only do exactly what you tell them, so the sequence is important because if the computer does the steps in the wrong order, the program doesn't turn out right. If there is an error in the syntax, the computer doesn't know how to read it at all.

**How is the way a computer reads instructions different from the way a human would understand them?**

Sample Response:
> Humans can use their own knowledge and other clues to figure things out if they don't make sense. Computers can only execute exactly what they are told.


### Coding Time (30-40 minutes)

Tell students they will be playing Levels 1 - 8 today. Allow students to move through these levels at their own pace. Circulate and assist, calling attention to the Hints button in the top right corner of each level as needed.

_We recommend stopping students after Level 8 and using the next lesson plan to introduce the next concepts before beginning Level 9._

#### Look Out For:
- Initially, some students may want to type and run one command at a time. Explain to them that the code must contain all the instructions for the program from start to finish, like a story: it has a beginning, a middle, and an end. Every time you click Start, the hero returns to the beginning of the level, and the full program runs again. 


### Closure (5 minutes)

Use one or more of the following questions to prompt reflection. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**Explain how to play CodeCombat to someone who has never played before. Use as many programming terms as you can.**

Sample Response:
>You have to move to the gem without hitting the spikes by writing a program. I learned that you have to type the object name first, like “hero.” then the method to make them do an action. You have to spell it right and put () at the end. You click RUN to make it go. It runs the whole program every time, and you can fix the code and try again as many times as you need.

**What’s the difference between an object and a method?**

Sample Response:
>The object is the hero, and she has methods that are things she can do. The object has a dot after it, and the method has (). 

**How can you tell when you’ve made a mistake in your code? How do you fix it?**

Sample Response:
>Sometimes the code won’t run because there is a mistake in it. They put a red `!` next to the mistake and try to help you. You have to read the code to figure out what’s wrong.

**How do comments work, and what are they for?**

Sample Response:
>Comments are lines you write in the program that the computer doesn't read. If you start a line with the # symbol, the computer doesn't see it. You can write comments to remind yourself how you did something or to leave a note for another human who might want to understand your code.


### Differentiation

#### Additional Supports:
- Show students how to find the hints, methods reference cards, error messages, and sample code provided within each level.
- Students struggling with a given level will be automatically directed to additional practice levels within the game.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If students struggle with breaking down problems, you can use the printable [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) to reinforce a step-by-step problem-solving approach.
- If students struggle to follow correct syntax, provide a copy of the printable [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)

#### Extension Activities:

- Have students come up with a backstory for their hero. For example, why are they in the Kithgard Dungeon? What is their quest? What obstacles have they faced along their journey, before reaching the dungeon? Have them produce a written narrative, video, short play, or other creative artifact to share their backstory with others.

******
## Lesson 2 - Loops
#### _(Levels 9-14)_
### Summary

In prior levels, students have had to write long sequences of actions with no shortcuts. Levels 9-14 introduce loops, which allow them to achieve more with fewer lines of code. Specifically, students use **while True loops** which allow a block of code to be repeated infinitely until the level is completed.

The puzzles in this section are harder to solve than in the first module. Encourage collaboration among your students as they first must understand what their goal is, then devise a strategy for solving the level, then put that plan into action. Consider using the [Pair Programming approach](https://codecombat.com/teachers/resources/pair-programming) or the [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf).

#### Materials
- Optional: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- Optional: [Pair Programming Guide](https://codecombat.com/teachers/resources/pair-programming)
- Optional: [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf)
- Optional: [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)


#### Learning Objectives

- Write a program that includes an infinite loop.
- Decompose a problem into smaller pieces and identify which pieces should be repeated.
- Understand and use key terms: evaluate, expression, loop, while loop, while True loop

#### Standards

- **CSTA: 1A-AP-10** Develop programs with sequences and simple loops, to express ideas or address a problem.
- **CCSS-Math: MP.1** Make sense of problems and persevere in solving them.
- **CCSS-Math: MP.6** Attend to precision.
- **CCSS-Math: MP.8** Look for and express regularity in repeated reasoning.

### Opening Activity (10 minutes): _Real Life Loops_
#### Explain

Explain that a **loop** is a way of repeating code. One type of loop is a **while loop**, which uses the word `while` followed by an **expression** that can be evaluated as True or False. `while` is a special word that tells the computer to repeat the commands inside the loop until the expression becomes False.

For example, the statement `while gems < 4` would tell the computer to keep repeating a set of actions until the player had collected 4 gems, and then stop.

#### Interact

As a class, brainstorm ways of writing a repeating action in English. For example:

>Keep walking **until** you get to the door.
>Bounce the ball **five times**.
>Hang up **all** of your shirts.

Circle the English words that tell you the action repeats. Then, rewrite one of the statements using `while`. For example:

>_While you are not at the door, keep walking._  
>_While bounces are less than 5, bounce the ball._  
>_While there are still shirts out, hang up a shirt._

Have the class rewrite the remaining statements using `while`. You might pair students and assign each pair to rewrite one statement, then share out.

Now, show how you would write each statement using code. Explain that you can put as many lines as needed inside the loop. In Python, all lines must be indented 4 spaces to be included in the loop. You might provide the first two examples, then have the class complete the rest. For example:

Keep walking **until** you get to the door.
``` python
    while distanceToDoor > 0: 
        hero.walk()
```

Bounce the ball **five times**.
``` python
    while bounces < 5: 
        ball.bounce()
```

Hang up **all** of your shirts.
``` python
    while clothes > 0: 
        hero.hangUp(shirt)
```

Finally, help students understand the purpose of a loop. For one of your examples, contrast the code that uses the `while` loop with the code that would be needed without a loop. For instance, to accomplish the task, "Bounce the ball five times", you would need to write very tedious code:

``` python
    ball.bounce()
    ball.bounce()
    ball.bounce()
    ball.bounce()
    ball.bounce()
```

And, for the other examples, you would need to know the exact distance to the door, or the exact number of shirts, in order to know how many times to write the command. With a while loop, you can accomplish the task even if you don't know how many times an action needs to happen.

#### Explain

Tell students that these levels in CodeCombat require an **infinite loop**, or a loop that repeats forever until the level is beaten. For that, we need an expression that is always true. Luckily, `True` is a Python expression that always evaluates as True! So, we can use a **while True loop**.

In the example below, `while` is the keyword, and `True` is the expression:
``` python
    while True: 
        hero.moveRight()
        hero.moveUp()
```
#### Discuss

Use one or more of the following discussion questions to prompt reflection:

**What is a loop? When might you want to use one?**

Sample Response:
> A way of repeating actions in a program. You can use them so you don't have to keep writing repetitive code, and when you don't know exactly how many times an action will need to occur to accomplish a task.

**Give an example of an expression. Describe a case when it evaluates to True and a case when it evaluates to False.** 

Sample Response:
> The expression `while pizza < 5` would evaluate to True if I have 3 pizzas, and to False if I have 6 pizzas.

### Coding Time (30-40 minutes)

Tell students they will be playing levels 9 - 14 today. Allow students to move through these levels at their own pace. Circulate and assist, calling attention to the Hints button in the top right corner of each level as needed.

_We recommend stopping students after Level 14 and using the next lesson plan to introduce the next concepts before beginning Level 15._

#### Look Out For:
- If students are struggling to find errors in their code, have them check for correct indentation and colons.
- Have students check that their loop includes all of the actions they want to repeat and only those actions.

### Closure (5 minutes)

Use one or more of the following questions to prompt reflection. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**Explain how you can tell when to use a loop in a program.**

Sample Response:
>You have to look for actions that repeat. Sometimes it is just one action, and sometimes it is a set of actions. You put whatever the repeatable actions are inside the loop.

**What are the things you have to remember to write a while loop?**

Sample Response:
>You have to type `while` and then the expression, like `while True` or `while gems < 4`, and remember to put a colon after it. On the next line, put four spaces before the code for the action you want to repeat. If you want more than one line to repeat, they all have to have four spaces. 

**Choose one level and explain how you used a loop to solve it.**

Sample Response:
>  I used `while True` loops to make my code repeat forever. I had to remember to put four spaces on each line. It’s faster because I didn't have to type the same line of code a bunch of times. For example, in the Haunted Kithmaze, you go to a dead end if you just put `hero.moveRight()` in the loop because it just goes right, right, right forever. Instead, you have to put `hero.moveRight()` and then `hero.moveUp()` so it goes right, up, right, up. 

### Differentiation

#### Additional Supports:
- Show students how to find the hints, methods reference cards, error messages, and sample code provided within each level.
- Students struggling with a given level will be automatically directed to additional practice levels within the game.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If students struggle with breaking down problems, you can use the printable [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) to reinforce a step-by-step problem-solving approach.
- If students struggle to follow correct syntax, provide a copy of the printable [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)

#### Extension Activities:

- Encourage students to think about loops as they move through their day-to-day activities. If they were to describe their daily actions in code, where might they use a while loop? Create an Everyday Loops poster and have students add their own examples, written in English and in code. For example:

    Keep chopping until you have 2 cups of diced carrots.
``` python
    while carrots < 2: 
        hero.chop(carrots)
```
- Have students come up with a backstory for their hero. For example, why are they in the Kithgard Dungeon? What is their quest? What obstacles have they faced along their journey, before reaching the dungeon? Have them produce a written narrative, video, short play, or other creative artifact to share their backstory with others.

******
## Lesson 3 - Variables
#### _(Levels 15 - 17)_
### Summary

Working with variables is like organizing things in shoeboxes. You give the shoebox a name, like "School Supplies", and then you put things inside. The exact contents of the box might change over time, but whatever's inside will always be called "School Supplies". In programming, variables are symbols used to store data that will change over the course of the program. Variables can hold a variety of data types, including numbers and strings.  

In these levels, variables are used to name enemies, so that the hero knows which character to attack.

#### Materials
- shoebox, or other small container, with a blank label
- assortment of school supplies
- Optional: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- Optional: [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf)
- Optional: [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)


#### Learning Objectives

- Create and clearly name a variable to store data.
- Use a variable as an argument in a method.
- Understand and use key terms: variable, value, data

#### Standards

- **CSTA: 1B-AP-09** Create programs that use variables to store and modify data.
- **CSTA: 2-AP-11** Create clearly named variables that represent different data types and perform operations on their values.
- **CCSS-Math: MP.1** Make sense of problems and persevere in solving them.
- **CCSS-Math: MP.2** Reason abstractly and quantitatively.

### Opening Activity (10 minutes):
#### Explain

Tell students that working with variables is like organizing things in shoeboxes in a closet. Show an image of an organized closet full of labeled boxes, or ask students to share personal examples of how they organize their things,  highlighting examples where they use labels to remember what is in each container. Elicit the idea that the labels help you group similar items together, and find them again later.

#### Interact

Show the class your shoebox and the objects inside - pens, glue, ruler, etc. Ask them to suggest a name for the box, and write their best idea on the label. For example, they might label it "School Supplies".

Change some of the contents of the box, and ask students to notice that "School Supplies" is still a clear and accurate name for the box, even though some of the contents have changed.

Suggest some unclear or inaccurate names for the box, such as "Markers", "Stuff", or "Snacks". Ask students what's wrong with each name, highlighting the idea that they are too narrow ("Markers"), too broad ("Stuff"), or inaccurate ("Snacks"). 

#### Explain

Make the connection back to variables, explaining that the label "School Supplies" is the **variable** and the objects inside are the **value**. The value can change, but whatever is in the box will always be called "School Supplies". If you were asked to bring your school supplies to class, you'd know to bring everything in that box. 

In a computer program, variables hold data that might change over the course of the program. For example, you might want your hero to attack the nearest enemy, no matter who that enemy is. The nearest enemy will probably change during the level. 

You define a variable by giving it a name, then setting it equal to the first **value** it should hold. Display the example:

`enemy = “Kratt”`

Explain that the variable `enemy` holds (`=`) the value `"Kratt"`

Now you can use your variable in place of the value itself: `hero.attack(enemy)` is the same as `hero.attack("Kratt")`

This is useful when there is more than one enemy in a level. For example, if you define the variable `enemy` as whatever enemy is closest to your hero, like this:

`enemy = hero.findNearestEnemy()`
`hero.attack(enemy)`

then you'll always attack whatever enemy is closest to you, no matter what the enemy's name is.

Finally, mention that for now, a variable can hold only one value, even though our shoebox could hold lots of things. Later, they'll learn ways to store multiple similar values under one variable; for now, the value is a single number or a single string. 


#### Discuss

Use one or more of the following discussion questions to prompt reflection:

**What are variables used for?**

Sample Response:
> Storing a value that might change later.

**How do variables in programming compare to variables in math or science?**

Sample Response:
> It's similar to science because in science a variable is a part of an experiment that can be changed. Like you might have "temperature" as a variable in your experiment, and test different values for "temperature".
> It's similar to math because in math a variable is a symbol that stands in for a number that changes value. Like in *x* + 5 = *y*, the variable *x* could be any value, and the value of the variable *y* would change too, depending on the value of *x*.


### Coding Time (30-40 minutes)

Tell students they will be playing Levels 15-17 today. Allow students to move through these levels at their own pace. Circulate and assist as they work, calling attention to the Hints button in the top right corner of each level as needed.

_We recommend stopping students after Level 17 and using the next lesson plan to introduce the next concepts before beginning Level 18._

#### Look Out For:
- In these levels, the values of the variables are strings. If students run into errors, have them check that they have used quotation marks correctly.
- Loops are also needed for these levels. Have students double check that they have correctly indented the code within their loops. 
- In these levels, the enemies typically require two hits to be defeated. If their hero does not survive, have students check to be sure they have attacked each enemy twice.


### Closure (5 minutes)

Use one or more of the following questions to prompt reflection. You can facilitate a short discussion, or have students submit written responses on Exit Tickets.

**What was the hardest puzzle you solved today? How did you solve it?**

Sample Response:
>15 was a hard level. There were lots of enemies and I died. So I made a loop for attack, but I didn’t know the name of who to attack. So I clicked on the glasses and it said I could use `findNearestEnemy`, but it didn’t work without saying `enemy =`. Then I could `attack(enemy)` and it worked. 

**What does the method `findNearestEnemy` do? When do you use it?**

Sample Response:
>The hero can see which enemy is closest by writing `hero.findNearestEnemy()`. But you have to name a variable for it so you can call it. You can say `enemy = hero.findNearestEnemy()`. Then you can attack the closest enemy on the next line by saying `hero.attack(enemy)`. If you put both of those lines inside a loop, the program will keep updating who the nearest enemy is, and you'll keep attacking new enemies!

### Differentiation

#### Additional Supports:
- Show students how to find the hints, methods reference cards, error messages, and sample code provided within each level.
- Students struggling with a given level will be automatically directed to additional practice levels within the game.
- If you would like students to take notes as they work, a printable template is available here: [Progress Journal](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)
- If students struggle with breaking down problems, you can use the printable [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf) to reinforce a step-by-step problem-solving approach.
- If students struggle to follow correct syntax, provide a copy of the printable [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)

#### Extension Activities:

- This lesson uses a shoebox analogy. Have students come up with their own analogies by completing the following sentence frame in as many ways as possible: A variable is like a _(blank)_ because _(blank)_. To push them creatively, set a minimum of 8 ideas, to help them get past their first or most obvious idea.

******
## Capstone Challenge - Multiplayer Arena
#### _(Level 18)_
### Summary

The arena level is an opportunity for students to creatively apply all the concepts they have learned to develop a program that solves a problem. Students first develop an algorithm that will defeat a computer opponent, then they compete against classmates, refining their algorithm to beat the level as quickly as possible. The friendly competition in this level is intended to motivate students to apply an iterative development process, creating and testing multiple possible solutions. Students can also work collaboratively using a pair programming approach, which may make the competition more comfortable for some students.

#### Materials
- [Engineering Cycle Worksheet](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet.pdf)
- Optional: [Pair Programming Guide](https://codecombat.com/teachers/resources/pair-programming)
- Optional: [Python Syntax Guide](http://files.codecombat.com/docs/resources/Course1PythonSyntaxGuide.pdf) or [JavaScript Syntax Guide](http://files.codecombat.com/docs/resources/Course1JavaScriptSyntaxGuide.pdf)


#### Learning Objectives

- Use an iterative process to develop a program that solves a problem.
- Develop a program with sequences, simple loops, and variables.
- Test and debug a program.

#### Standards

- **CSTA 1A-AP-10** Develop programs with sequences and simple loops, to express ideas or address a problem.
- **CSTA 1B-AP-09** Create programs that use variables to store and modify data.
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

Have students navigate to the last level, **Wakka Maul**. They should take a few minutes to complete the Engineering Cycle Worksheet, then complete the level at their own pace.  Circulate and assist as they work.


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
