###### Last updated: 09/13/2016

##### Lesson Plans
# Computer Science 3

### Curriculum Summary
- Recommended Prerequisite: Computer Science 2
- 11 x 45-60 minute coding sessions

#### Overview
Now that students have a solid foundation in the most useful types of control flow (conditionals, functions, and events), they're prepared to level up both their conditional logic skills and their control flow control. Most of the differences in the programs the students want to write and the programs they know how to write start to fall away in Computer Science 3.

In this course, students will keep practicing their functions, events, and nested conditionals. On top of those, they'll get into more sophisticated operators and keywords. String concatenation will let players modify strings dynamically in their code to produce whatever text they want. Arithmetic will help players become more comfortable with using math in programming. All things in CodeCombat are objects, (that's the "object" part of object-oriented programming,) and these things have accessible attributes, such as a Munchkin's position or a coin's value; both are important to begin visualizing the internal structure of the objects that make up their game world. Alongside properties, students unlock the additional game mechanic of real-time input handling with flags. They then learn to use functions that return values, to break up computations into smaller pieces. The boolean *equality*, *inequality*, *or*, and *and* operators let them express compound conditionals. Combining those with computer arithmetic and properties lets players finally explore relative movement, directing their hero to dynamic locations. They also learn to work with time programmatically, and to manipulate their while-loops with the *break* and *continue* statements.


_This guide is written with Python-language classrooms in mind, but can easily be adapted for JavaScript._

### Scope and Sequence

