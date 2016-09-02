###### Last updated: 

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

### Written Reflection (5 mins)
**How did you use properties today?**
>I had to see where the flag was and the flag has a property called pos. Then inside that it has two more properties, x and y. You use a dot to get inside the object, or inside the property.

**Tell me about flags.**
>You use flags to tell the hero what to do when the game is running. You can write code to say if there’s a flag, then go to it. Flags have a pos that has x and y. X is right-left and y is up-down.

##### Module 10
## Review and Synthesis
### Summary
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
