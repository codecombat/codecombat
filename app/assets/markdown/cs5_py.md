##### Lesson Plans
# Computer Science 5 (Python)

### Curriculum Summary
- Recommended Prerequisite: Computer Science 4
- 12 x 45-60 minute coding sessions

#### Overview
<!-- [MISSING] -->

*This guide is written with Python-language classrooms in mind. Please see the [JavaScript-specific curriculum](/teachers/resources/cs5_js) if your classroom is not using Python.*

### Scope and Sequence

| Module                                                      |                      | Transfer Goals                                            |
| -----------------------------------------------------       | :-----------------   | :-----------------                                        |
| [28. Modulo for Arrays](#modulo-for-arrays)               |                      |                   |
| [29. Predefined Functions](#using-predefined-functions)                                       |                      |               |
| [30. String Searching](#string-searching)              |                      |                            |
| [31. For Loops with Non-1 Steps](#for-loops-with-non-1-steps)                           |                      |                        |
| [32. Array Push](#array-push)                                     |                      |                       |
| [33. Same Array Searching](#same-array-searching)               |                      |    |
| [34. Nested Fors As Grid](#nest-fors-as-grid)       |                      |    |
| [35. Nested Arrays As Grid](#nested-arrays-as-grid)       |                      |    |
| [36. 2D Array Access](#2d-array-access)       |                      |    |
| [37. For Loop Array Access](#for-loop-array-access)       |                      |    |
| [38. Geometry](#geometry)       |                      |    |
| [39. Number Base Conversion](#number-base-conversion)       |                      |    |


##### Module 28
## Modulo for Arrays
### Summary
In this module, the students will learn about the **modulo** operator. The modulo operator is an arithmetic operator used to calculate the remainder of two integers after they are divided. The symbol used for the operator is `%`.

The modulo operator can be used simply to find the remainder after dividing two numbers, but it is often used for other tasks in programming. One task for which it is used is to wrap around back to the beginning of an array. This is useful when trying to access an index that is greater than the length of the array itself.

In these levels, the students will learn how to use the modulo operator with an array in order to wrap back around to the beginning of an array. They will use this skill to summon and command troops in battle.

### Transfer Goals
- Understand what the modulo operator does
- Use the modulo operator to wrap around an array


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Modulo Clock (10 mins)
#### Explain (3 mins)

The students have learned about the arithmetic operators `+`, `-`, `*`, and `/`. Today, they will learn about a new operator called the **modulo operator**. The symbol for the modulo operator is `%`.

`%` returns the remainder after dividing two integers. For example:

```
5 % 3 = 2
10 % 7 = 3
1 % 4 = 1
```
At this point, if the students try to access an index that is outside of an array, they will hit an error. They may have encountered this error already throughout the game.

Now, however, the students know about `%` and how to use it to find the remainder. They can use this to wrap around an array if the index is greater than the length of the array.

For example, consider the following array:

```
summonTypes = ["soldier", "archer", "peasant", "paladin"]

```

Although the array only has four elements, with the use of `%`, the students can summon more than four troops, as so:

```
summonTypes = ["soldier", "archer", "peasant", "paladin"]
for i in range(10):
	type = summonTypes[ i % summonTypes.length ]
	hero.summon(type)
```
The code above will cause the hero to summon ten different troops based on the types listed in the `summonTypes` array. Specifically, the troops will be summoned in this order:

1. `0 % 4 = 0` so type = `"soldier"`
2. `1 % 4 = 1` so type = `"archer"`
3. `2 % 4 = 2` so type = `"peasant"`
4. `3 % 4 = 3` so type = `"paladin"`
5. `4 % 4 = 0` so type = `"soldier"`
6. `5 % 4 = 1` so type = `"archer"`
7. `6 % 4 = 2` so type = `"peasant"`
8. `7 % 4 = 3` so type = `"paladin"`
9. `8 % 4 = 0` so type = `"soldier"`
10. `9 % 4 = 1` so type = `"archer"`

Notice that by using the `%` operator, the troops are created in the order that they are listed in the `summonTypes` array.


#### Interact (5 mins)

This activity will utilize the modulo operator to help the students see and understand military time. You may wish to have an analog clock (one with hands) as a visual for this activity.

Begin by asking the students if they have heard of military time and what they know about it. Students may know that military time goes from 0000 hours (read 0-hundred hours) to 2359.

Explain that you want the students to help you write code that could convert time from military time to standard time. Begin by having them help you to create an array of the hours that are used in standard time. Because our days start with 12:00, you will want to put that as the first element, as so:

```
standardHours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
```

Give the students a brief description of the way military time works, if it was not already mentioned by one of the students. Be sure to give examples of some of the conversions, for example 1400 = 2:00 and 1900 = 7:00.

Note that the code you write with the students will convert only hours from military time to standard time. Thus, for the military time hour 23, it will output the standard time hour 11.

Have the students help you write code that will convert a single hour of military time into its corresponding hour in standard time:

```
standardHours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
hour = standardHours[militaryHour % standardHours.length]
```

Go through a few examples of conversion with the students while walking through the code to show how this works. Note that the remainder calculated gives the element of the corresponding standard hour in the array. For example, 12 % 12 = 0, so that gives the 0th element in the array, which is 12.

Be sure to point to the corresponding element in the array with each conversion. It may be helpful to write the numbers and equations with each one.

Have the students then help you adapt the code so that it loops through every hour of military time and converts it to its corresponding standard hour. This should be done with a `for` loop, as shown below:

```
standardHours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
for (i in range(24)):
	hour = standardHours[militaryHour % standardHours.length]
```

Tell the students now to imagine that a group of aliens lands on earth. These aliens use a way of telling time that is similar to military time, but instead of counting up to the hours in a day, they count up to the hours in a week.

Have the students help you adapt the code to handle this. This requires simply changing the range of the `for` loop shown above to loop through up to 24 * 7, or 168.

```
standardHours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
# note that you can put either 24 * 7 or 168 in these parentheses
for (i in range(24 * 7)):
	hour = standardHours[alienHour % standardHours.length]
```

Once again, go through a few examples with the students to show how this code works for the conversions.

Throughout this activity, it may also be helpful to use the clock (if you have it) as a way to show the circular nature in which the array is looped through by using `%`.

#### Reflect (2 mins)
**What does the `%` operator return?** (The remainder after dividing two numbers.)
**How does the `%` operator help wrap around an array?** (By calculating the remainder between a number and the array length so that you never try to access an index that is out of bounds.)

### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Remind students of the clock activity if they are having trouble figuring out the logic when using the `%` operator.


### Written Reflection (5 mins)

**How was looping back to the beginning of an array useful in these levels?**
>Looping back to the beginning of the array helped me to summon a large number of troops, even though the array I had was not that large.

**What other scenarios can you think of in which the `%` operator might be helpful?**
>The `%` operator could be helpful in determining how many coins I would have left after summoning a certain number or kind of troop. I could use this knowledge to figure out how to summon the most troops based on the coins I have.

##### Module 29
## Using Predefined Functions
### Summary

In this module, CodeCombat provides predefined functions that can be used to draw shapes and position items a certain distance from each other. These functions are already written and must be used in order to pass the levels.

In these levels, the students will learn about these methods and practice using them. Although the students may not understand exactly how the functions work, they will call the functions and use the return values to position soldiers and draw shapes.


### Transfer Goals
- Call a predefined function and use its return value appropriately
- Use different elements of an array to position an item as desired

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Function Pictionary (15 mins)

#### Explain (3 mins)

**Predefined functions** are functions that are already written for programmers to use. The students have use predefined functions in many prior CodeCombat modules. Even in very early modules, the students learned how to do this by calling methods such as `hero.findEnemies()`. Although the students do not know the inner workings of the `findEnemies()` function, they know how to call it and how to handle the return value.

In this module, the students will practice using additional predefined functions. Many of the predefined functions in these levels are written out in the starter code for the students to see. Some of the code utilizes trigonometry and the students may not understand what it means or exactly how it works. Note that this is expected. The focus is not to get the students to understand trigonometry, but instead to practice calling functions and handling their output.

For example, consider the following function:

```
# here is a function for drawing a circle
# x, y - center of the circle
# size - length of the circle's radius
def drawCircle(x, y, size):
    angle = 0
    hero.toggleFlowers(False)
    while angle <= Math.PI * 2:
        newX = x + (size * Math.cos(angle))
        newY = y + (size * Math.sin(angle))
        hero.moveXY(newX, newY)
        hero.toggleFlowers(True)
        angle += 0.2
```

In order to use this function and predict its output, the students do not need to know what each line means or how it works. Instead, they need to simply read the comments to see what the function does. Additionally, they look at the **function signature**, the name of the function, the parameters it accepts, and what it returns.

Notice that the function's comments and name both indicate that it can be used to draw a circle. Thus, the students can infer that calling the function will result in a circle being drawn.

In the function signature, one can also see that the function requires three arguments, `x`, `y`, and `size`. The function's comments mention that `x` and `y` refer to the center point of the circle. The variable `size` refers to the circle's **radius**, which is the length of the line from the circle's center point to its edge. Notice that the radius is equivalent from a circle's center point to any of its edges.

Based on just the comments and function signature, the students can call the function and predict its output correctly. For example, to draw a circle with a radius of 5 at the point (50, 70), simply write the following line of code:

`drawCircle(50, 70, 5)`

Because the comments indicated the meaning of each variable, it is clear that the x value of the point should be substituted for `x`, the y value should be substituted for `y`, and the desired radius should be substituted for `size`.

#### Interact (10 mins)

For this activity, you will want basic graph paper, with just the grid lines, for the students to use. You should have at least one sheet for each student.

Begin by dividing the students into pairs and giving each pair two sheets of graph paper. Tell them to work together to create a simple design using only circles and squares. They may use one sheet of paper to sketch out their design. Give them about two minutes to work on their design.

As the students work on their designs, put the following code on the board:

```
# Here are some functions for drawing shapes:
# x, y - center of the shape
# size - size of the shape (radius, side length)
def drawCircle(x, y, size):
    angle = 0
    while angle <= Math.PI * 2:
        newX = x + (size * Math.cos(angle))
        newY = y + (size * Math.sin(angle))
        hero.moveXY(newX, newY)
        angle += 0.2

def drawSquare(x, y, size):
    cornerOffset = size / 2
    hero.moveXY(x - cornerOffset, y - cornerOffset)
    hero.moveXY(x + cornerOffset, y - cornerOffset)
    hero.moveXY(x + cornerOffset, y + cornerOffset)
    hero.moveXY(x - cornerOffset, y + cornerOffset)
    hero.moveXY(x - cornerOffset, y - cornerOffset)
```

Instruct the students to examine the code on the board and talk with their partners to discuss how it works. Then have them work together to determine a sequence of function calls, using the predefined methods on the board, that will output their design. Each grid line on their paper is one unit. Note that they should write down the code sequence.

After allowing them a few minutes to generate their code, have each pair swap their code with another pair. Each pair should use their second sheet of graph paper to go through the code they received and draw the output of it.

Once each pair is finished drawing the code from another pair, have them give their drawn output to the pair who wrote the code. Ask the students if the output is what they expected. Be sure to handle any discrepancies by consulting the predefined functions.

If necessary, point out that the `x` and `y` parameters refer to the center for each shape. Note as well that the `size` variable refers to the whole side length for a square and the radius for a circle. Go through one example of each shape, pointing out its `x`, `y`, and `size` variables if the students need some extra guidance.


#### Reflect (2 mins)
**How can you tell what a predefined function does, even if you don't understand how every line in it works?** (By looking at the function's name and comments, you can decipher what it does.)

**How does looking at the function signature (its name and arguments) help when calling a predefined function?**  (Looking at a function signature helps when calling a function because you can see what arguments it requires and ensure that you pass in all of those arguments and don't cause an error.)


### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips.

If students are having trouble, remind them to read all of the comments carefully. Have them take notes on each function and use their own words to paraphrase what it does, what arguments it requires, and what it returns. They should then consult their notes when they need to call a function.

### Written Reflection (5 mins)

**Why are comments important for programming?**
>Comments are important for programming because they allow others to see how to use functions even if they don't understand exactly how they work.

**Imagine yourself a few years from now writing code that younger students and programmers will use. What will you do to make sure that they can use your code?**
>In order to make sure that younger students and programmers can use my code, I will write good comments for each of my functions saying what it does, what arguments it requires, and what each of those arguments means. I will also add a comment if it returns anything. Additionally, I will give my functions and variables all friendly names that reflect what they do and mean.

##### Module 30
## String Searching
### Summary

The students have used both strings and arrays extensively in CodeCombat thus far. In this module, the students will learn that strings are virtually arrays of **characters**, or single letters. With that knowledge, students will loop through strings one letter at a time to find a certain element (character) or index.

These levels teach the students how to index and search through strings in order to detect spies, open treasure chests, and escape black magic.

### Transfer Goals
- Traverse through a string one character at a time
- Find a certain character in a string
- Find the index of a character in a string
- Find a string within a larger string


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Hangman (10 mins)
#### Explain (2 mins)

The students should be very familiar with strings at this point. They have used strings many times throughout the game, particularly when checking against friend names and enemy types:

```
if enemy.type != "sand-yak":
	do something
```

Note that in Python, everything that appears between quotations is considered a string. This includes both single quotations, such as `'sand-yak'` and double quotations, such as `"sand-yak"`.

The students have also had extensive experience with arrays thus far. They have written code to iterate through an array, as shown below:

```
# code to iterate through each friend in the friends array
friends = hero.findFriends()
for i in range(len(friends)):
	friend = friends[i]
```

The students will see in these levels that strings are, in fact, just like arrays. They are similar to arrays because they are made up of a set of elements, in which each element is a single character.

Because strings are like arrays, they have a length and can be iterated through just as arrays can:

```
# code to loop through each character in the string 'apple'
word = 'apple'
for i in range(len(word)):
	character = word[i]

```
Iteratering through a string allows the programmer to examine each character separately. Then the programmer can determine if a string contains a certain character by adding a simple conditional, as so:

```
for i in range(len(word)):
	character = word[i]
	if character == 'q':
		# do something
```
The students will utilize code such as shown above to return boolean values and indexes if a string contains a certain character.

#### Interact (6 mins)

In this activity, you will work with the students to write the code for the commonly played game, Hangman. After writing the code, you should play through at least one round of the game while pointing to the corresponding code to visually show the students the flow of control.

Begin by describing the activity to the students and writing the following starter code on the board:

```
# this function returns True if the letter is in the word and False if it is not:
def checkForLetter(letter, word)

while True:
	word = teacher.pickWord()
	letter = student.guessLetter()
	inWord = checkForLetter(letter, word)
	if inWord:
		# this function will fill in the letters if they are in the word
		fillInLetters()
	else:
		# this function will draw the next part of the hangman
		drawHangman()
```

Then have the students help you fill in the code for the `checkForLetter()` function. The code should look like this:


```
# this function returns True if the letter is in the word and False if it is not:
def checkForLetter(letter, word):
	for i in range(len(word)):
		character = word[i]
		if character == letter:
			return True
	# the letter isn't in the word, so return False
	return False

while True:
	word = teacher.pickWord()
	letter = student.guessLetter()
	inWord = checkForLetter(letter, word)
	if inWord:
		# this function will fill in the letters if they are in the word
		fillInLetters()
	else:
		# this function will draw the next part of the hangman
		drawHangman()
```

Before playing a round, be sure that the students understand the code written above, particularly for the `checkForLetter()` function. Note that the `word` string is looped through one character at a time and each character is compared to the one that was guessed by the student. If a match is found, then the loop breaks and the function returns `True`. The function returns `False` if the whole string is looped through and the letter is not found.

The code in the `while` loop simply calls the functions and executes the proper actions depending on if the letter is in the word or not. If the students begin to ask questions about the logic of the other functions that are called or the fact that there is no logic to handle winning or losing, then tell them to glaze over that for now and encourage them to think about how they would execute that if they have extra time at the end of class.

Once you are confident that the students understand the code, you should set up for a round of Hangman by picking a word (or phrase), drawing the lines to represent each letter in the word, and drawing the stand on which to draw the hangman.

Allow the students to guess letters one at a time and point to the corresponding line of code with each action throughout the round. It may be helpful to point to the lines you drew for each letter of the word as you illustrate the flow of control for the `for` loop. You may also choose to have a student come up to help you illustrate part of the flow.


#### Reflect (2 mins)
**What is similar between arrays and strings?** (Both arrays and strings have a length and can be referenced by indexes.)
**What data type are each of the elements in a string?** (Each element in a string is a single character, or letter.)

### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. If students are having trouble, remind them of the way in which the code was set up for the Hangman activity.

Students may have trouble in the Highlanders level, in which they need to search for a string within a string. Encourage them to carefully read the comments, to think about each string in terms of single characters, and to write out the solution in pseudocode first.

### Written Reflection (5 mins)

**What are the different ways you used string searching in these levels?**
>I used string searching to first look for a specific letter in a string and return True or False based on whether or not the letter is in the string. Then I used string searching to find the index of a letter in a string. Last, I used it to find a whole string within another string.

**What was the process you used to search for a string within a word?**
>I looped through the word, comparing each letter to the first letter of the string I was looking for. If I found the first letter, then I compared each letter from the rest of the string I was searching for to each of the letters following the one I found in the word. If they all matched, then the string was in the word.


##### Module 31
## For Loops with Non-1 Steps
### Summary

The students have used `for` loops numerous times to iterate through arrays. They have also used `for` loops to execute an action a certain number of times by iterating through a list of numbers. In each of those implementations, the iteration happens one item at a time.

In this module, the students will learn how to use `for` loops to iterate through a list by more than one at a time (i.e. two at a time, three at a time, etc.). They will use this new skill to place barriers at evenly-placed positions in order to protect themselves and the villagers.

### Transfer Goals
- Use a `for` loop to increment by more than one item at a time
- Place items a certain distance apart with the use of `for` loops


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Team Up (10 mins)
#### Explain (3 mins)

Until now, the students have used `for` loops to iterate through lists and arrays one item at a time. The students have also used `for` loops in conjunction with `range()` to execute an action a certain number of times, as so:

```
for i in range(4):
	# do something
```

Remember that the code above will execute the action 4 times, once each when `i` is 0, 1, 2, and 3.

`for` loops can also be used with `range()` to increment by more than one value at a time. The general syntax for this is as follows:

```
for i in range(start, stop, step)
```

`start` refers to the starting value for iteration, `stop` refers to the ending value, and `step` refers to the amount to increment by each time. Note that the `start` value is included in the iteration, but the `stop` value is not.

For example, consider the following code segment:

```
for i in range(0, 50, 10):
	hero.say(i)
```
The code above will cause the hero to say the numbers 0, 10, 20, 30, and 40. The hero starts with 0 because that is the starting value. 50 is not spoken because the stop value is not included in the iteration. 10 indicates the number to increase `i` by with each iteration.

Note that by using `for` and `range()` in this way, the iterations do not have to start with 0. For example,

```
for i in range(5, 50, 10):
	hero.say(i)
```

would cause the hero to say the numbers 5, 15, 25, 35, and 45.

#### Interact (7 mins)

Begin by issuing a "think-pair-share" challenge to the students. The students should first think individually about a solution, then turn to a neighbor to discuss their ideas, then finally share with the class if they choose to.

Next, tell the students that you want to split the class up into two teams. You believe you could write a single `for` to help you accomplish this. Can the students figure out what that loop would look like?

Allow the students about one minute for the "think" and "pair" portions of the exercise, then solicit answers from the class. Have students come up to write their solution on the board then discuss the solution as a class. The correct solution should incorporate a `for` loop with non-1 steps and look something like this:

```
# loop through the students two at a time putting every other student in team 1
for i in range(0, students.length, 2):
	student = students[i]
	student.team = "team 1"

# all other students are in team 2
```
Note that the important concepts from the code above are the usage and syntax of the `for` loop and the concept of using a single loop to split the class into two separate teams.

You may find that students offer different solutions that achieve the same outcome but do not use `for` loops that increment by more than 1. Praise them for their efforts and push them to think of a solution that uses the concept taught earlier.

After reviewing the correct code, use it to loop through the students two at a time and separate the class into two teams. Be sure to point to the corresponding code segment as you iterate through the students. You may choose to have a student help you with this. You may also find it helpful to record the value of `i` on the board as you iterate through the students.

Once the class is split into two teams, challenge the students to separate each team into three smaller teams using `for` loops with non-1 steps. They should do this with another "think-pair-share" in which they share within their respective team. Give the students about two minutes to complete this "think-pair-share". Each team should come up with its own solution to the problem then share its solution with the rest of the class by writing it on the board.

Discuss the written solutions and be sure to address any discrepancies between the two. Note that the correct solution should use two `for` loops as shown below:

```
# assign every third student to team 1
for i in range(0, students.lenth, 3):
	student = students[i]
	student.team = "team 1"

# assign every third student to team 2, beginning with the first student who was not assigned to team 1
for i in range(1, students.length, 3):
	student = students[i]
	student.team = "team 2"

# all other students are in team 3
```

Note that two loops are required for this task, one to get the create the first team and another to create the second. The students who are left over then make up the third team. The second `for` loop starts from 1 rather than 0 to ensure that the students who are placed in team 2 are not the same ones who were placed in team 1.

Once again, the students may come up with other solutions to the problem that do not include `for` loops with non-1 steps. Be sure to give them positive feedback for their efforts but to also reiterate the concept you want them to focus on today.

#### Reflect (2 mins)
**Why is incrementing by more than one step at a time useful?** (Because you may want to perform an action repeatedly, not for every unit in an iteration but for every second, every third, etc.)
**How do you initialize a `for` loop to increment by more than one step at a time?** (You use the `range` function with parameters for the starting index, the ending index, and the amount by which to increment.)

### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips.

If students are having trouble, encourage them to read the comments carefully. Have them consult their notes or a classmate if they don't remember the correct order for the parameters. If necessary, remind them that the ending index is not included as an iteration.

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**Why is it helpful to be able to start iterating from a value other than 0?**
>Because you may want to repeat an action, but only after skipping the first few items in a list or set.

**What are other scenarios that you think using `for` loops in this way could be helpful?**
>I think that using `for` loops in this way could be helpful to perform an action for every few villagers or allies, such as ordering every other soldier to shoot at a target while the others defend the village.


##### Module 32
## Array Push
### Summary

In prior modules, the students learned how to initialize and iterate through arrays. Additionally, they have learned how to examine a single element and compare it to a certain condition.

In this module, students will learn how to filter the items in an array, then **push** elements into a new array. Pushing an item into an array increases the size of the array by one, then adds the item as the last element in the array.

Students will use their newly learned skill to filter coins and sort them into separate arrays based on their type.

### Transfer Goals
- Filter items in an array
- Push elements into an array


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Girls vs. Boys (10 mins)
#### Explain (2 mins)

The students have learned a variety of skills related to arrays in prior modules. At this point, they know how to initialize arrays, how to loop through them, and how to examine single elements, as so:

```
enemies = hero.findEnemies()
for i in range(len(enemies)):
	enemy = enemies[i]
```
In this module, the students will learn about a new built-in function for arrays called `push()`. The `push()` function accepts an element as an argument then adds that element to the end of the array it is called on. For example:

```
friends = []
friends.push('Aurum')
```

The code above first creates an empty array called `friends`. Then, when the `push()` function is called, the length of the array is increased by one (so the length is now 1). `'Aurum'` is then added at the end of the array, which in this example is the first element.

The push function can be called numerous times to continuously push elements to the end of the array:

```
friends.push('Argentum')
friends.push('Cuprum')
```
The two lines above each add an element to the end of the `friends` array then fill those elements with the respective friends' names. The `friends` array would now appear as so:

`friends = ['Aurum', 'Argentum', 'Cuprum')`

#### Interact (6 mins)

In this activity, the students will use the newly learned `push()` function to separate the class into girls and boys. You will get their help writing the code to do so, and the end goal is to have two separate lines of students, one of girls and the other of boys.

To begin, have the students line up facing the board and write the following starter code on the board:

```
students = class.findStudents()
girls = []
boys = []
for i in range(len(students)):
	student = students[i]
```
Ensure that the students all understand the code you have written on the board. Notice that there are three different arrays now; the `students` array, which includes all of the students in the class, and the `girls` and `boys` arrays, which are currently both empty. Note that the `for` loop simply loops through the `students` array one at a time.

Tell the students that you want to filter them into girls and boys and need their help filling in the rest of the code. The final code should look like this:

```
students = class.findStudents()
girls = []
boys = []
for i in range(len(students)):
	student = students[i]
	if student.gender == "girl":
		girls.push(student)
	else:
		boys.push(student)
```

Going through the students one at a time, have them filter themselves appropriately into two separate lines. Point to the corresponding line of code as the students are filtered so they can see the flow of control.

Be sure that the student always positions him or herself at the end of the line, to represent the last position of the array. It may be helpful to have each student say their index out loud as they move to the appropriate line. Remember that arrays begin with an index of 0, so the index should always be one less than the number of students in the line.

It may also be helpful to record the contents of the arrays separately as students are added to them. If you choose to do this, then have the students each write their own name in the array as they are filtered. You should then have an area of the board with the contents of the arrays as so:

```
girls = ["Leah", "Maria", "Rosa"]
boys = ["Shawn", "Julio"]
```

If you are concerned about issues such as gender imbalance or gender identity, then you can choose to have the students filter themselves on another trait as you see fit. For example, you can have shorter students vs. taller students, birthdays before July vs. birthdays after July, names in first half of the alphabet vs. second half, etc.

#### Reflect (2 mins)
**Write the code to add one of your friends to a `friends` array?** (`friends.push('Sarah')`)
**What position in the array is an element pushed into when you use the `push()` function?** (It is pushed into the last element in the array.)

### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Point the students to the starter code and comments to see how they should filter the coins and which arrays they should be pushed into.

### Written Reflection (5 mins)
Select appropriate prompt(s) for the students respond to, referring to their notes.

**What is the benefit of having a `push()` function?**
>The push() function allows the array to change size dynamically so that items can be added as necessary based on a certain condition.

**What are other scenarios that you think `push()` could be helpful for in CodeCombat?**
>I think that `push()` could be helpful for filtering enemies into arrays based on their types then looping through the arrays to attack enemies in different ways.


##### Module 33
## Same Array Searching
### Summary

The students have learned how to search through an array for a particular element. They have also learned how to examine single elements based on a certain condition. Furthermore, the students have learned how to use nested `for` loops to iterate through two arrays at the same time.

In this module, students will combine those skills to learn how to search for duplicates within the same array. By looping through the same array twice and comparing elements to each other, the students will write code to search for matching gems and paladins. They will also utilize similar logic to find the minimum distance between a set of items.

### Transfer Goals
- Use nested `for` loops to iterate through the same array twice
- Compare elements within the same array
- Find duplicate items in a single array


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: The Birthday Paradox (10 mins)
#### Explain (2 mins)

Finding duplicates from a set is a common task in problem solving. As the students have seen in prior modules, a set of items is often stored as an array.

To find duplicates in an array, each item must be compared to every other item in the array. This requires looping through the array to examine each element, then looping through the rest of the array to compare each every other element to the one being examined in the outer loop.

The syntax to do this is written as so:

```
for i in range(len(array)):
	elemI = array[i]
	for j in range(len(array)):
		if i == j:
			continue
		elemJ = array[j]
		if elemI == elemJ:
			# do something
```

Notice that both the outer and inner loop go through each element in the array one at a time. Thus, it is necessary to check that `i` and `j` are not equal to ensure that the values being found are actual duplicates and not the same element.

#### Interact (6 mins)

Begin by introducing the premise of the birthday paradox to the students. Tell them that because there are 366 possibilities for birthdays, if there were 367 people in a room, there would be a 100% probability of finding two people with the same birthday.

Because there are certainly many less than 367 people in the class, it would seem that the chances of two students having the same birthday would be much less than 100%. In fact, due to the laws of probability theory, there is a 99.9% chance two people share a birthday in a room of just 70 people, and a 50% chance when there are only 23 people in a room together!

Have the students help you write the code to loop through the students and compare birthdays of each of the students. The code should return True if you find two students with the same birthday and False if not. The code you write should look like this:

```
students = class.findStudents()
for i in range(len(students)):
	studentI = students[i]
	for j in range(len(students)):
		if i == j:
			continue
		studentJ = students[j]
		if studentI.birthday == studentJ.birthday:
			return True
# return False if you loop through all students and don't find two with the same birthday
return False
```

Have the students line up facing the board and have them help you go through the code. Start by having the first student say his or her birthday out loud. Then go down the line of students and have them each say their birthday out loud. Compare each birthday to the first student's.

Be sure to point to the corresponding line of code, or have a student help you do so as you go through the activity. This will help the students visually see the flow of control. You may also find it helpful to record the values of `i` and `j` on the board as you go through the activity.

When you reach the line `if i == j`, if you are comparing two equal numbers, then be sure to continue, by simply moving to the next student. Do not allow a student to say his or her birthday twice to compare it to itself.

After finishing with the first student, move to the second student and repeat the process. Be sure to compare that student's birthday to each other student's including the prior ones.

If you happen to find a match quickly, then run through the activity again with a different criteria other than birthdays. For example, you could use height, last letter of last name, etc.

#### Reflect (2 mins)
**Why do you need to use two `for` loops to find duplicates in a single array?** (Because the first time you loop through the array, it is to examine each element, and the second time is to compare all the other elements to that one.)

**Why did we need to add a condition to check if `i == j`?** (We check to see if `i == j` because we want to ensure that we are finding a true duplicate, and not the same element compared to itself.)

### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Point the students to the starter code and comments to see how they should filter the coins and which arrays they should be pushed into.

### Written Reflection (5 mins)

**What did you use same array searching for in these levels?**
>I used it to find matching coins and twins. I also used it to find the two elements in an array that had a minimum distance from each other.

**Knowing that you can use same array searching to find more than just duplicates, what else do you think it would be useful for in CodeCombat?**
>I think that same array searching could be useful to find the minimum or maximum distance between two people or objects. I also think that it could be used to find comparisons for any other property that has a numerical value, like cost.

##### Module 34
## Nested Fors as Grid
### Summary

In this module, the students will use their skills of nested `for` loops to build a grid. They will do this by having one `for` loop that iterates through the x-coordinates and another `for` loop that iterates through the y-coordinates.

The students will then set the nested `for` loops to increment by more than one to place mines and wake soldiers in a grid-like fashion in order to defend the village.


### Transfer Goals
- Use nested `for` loops to create a virtual grid
- Traverse through nested `for` loops to place items or perform actions in a grid-like manner

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Treasure Hunter (10 mins)
#### Explain (3 mins)

The students have used nested `for` loops in prior modules to loop through the elements of an array and execute an action on each item a certain number of times.

In this module, the students will use nested `for` loops to create a virtual grid. This will allow them to place items and perform actions in a grid-like fashion (i.e. in rows and columns).

When using nested `for` loops as a grid, one loop initializes the rows and the other loop initializes the columns. For example, consider the following code segment:

```
for x in range(10, 100, 10):
	for y in range(10, 100, 10):
		hero.moveXY(x, y)
```
Step through the code above while keeping in mind the flow of control. Notice that the first line of code iterates through x-coordinates from 10 to 100 with a step of 10. The next line of code, which is the inner loop, iterates y-coordinates from 10 through 100 with a step of 10 **for each x-coordinate**.

The effect of the code above could be visualized as so:

```
# the hero moves to each tile in a 100 x 100 square

# (10, 10)	(20, 10)  (30, 10) ... (90, 10)
#    |	   /	|	 /	  |    /	   |
#    V	  /		V	/	  V	  /		   V
# (10, 90)	(20, 90)  (30, 90) ... (90, 90)
```

Notice that the hero moves to the first x-coordinate, then moves down to the appropriate y-coordinates for that x-coordinate. The hero then moves to the next x-coordinate at the original y-coordinate and moves down the column of appropriate y-coordinates again.

Note that the hero could traverse one row at a time (rather than one column at a time) by switching the order of the loops so that the y-coordinate `for` loop comes first.


#### Interact (5 mins)

Begin by telling the students that you met a pirate last night who told you about a legend of buried treasure nearby. He didn't know exactly where the treasure is buried, but he mentioned that it is supposedly buried in a field nearby.

Of course, you want to find the buried treasure, but searching the entire field on your own would take quite some time. You chose to build a simple robot that could move through the field digging for you. You want the students to help you program the robot so that it moves through the field digging holes until it finds the treasure.

You searched through local maps and discovered that the field is 100 feet wide and 200 feet long. The robot you built is able to dig a hole 10 feet in diameter. Ask the students to help you write the code that will get your robot to dig through the field until it finds the treasure.

Guide the students to see that you want to create a virtual grid on the field, so you will want to use nested `for` loops. Because the robot can dig a hole 10 feet in diameter, it should move by 10 feet each time. Also remind the students, if necessary, that the field is 100 feet wide and 200 feet long.

Thus, the nested `for` loops will look like this:

```
for x in range(0, 100, 10):
	for y in range (0, 200, 10):
```

Once you have the nested `for` loops setup with the correct syntax, you will want to add code that gets the robot to move to the desired location and dig there, as so:

```
for x in range(0, 100, 10):
	for y in range (0, 200, 10):
		robot.move(x, y)
		robot.dig(x, y)
```

The students may also wish to add code that gets the robot to stop searching once it has found the treasure. One way this can be done is by putting the code in a function that returns the string "found" if the treasure is found and "not found" if it isn't, as so:

```
for x in range(0, 100, 10):
	for y in range (0, 200, 10):
		robot.move(x, y)
		robot.dig(x, y)
		if robot.finds(treasure):
			return "found"

# if the robot searches through the entire field without finding the treasure, then it is not there
return "not found"
```

Now tell the students that you just remembered another piece of information from the pirate. He told you that the treasure is supposed to be buried in the northern, or top, half of the field. Thus, you want to reprogram the robot so that it searches through that half of the field.

Have the students help you rewrite the prior code to go through the top half of the field. Note that there are different ways to do this, and you should encourage the students to try and think of them.

One way is to simply change the range of y-values to only loop through to 100. Another way is to change the order of the `for` loops so that the robot searches row by row instead of column by column, as so:

```
for y in range(0, 200, 10):
	for x in range (0, 100, 10):
		robot.move(x, y)
		robot.dig(x, y)
		if robot.finds(treasure):
			return "found"

# if the robot searches through the entire field without finding the treasure, then it is not there
return "not found"
```
By searching one row at a time, the robot will inherently search the first half of the field first. If the treasure is not found in that half, it will still search the other half just in case the pirate made a mistake.

#### Reflect (2 mins)
**How are nested for loops used to create a virtual grid?** (Nested `for` loops are used to create a virtual grid by first setting up a loop to go through each x-coordinate then looping through each y-coordinate for that x. The flow examines an x-coordinate, goes through the y-coordinates for that x, then moves to the next x-coordinate and does the same thing.)

**How should `for` loops be initialized to traverse a grid one row at a time?**  (To traverse a grid one row at a time, you would set up the outer `for` loop to examine each y-coordinate one at a time. The inner `for` loop would then go through each x-coordinate for that y. The next iteration of the outer `for` loop would move the flow to the next y-coordinate then go through each x-coordinate for that y.)


### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Remind students of the code generated during the activity if they get stuck.

### Written Reflection (5 mins)

**What changes if you switch the order of the nested `for` loops?**
>If you switch the order of the nested `for` loops then the hero will move row by row instead of column by column.

**How does the use of nested `for` loops in these levels differ from prior usage?**
>In earlier lessons, we used nested `for` loops to do something a certain amount of times for each item or to loop through an array twice. In this lesson, we used them to have the hero move in a grid-like way by going column by column or row by row.


##### Module 35
## Nested Arrays as Grid
### Summary

Arrays can hold any data type or object. In prior modules, the students have seen arrays of integers, strings, enemies, and much more. In this module, they will learn that an array can even hold arrays.

These **nested** or **2D** arrays can be used to represent virtual grids, similar to those used in the prior module. In these levels, the students will use nested arrays to place traps and fences in a grid-like manner.

### Transfer Goals
- Use nested arrays to create a virtual grid
- Traverse through 2D arrays with the use of nested `for` loops
- Access a row, column, or element of a nested array


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Jumping Grid (10 mins)
#### Explain (3 mins)

In these levels, the students will see that arrays can hold other arrays! Arrays in which each element is another array are called **nested** or **2D arrays**.

Nested arrays are represented as grids and can be visualized as so:

```
arrayGrid = [
	[0, 1, 0, 0],
	[2, 0, 0, 3],
	[0, 0, 4, 0],
	[0, 0, 1, 5] ]
```
Notice that the visualization shows each array as a separate row. Thus, each array represents a row in the grid. The columns of the grid are composed of the elements in each array in the same position. The first column is each element with an index of 0 from each array, the second column is each element with an index of 1, and so on.

As with the prior module, nested `for` loops are used to iterate through the grid. The first, or outer, `for` loop iterates through the outer array. The syntax for this loop should be familiar to the students:

```
for i in range(len(arrayGrid)):
```

Note that this loop iterates through each item of `arrayGrid` one at a time. Remember that each item is also an array and that these inner arrays are representative of the grid's rows. Thus, `arrayGrid[i]` refers to a different array, or row, with each iteration of the loop.

Next, a second `for` loop is nested within the first one. This allows for the iteration of each inner array, or row. Note that because each row is an array, the `len()` method must be used to iterate through each element. The nested `for` loops will be written as so:

```
for i in range(len(arrayGrid)):
	for j in range(len(arrayGrid[i])):
```

Remember that each element in `arrayGrid` is an array. Thus, `arrayGrid[i]` is an array. Because it is an array, it is iterated through as any other array, with a `for` loop going through the range of its length.

After the nested `for` loops are initialized, a single element can be accessed by calling each of its elements, as so:

```
for i in range(len(arrayGrid)):
	for j in range(len(arrayGrid[i])):
		value = arrayGrid[i][j]
```
The variable `value` can then be used as any other variable.

#### Interact (5 mins)

For this activity, you will need to have the students arranged in a grid like fashion with rows and columns. If your classroom is not already set up this way, then you can choose to have the students rearrange their desks so that they are in a grid, or simply stand and arrange themselves in one.

You should aim to have at least 4 students per row and at least 3 rows of students. If you are unable to have an equal amount of students per row, then try to have the same number for each row except the last one.

You may choose to modify the activity if you would like to by having the students perform an action other than jumping, such as speaking, singing, sitting, standing, etc.

Begin by having the students face the board in their rows. Write the following code on the board:

```
for i in range(len(studentGrid)):
	for j in range(len(studentGrid[i])):
		student = studentGrid[i][j]
		student.jump()
```

Go through the grid of students getting each one to jump by following the code written on the board. Be sure to go through slowly with the first few students. Point to each corresponding segment of code with each iteration. You can also have a student help with with this as the other students jump. You may also find it helpful to track the values of `i` and `j` on the board as you go along.

Note that the code goes through each row of students one at a time. Once a row has been iterated through, the flow of control goes to the first student (with index 0) in the next row. While pointing to the corresponding code, be sure to point to the outer loop only when moving to a new row. The inner loop is the one that controls moving from student to student in each row.

If you think the students need additional practice after going through the grid, you can erase the code from the board then have them help you to write new code that will go through the grid again performing a different action, such as laughing, singing, or smiling.


#### Reflect (2 mins)
**How does a 2D array act as a grid?** (A 2D array acts as a grid because each element in the array is an array. Each of those arrays is like a row in the grid, while each of the elements in the inner array is like a column.)

**Describe the process used to loop through a 2D array.**  (To loop through a 2D array, you set up two nested `for` loops. The first, or outer loop, goes through the outer array, accessing each inner array, or row, one at a time. The inner loop goes through each row accessing each element one at a time.)


### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Point the students to the starter code and comments if they get stuck.

You may need to remind the students that each element in a 2D array is an array representing the row, and each element in the row represents one item in that column. Encourage the students to draw out a grid in their notes and step through the grid row by row to understand how they would access each value.

### Written Reflection (5 mins)

**How do 2D arrays differ from nested `for` loops as grids?**
>2D arrays differ from nested `for` loops because each row is an array and the rows are stored in another array. With the nested `for` loops used in the last module, the items were not stored in arrays.

**How did you use 2D arrays in this module? How was having a 2D array helpful to do this?**
>I used 2D arrays to set up fences and traps in a grid. Having a 2D array was helpful because the spots were already set up for the placement of the objects, I just had to loop through each spot and place the item there.


##### Module 36
## 2D Array Access
### Summary

In the last module, the students learned how to use and traverse through 2D arrays as grids. They iterated through the array with nested `for` loops to access each element in the grid one at a time. While it is often helpful to iterate through each element of a nested array, there are times in which only a single element must be accessed.

In this module, the students will learn how to access specific elements of a 2D array grid. By accessing specific cells, the students will be able to set traps and shoot ammo at specific targets.

### Transfer Goals
- Access a specific element of a 2D array
- Use zero based indexing for nested arrays


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Tic-Tac-Toe (10 mins)
#### Explain (3 mins)

In the past few levels, the students used nested `for` loops to iterate through nested arrays and access each element one at a time. In these levels, the students will learn how to access specific elements of a nested array, rather than all of them.

The students should be familiar with the syntax to access a specific element of a single array. This can be done by using the array name with the index of the element to be accessed. The students should remember that array indexes always begin at 0.

For example, to access the 2nd element of an array called `array`, the following line of code could be used:

```
# code to access the 2nd element of an array.
element = array[1]
```
Remember that 2D arrays can be visualized as grids, like shown below:

```
grid = [
	[0, 1, 2],
	[3, 4, 5] ]
```
Notice that `grid` has 2 inner arrays, or rows, and 3 columns. To access a specific element of the array, use the name of the array with two indexes - the index of its array, or row, in `grid` and the index of the element within its inner array.

For example, to get the element `1` above, use the following code:

```
one = grid[0][1]
```
Note that because `1` is in the first row, the index of its array within `grid` is 0. Because `1` is in the second position of its array, its index within the array is 1. Thus, the index of `1` within `grid` is `[0][1]`.

The following code shows the syntax to get the value of other elements from `grid` shown above:

```
# get the first element
grid[0][0] #returns 0

# the last element
grid[1][2] #returns 5

# the first element of the second row
grid[1][0] #returns 3
```

Remember that the index of the element's row always comes before the index of its column.

#### Interact (5 mins)

Tell the students that they are going to play 2D array Tic-Tac-Toe. Begin by dividing the students into pairs. If there are an odd number of students, you can either have a group of 3 or work with one of the students yourself.

Each pair should start by drawing a grid with 3 rows and 3 columns for the playing space. Tell the students that the grid represents a 2D array. The array consists of 3 inner arrays, each represented as a row, and each array has 3 elements.

The students should play Tic-Tac-Toe against each other by writing code that will set a cell to 'X' or 'O' with each turn.

For example, the first turn could be:

```
ttt[1][1] = 'X'
```
Which would then set the middle cell to be 'X'. Players should check each other's syntax as they write the code. After the line is written correctly, the cell can be updated to have the correct value. The students should check that their partner puts the symbol in the correct spot based on their line of code.

Have the students play the game until you feel that they have a good grasp of the way in which to access elements in a 2D array.

If students are moving quickly, encourage them to write code that will check to see if either player has won. That code could look something like this:

```
# check each row
if ((ttt[0][0] == ttt[0][1]) && (ttt[0][1] == ttt[0][2])):
	win = True
elif ((ttt[1][0] == ttt[1][1]) && (ttt[1][1] == ttt[1][2])):
	win = True
elif ((ttt[2][0] == ttt[2][1]) && (ttt[2][1] == ttt[2][2])):
	win = True

# check each column
elif ((ttt[0][0] == ttt[1][0]) && (ttt[1][0] == ttt[2][0])):
	win = True
elif ((ttt[0][1] == ttt[1][1]) && (ttt[1][1] == ttt[2][1])):
	rwin = True
elif ((ttt[0][2] == ttt[1][2]) && (ttt[1][2] == ttt[2][2])):
	win = True

# check diagonals
elif ((ttt[0][0] == ttt[1][1]) && (ttt[1][1] == ttt[2][2])):
	win = True
elif ((ttt[0][2] == ttt[1][1]) && (ttt[1][1] == ttt[2][0])):
	win = True

else:
	win = False

```


#### Reflect (2 mins)
**How would you access the 3rd element of the second row in a 2D array called `grid`?** (`grid[1][2]`)

**When accessing an element in a 2D array, why does the row's index come before the column's index?**  (The row's index comes before the column's index because you first have to find which array, or row, the element is in then you find which position in that array the element is.)


### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Remind students, if necessary, that the row's index comes before the column's when accessing an element in a 2D array.

### Written Reflection (5 mins)

**What, if anything, do you find simple about using 2D arrays? What, if anything, do you find difficult about using them?**
>I find it simple to loop through them because you just need to use nested `for` loops. I find it difficult to access specific elements because you have to remember to put the row before the column and to start with 0 based indexing for both.

**In the past few levels, you have seen that arrays can hold other arrays to create 2D arrays. In fact, the inner arrays can also hold arrays creating 3D arrays. Can you think of a scenario in which 3D arrays would be useful?**
>If I were writing a program to solve a Rubik's cube then having a 3D array would be helpful. Each side has rows and columns, but they also have additional depth rows. Thus, having a 3D array would allow me to store the color at each square of the cube.

##### Module 37
## For Loop Array Access
### Summary

The students have used arrays many times in prior modules. They have learned to create, access, and loop through arrays in a number of different levels. In this module, the students will use their existing programming skills to interact with arrays in a new way. Specifically, they will write code to loop through multiple arrays simultaneously. By doing this, they will help a herder place and tend to his reindeer appropriately.

### Transfer Goals
- Loop through multiple arrays at once
- Associate the elements of one array with another

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Roll Call Robot (10 mins)
#### Explain (3 mins)
The students have used arrays many times in prior modules. They have learned how to use an element's index to access or set a specific element as they wish:

```
array = [null, "one", "two"]

# accesses the second element, at index 1, returning "one"
element = array[1]

# sets the first element, at element 0
array[0] = "zero"
```

The students have also learned how to loop through arrays with a `for` loop, as so:

```
for i in range(len(array)):
	# do something
```

In this module, the students will use their existing programming skills to loop through multiple arrays simultaneously. This is particularly helpful when trying to track some kind of information about the items in an array.

For example, suppose that the student's hero has five friends nearby and wants to keep track of each friend's role (i.e. "soldier" or "archer"). To do this, the student could create an array to hold each friend's role, as so:

`friendRoles = ["unknown", "unknown", "unknown", "unknown", "unknown"]`

To start off, the student could fill this array with strings such as "unknown", an empty string (`""`), or another phrase, as the roles are still not known.

To fill the array with the appropriate roles, the student could find the friends near the hero, get their roles, then store them in the `friendRoles` array:

```
# this array creates all of the friends
friends = hero.findFriends()

# loop through each friend and fill in the friendRoles array with their role
for i in range(len(friends)):
	friend = friends[i]
	friendRoles[i] = friend.type
```

Notice that each friend's role is stored at the same index in the `friendRoles` array as the friend is stored in the `friends` array. In other words, the role for the friend at `friends[0]` is stored at `friendRoles[0]`, the role for the friend at `friends[1]` is stored at `friendRoles[1]`, etc.

Once the array for `friendRoles` is filled in correctly, it can then be looped through as well. For example, the hero could say each friend's role out loud by using code like this:

```
for i in range(len(friendRoles)):
	hero.say("The friend at index " + i + " is a " + friendRoles[i])
```


#### Interact (5 mins)

Tell the students that you want their help programming a robot that will keep track of the students' attendance for the day. Solicit ideas from them on how you can accomplish this. Ensure that the students come to a solution that involves separate arrays, one holding each student and the other holding their attendance status.

After the students have offered up an appropriate solution, have them help you write code on the board to execute the program. Begin by declaring an array that stores all of the students, as so:

```
students = ["Anne", "Brian", "Carlos", "Fiona", ...]
```

Then create a second array that stores the students' attendance. Get suggestions from the students on what the default value of each student's attendance should be. Be sure that the array has the same number of elements as the `students` array you just created.

```
studentsAttendance = ["absent", "absent", "absent", "absent", ...]
```

Have the students then help you write the loop to go through each student and update his or her attendance. The code should look something like this:

```
for i in range(len(students)):
	student = students[i]
	attendance = student.attendance
	studentsAttendance[i] = attendance
```

After the code is written on the board, execute it with the class by looping through student by student and updating the `studentsAttendance` array with their attendance. It may be helpful to point at each line as it is executed.

Finally, tell the students that you want to add a few lines of code that will make the robot say each student's name and attendance out loud. Get the students to help you write the code, which should look like this:

```
for i in range(len(students)):
	robot.say(students[i] + " is " + studentsAttendance[i] + " today.")
```

Ask the students to help you predict the first three statements the robot will say. Ensure that they choose the students and attendances from indexes 0 through 2, as so:

```
"Anne is present today."
"Brian is absent today."
"Carlos is present today."
```

#### Reflect (2 mins)
**Why are arrays useful to keep track of data?** (Arrays are useful to keep track of data because the data is all stored together in one place and it can be looped through easily.)

**Why is it helpful to have the indexes of the `students` and `studentsAttendance` arrays line up?**  (It is helpful to have the indexes line up because then a student's attendance can be accessed by simply calling the `studentsAttendance` array with the student's index from the `students` array.)


### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. If students are stuck, remind them of the attendance program worked through in class. Also ensure that they are aware of which array they are looping through with each loop.

### Written Reflection (5 mins)

**Describe what you did in these levels and how the multiple arrays helped you accomplish this.**
>In these levels, I helped the blind herder keep track of his reindeer by telling him if they were awake or not. I also helped him place them in their pens. Having multiple arrays helped me with this because I could store the status in one array, align it with the reindeer who were stored in another array, then say it all out loud.

**What other scenarios do you think using multiple arrays like this could be helpful for?**
>I think that using multiple arrays like this to keep track of enemies' status or friends' roles could be helpful. It could also be helpful for tracking the position of villagers, enemies, or friends.

##### Module 38
## Geometry
### Summary

In this module, students will learn basic geometry concepts and practice implementing them via code. In particular, they will write code that computes the area and perimeter of a rectangle, and also command soldiers into a square.

### Transfer Goals
- Computationally compute the perimeter and area of a rectangle
- Computationally form the 4 points of a square


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Interior Design (10 mins)
#### Explain (3 mins)

In these levels, the students are expected to have an understanding of basic geometry concepts related to rectangles and squares. Below is a summarization of these concepts to give the students a refresher if necessary.

A **rectangle** is a shape that has four sides and four corners. Note that this is the shape of most rooms, doors, and windows. A **square** is a special kind of rectangle that has four sides of the same length.

The **perimeter** of an object is the total length of its edges. For rectangles, one can find the perimeter by simply adding the lengths of the four sides together.

The **area** of an object is the measurement of its size or space inside the edges. To find the area of a rectangle, one can multiply the length of one side by the length of the side next to (but not across from) it.

To compute the area and perimeter via code, simply perform the arithmetic with the appropriate operators.

For example, the following lines of code would compute the area and perimeter of a rectangle with the sides `side1` and `side2`:

```
area = side1 * side2
perimeter = side1 * 2 + side2 * 2
```

#### Interact (5 mins)

This activity assumes that the classroom is rectangular. If your classroom is not, you should choose a rectangular object, such as a door or closet, to decorate. You will also want to have a measuring device, such as a tape measure or yard stick for this activity.

Begin by telling the students that you want their help decorating the classroom. Say that you first want to get some trim to put on the wall around the floor. You need to know how much to get though and want the students to help you figure this out.

Ask the students how you should go about determining the amount of trim you need. The students should recognize that you want the same length as the length of all four walls combined. Push the students to realize this is the same as the perimeter of the room.

Get two volunteers to help you measure the sides of the room. As they get the measurement, ask the rest of the class how many measurements need to be made to get the perimeter. They should recognize that you only need two because each wall's opposite wall is the same length.

Record the lengths measured by the students on the board as side1 and side2. Then ask the class to help you write a function called `getPerimeter` that will help you calculuate the perimeter based on the measurements of the two sides.

Begin by writing the following starter code on the board:

```
def getPerimeter(side1, side2):

	return perimeter
```

Have the students help you write the missing line of code to compute the perimeter based on the values of `side1` and `side2`. The final code should look similar to this:

```
def getPerimeter(side1, side2):
	perimeter = side1 * 2 + side2 * 2
	return perimeter
```

Now tell the students that you are also interested in getting a rug that will cover the entire floor. You want to know what dimensions to look for while you are shopping.

First ask them if they have enough information to determine the size rug needed for the classroom. If necessary, help them recognize that the measurements of `side1` and `side2` are not just the measurements for the walls, but also for the floor.

Ask the students how those measurements can be used to determine the size rug needed for the classroom. They should recognize that the size of the rug is equivalent to the area of the room, and the area of the room can be found by multiplying the lengths of the walls.

Have the students help you write a function called `getArea` that computes the area based on the values of `side1` and `side2`.

Begin by writing the starter code for the `getArea` function on the board as so:

```
def getArea(side1, side2):

	return area
```

Get the students to help you fill in the missing line of code that computes the area. The final code should look like this:

```
def getArea(side1, side2):
	area = side1 * side2
	return area
```

#### Reflect (2 mins)
**How do you find the area of a rectangle if you have one variable for each of the sides?** (You can find the area by simply multiplying the sides, like `side1 * side2`.)

**How do you find the perimeter of a rectangle if you have one variable for each of the sides?**  (You can find the perimeter by multiplying each side by 2 then adding the products together, like `side1 * 2 + side2 * 2`)


### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips.

Remind students of the code segments generated during the activity to find the area and perimeter of a rectangle.

For the level 'Square Shield', encourage the students to draw out a square on paper and think about the coordinates of each corner in relation to each other. Have them start by labeling one corner with the coordinates (x, y) then labeling the others with only x, y, a variable sideLength to represent the length of each side, and any necessary operators.

### Written Reflection (5 mins)

**How did you use prior known coordinates to create a square?**
>I used the prior known coordinates to figure out where to put the other two soliders to make a square. Because squares have four equal sides, I knew that the two soldiers I placed had to be equal distance from each corner but would share one x or y value. By using the position of the other soldiers and the variable `sideLength`, I was able to place the soldiers in a square.

**Why was it necessary to use `almostEqual` instead of just `=` in Ritual of Rectangling?**
>It was necessary to use `almostEqual` because the soldiers were moving around, so it was possible that they would move to a position that wasn't exactly the right spot for the desired value of the area or perimeter.

##### Module 39
## Number Base Conversion
### Summary

The number system the students, and most people, are familiar with is called **base-10**. This is the number system used around the world for math, counting, financial transactions, etc. Computers, however, often work in other number systems, particularly **binary**, which students may have heard of before.

In this module, the students will learn about **binary**, or **base-2**, and **ternary**, or **base-3**, number systems. They will write code that uses the `/` and `%` operators to convert between number systems in order to command robots and defend against brawlers.

### Transfer Goals
- Understand the difference between base-10, base-2, and base-3 number systems
- Convert numbers from base-10 to base-2 or base-3
- Convert numbers from base-2 or base-3 to base-10


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: A Message from Aliens (20 mins)
#### Explain (10 mins)

The number system that is used on a daily basis is referred to as **base-10** or **decimal**. It is referred to as so because each digit can be represented by one of 10 numbers ranging from 0 through 9. A single digit number then has 10 possibilities from 0 to 9. A double digit number has 100 possibilities, from 00 to 99.

Additionally, this number system is referred to as base-10 because each digit of a number symbolizes a factor of ten. For example, consider the following numbers:

```
11			10 + 1				1 * 10 + 1 * 1
23			20 + 3				2 * 10 + 3 * 1
456			400 + 50 + 6		4 * 100 + 5 * 10 + 6 * 1

```

Notice in the numbers above that each digit is representative of a different power of 10 depending on its placement in the number. In the number 456, the first digit, 4, is in the 100's place; the 5 is in the 10's place, and the 6 is in the 1's place. The number in each spot is then multiplied by the appropriate power to get the final number. So in this example, 4 is multiplied by 100, 5 by 10, and 6 by 1 to get 456.

If the students are familiar with exponents, you can describe how these powers are shown exponentially. The 100's place is 10 to the 2nd power, the 10's place is 10 to the 1st power, and the 1's place is 10 to the 0th power. If the students have not learned exponents yet, then simply note that the right most digit is always at the 1's place, and each digit to the left goes up by multiplying by 10 each time.

**Base-2**, or **binary** numbers work similarly to base-10, except that instead of 10 number possibilities for each digit, there are only 2 - the numbers 0 and 1. Similarly, each digit goes up by a power of 2, compared to the power of 10 used in the base-10 number system.

Consider the following base-2 numbers:

```
10			2 + 0				1 * 2 + 0 * 1
111			4 + 2 + 1			1 * 4 + 1 * 2 + 1 * 1
1011		8 + 2 + 1			1 * 8 + 0 * 4 + 1 * 2 + 1 * 1

```

Notice in the numbers above that each digit is representative of a different power of 2. In the number 1011, for example, the first 1 is at the 8's place, the 0 is at the 4's place, and the next two ones are at the 2's and 1's place.

Once again, if your students are familiar with exponents, you can explain the digits in terms of 2 to different powers. The right most digit is 2 to the 0th power, the digit to the left of that is 2 to the first power, to the left of that is 2 to the second power, and so on.

If your students are not familiar with exponents, then point out that each digit is representative of the digit to its right multiplied by 2. The rightmost digit represents 1, the next one to the left represents 2, the next one 4, and so on.

Note that to convert base-2 numbers to base-10, one can simply multiply the number by the appropriate factor for that digit then add them all together. For example to convert the number 1011, start by multiplying each digit by its corresponding power of 2, namely 1 * 8, 0 * 4, 1 * 2, and 1 * 1. The products found - 8, 0, 2, and 1 - can then be added to find the decimal number, 11.

To convert a number from base-10 to base-2, one must repeatedly divide by 2 and note the remainder each time. Because the remainder can only be 0 or 1, that provides the numbers to be used in the binary representation.

For example, note the steps used to convert the number 13 to binary:

```
13 / 2 = 6, with remainder = 1
6 / 2 = 3, with remainder = 0
3 / 2 = 1, with remainder = 1
1 / 2 = 0, with remainder = 1

# remainders from bottom to top give the binary representation
13 in binary is 1101
```

Note that after dividing the number by 2, the quotient  (answer found from dividing) is then divided by 2 until the quotient is 0. The remainders are then ordered from bottom to top to form the binary representation of the number.

**Base-3**, or **ternary** works similarly to base-2 and base-10, except that each digit can be represented by 3 numbers - 0, 1, or 2. Additionally, each digit of a number represents a different power of 3.

For example, consider the following base-3 numbers:

```
10			3 + 0				1 * 3 + 0 * 1
112			9 + 3 + 2			1 * 9 + 1 * 3 + 2 * 1
1021		27 + 0 + 6 + 1		1 * 27 + 0 * 9 + 2 * 3 + 1 * 1

```
Notice in the numbers above that each digit represents a different power of 3. For example, in the number 112, the first 1 is in the 9's place, the next one is in the 3's place, and the 2 is in the 1's place. As with base-2 and base-10 numbers, the rightmost digit is always representative of the 1's.

As mentioned above, if the students are familiar with exponents, you can also show each digit as it relates to powers of 3. The rightmost digit is 3 to the 0th power, the next digit to the left is 3 to the 1st power, to the left of that is 3 to the 2nd, and so on.

As with base-2 numbers, to convert base-3 numbers to base-10, one can multiply the number by the appropriate factor for that digit then add the products together. For example, to convert the number 1021, first multiply each digit by its corresponding power of 3 - 1 * 27, 0 * 9, 2 * 3, and 1 * 1. The products found - 27, 0, 6, and 1 - can then be added to find the decimal number, 34.

To convert base-10 numbers to base-3, follow the same steps used to convert to base-2, except divide the number by 3 rather than 2. For example, note the steps below to convert 13 from base-10 to base-3:

```
13 / 3 = 4, with remainder = 1
4 / 3 = 1, with remainder = 1
1 / 3 = 0, with remainder = 1

# remainders from bottom to top give the ternary representation
13 in ternary is 111
```

Below is a list of the numbers 0 through 10 in base-10, base-2, and base-3:

```
Base-10:			Base-2:			Base-3:
0					0					0
1					1					1
2					10					2
3					11					10
4					100					11
5					101					12
6					110					20
7					111					21
8					1000				22
9					1001				100
10					1010				101

```


#### Interact (8 mins)

Tell the students that you saw a UFO last night and received a message from the aliens in the UFO. The aliens speak English, and because of the aliens' advanced abilities, they were able to transmit the message straight to your mind. The message said, "Hello earthling, we come in peace. We would like to challenge you to a dance-off. Do you accept?"

Mention that the aliens also told you that they will be back in the sky tonight awaiting your reply. You do not have telepathic powers and cannot fly up to meet them. Your thought is that you will use a flashlight to send them your response in binary. When the light is on, it will represent 1 and when it is off it will represent 0. You will construct a message, record the value of each letter based on its position in the alphabet, convert that to binary, then use the flashlight to send the message to the aliens.

Start by having the students help you construct a message to respond to the aliens. For example, perhaps the message you choose to send back is:

` "Yes I do"`

Whatever the message is, be sure to record it on the board. You may wish to leave space between each letter as you will be recording the corresponding decimal and binary values below each letter.

Next, have the students help you record the decimal values of each letter based on their position in the alphabet. For the message above, the values would be 25, 5, 19, etc. Record each decimal value of the letter below the actual letter of the original message you wrote.

Ask the students how you can go about converting each number from decimal to binary. Be sure that they mention the following steps:

1. Divide the number by the desired base.
2. Take the remainder of the division and add it to the front of the converted number (shifting all other numbers over so the remainder is the first digit).
3. Repeat using the quotient (answer from division) from step 1, until the quotient is 0.

Go through these steps with the first conversion to show that the steps work. If using the text above, the first binary value should be 11001.

Tell the students that because the message is long and because you may want to make it longer, you would like to automate the conversion process using code. Get the students to help you write the code to automate the process.

Begin by pushing the students to see that since the task is being repeated, you will want to use a loop. Because the loop must run until a specific condition is met, a `while` loop should be used.

Next, the students should recognize to use the `%` and `/` operators to get the remainder and quotient. They should also recognize that they will need a string to hold the converted number so they can append the remainder to the front each time. Ask leading questions to guide them to these points if necessary

The final code should look like this:

```
base2 = ""
while number != 0:
	remainder = number % 2
	number = number / 2
	base2 = remainder + base2
```

Note that because of integer division, `number = number / 2` will return the correct value, even if it mathematically not an integer. Additionally, be sure the students see that by assigning the quotient to the variable `number`, they are able to use a simple `while` loop to perform the conversion.

After the code is written, go through a few more numbers converting them to decimal to binary. Be sure to trace the flow of control by pointing to each corresponding line of code with each number. You may also wish to have a student help you do this.

#### Reflect (2 mins)
**How does our number system (base-10) differ from base-2 and base-3?** (The base-10 number system differs from base-2 and base-3 because it is based on the number 10. This means that each digit can have one of ten different numbers and that each digit in a number represents a different power of 10.)

**Describe the process used to convert numbers from base-10 to base-2 or base-3.**  (To convert a number from base-10 to base-2 or base-3, you divide the number by the base you want, put the remainder in the front of the converted number, and repeat.)


### Coding Time (25-40 mins)
Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students' attention to the instructions and tips. Remind them of the code that was written in the activity to convert from decimal to binary. Encourage them to write the steps out in English first before coding them. If they are having trouble converting numbers to base-3, push them to see that the process is the same as with base-2 only with a different number.

### Written Reflection (5 mins)

**What did you use binary and ternary conversion for in this module?**
>I used it to convert numbers so that the robot could understand instructions, since he only understands binary and ternary.

**You may have heard that computers store information and instructions in binary. Why do you think this is so?**
>I think this is so because it can perform instructions by simply turning things on and off, which would represent 1 and 0.
