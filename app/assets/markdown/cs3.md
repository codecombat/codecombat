###### Last updated: 09/12/2016

##### Lesson Plans
# Computer Science 3

### Curriculum Summary
- Recommended Prerequisite: Computer Science 2
- 6 x 45-60 minute coding sessions

#### Overview
Armed with basic knowledge of the structure and syntax of simple programs, students are ready to tackle more advanced topics. Conditionals, arithmetic, input handling, oh my! Computer Science 2 is where students move past the programming-toy stage into writing code similar to that they would use in the next major software or killer app!

In Computer Science 2, students will continue to learn the fundamentals, (basic syntax, arguments, strings, variables, and loops) as well as being introduced to a second level of concepts for them to master. If statements allow the student to perform different actions depending on the state of the battlefield. Arithmetic will help players become more comfortable with using math in programming. All things in CodeCombat are objects, (that's the ‘object’ part of object-oriented programming,) and these things have accessible attributes, such as a Munchkin's position or a coin's value; both  are important to begin visualizing the internal structure of the objects that make up their game world. Near the end of the Course there are some levels dedicated to input handling so the students can get introduced to the basic concept of events, and, well, it's just great fun, too!


_This guide is written with Python-language classrooms in mind, but can easily be adapted for JavaScript._

### Scope and Sequence

| Module                                                      | First Level          | Transfer Goals                                            |
| -----------------------------------------------------       | :-----------------   | :-----------------                                        |
| [11. String Concatenation](#string-concatenation)           | Friend and Foe       | Add strings together with +                               |
| [12. Computer Arithmetic](#computer-arithmetic)             | The Wizard's Door    | Do arithmetic with code (+ - * /)                         |
| [13. Properties](#properties)                               | Backwoods Bombardier | Access object properties with .                           |
| [14. Functions with Returns](#functions-with-returns)       | Burlbole Grove       | Write functions that return answers                       |
| [15. Not Equals](#not-equals)                               | Useful Competitors   | Test whether two things are not the same                  |
| [16. Boolean Or](#boolean-or)                               | Salted Earth         | Execute if-statements if one of two things are true       |
| [17. Boolean And](#boolean-and)                             | Spring Thunder       | Execute if-statements if both of two things are true      |
| [18. Relative Movement](#relative-movement)                 | The Mighty Sand Yak  | Combine x- and y-properties and arithmetic for movement   |
| [19. Time](#time)                                           | Keeping Time         | Code based on elapsed time with the now() function        |
| [20. Break and Continue](#break-and-continue)               | Hoarding Gold        | Skip or end while-loops with break and continue statments |
| [21. Review - Multiplayer Arena](#review-multiplayer-arena) | Cross Bones          | Synthesize all CS3 concepts                               |


### Core Vocabulary
**Concatenation** - String concatenation is used to add two strings together with the **string concatenation operator: `+`**

**Arithmetic** - Course 3 begins to ease the player into using math while coding. Levels catering to basic arithmetic address how to use math as needed in order to perform different actions effectively.

**Property** - data about or belonging to an object. You get to it by specifying the object, then a dot, then the name of the property, like `item.pos`.

**Flags** - TODO

**Return** - TODO

**Boolean** - TODO

**Break** - TODO

**Continue** - TODO


#### Extra activities for students who finish Course 3 early:
- Help someone else
- Refine a multiplayer arena strategy in Cross Bones
- Write a walkthrough
- Write a review of the game
- Write a guide to their favorite level
- Design a new level


##### Module 11
## String Concatenation
### Summary
**String concatenation** is used to add two strings together. Remember that strings are `"text inside quotes"`. When you want to build a longer string out of two shorter strings, or combine a string and a variable, you can use the **string concatenation operator: `+**`

In CodeCombat, using strings and `hero.say()` is useful for communicating with friends in the game. These levels will prepare the student for more sophisticated communication using concatenated strings.

### Transfer Goals
- Concatenate two strings with `"string1" + "string2"`
- Concatenate strings and variables, like `"string1" + variable1`
- Use proper spacing around concatenated variables

### Instructive Activity: String Chuck (12 mins)
#### Explain (2 mins)
Strings are pieces of text inside quotes. You have been using strings ever since Course 1, like the `"fence"` in `hero.buildXY("fence", 34, 30)`, or the `"Chest"` in `hero.attack("Chest")`. You have also been using variables, like the variable `enemy` in `hero.findNearestEnemy()`. Sometimes, you need to be able to combine a string and a variable together, and for that we use the string concatenation operator: `+`. String concatenation just means adding something to a string. Here's how it works:

Concatenating two strings:

```
hero.say("Come at me, " + "Treg!")
```

This will cause your hero to say the combined string, "Come at me, Treg!".

You can also concatenate strings stored in variables:

```
ogre = hero.findNearestEnemy()
hero.say("Come at me, " + ogre.id)
```

This lets you call out an ogre without having to hard-code their name into your program.

#### Interact (8 mins)
Practice concatenating strings and variables.

You are going to guide the class through concatenating strings to make a common phrase. The goal of this exercise is for the class to collectively write a program like this:

```
noun = "wood"
verb = "chuck"
teacher.write("How much " + noun + " could a " + noun + verb + " " + verb + " if a " + noun + verb + " could " + verb + " " + noun + "?")
```

This should demonstrate both how to use the string concatenation operator and the importance of getting spaces around variables correct when concatenating strings.

Start by writing this string on the board:

```
goal = "How much wood would a woodchuck chuck if a woodchuck could chuck wood?"
```

Explain to the class that you need to make this string while only writing the words `"wood"` and `"chuck"` once, so we're going to store them in the variables so we can reuse them, and add:

```
noun = "wood"
verb = 
teacher.write("How much " + noun)
```

Ask students to fill in the verb and the rest of the phrase one string or variable at a time. Add an output variable under your goal variable as you go:

```
output = "How much wood"
```

Let the students find their own mistakes in the output. They will likely forget to add spaces in the strings at first and get output like this:

```
output = "How much woodcould a woodchuckchuckif a"
```

Remind them that if you want a space to appear in the concatenated output string, you need to include it in the string before or after the variable, and sometimes you even need to add a string that's just a single space.

Once the program is complete, ask the class for a new noun and a new verb. Rewrite the variables and the final output accordingly. Example:

```
noun = "cheese"
verb = "spray"
teacher.write("How much " + noun + " could a " + noun + verb + " " + verb + " if a " + noun + verb + " could " + verb + " " + noun + "?")

goal = "How much wood would a woodchuck chuck if a woodchuck could chuck wood?"
output = "How much cheese would a cheesespray spray if a cheesespray could spray cheese?"
```

#### Reflect (2 mins)
**When have you used strings before in CodeCombat?** (To attack by name, like `hero.attack("Treg")`; to `buildXY` by type, like `hero.buildXY("fence", 34, 30)`; to say passwords, like `hero.say("Hush!")`; etc.)
**What kind of text can you put in a string?** (>Any text you want!)
**What does string concatenation mean?** (Adding something to a string.)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips, and especially for string concatenation, the error messages. You may need to reinforce that each string needs opening and closing quotes, and that in between strings and other strings or strings and variables, you always need a `+` to concatenate.

Students may run into errors with code like this:

```
hero.say("Take " + numToTakeDown " down, pass it around!")  # Missing second +
hero.say("Take " + numToTakeDown + down, pass it around!")  # Missing second opening "
```

If student have trouble figuring out an error, ask them to carefully review their string and concatenation syntax, or see if a classmate can spot the mistake.

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**When would you need to use the string concatenation operator, `+`?**
>When you have to put a string together with a variable. Since you don't know what the variable is ahead of time, but you need to do something with it in a string, like sing it in a song. So you put the song lyric with a `+` and the variable.

**How do you combine two variables into a string with a space between them?
>You can't just put the variables together like `x + y`, because they won't have a space. You have to put a string that just has a space in between, like `x + " " + y`.

**Why do you think that the people who designed Python chose the `+` sign to represent concatenating strings together?
>Because what you really doing is adding one string to the other string, and the symbol for addition is `+`.














##### Module 12
## Computer Arithmetic
### Summary
**Computer Arithmetic** is TODO

### Transfer Goals
- TODO
- TODO
- 

### Instructive Activity: Arithmetic Algorithm (12 mins)
#### Explain (2 mins)
TODO

#### Interact (8 mins)
TODO

#### Reflect (2 mins)
**TODO?** (TODO)
**TODO?** (TODO)
**TODO?** (TODO)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and TODO

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**TODO?**
>TODO

**TODO?**
>TODO

**TODO?**
>TODO


##### Module 13
## Properties
### Summary
Flags give the game a real-time element. Players may place flags on the game screen, and have their hero respond to them. Either click on the flag color, or use the first letter of the color, then click on the screen to place the flag. Use `hero.pickUpFlag()` to make the hero go to the flag and clear it.

### Transfer Goals
- Access a property using dot notation.
- Save a property in a variable.
- Tell the difference between a property and a function.

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
  `"Die Hard"`
  `4.5 feet`
  `"Diana"`

Note that everyone has an age property, and the same way of accessing it, but the values of that property are not the same for everyone!

#### Reflect (2 mins)
**What’s a property?** (Something about an object)  
**How can you tell the difference between a function and a property?** Functions have parentheses (), properties do not.  
**Can two objects have the same property?** (yes)  
**Do two objects’ properties always have the same value?** (no)  


### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Flags can be tricky for some students, so allow them to pair up to beat the levels. Each student should write their own code, but it’s ok for another student to place the flags for them.

### Written Reflection (5 mins)
**How did you use properties today?**
>I had to see where the flag was and the flag has a property called pos. Then inside that it has two more properties, x and y. You use a dot to get inside the object, or inside the property.

**Tell me about flags.**
>You use flags to tell the hero what to do when the game is running. You can write code to say if there’s a flag, then go to it. Flags have a pos that has x and y. X is right-left and y is up-down.



##### Module 14
## Functions with Returns
### Summary
**Return statements** are TODO

### Transfer Goals
- TODO
- TODO
- 

### Instructive Activity: Vending Machine (12 mins)
#### Explain (2 mins)
TODO

#### Interact (8 mins)
TODO

#### Reflect (2 mins)
**TODO?** (TODO)
**TODO?** (TODO)
**TODO?** (TODO)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and TODO

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**TODO?**
>TODO

**TODO?**
>TODO

**TODO?**
>TODO



##### Module 15
## Not Equals
### Summary
**Not Equals** are TODO

### Transfer Goals
- TODO
- TODO
- 

### Instructive Activity: Picky Eating (12 mins)
#### Explain (2 mins)
TODO

#### Interact (8 mins)
TODO

#### Reflect (2 mins)
**TODO?** (TODO)
**TODO?** (TODO)
**TODO?** (TODO)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and TODO

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**TODO?**
>TODO

**TODO?**
>TODO

**TODO?**
>TODO



##### Module 16
## Boolean Or
### Summary
**Boolean Or** is TODO

### Transfer Goals
- TODO
- TODO
- 

### Instructive Activity: Dance Party (12 mins)
#### Explain (2 mins)
TODO

#### Interact (8 mins)
TODO

#### Reflect (2 mins)
**TODO?** (TODO)
**TODO?** (TODO)
**TODO?** (TODO)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and TODO

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**TODO?**
>TODO

**TODO?**
>TODO

**TODO?**
>TODO



##### Module 17
## Boolean And
### Summary
**Boolean And** is TODO

### Transfer Goals
- TODO
- TODO
- 

### Instructive Activity: Dance Party - Extended Mix (12 mins)
#### Explain (2 mins)
TODO

#### Interact (8 mins)
TODO

#### Reflect (2 mins)
**TODO?** (TODO)
**TODO?** (TODO)
**TODO?** (TODO)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and TODO

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**TODO?**
>TODO

**TODO?**
>TODO

**TODO?**
>TODO



##### Module 18
## Relative Movement
### Summary
**Relative movement** is TODO

### Transfer Goals
- TODO
- TODO
- 

### Instructive Activity: Teacher Patrol (12 mins)
#### Explain (2 mins)
TODO

#### Interact (8 mins)
TODO

#### Reflect (2 mins)
**TODO?** (TODO)
**TODO?** (TODO)
**TODO?** (TODO)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and TODO

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**TODO?**
>TODO

**TODO?**
>TODO

**TODO?**
>TODO



##### Module 19
## Time
### Summary
**Time** is TODO

### Transfer Goals
- TODO
- TODO
- 

### Instructive Activity: Breath Stopwatch (12 mins)
#### Explain (2 mins)
TODO

#### Interact (8 mins)
TODO

#### Reflect (2 mins)
**TODO?** (TODO)
**TODO?** (TODO)
**TODO?** (TODO)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and TODO

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**TODO?**
>TODO

**TODO?**
>TODO

**TODO?**
>TODO



##### Module 20
## Break and Continue
### Summary
**Break and continue statements** are TODO

### Transfer Goals
- TODO
- TODO
- 

### Instructive Activity: TODO??? (12 mins)
#### Explain (2 mins)
TODO

#### Interact (8 mins)
TODO

#### Reflect (2 mins)
**TODO?** (TODO)
**TODO?** (TODO)
**TODO?** (TODO)

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and TODO

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**TODO?**
>TODO

**TODO?**
>TODO

**TODO?**
>TODO








##### Module 21
## Review - Multiplayer Arena
### Summary

This is a boss level! It will take all your ingenuity and collaboration to solve it. Have students work in pairs and share their tips with other teams. Make observations about the level on scratch paper, and then use them to make a plan. The goal of the level is to defeat the main boss, but you also have to collect coins, hire mercenaries, and heal your champion. The player area is in the bottom left, and the tents may be obscured by the status bar. Press SUBMIT to see the full screen.

The arena level is a reward for completing the required work. Students who have fallen behind in the levels or who have not completed their written reflections should use this time to finish. As students turn in their work, they can enter the Cross Bones arena and attempt multiple solutions until time is called.

### Transfer Goals
- Synthesize all CS3 concepts.

### Instructive Activity: Review & Synthesis (10 mins)

#### Interact (10 mins)
Review! As a class, try to remember all the new vocabulary words you learned so far. Decide on a definition and an example. Have students write these on the board and correct each other’s work. Consult the game where there are disputes.

**Object** - a character or thing can can do actions, `hero`
**Function** - an action that an object can do, `hero.cleave()`
**Argument** - additional information for a function, `hero.attack(enemy)`
**Loop** - code that repeats, `while True:`
**Variable** - a holder for a value, `enemy = ...`
**Conditional** - code that checks if, `if hero.isReady()`:
**Concatenation** - adding two strings together, `"string1" + "string2"`
**Arithmetic** - using Python to do math, like `2 + 2`
**Property** - data belonging to an object, like `item.pos`
**Flags** - objects you put down to send input to your program
**Return** - when a function computes a value and returns it
**Boolean** - whether something is true or false
**Break** - a way to exit a `while` loop
**Continue** - a way to skip to the top of a `while` loop

### Coding Time (30-45 mins)

Have students who have completed the rest of Course 3 work in pairs and navigate to the last level, **Cross Bones**, and complete it at their own pace.

For students having problems, remind them of all the debugging strategies they have learned so far. Read the instructions! Remember the hints! Sit and think about how to solve the problem and how you’ll be able to tell it’s solved. All the habits of mind of a good programmer come to bear on these levels: defining the problem, breaking the problem down into parts, making a plan, syntax and debugging, sticking to it, and asking for help.

#### Rankings

Once students beat the default computer they will be put in for the class ranking. Red teams only fight against blue teams and there will be top rankings for each. Students will only compete against the computer and other students in your CodeCombat class (not strangers).

Note that the class rankings are plainly visible. If some students are intimidated by competition or being publicly ranked, give them the option of a writing exercise instead:

- Write a walkthrough or guide to your favorite level
- Write a review of the game
- Design a new level

#### Dividing the Class

Students must choose a team to join: Red or Blue. It is important to divide the class as most students will choose red. It doesn’t matter if the sides are even, but it is important that there ARE players for both sides.

- Divide the class into two randomly by drawing from a deck of cards.
- Students who turn in their work early join the blue team, and latecomers play red.

#### Refining the Code

Code for Power Peak can be submitted more than once. Encourage your students to submit code, observe how it fares against their classmates, and then make improvements and resubmit. In addition, students who have finished the code for one team can go on to create code for the other team.

### Written Reflection (5 mins)

**Write a chronicle of your epic battle from the point of view of either the hero or the boss.**
>I am Tharin Thunderfist, the great hero of the battle of Cross Bones. Together with my guardian, Okar Stompfoot, I attacked the ogres and freed the valley from their tyranny. I gathered coins to pay archers and fighters to join the battle. Then I cured Okar when he was injured.

**How did you break down the problem? What challenges did you come up against? How did you solve them? How did you work together?**
>First we saw that the code already did collecting coins. So we made it go to the tents when we could afford to hire fighters. Then we had to get the potion, but we messed up the code. The teacher helped us fix it. But we still didn’t win, so we asked another team for help and they showed us how to defeat the enemy. We worked well together. It was fun and hard.