| Module                                                      | First Level          | Transfer Goals                                            |
| -----------------------------------------------------       | :-----------------   | :-----------------                                        |
| [11. String Concatenation](#string-concatenation)           | Friend and Foe       | Add strings together with `+`                             |
| [12. Computer Arithmetic](#computer-arithmetic)             | The Wizard's Door    | Do arithmetic with code (`+` `-` `*` `/`)                 |
| [13. Properties](#properties)                               | Backwoods Bombardier | Access object properties with `.`                         |
| [14. Functions with Returns](#functions-with-returns)       | Burlbole Grove       | Write functions that return answers                       |
| [15. Not Equals](#not-equals)                               | Useful Competitors   | Test whether two things are not the same                  |
| [16. Boolean Or](#boolean-or)                               | Salted Earth         | Execute if-statements if one of two things are true       |
| [17. Boolean And](#boolean-and)                             | Spring Thunder       | Execute if-statements if both of two things are true      |
| [18. Relative Movement](#relative-movement)                 | The Mighty Sand Yak  | Combine x- and y-properties and arithmetic for movement   |
| [19. Time and Health](#time-and-health)                     | Minesweeper          | Code based on elapsed time and hero health                |
| [20. Break and Continue](#break-and-continue)               | Hoarding Gold        | Skip or end while-loops with break and continue statments |
| [21. Review - Multiplayer Arena](#review-multiplayer-arena) | Cross Bones          | Synthesize all CS3 concepts                               |


### Core Vocabulary
**Concatenation** - String concatenation is used to add two strings together with the **string concatenation operator:** `+`

**Arithmetic** - Addition, subtraction, multiplication, and division. Course 3 begins to ease the player into using math while coding. Levels catering to basic arithmetic address how to use math as needed in order to perform different actions effectively.

**Property** - Data about or belonging to an object. You get to it by specifying the object, then a dot, then the name of the property, like `item.pos`.

**Flags** - Real-time input devices. Up until now, students' CodeCombat programs haven't been interactive--there hasn't been real-time player input while the level is running. Now with flags, students have a way of sending input to their programs: clicking a mouse plants a flag that the hero can respond to with the `hero.findFlag()` function.

**Return** - A return statements lets a function compute a result value and return it to the place that called the function. When your functions can return their results, it's easier to break data-producing computations into smaller steps.

**Boolean** - A binary variable with two possible values: `True` and `False`. The `conditionals` you use in if-statements and even while-loops are evaluated to boolean results. Boolean logic is the way that boolean values combine to form a single boolean value.

**Break** - A way to exit out of a while loop early. Break statements say, "Break out the loop, we're done with it." You might use a break statement to move on to the rest of your program after a loop.

**Continue** - A way to skip back to the top of a while loop. Continue statements say, "Let's stop this loop here and continue at the top on the next iteration." If you don't need to finish a loop (because it doesn't need to do anything right now), you can use a continue statement.


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
**String concatenation** is used to add two strings together. Remember that strings are `"text inside quotes"`. When you want to build a longer string out of two shorter strings, or combine a string and a variable, you can use the **string concatenation operator:** `+`

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
**What kind of text can you put in a string?** (Any text you want!)  
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

**How do you combine two variables into a string with a space between them?**
>You can't just put the variables together like `x + y`, because they won't have a space. You have to put a string that just has a space in between, like `x + " " + y`.

**Why do you think that the people who designed Python chose the `+` sign to represent concatenating strings together?**
>Because what you really doing is adding one string to the other string, and the symbol for addition is `+`.



##### Module 12
## Computer Arithmetic
### Summary
**Computer arithmetic** is how you write code to do math. You can add, subtract, multiply, and divide not just numbers, but variables representing numbers and the results of functions that return numbers. Computer arithmetic lets you dynamically calculate all sorts of things.

### Transfer Goals
- Learn how to use the addition, subtraction, multiplication, and division operators: `+`, `-`, `*`, and `/`
- Perform arithmetic on "numeric literals" (like `2 + 2`)
- Perform arithmetic on variables (like `x - 5`)
- Perform arithmetic on properties (like `hero.pos.y + 10`)

### Instructive Activity: Hailstone Numbers (15 mins)
#### Explain (2 mins)
Just like you can do arithmetic by hand or with a calculator, you can do it with computer code. It should look very familiar, but instead of `×` for multiplication, we use `*` because it's easier to type. Here are some examples:

```
5 + 2  # answer: 7
5 - 2  # answer: 3
5 * 2  # answer: 10
5 / 2  # answer: 2.5
```

The exciting part is when you can make the arithmetic automatic, and since computers are very fast, you can calculate the answers almost instantly. Let's look at an example.

#### Interact (13 mins)

Explain this to the class:

"We are going to pick a number. If it's an even number, we are going to divide it two; else if it's odd, we're going to multiply it by three and add one. We'll keep doing this until we get down to 1. Let's start with 5. 5 is odd, so we multiply by 3 and add 1: 16." Feel free to involve the class, and write down the steps as you go, like this:

```
5 is odd
5 * 3 + 1 == 16, which is even
16 / 2 == 8, which is even
8 / 2 == 4, which is even
4 / 2 == 2, which is even
2 / 2 == 1, so we're done
-------------------------
5 total steps
```

Now, write the following function on the board and tell the class that this will automatically write out the sequence of steps needed.

```
def hailstone(number):
    teacher.write("Sequence: " + number)
    while number != 1:
        if isEven(number):
            number = number / 2
        else:
            number = number * 3 + 1
        teacher.write(" " + number)
```

Ask the students for a number between 2 and 10 to start with and then run through the program with them, writing out the numbers as they go:

```
hailstone(10)
Sequence: 10 5 16 8 4 2 1
```

If time permits, walk the students through adding a counter to the code to keep track of how many steps it took:

```
def hailstone(number):
    teacher.write("Sequence: " + number)
    steps = 0
    while number != 1:
        if isEven(number):
            number = number / 2
        else:
            number = number * 3 + 1
        teacher.write(" " + number)
        steps = steps + 1
    teacher.write("Steps: " + steps)

hailstone(3)
Sequence: 3 10 5 16 8 4 2 1
Steps: 7
```

Share that `hailstone(27)` takes 111 steps and gets as high as 9232 before falling back down to 1. Explain that these are called hailstone numbers because like hailstones, they go up and down a number of times before inevitably falling all the way. However, no one has been able to prove that this has to happen every time, even though computers can calculate the number of hailstone steps for numbers with thousands of digits instantly with the code on the board. If you found a number that didn't eventually fall back to 1, you'd be famous.


### Coding Time (25 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and remind them that they'll have to edit and run their programs multiple times to get all the instructions.

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**When does it make sense to use a computer to do math?**
>When you have to do a lot of math really fast, like to calculate a big number. Or when you don't know what the values are ahead of time, so the computer can do the math on a variable.

**What kind of math do you know how to do yourself but don't know how to use a computer to do, and how do you think you can do it with a computer?**
>I can square numbers. Maybe there is a square function, like square(number)?



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
**How can you tell the difference between a function and a property?** (Functions have parentheses (), properties do not.)  
**Can two objects have the same property?** (Yes)  
**Do two objects’ properties always have the same value?** (No)  


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
**Return statements** let functions `return` a value! Whenever a function is called, it will be equal to whatever value it `returns`. When a function gets to a `return` statement, the function immediately ends.

### Transfer Goals
- Write functions that `return` answers
- Use `return` statements to exit functions

### Instructive Activity: Vending Machine (12 mins)
#### Explain (2 mins)
Previously, you have been writing functions that make your hero or pet perform an action, like the `goFetch` function that would call `pet.fetch()`. This let you organize your code into different functions and make it easier to understand. Now you're going to learn how to write code that instead of performing an action, performs a computation and returns the result with a `return` statement.

Here's an example:

```
def howMany(things):
    if things == 1:
        return "a"
    if things == 2:
        return "a couple"
    if things <= 4:
        return "a few"
    if things <= 7:
        return "several"
    return "a lot of"

teacher.say("I see " + howMany(hats) + " hats.")
```

#### Interact (8 mins)
With the class, code up a simple vending machine.

Draw a picture of a vending machine with four buttons on the board, with buttons labeled A1, A2, B1, and B2 in a 2x2 grid. Walk the class through writing the code for the vending machine. Start with this vending machine skeleton:

```
def vend(button):
    if button == "A1":
        return ""

while True:
    button = class.pressButton()
    food = vend(button)
    class.eat(food)
```

Ask the class what the vending machine should sell when you press button A1, and write it in as the first string to `return`. Have the class help you choose the rest of the food and write the rest of the `if` and `return` statements. You might end up with something like this:

```
def vend(button):
    if button == "A1":
        return "Cheetos"
    elif button == "A2":
        return "Apple"
    elif button == "B1":
        return "Slime"
    elif button == "B2":
        return "A bear"

while True:
    button = class.pressButton()
    food = vend(button)
    class.eat(food)
```

Reiterate how the `vend` function is using `return` statements to return food values when the function is called. Functions with `return` statements are a good way to split up and organize computations.

If there's time, add a fifth button to return your change, and show the class how you can modify the code to deal with it by moving all the `return` statements to just `return` a `result` variable:

```
def vend(button):
    result = "money"
    if button == "A1":
        result = "Cheetos"
    elif button == "A2":
        result = "Apple"
    elif button == "B1":
        result = "Slime"
    elif button == "B2":
        result = "A bear"
    return result

while True:
    button = class.pressButton()
    food = vend(button)
    if food != "money":
        class.eat(food)
```


#### Reflect (2 mins)
**What are some functions you have written functions before in CodeCombat?** (`goFetch()`, `sayName()`, `cleaveOrAttack()`, `maybeBuildTrap(x, y)`, `cleaveWhenClose(target)`, `checkEnemyOrSafe(target)`, `checkTakeHide(item)`, `checkAndDefend(target)`, `checkAndAttack(target)`, `pickUpCoin()`, `attackEnemy()`)  
**What are some built-in CodeCombat functions you use that `return` values?** (`hero.findNearestEnemy()`, `hero.isReady("cleave")`, `hero.distanceTo(target)`, `hero.findNearestItem()`)  
**Why does a return statement immediately exit a function?** (Because if you called `return` twice, you wouldn't know which value to use.)  

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Whenever a student is having trouble with a function, have them go execute the function themselves so they can say exactly what value it will return. Remind students to make sure that they do something with the return value of the function once they have called it--watch out for mistakes:

```
# Correct: storing return value in a variable, then using if
canAttack = inAttackRange(nearestEnemy)
if canAttack:
    hero.attack(nearestEnemy)

# Correct: using return value directly in if
if inAttackRange(nearestEnemy):
    hero.attack(nearestEnemy)

# Incorrect: not doing anything with return value
inAttackRange(nearestEnemy)
hero.attack(nearestEnemy)
```

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**When are functions with returns useful?**
>When you want to figure something out, like whether to attack an enemy or pick up a coin, instead of just attacking it directly inside the function. Or when you want to get some return value from outside your code, like with findNearestEnemy().

**Naming functions that return values is important. Come up with three function names that would return a value useful in daily life, and write some example values they would return to make sure the names make sense.**
>`whatTimeIsIt()` would return the time, like `"7:30 am"` or `"1:11 pm"`. `findColor(thing)` would return what color something is, like `"red"` or `"mahogany"`. `isFriend(person)` would return whether someone likes you, either `True` or `False`.b



##### Module 15
## Not Equals
### Summary
The **inequality operator** is `!=` (*not equals*) and lets one compare two values to see if they're different. It's the opposite of the **equality operator**, `==` (*equals*). The `!` means *not*.

### Transfer Goals
- Test whether two things are not the same
- Use `!=` and `==` appropriately in code
- Read `!=` as "not equals"

### Instructive Activity: Picky Eating (10 mins)
#### Explain (2 mins)
Remember the equality operator, `==`, which asks if two things are equal? There's also the *in*equality operator, `!=`, which asks if two things are *not* equal. So where `x == 4` asks whether "x equals four", you can use `x != 4` to ask whether "x does not equal four". Or you can use `if enemy.type != "burl":` to do something whenever you see an enemy that isn't a burl.

#### Interact (8 mins)
Tell the class to imagine it's 4:00 am and they wake up for a snack, going to the fridge in zombie mode. As a zombie, they aren't thinking straight, so we need to write a simple algorithm for them to follow in their snacking. Write the following code on the board:

```
fridge = zombie.findNearestFridge()
zombie.moveXY(fridge.pos.x, fridge.pos.y)
while True:
    food = zombie.ransack(fridge)
```

Ask the class what do to next with the `food` variable, looking for `zombie.eat(food)`. Ask if they want to eat just any food, or if there is a specific food to avoid. Take the first bad food mentioned and add an inequality comparison:

```
fridge = zombie.findNearestFridge()
zombie.moveXY(fridge.pos.x, fridge.pos.y)
while True:
    food = zombie.ransack(fridge)
    if food.type != "broccoli":
        zombie.eat(food)
```

Add a nested inequality comparison by suggesting that the zombie should just make sure to avoid foods with any given attribute, like shape or color:

```
fridge = zombie.findNearestFridge()
zombie.moveXY(fridge.pos.x, fridge.pos.y)
while True:
    food = zombie.ransack(fridge)
    if food.type != "broccoli":
        if food.color != "green":
            zombie.eat(food)
```

Explain how because you want to eat most foods and don't want to have to explicitly name each food you *do* want to eat with `==`, you instead use `!=` to avoid the ones you *don't* want to eat.

Note that you can't do a compound conditional yet, but if students ask, those are coming up in the next two modules, so you could soon write: `if food.type != "broccoli" and food.color != "green"`.


### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. When students are checking `item.type` and `enemy.type`, remind them to make sure they are spelling the types correctly: `if enemy.type != "peon"`, `if item.type != "poison"`,  and `if item.type != "gem"`. Have students pay attention to the yellow arrows indicating where to code, since sometimes they need to modify existing `if` conditions.

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**What are `==` and `!=` and how do you pronounce them?**
>`==` is the equality operator, and you say "is equal to". `!=" is the inequality operator, and you say "is not equal to". `!=` is the opposite of `==`.

**Where do you use `==` and `!=` in your code?**
>You use them in if-statements, because you have to decide whether to do something or not based on whether two values are the same or different.



##### Module 16
## Boolean Or
### Summary
A **boolean** is a variable with two possible values: `True` and `False`. The `conditionals` you use in if-statements and even while-loops are evaluated to boolean results. Boolean logic is the way that boolean values combine to form a single boolean value. The **boolean or** operator, `or`, returns `True` if either the value before or after is `True`, or `False` if both are `False`.

### Transfer Goals
- Execute if-statements if one of two things are true
- Understand what a boolean value is
- Understand how to use the boolean `or` operator

### Instructive Activity: Dance Party (10 mins)
#### Explain (2 mins)
`True` and `False` are called boolean values. Remember the `hero.isReady("cleave")` function? It would return either `True` or `False`. And when you write `enemy.type == "munchkin"`, the expression becomes either `True` or `False`. We're going to introduce the boolean `or` operator, which lets you combine two boolean values into one.

#### Interact (7 mins)
Ask the class to thing of a few dance moves. While they're thinking, write the following code on the board:

```
def hearSong(song):
    

dj.on("play", hearSong)
while True:
    dj.play()
```

For each dance move the class came up with, ask for two or more songs or artists that would make them do that dance move. Write the examples in the `hearSong` function:

```
def hearSong(song):
    if song.title == "My Boo" or song.artist == "MC Hammer":
        crowd.dance("Running Man")
    elif song.artist == "The Chainsmokers" or song.genre = "Electronica":
        crowd.dance("Rave")
```

Save this code for the next module, so you can extend it.

#### Reflect (1 min)
**Why would you want to use `or` in your code?** (To combine two if-statement checks into one.)  
**What is a boolean value?** (Either `True` or `False`.)  

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Watch out for mistakes like this, where the students format their code like English and don't repeat both sides of the `or`:

```
if enemy.type == "thrower" or "munchkin":  # Incorrect, since the computer sees (enemy.type == "thrower") or "munchkin"
if enemy.type == "thrower" or enemy.type == "munchkin":  # Correct
```

### Written Reflection (5 mins)
**What is the `type` property? What types of things have you seen in CodeCombat so far?**
>The `type` property is a string telling you what kind of object something is, like `"munchkin"`, `"thrower"`, `"burl"`, `"gem"`, `"coin"`, and `"poison"`.



##### Module 17
## Boolean And
### Summary
Just like the boolean `or` operator lets you combine two boolean values into one, so does the **boolean and** operator, `and`. Whereas `True or False` becomes `True`, `True and False` is `False`--the `and` operator makes sure both values are `True`, `True and True` is `True`.

### Transfer Goals
- Execute if-statements if both of two things are true
- Understand how to use the boolean `and` operator

### Instructive Activity: Dance Party - Extended Mix (10 mins)
#### Explain (2 mins)
Up until now we have been using boolean `or` with things like `==` and `!=`. You can also use the boolean `and` operator, which works just like it sounds: do something if both this *and* that are `True`. Note that if the first part is `False`, then it doesn't even check the second part, to save time, so you can write code like `if enemy and enemy.type == "dragon":` and there won't be an error if there is no `enemy`, since it doesn't get to checking whether `enemy.type` is `"dragon"`. This is called short-circuiting.

Let's use `and` to make our dance party from last time better by taking out some overplayed songs.

#### Interact (6 mins)
Bring back the code the class had from last time:

```
def hearSong(song):
    if song.title == "My Boo" or song.artist == "MC Hammer":
        crowd.dance("Running Man")
    elif song.artist == "The Chainsmokers" or song.genre = "Electronica":
        crowd.dance("Rave")

dj.on("play", hearSong)
while True:
    dj.play()
```

Ask for a favorite artist from the class, and then a crowd reaction that would go with that artist. Then ask for bad or overplayed song by that artist that the crowd shouldn't react to. Turn it into a compound if-statement using `and`, like this:

```
def hearSong(song):
    if song.title == "My Boo" or song.artist == "MC Hammer":
        crowd.dance("Running Man")
    elif song.artist == "The Chainsmokers" or song.genre = "Electronica":
        crowd.dance("Rave")
    elif song.artist == "One Direction" and song.title != "Story Of My Life":
        crowd.scream("THIS IS MY JAM YO!")
```

Now ask for some other music that has the same reaction as the previous one. Explain that when you combine `or` and `and`, you should group things with parentheses to make sure the computer knows which parts go together:

```
    elif (song.artist == "One Direction" and song.title != "Story Of My Life") or song.title == "Can't Feel My Face":
        crowd.scream("THIS IS MY JAM YO!")
```


#### Reflect (2 mins)
**What is some code you have written in CodeCombat that you can use `and` to simplify?** (Checking whether there is an enemy and cleave is ready, or if cleave is ready and the enemy is close enough.)  
**If you have three `and` or three `or` operators, do you need parentheses to group them?** (No, because the order doesn't matter until you mix `and` and `or`.)  

### Coding Time (35-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Remind students to read their compound if-statements aloud to make sure they make sense.

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**Challenge: what happens in code like `if item and item.type == "gem":`?**
>`item` gets converted to `True` or `False`, depending on whether it exists, and `item.type == "gem"` gets converted to `True` or `False` depending on whether it's a gem, and then the `and` combines them into `True` if the item exists and is a gem, otherwise `False`.

**Given an `enemy` variable, can you think of a way to use boolean `and` to both check if there's an enemy and to check if the enemy is closer than 10 meters, in one line?**
>`if enemy and hero.distanceTo(enemy) < 10:`

**Make up an `if` example, either in CodeCombat or real life, that uses both `and` and `or` on the same line to combine three boolean values.**
>`if fridge.hasFood() and (me.isHungry() or me.isBored()): me.open(fridge)`




##### Module 18
## Relative Movement
### Summary
**Relative movement** combines computer arithmetic and property access, letting students direct their hero to move to dynamic locations with commands like `hero.moveXY(hero.pos.x + 10, hero.pos.y)` or `hero.buildXY("fence", yak.pos.x, yak.pos.y - 10)`.

### Transfer Goals
- Use `moveXY` to move relative to dynamic positions with coordinate arithmetic
- Internalize how positive and negative `x` and `y` coordinates relate to movement up, down, left, and right
- Combine relative movement with loops and conditionals to produce desired movement patterns

### Instructive Activity: Teacher Patrol (12 mins)
#### Explain (2 mins)
Previously, you have used three types of movement:

```
hero.moveRight()
hero.moveXY(34, 20)
hero.moveXY(item.pos.x, item.pos.y)
```

Now that you know how to do computer arithmetic, you can have your hero move relative to something else, whether it's their previous position or an enemy unit. Here's some code that will move up and to the right forever:

```
while True:
    hero.moveXY(hero.pos.x + 5, hero.pos.y + 5)
```

#### Interact (8 mins)
Explain to the class that the goal is to write a program to make you (the teacher) walk in a square around a student whenever the student claps. Ask for a volunteer to stand in front of the class and clap. Have the class help write the event handler from scratch, prompting them for a function name ("What should we call the function to run when we hear a clap?") and how to start listening for a clap event from a student:

```
def heardClap():
    

maria.on("clap", heardClap)
```

Now draw a diagram on the board of a square with a dot in the middle, and label the dot as `{x: 0, y: 0}`. Say you're going to start in the top right. Label it {x: 5, y: 5}, and write the first line of your function:

```
def heardClap():
    teacher.moveXY(student.pos.x + 5, student.pos.y + 5)

maria.on("clap", heardClap)
```

Tell the chosen student to clap, and move to the corresponding coordinate five feet to the right and five feet in front of her (if she is facing the board). Have the class work through the rest of the program on the board to get to a solution that correctly has you walking in a square, having the student clap every time a new line of code is added to test the solution. If going clockwise, it might look like this, but it's up to you and the class which order to go (and which way your axes are aligned).

```
def heardClap():
    teacher.moveXY(student.pos.x + 5, student.pos.y + 5)
    teacher.moveXY(student.pos.x + 5, student.pos.y - 5)
    teacher.moveXY(student.pos.x - 5, student.pos.y - 5)
    teacher.moveXY(student.pos.x - 5, student.pos.y + 5)
    teacher.moveXY(student.pos.x + 5, student.pos.y + 5)

maria.on("clap", heardClap)
```

Pay attention to the code they suggest, since it may not be what they mean. The students will probably make mistakes that involve you walking diagonally across the square, bumping into the student in the center. Pretend to throw an error message and then have them debug what happened to fix the code.


#### Reflect (2 mins)
**What would happen if the student moved while the teacher was moving around her?** (The teacher would walk in a different shape depending on where the student was when each `moveXY` started.)  
**What two new Course 3 concepts do you have to combine to do relative movement?** (Properties and computer arithmetic.)  
**In CodeCombat, which directions are -x, +x, -y, and +y?** (Left, right, down, and up.)  

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. If they aren't moving like they expected to, have them drag the time scrubber to the moment where it all went wrong and pause the code, then think about exactly what coordinates are being calculated at that time.

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**How would you implement `hero.moveRight()`, where the hero moves 12 meters to the right, using `hero.moveXY()` and relative movement? What about `hero.moveLeft()`, `hero.moveUp()`, and `hero.moveDown()`?**
>For `hero.moveRight()`: `hero.moveXY(hero.pos.x + 12, hero.pos.y)`
>For `hero.moveLeft()`: `hero.moveXY(hero.pos.x - 12, hero.pos.y)`
>For `hero.moveUp()`: `hero.moveXY(hero.pos.x, hero.pos.y + 12)`
>For `hero.moveDown()`: `hero.moveXY(hero.pos.x, hero.pos.y - 12)`

**Make up a story: why do you think the yaks are so violent in CodeCombat that they would attack you if you ever got too close to them?**
>Probably they have learned to defend themselves against ogre poachers so they have a built-in fight response when they get close to anything with two legs. Before the ogres came, they would come right up to you and ask for food instead, but now they living in paranoia and fear after the ogres started hunting them.



##### Module 19
## Time and Health
### Summary
**Time** is a basic input to a lot of programs. When it's a certain time, do this. When enough time has passed, do that. In this module, students will learn to respond to time passing with the `hero.now()` function. Also in this module is practice with `hero.health`, which is another way to determine *when* to do something: when your health reaches a certain threshold.

### Transfer Goals
- Code based on elapsed time with the `hero.now()` function
- Code based on the time `hero.health` passes thresholds
- Learn *when* to change overall strategies in code

### Instructive Activity: Breath Stopwatch (12 mins)
#### Explain (2 mins)
You've already used events to determine when to do things in your programs, and you've also used a while-loop with if statements to decide when to do one thing or another. In those if statements, you already know how to check whether there are enemies, if you see items, if things are close by, or if cleave is ready. These levels add two new things you can check: how hurt your hero is with `hero.health` and `hero.maxHealth`, and what time it is with the `hero.now()` function. The current time is a very useful input to all sorts of programs.

#### Interact (8 mins)
Tell the class you're going to write a program to score yourself on how long you can hold your breath. Start with this code on the board:

```
def calculateScore():
    endTime = now()

startTime = now()
teacher.on("exhale", countScore)
```

Say that you're going to test the program. Announce the current time, including the seconds: "`startTime` is 10:05:30". Hold your breath for a few seconds, then exhale. Now say, "10:05:35. I exhaled, so my countScore event listener fired for the "exhale" event, so I calculate the `endTime` as 10:05:35. In code, how do we figure out how many seconds I held my breath for?" Help the students to figure out to subtract the two times and then start grading yourself:

```
def calculateScore():
    endTime = now()
    duration = endTime - startTime
    if duration < 10:
        score = "baby"
```

Ask the students for other time thresholds and scores until you have a program like this:

```
def calculateScore():
    endTime = now()
    duration = endTime - startTime
    if duration < 10:
        score = "baby"
    elif duration < 20:
        score = "senior citizen"
    elif duration < 30:
        score = "good"
    elif duration < 40:
        score = "athlete"
    else:
        score = "robot"
    return score

startTime = now()
teacher.on("exhale", countScore)
```

Once the program is ready, erase `teacher` and write `student`, then help the students time holding their breaths all at once. Once everyone is done, find the longest duration and explain the class that now that you know the range, by using more computer arithmetic, you can adjust the program to adapt to the best score:

```
maxTime = 55
def calculateScore():
    endTime = now()
    duration = endTime - startTime
    if duration < 1 / 5 * maxTime:
        score = "baby"
    elif duration < 2 / 5 * maxTime:
        score = "senior citizen"
    elif duration < 3 / 5 * maxTime:
        score = "good"
    elif duration < 4 / 5 * maxTime:
        score = "athlete"
    else:
        score = "robot"
    return score

startTime = now()
student.on("exhale", countScore)
```

Explain that if you held your breath for at least four-fifths as long as the longest breath, you would be a robot; if you held it for at least three-fifths as long, you'd be an athlete; and so on.


#### Reflect (2 mins)
**How do you get a time duration from two absolute times?** (Subtract them.)  
**How do you pronounce `if duration < 1 / 5 * maxTime:`?** ("If the duration is less than one-fifth of the maxTime...")  

### Coding Time (30-45 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Remind them to compare their current `hero.health` to some fraction of `hero.maxHealth` and to make sure they are spelling those correctly, since `hero.health < hero.mxahealth` or some other typo will just always return `False` (since a number is not less-than an undefined property).

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**Apart from choosing when to fight and to get healed, what else do you think you will use `hero.now()` or `hero.health` to do?**
>I would use `hero.now()` to run in a square for the first 30 seconds, and then once all the ogres are chasing me I would stop and cleave them all at once. Or I could shield until I was about to die and then cleave everyone.

**When you call `hero.now()`, it returns a number. What does that number mean? Why doesn't it return today's real-world date and time?**
>The time it returns is the number of seconds since the level started. It is easier to work with than the real time since you don't have to change your code to have a different time threshold every time you run it, and you don't have to keep track of the start time in your code.




##### Module 20
## Break and Continue
### Summary
**Break statements** let you exit out of a while loop early. Break statements say, "Break out the loop, we're done with it." You might use a break statement to move on to the rest of your program after a loop.

**Continue statements** are like break statements, but they skip to the top of the while loop instead of exiting. Continue statements say, "Let's stop this loop here and continue at the top on the next iteration." If you don't need to finish a loop (because it doesn't need to do anything right now), you can use a continue statement.

### Transfer Goals
- End while loops with break statements
- Skip while loop iterations with continue statements
- Understand when break/continue are cleaner than nested if/else

### Instructive Activity: A Day in the Life (17 mins)
#### Explain (5 mins)
You have been writing `while True:` loops this whole time, without any way to end the loops; they are infinite. But what if you want to stop doing a loop and start doing something else, like if you have defeated all the enemies and want to go home? You can use a `break` statement to exit a loop if you don't see any enemies.

```
while True:
    enemy = hero.findNearestEnemy()
    if enemy:
        hero.attack(enemy)
    else:
        break

hero.say("My job here is done!")
hero.retire()
```

Or what if you have a lot of code to run if there *are* enemies, but you just want to do nothing as long as there are *no* enemies? You could put all your code in an `if enemy:` check, or you could use a `continue` statement at the top of your loop:

```
while True:
    enemy = hero.findNearestEnemy()
    if not enemy:
        continue
    # ...
    # ... lots of code here to deal with the enemy
    # ...
```

`Break` and `continue` statements let you control what is happening with your `while` loops.


#### Interact (10 mins)

Write the following schedule on the board, asking students for some information and customizing:

1) What do they do when they aren't in school? (Ex.: play Minecraft and sleep)
2) When does school end? (Ex.: 3:00 pm)
3) How long does a class period last? (Ex.: 45 minutes * 60 seconds per minute)
4) What do students do in between classes? (Ex.: hang out)

```
# A Day in the Life of a Student
while True:
    if today() == "Saturday" or today() == "Sunday":
        student.play("Minecraft")
        student.sleep()
    elif now() < "3:00 pm":
        class = student.findNextClass()
        if class:
            student.moveXY(class.pos.x, class.pos.y)
            student.sit()
            student.wait(45 * 60)
        else:
            student.hangOut()
    else:
        student.moveXY(student.home.pos.x, student.home.pos.y)
        student.play("Minecraft")
        student.sleep()
```

Now say that you are going to use `break` and `else` to transform the program so that we don't have to have any nested `if` statements or use any `else` conditions. This should make the code easier to follow.

```
# A Day in the Life of a Student
while True:
    if today() == "Saturday" or today() == "Sunday":
        break
    if now() > "3:00 pm":
        student.moveXY(student.home.pos.x, student.home.pos.y)
        break
    class = student.findNextClass()
    if not class:
        student.hangOut()
        continue
    student.moveXY(class.pos.x, class.pos.y)
    student.sit()
    student.wait(45 * 60)

student.play("Minecraft")
student.sleep()
```


#### Reflect (2 mins)
**When does it make sense to use `break`?** (When you want to stop doing a while loop and do something else.)  
**When does it make sense to use `continue`?** (When you don't want to have everything nested inside an `else`.)  

### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips, and if they get stuck, have them drag the timeline scrubber to the point where their code stopped doing what they expected and have them reconstruct what their code is trying to do at that time. To help with debugging, this could be a good time to use the Engineering Cycle worksheet again if students haven't tried that recently.

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**What's some code that you have been writing in CodeCombat that could be simpler with `break` or `continue`?**
>A lot of times I check whether there is an enemy or an item. If there's not, I could use `continue` to wait until there is instead of using an `else`. Also, if I wanted to break down a strong door and then keep moving afterward, I could use `break`.

**Make up a story: your hero seems to have more and more soldiers and peasants on their side. Why? Who are the humans, who is your hero, and why are they on the same team?**
>My hero is the one who led the human expedition into these lands ten years ago, since our people were being persecuted in our original country and we wanted freedom to listen to the rhythmic drumming music we like 24/7. But our rhythmic drumming attracted the attention of the ogres, who love to mosh, and our people blame my hero and rely on her for protection and to basically do everything for them, like defending them from ogres and powering their entire coin-collecting economy.



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

Code for Cross Bones can be submitted more than once. Encourage your students to submit code, observe how it fares against their classmates, and then make improvements and resubmit. In addition, students who have finished the code for one team can go on to create code for the other team.

### Written Reflection (5 mins)

**Write a chronicle of your epic battle from the point of view of either the hero or the boss.**
>I am Tharin Thunderfist, the great hero of the battle of Cross Bones. Together with my guardian, Okar Stompfoot, I attacked the ogres and freed the valley from their tyranny. I gathered coins to pay archers and fighters to join the battle. Then I cured Okar when he was injured.

**How did you break down the problem? What challenges did you come up against? How did you solve them? How did you work together?**
>First we saw that the code already did collecting coins. So we made it go to the tents when we could afford to hire fighters. Then we had to get the potion, but we messed up the code. The teacher helped us fix it. But we still didn’t win, so we asked another team for help and they showed us how to defeat the enemy. We worked well together. It was fun and hard.
