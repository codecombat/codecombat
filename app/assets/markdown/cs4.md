###### Last updated: 10/24/2016

##### Lesson Plans
# Computer Science 4

### Curriculum Summary
- Recommended Prerequisite: Computer Science 3
- 6 x 45-60 minute coding sessions

#### Overview
<!-- [MISSING] -->

_This guide is written with Python-language classrooms in mind. With the exception of the For Loops module, all modules can easily be adapted for JavaScript. There is a JavaScript-specific For Loops module available._

### Scope and Sequence

| Module                                                      |                      | Transfer Goals                                            |
| -----------------------------------------------------       | :-----------------   | :-----------------                                        |
| [21. While Conditionals](#while-conditionals)               |                      | Create a `while` loop with a conditional                  |
| [22. Arrays](#arrays)                                       |                      | Access an element in an array using an index              |
| [23. Nested While Loops ](#nested-while-loops)              |                      | Construct a nested `while` loop                           |
| [24. Optimization](#optimization)                           |                      | Use optimization in problem solving                       |
| [25. Objects](#objects)                                     |                      | Use an object literal as an argument                      |
| [26a. For Loops (Python)](#for-loops-python-)               |                      | PYTHON: Use a for loop to loop through the elements in an array   |
| [26b. For Loops (JavaScript)](#for-loops-javascript-)       |                      | JAVASCRIPT: Use a for loop to loop through the elements in an array   |



### Core Vocabulary
**While Conditionals**  - A `while` loop that runs until the condition is no longer true.  
**Arrays**  - a ordered list of items.  
**Nested While Loops**  - two or more while loops that are nested within each other -- students will need to check to make sure they both eventually become `false` so that they don't create multiple infinite loops!  
**Optimization**  - writing code that can choose the best strategy to execute.  
**Objects**  - object literals contain properties and values that other methods can access and modify.  
**For Loops**  - A `for` loop allows you to loop thought elements in an array without having to increment an index value.  

#### Extra activities for students who finish Course 4 early:
- Help someone else
- Write a walkthrough
- Write a review of the game
- Write a guide to their favorite level
- Design a new level


##### Module 21
## While Conditionals

### Summary

Up to this point, students have only used `while` loops that are set to True so that they will repeat forever. In these levels, students will be exposed to `while` loops that use conditionals to do things like attack enemies for a certain amount of time.

`while` loops are similar to `if` statements, but add complexity by introducing the possibility of creating a loop that will unintentionally run forever. Encourage students to read the directions carefully and collaborate as they work through the levels.

### Transfer Goals

* Create a `while` loop with a conditional
* Choose appropriate expressions
* Increment a `while` loop condition
* Understand what makes a loop run infinitely

### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP4** Model with mathematics.<br>
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Conditional Passing (10 mins)

#### Explain (3 mins)

Similar to `if` statements, `while` loops can include conditionals. The conditionals must be evaluated to either `True` or `False`, and the code inside of the loop will run continuously as long as the condition is found to be `True`.

Notice that the syntax is identical to the `while` loops seen previously in the game, but instead of being set to `True`, the `while` loop runs on a conditional expression.

```
bounces = 0
while bounces < 5:
	ball.bounce()
```
The loop above runs over and over again for as long as the number of bounces is less than 5. Because the value for `bounces` is not updated each time the ball is bounced though, the loop will continue to run forever.

```
attacks = 0
while attacks < 10:
	hero.attack(enemy)
	attacks += 1
```
This loop runs over and over again for as long as the number of attacks is less than 10. Notice that within the loop, the `attacks` value increases, or **increments**, by 1 each time the loop runs. This ensures that the next time the condition in the loop is checked, it is checking against the correct, updated value of attacks. Notice the syntax used to increment attacks:

`attacks += 1`

This is equivalent to the following:

`attacks = attacks + 1`

Similarly, a variable's value can **decrement** or decrease by 1 using the following syntax:

`attacks -= 1`

#### Interact (5 mins)

Present a ball in front of the class and let the students know that this will be the object acted on in the loop. If you do not have a ball, you can substitute a pencil, eraser, or any other object that can be easily passed from student to student. Write the following loop on the board:

```
while True:
	ball.pass( )
```
Point to the top line and ask the students if the condition is true (they should all say yes). Pass the ball to a student, then ask again if the condition is true. Once again, they should all say yes.

Allow the ball to be passed from student to student through the room as long as the condition is true. In this case, it is always true, so let the ball be passed for about a minute or until students can see that this would go on forever. Then write this second loop on the board:

```
passes = 0
while passes < 3:
	ball.pass( )
```
Once again point to the condition `(passes < 3)` and ask the students if the condition is true. Allow 3 turns of passing, asking each time first if the condition is true.

On the 4th time, when you ask the students if the condition is true, many of them will likely say no. Follow up by asking how many times the ball has been passed (3). Then ask, what is the value of the variable `passes`? Lead them to see that since the value of `passes` was never changed, the value is still 0 and thus the condition is true and the loop would run forever.

Finally write this third loop on the board:

```
passes = 0
while passes < 5:
	ball.pass( )
	passes += 1
```
Following the same steps as above, ask students if the condition is true and allow the ball to be passed as long as it is (5 times). On the 6th time, when you ask the students if the condition is true, some of them may say yes. Follow up by asking how many times the ball was passed (5), then ask what the value of `passes` is (also 5).

If necessary, run through the last loop again recording the value of `passes` on the board with tally marks or a table as students pass the ball around.



#### Reflect (2 mins)

**What is similar between a conditional `while` loop and an `if` statement?**  (Both rely on conditionals to run.)

**What is different between a conditional `while` loop and an `if` statment?**  (An if statement runs only once if the condition is true. A while loop runs continuously as long as the condition is true.)

**What is important about the conditional in a `while` loop?**  (It must evaluate to either True or False.)


### Coding Time (30-45 mins)

Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips, particularly for avoiding and correcting infinite loops. If their hero moves past the last ally and into the rocks at the bottom, this indicates that they have an infinite loop in their code. Students will have to increment `ordersGiven` by 1 within the `while` loop to correct this.

### Written Reflection (5 mins)

**What is different about the `while` loops you worked with today than the ones you've seen throughout the game thus far?**  
(The ones I worked with today used conditional statements to determine when and how long to run for. The others we've seen so far have just used True.)

**When would you use a conditional `while` loop?**   
(When you want something to run repeatedly as long as a certain conditional is true.)

**Why is it important to increment your `while` loop condition?**   
(If you do not, then you will get stuck in an infinite loop - one that never ends.)


##### Module 22
## Arrays

### Summary

**Arrays** are ordered lists of items. In fact, in Python, the name used for an array is `list`. Arrays can contain any type of item -- strings, integers, even other arrays -- and they can be any size. An element in an array can be accessed by its **index**, or its position in the list.

The array is a fundamental data structure, and it shows up quite often in programming. It also shows up frequently in CodeCombat, in a variety of ways. Sometimes, students will find the data stored at a certain position in an array, or use a loop to access all of the items in a list. Other times, a method (like `findEnemies()`) will return an array that can be used along with loops and conditionals to execute actions more effectively.

### Transfer Goals

- Recognize the array data structure
- Access an element in an array using an index
- Determine the length of a list in Python
- Iterate over an array with a loop


### Instructive Activity: Secret Boxes (15 mins)

#### Explain (6 mins)

Currently, the students know how to store data with the use of **variables**. For example the following code can be used to declare a hero named Ida:

`hero = "Ida"`

Variables are extremely useful, but allow for only one element to be stored at a time. **Arrays**, or lists, however, allow for multiple elements to be stored at a time.

The syntax used to create an array is square brackets (`[]`) around the entire list and commas (`,`) between each list item.

For example, the following code declares an array of the hero's items:
`heroItems = ['boots', 'sword', 'shield']`

Notice that the array above has a name, `heroItems`. Once the array is declared, it can be used by referencing its name, just like other variables used througout the game. Inside the square brackets are the items in the array, which in this example are the hero's inventory items. Boots is the first item, sword is the second, and shield is the third.

Arrays store items in order. Thus, each item in the array can be retrieved using its **index**, or position in the array. Indexes in arrays start at 0 rather than 1, so the index of the first item is 0, the index of the second item is 1, and so on.

The syntax to retrieve an element from an array is as follows:

```
# returns the item at index 0, which is 'boots'
heroItems[0]

# returns the item at index 1, which is 'sword'
heroItems[1]
```
Notice that the name of the array is followed by square brackets, then the index of the item to be retrieved.

Oftentimes, it is helpful to know the number of items that are in an array. This can be done by using the `len()` function, as shown below:

```
# this returns 3 since there are 3 items in the array
len(heroItems)  
```

The `len()` function is particularly useful for looping through an array in order to perform an action on each item in it. For example, view the following code segment:

```
itemsIndex = 0
while itemsIndex < len(heroItems):
	hero.say("I have " + heroItems[itemsIndex])
	itemsIndex += 1
```
This could be translated into pseudocode as so:

```
declare a variable itemsIndex and initialize it to 0
while the value of itemsIndex is less than the amount of items in the heroItems array:
	the hero says "I have " + the current item in the array
	increment itemsIndex by 1
	(loop again from while the value...)
```

The result of this code is that the hero says the following statements:

```
I have boots.
I have sword.
I have shield.
```

By using the variable `itemsIndex` and incrementing it with each iteration of the loop as long as it is less than the length of the array, the elements `heroItems[0]`, `heroItems[1]`, and `heroItems[2]` are all called upon. This causes the array to be looped through fully and results in the hero saying each of the items aloud.

Throughout the game, in addition to creating their own arrays for use, students will also use arrays that are returned from methods. For example, the method `findEnemies()` returns an array that students can call or access the elements of as described above.


#### Interact (7 mins)

For this activity, gather a few cardboard boxes and an item to be placed in each box. Set up the boxes in a row facing the students and place an item in each box. This set of boxes will act as the physical implementation of an array. Paper bags may be substituted for the boxes, if desired. This activity could be made to be especially fun and engaging by choosing funny or unexpected items to be placed inside of the boxes.

Choose a name for the array, such as `ourItems`. Record this name on the board and tell the students that the `ourItems` array consists of the boxes in front of them.

Have students verify the indexes of the array by beginning at the first box (the one to the students' far left), pointing to it, and asking what the index is. Ensure that the students remember that the index of this item is 0.

Move down the line, repeatedly asking the index of the box. Then move randomly pointing to different boxes, asking for the index of each box until the students seem to have a good grasp on the concept of counting from 0.

Then ask the students to help you retrieve the first item in the array. Remind them, if necessary, that the syntax is as follows:

`ourItems[0]`

If desired, you may have a student come up to the board to write the code. Once the code is written correctly, the item in the first box can be taken out and placed in front of the box for the class to see. Once again, a student can help with this if desired.

Once the item is visible to the class, extend the line of code above to include the assignment to the actual item, as shown below:

`ourItems[0] = 'teddy bear'`

Repeat the process of asking students to help you retrieve a specific item, write the corresponding code on the board, show the item to the class, then complete the line of code as described above. Instead of going in a linear fashion, it may be best to choose random items each time to ensure the students remember the correct index to use for each position (i.e., ask for the first item, then the fourth, then the second).

You may also wish to ask the students to help you retrieve an item that is not in the array (i.e. if the array has four items you ask for the fifth) to ensure that they understand it would return an error.

Once all items are visible to the class, have the students help write the line of code that would create this array. Ensure that the items are added in the correct order, and that commas are placed between each item.

For example, if your items are a teddy bear, a pencil, and a juice box, your code should be written as so:

`ourItems = ['teddy bear', 'pencil', 'juice box']`

Now ask the students how to find the number of items in the array. Remind them, if necessary, about the `len()` method. With their help, write the following code segment on the board:

`len(ourItems)`

Ask the students what value would be returned from this line of code and ensure it matches up with the number of items you have in your array. For the example shown above, `len(ourItems)` would return 3. Append to the line you just wrote on the board by adding = and the value, as so:

`len(ourItems) = 3`

Finally, with all items still visible, write the following code segment on the board:

```
itemIndex = 0
while itemIndex < len(ourItems):
	students.say("We have " + ourItems[itemIndex])
	itemIndex += 1
```

Have the students walk through the code with you and say the correct item as you point to each line of code. It may be helpful to record the value of itemIndex on the board as you move through the `while` loop.

#### Reflect (2 mins)

**What are arrays used for? How do they differ from variables** Arrays are used to store a list of items in order. They differ from variables because variables can only store one item, and arrays can store many.

**What are array indexes used for?** Indexes are used to find a specific element in an array, based on its position.

**For the array `heroes`, how can you find out how many items are in the array? How do you get the first item from the array?** `len(heroes)` gives you the number of items in the array. `heroes[0]` gives you the first item.


### Coding Time (30-45 mins)

Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Use leading questions to remind students about the `len()` function to be used in their while loops for later levels. Remind them of the way in which a `while` loop was used in conjunction with an array while doing the interactive activity with boxes. Encourage students to write out their answers in English and to work together to solve some of the tougher levels.

### Written Reflection (5 mins)


**What did you use arrays to do in these levels?**
> In these levels, I was able to use arrays to fight different enemies and say different names based on the array element I was looking at.

**What did you find simple about using arrays? What did you find difficult?**
>I found that using the array returned by the `findEnemies()` function made it simpler to beat enemies faster. I found that using while loops with arrays was difficult though because I had to remember to use the `len()` function and to increment the variable for the index.



##### Module 23
## Nested While Loops

### Summary

The next few levels combine skills from the previous two modules to introduce nested `while` loops. Students will use nested `while` loops to go through all enemies and attack only certain ones, or to go through all allies and command certain ones.

Conceptually, nested `while` loops are similar to nested conditionals, but the inclusion of arrays and possibility of multiple infinite loops adds difficulty. If students are having trouble, encourage them to carefully read the hints, collaborate with each other, and write out solutions in English before attempting to code them.

### Transfer Goals

* Construct a nested `while` loop
* Read and understand a nested `while` loop
* Properly increment nested `while` loops


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.<br>
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Jumping While (10 mins)


#### Explain (2 mins)
At this point the students know how to use a `while` loop to loop through and execute on the items in an array. Additionally, they can write a `while` loop that executes based on a certain condition. Now they will learn how to loop through an array and only perform an action on the items that meet a certain condition with nested `while` loops.

For example, perhaps they want to find all of the enemies nearby and attack each one for as long as its health is greater than 0. This could be expressed in English using `while` statements - "While there is an enemy nearby and while that enemy's health is greater than 0, attack it." The following code represents that:

```
enemies = hero.findEnemies()
enemyIndex = 0

while enemyIndex < len(enemies):
	enemy = enemies[enemyIndex]
	while enemy.health > 0:
		hero.attack(enemy)
	enemyIndex += 1
```
The first `while` loop loops through each enemy that was found. The second `while` loop is a conditional loop that runs as long as an enemy's health is greater than 0. Notice that the value of `enemyIndex` must be incremented to avoid running the outer loop infinitely.


#### Interact (5 mins)

Have the students line up along a wall (use two walls if needed) facing the board. On the board write the following code:

```
students = class.findStudents()
studentIndex = 0

while studentIndex < len(students):
	student = students[studentIndex]
	jumps = 0
	while jumps <= 3:
		student.jump()
		jumps += 1
	studentIndex += 1
```

Tell the students that each of them is an element in the `students` array. As you loop through each element in the array, you will move down the line of students. When you reach a student, it will be his or her turn to jump while the number of jumps for that student is less than or equal to three. Have the students walk through the code with you as you point to each line.

Point to the first line and ask students what they think it does. Be sure they understand that it creates an array of students, similar to the `findEnemies()` function in the game.

Then point to the second line and ensure they understand that it initializes a variable by which you can loop through the array, as they did in the most recent levels of the game.

Point to the next two lines of code and ask the students what they do. The students should recognize that those two lines work together to loop through each student of the students array. Explain that we initialize the variable `jumps` to be 0 each time we run through that loop to ensure that each student's `jumps` value begins at 0.

Point to the second `while` loop and ask students what it does. They should recognize that it is a loop that executes on a conditional based on the value of jumps and the effect is to have each student jump three times.

Go through the line of students one at at time getting each student to jump three times. As you move from student to student, be sure to point to the corresponding code to show the `studentIndex` variable incrementing and the outer `while` loop executing again.

Ensure that the students jump slowly so that you can point to the corresponding code that causes them to jump. It may be helpful to get a volunteer to record the values of `studentIndex` and `jumps` as you go through this exercise.

After having everyone in the class jump, point again to the code and ask students what would happen if you removed the line `jumps += 1`. Ask them then what would happen if you removed the line `studentIndex += 1`. For both questions they should respond that the `while` loop dependent on that value would run infinitely.

Note: If you need to modify this activity due to time or space constraints, you can have a subset of the class do the jumping activity while other students keep track of the variables and follow along by pointing to the corresponding lines of code.


#### Explain (1 min)
Nested `while` loops allow us to execute statements as long as two separate conditional statements are true. We must be careful when using them, as with each new loop we introduce another possibility of executing a command infinitely.


#### Reflect (2 mins)

**Why do we use nested `while` loops?** (To execute commands as long as two separate conditionals are true.)   
**What is different about using nested loops versus just one `while` loop?** (You are able to be more specific about your actions since you can specify two conditionals, but you also have the possibility of more infinite loops)    
**What does the indentation look like for nested `while` loops and why?** (The inside loop is indented by an additional 4 spaces to show that it is part of the outer loop.)


### Coding Time (30-45 mins)


Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Also be sure that they read all of the comments in the starter code and are aware of the goals for each level.

Remind students to check each `while` loop carefully for correct indentation and infinite loops before running their code. They will have to change the indentation for much of the starter code in order to get it running correctly.

### Written Reflection (5 mins)
**What is different about nested `while` loops than nested conditionals?**

(Nested while loops can be used to loop through an array then act on certain items based on a conditional. They also introduce the possibility of unintentionally executing an action forever.)  

**When using nested `while` loops, how many infinite loops could you unintentially create?**

(Generally the number of while loops you create, though more specifically, the number of while loops you create that are dependent on a value that must be updated manually)  

**What kinds of scenarios in the game did you use nested `while` loops for?**

(To go through all enemies and attack as long as their health was greater than 0, to go through all coins and pick up only gold ones)  



##### Module 24
## Optimization

### Summary

Optimization describes the act of solving a problem by selecting the "best" element from a set based on a certain criteria. Students will use optimization to strategize by attacking the farthest away and smallest enemies first.

These levels give students an introduction to the concept of problem solving through optimization. The syntax and coding concepts in these levels are familiar to the students, but this approach to solving problems may not be. Thus, these levels may prove to be difficult for some students.

### Transfer Goals

* Compare values to each other
* Set an initial value to compare to
* Use optimization in problem solving


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.   
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.   
**CCSS.Math.Practice.MP4** Model with mathematics.   
**CCSS.Math.Practice.MP6** Attend to precision.   

### Instructive Activity: Longest Item (10 mins)


#### Explain (3 mins)
The students now have the skills to attack an enemy at random and to attack enemies of a certain type. Today they will learn how to attack different enemies, such as the biggest, smallest, or farthest away through a process called **optimization**.

Optimization involves selecting an item that is determined to be "best" based on a certain criteria. Generally, it is selected as the "best" by comparing it to other items and finding the minimum or maximum.

For example, in order to find the enemy that is farthest away, the students could compare the distances of each enemy. One way to do this would be to store the values of all of the distances then loop through them to try and find the smallest.

Another way to do this, though, is to use a single variable that stores the maximum known distance at the time, then compares the distance of each enemy to that value. This could be implemented by using the following code:

```
farthest = None
maxDistance = 0
enemyIndex = 0
enemies = hero.findEnemies()

while enemyIndex < len(enemies):
	target = enemies[enemyIndex]
	distance = hero.distanceTo(target)

	if distance > maxDistance:
		maxDistance = distance
		farthest = target

	enemyIndex += 1
```
The important parts of the code to notice here are the first two lines and nested conditional (`if distance...`). `farthest` is initialized as `None` because it is unknown who the farthest enemy is, or if there even is a farthest enemy (perhaps there are no enemies at all). `maxDistance` is initialized to be 0 because it is unknown what the maximum distance will be. It is important to start at the smallest possible value `maxDistance` could be to ensure that each and every item is compared.

The if statement at the end compares the distance of the current target to the known maximum distance. If the target's distance is greater, then `maxDistance` is updated to have the value of the target's distance and `farthest` is updated to be that target. If the target's distance is not greater, then the variables' values are not changed.

The  `while` loop portion of the code above could be read as follows:

"While there are `enemies` in the array, set the variable `target` to the enemy at the current index. Now set the `distance` variable to the distance between my hero and this enemy. If the distance to this enemy is greater than the maximum distance I've found so far, update my `maxDistance` variable and set the variable `farthest` to this enemy. Now increment the index and check to see if the `while` loop should run again."

#### Interact (5 mins)
For this activity, you will need:

* A tape measure (preferably one with a switch to allow the tape to be left out)  
* A box full of items of various lengths.

Explain to the students that you want their help to find the longest item in the box, but with a few rules:

* You can only have one item out of the box at a time.  
* You can use the tape measure to measure each item after you take it out, but you cannot record the lengths of any items.

Ask students how they think you could go about doing this. Be sure to lead the discussion into using comparisons and optimization.

Before you take any items out of the box, ask the students what your initial maximum length is. Be sure they understand that the initial maximum length is 0 since no items have been measured. You can help them to visualize this by displaying the tape measure and asking what its current measurement says.

Additionally, ask them what the current longest item is. They should respond that it is `None` since no items have been measured yet. Record these values on the board using the variable names `maxLength` and `longestItem`. Feel free to have a student help you update these values throughout the activity.

Randomly select an item from the box and hold it next to the closed tape measure. Ask students if the length is longer than the current `maxLength` (to which they should all say yes). Measure its length with the tape measure and use the switch to leave the tape at that measurement. Ask the class what the `maxLength` and `longestItem` are now (they should say it's the current measurement and that item). Be sure to update the values on the board appropriately.

Continue taking items out of the box one at a time and comparing it to the amount of tape that is visible. You may also have students assist you in this process if you desire. Ask the class each time if the length of the current item is greater than the value of `maxLength`. If it is, then measure the item and update both values on the board accordingly. Remember to keep the tape out after each new measurement so that the students can visually see the `maxLength` with each comparison.

After you've gone through all of the items in the box ask the students if they can identify the length of the longest item. They should all recognize that the information on the board and the tape measure both show this value.

Note: If necessary, you can use a ruler or yard stick instead of a tape measure, but the activity will work best if you are able to show just the current maximum length on your measuring device.


#### Reflect (2 mins)

**Why is optimization useful?** (Compare values to each other so that you can execute an action on the "best" element based on your criteria.)   
**To find the maximum or largest value of a set, what is the initial value you should set to compare to?** (You should set the initial value to be 0, or a very small number so that you evaluate every item are always comparing to the largest known value)   
**To find the minimum or smallest value of a set, what is the initial value you should set to compare to?** (You should set the initial value to be a very large number so that you evaluate every item and are always comparing to the smallest known value.)


### Coding Time (30-45 mins)


Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Be sure that they read all of the comments included in the starter code and understand why the initial values are set as they are. Encourage them to collaborate and to write down or verbalize what value they are looking for and how they should go about finding it through comparisons.

Remind students of the interactive activity and draw parallels to it, asking leading questions such as, "What could you compare to the tape measure here?" or "What variable is similar to the `maxLength` from our activity?".

### Written Reflection (5 mins)
**Why is optimization used to find the largest or smallest value?**

(Because it allows us to compare each item to one value rather than storing information about all of the items and looping through them.)  

**What is the risk of setting your initial value greater than 0 if you are looking for the maximum?**

(The risk is that the values you're comparing are smaller than you think and you determine that none of them are the maximum because they are all less than the initial value you chose to set.)  

**If you were using optimization to find the youngest person in a room, what value would you set as your initial minAge? Why?**

(I would use 1000 because that is much longer than people live, and thus it would ensure that as long as there are people in the room, their ages will all be compared.)  



##### Module 25
## Objects

### Summary

Students have been using the `moveXY()` function to move their hero, but in these next few levels they will learn about a new function called `move()`. The `move()` function differs from `moveXY()` because it makes use of objects.

Objects, also referred to as dictionaries in Python, consist of properties and values. Students will learn how to create objects and use them for the new `move()` function to move their hero throughout the game.

### Transfer Goals

* Construct an object literal
* Use an object literal as an argument


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.  
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.  
**CCSS.Math.Practice.MP6** Attend to precision.  
**CCSS.Math.Practice.MP7** Look for and make use of structure.  

### Instructive Activity: Classroom Objects (10 mins)


#### Explain (3 mins)
The `moveXY()` function accepts an X and Y coordinate, which are passed as two separate arguments. The X coordinate is one argument, and the Y coordinate is another.

The `move()` function accepts only one argument. The argument is still a position with an X and Y coordinate, but the coordinates are passed as a set of properties into a single argument called an **object literal**.

Object literals are structures that consist of **keys** to define objects. Each key is made up of a property that the object has and a value for that property.

For example, an object for hair could have the properties 'color' and 'length' and the values 'brown' and 'long', respectively. An object for a person could have the property 'birthday' and the value 1/1/2000.

The syntax for an object literal is as follows:

`object = { 'property1':value1, 'property2':value2 }`

Note that the property names are always in quotations and they are separated from their values with a colon. An object literal can have any number of properties that are relevant or necessary for the object. If multiple properties are included, then they are separated by a comma.

As mentioned above, `move()` accepts an object with an X property and a Y property to specify the coordinates to move to. Students will use object literals to create a single position object that consists of the keys for X and Y. This will allow them to pass the position as a single argument that contains two separate values, one for the X coordinate and one for the Y coordinate. An example of this is shown in the following line of code:

`move({ 'x':10, 'y':20 })`  

Additionally, the position object can be created first, then passed in as an argument:

```
position = { 'x':10, 'y':20 }
move(position)
```

#### Interact (5 mins)
With help from the students, make a list of items around the classroom. As you write each item on the board, also record at least one property and its value for that item.

It will be helpful to:

* Get properties that have different value types (i.e. integers and strings)
* Have a list of at least ten items
* Get more than one property and value for most, if not all, of the items

If students suggest values for an object but not a property, encourage them to think about what property that value is before recording the value on the board.

Some suggested items you could use are:

* **board**
	* color: black
	* shape: rectangle
* **desk**
	* color: brown  
	* amount: 20
* **clock**
	* shape: round  
	* hour: 10
* **door**
	* color: brown  
	* inches: 80


You can also use non-physical objects such as:

* **lunch**
	* hour: 12
* **recess**
	* location: outside
	* hour:12.5


Once you have a list of at least ten items with corresponding properties and values, formulate them into object literals using Python syntax, e.g.:

```
board = { 'color': 'black', 'shape': 'rectangle' }
desk = { 'color': 'brown', 'amount': 20 }
recess = { 'location': 'outside', 'hour': 12.5 }
```
Ensure that you put quotations around every property name and around the values that are strings (rather than integers or decimals).

Pick a few of the object literals you've created and solicit help from the students to think of functions in which you could use them. Write out the different ways you could pass the object into the function. For example:

```
recess = { 'location': 'outside', 'hour': 12.5 }
go(recess)
```
Note this could also be written as:

```
go({ 'location': 'outside', 'hour': 12.5 })

```

Once you have two or three examples of object literals as function arguments written on the board, underline the properties and values in different colors. Then circle the different punctuation used in the syntax, including the curly braces, colons, commas, and quotations in different colors.

#### Reflect (2 mins)

**What does an object literal consist of?** (Keys, or properties and values that make up the object.)<br>
**What is the syntax for an object literal?**(`{ 'property1':value1, 'property2':value2 }`)



### Coding Time (30-45 mins)


Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Remind them that `move()` works differently than `moveXY()`. Encourage the students to think about the object literals that were created together in class and to recall the syntax used for them.

### Written Reflection (5 mins)
**What is different between the `move()` and `moveXY()` functions?**

(`move()` takes a single object literal as an argument and `moveXY()` takes two arguments, an X and a Y value.)  

**Why are object literals useful in Python?**

(They allow you to set properties and values for an object that you pass as a single argument.)  

**In these levels, you used object literals to create position objects for the `move()` function. What other objects do you think could be created with object literals in the game and what properties would they have?**

(I think that enemy or ally objects could be created by having a 'type' property that specifies its type and maybe a 'health' property that specifies its health.)



##### Module 26a
## For Loops (Python)
_Make sure you are using the Module appropriate to your classroom language_

### Summary

`for` loops are similar to `while` loops, but with different syntax and setup. In these levels, students will learn how to use `for` loops to loop through arrays and to perform an action a certain number of times. Although the inital learning curve may be steep for some students, the fact that the loop itself handles the incrementing should make it easier for students to avoid common pitfalls, such as infinite loops.

### Transfer Goals

* Construct a `for` loop
* Use a `for` loop to loop through the elements in an array
* Use a `for` loop to execute an action a certain number of times


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Jumping For (10 mins)


#### Explain (3 mins)
`for` loops are similar to `while` loops and can be used to accomplish the same things. `for` loops can be used to loop through the elements in an array and to execute an action a certain number of times. Like `while` loops, they can be nested as well. The difference between the loops lies in the syntax and setup.

The general syntax for a `for` loop is `for X in Y`. `Y` is the array or set of items to run through and `X` is the name of the variable that is chosen by the coder for each item to have as it is acted upon.

The following code shows a for loop looping through an array:

```
for friend in hero.friends():
    if friend.type == 'soldier':
    enemy = friend.findNearestEnemy()
```
This block of code could be translated into pseudocode as so:

```
for each friend in the friends array:
	if the friend is a soldier:
		assign the variable enemy to the friend's nearest enemy
```

Compare this to the code for a while loop that does the same thing:

```
friendIndex = 0
while friendIndex < len(friends):
    friend = friends[friendIndex]
    if friend.type == 'soldier':
        enemy = friend.findNearestEnemy()
    friendIndex += 1
```

This second block of code could be translated into pseudocode as so:

```
create a variable friendIndex and assign it the value 0
while friendIndex is less than the amount of friends in the array:
	assign the variable friend to the current element in the array
	if the friend is a soldier:
		assign the variable enemy to the friend's nearest enemy
	add one to friendIndex (and run the while loop again)
```

When comparing the code and pseudocode for both loops, notice that in the `for` loop code, there is no variable `friendIndex`. When using a `for` loop, there is no need to create a variable to track the index and increment it because Python does that automatically with each iteration of the loop. Additionally, there is no need to assign the variable `friend`, as this is done in the first line of the loop when it is initialized.

`for` loops can also be used to execute a statement or block of code a certain number of times, by using `range()` as shown below:

```
for i in range(4):
	hero.summon("soldier")
```
The argument for `range()` must be an integer, and it specifies how many times the loop will execute. Thus in the example shown above, 4 soldiers would be summoned.

Note that `range()` creates an array of integers that starts at 0 and has the number of elements specified in parentheses. So `range(4)` creates an array with the integers 0, 1, 2, and 3. Although the counting does not start at 1, it still ensures that the loop is run 4 times.

#### Interact (5 mins)
To show the similarities and differences between `while` and `for` loops, the same activity as was used for nested `while` loops wil be used to demonstrate `for` loops. If you wish to modify it, you could choose to have the students perform a different action than jump, such as laugh, clap, or say a silly word or phrase.

Have the students line up facing the board. Write the following code on the board:

```
for student in class.findStudents():
	for i in range(3):
		student.jump()
```
Tell the students that each of them is an element in the students array that is generated from the `findStudents()` function. As you loop through each element in the array, you will move down the line of students. When you reach a student, it will be his or her turn to jump for as long as the value of `i` is within range.

Have the students walk through the code with you as you point to each line. Point to the first line and ask the students what they think it does. Be sure that they understand everything that happens in that one line of code:

* An array of students is created using the function `findStudents()`
* The variable `student` is given to each item in the array as it is executed on
* The entire array is looped through one item at a time

Point to the second line of code and ask the students what it does. Ensure that they are aware of everything that happens in this line of code:

* An array of integers is created using the `range()` function. The array starts at 0 and has 3 integers in it, 0, 1, and 2.
* The variable `i` is given to each item in the array as it is executed on
* `i` is incremented with each execution of the loop
* The entire array is looped through one item at a time

Go through the line of students one at a time getting each student to jump three times. It is very important to move slowly through this and to point at the corresponding line of code with each jump and each change of student.

It may be helpful to record the value of `i` on the board as you move through the loops. Note that with each new student, `i` will start again at 0 then be incremented each time the inner `for` loop executes.

Ensure the students understand that, as with nested `while` loops, the inner `for` loop will run for as long as it can, then the code in the outer loop will be run again.

#### Reflect (2 mins)

**How is a `for` loop similar to a `while` loop?** (Both a for loop and a while loop can be used to loop through an array and to execute an action a certain number of times.)

**How is a `for` loop different from a `while` loop?** (You do not need to create and increment a variable for the index because Python does that automatically for you.)


### Coding Time (30-45 mins)

Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Remind them that once they set up the `for` loop there is no need to increment variables or set them to be an element in the array. Encourage students to work together and write out the answers in English if they are stuck.

### Written Reflection (5 mins)
**How did you use `for` loops in these levels?**

(I used them to loop through allies and to create a certain number of soldiers)

**Which do you think are easier to use, `for` loops or `while` loops? Why?**

(I think for loops are easier because even though there is more set up, there is less to remember for extra variables and it is not easy to end up in an infinite loop.)


##### Module 26b
## For Loops (JavaScript)
_Make sure you are using the Module appropriate to your classroom language_

### Summary

`for` loops are similar to `while` loops, but with different syntax and setup. In these levels, students will learn how to use `for` loops to loop through arrays and to perform an action a certain number of times. The inital learning curve may be steep for some students until they know how to correctly set up the `for` loop. Once they have mastered the setup, students should find that using `for` loops makes it easier to avoid common pitfalls, such as infinite loops.

### Transfer Goals

* Construct a `for` loop
* Use a `for` loop to loop through the elements in an array
* Use a `for` loop to execute an action a certain number of times


### Standards
**CCSS.Math.Practice.MP1** Make sense of problems and persevere in solving them.<br>
**CCSS.Math.Practice.MP2** Reason abstractly and quantitatively.<br>
**CCSS.Math.Practice.MP6** Attend to precision.
**CCSS.Math.Practice.MP7** Look for and make use of structure.

### Instructive Activity: Jump For (10 mins)


#### Explain (3 mins)
`for` loops are similar to `while` loops and can be used to accomplish the same things. `for` loops can be used to loop through the elements in an array and to execute an action a certain number of times. Like `while` loops, they can be nested as well. The difference between the loops lies in the syntax and setup.

The general syntax for a `for` loop is `for (initialization; condition; expression)`. `initialization` runs only once at the start of the first loop iteration. It initializes a variable to be used in the loop.

`condition` defines the condition for the loop to run.  It is often used to evaluate the variable that is created in the `initialization` segment to see if it meets a certain condition. The loop will continue to run as long as the condition is `true`. After each time the loop completes, it checks to see if the condition is `true` then runs if it is. If the condition is `false`, the loop body is skipped and the code below the closing brace of the `for` loop is executed.

`expression` is an expression that acts on the variable initialized in `initialization`. It is usually used to increment or decrement the variable. `expression` runs at the end of each loop iteration, after the body of the loop has been executed.

The flow of control for `for` loops is as follows:

1. `intialization` executes to initialize a variable.
2. The `condition` is evaluated. If it is `true` move to the next step. If it is `false` then move to the code after the loop.
3. The code in the loop body is executed.
4. `expression` is executed.
5. Repeat beginning from step 2.

Notice that `initialization` occurs only once, right at the start of the loop execution. Additionally, although the `expression` is written before the loop body, it is executed after the loop body is.

The following code shows a `for` loop looping through an array:

```
for(var friendIndex = 0; friendIndex < friends.length; friendIndex++) {
    var friend = friends[friendIndex];
    if(friend.type == "soldier") {
        var enemy = friend.findNearestEnemy();
    }
}
```
This block of code could be translated into pseudocode as so:

```
create a variable friendIndex and initialize it to be 0

if friendIndex is less than the number of friends in the array {
	initialize a variable friend to be the current element in the array
	if the friend is a soldier:
		assign the variable enemy to the friend's nearest enemy
	increment friendIndex by 1
	repeat the loop (from if friendIndex...)
```

Compare this to the code for a while loop that does the same thing:

```
var friendIndex = 0;
while (friendIndex < len(friends) {
    var friend = friends[friendIndex];
    if (friend.type == "soldier") {
        enemy = friend.findNearestEnemy();
    friendIndex += 1;
```

This second block of code could be translated into pseudocode as so:

```
create a variable friendIndex and assign it the value 0
while friendIndex is less than the amount of friends in the array:
	assign the variable friend to the current element in the array
	if the friend is a soldier:
		assign the variable enemy to the friend's nearest enemy
	add one to friendIndex (and run the while loop again)
```

When comparing the code and pseudocode for both loops, notice that in the `for` loop code, the variable `friendIndex` is initialized and incremented within the first line of the `for` loop. Thus, there are no separate lines for these actions, as there are in the `while` loop.

`for` loops can also be used to execute a statement or block of code a certain number of times as shown below:

```
for (var i = 0; i < 4; i++) {
	hero.summon("soldier");
```
In the example shown above, the variable `i` is initialized to be 0. It is then incremented by 1 each time the loop runs, for as long as `i` is less than 4.  The loop will run 4 times, one time each when `i` equals 0, 1, 2, and 3. Thus, 4 soldiers will be summoned.


#### Interact (5 mins)
To show the similarities and differences between `while` and `for` loops, the same activity as was used for nested `while` loops wil be used to demonstrate `for` loops. If you wish to modify it, you could choose to have the students perform a different action than jump, such as laugh, clap, or say a silly word or phrase.

Have the students line up facing the board. Write the following code on the board:

```
var students = class.findStudents();

for(var studentIndex = 0; studentIndex < students.length; studentIndex++) {
    var student = students[studentIndex];
    for (var i = 0; i < 3; i++) {
        student.jump();
    }
}
```
Tell the students that each of them is an element in the `students` array that is generated from the `findStudents()` function. As you loop through each element in the array, you will move down the line of students. When you reach a student, it will be his or her turn to jump for as long as the value of `i` is less than 3.

Have the students walk through the code with you as you point to each line. Point to the first line and ask the students what they think it does. Ensure they understand that this creates an array of students, similar to the `findEnemies()` function in the game.

Point to the second line of code and ask the students what it does. Ensure that they are aware of everything that happens in this line of code:

* The variable `studentIndex` is declared and initialized to be 0
* A condition is set for the loop to run only as long as `studentIndex` is less than the length of the `students` array
* `i` is incremented after each execution of the loop

Then point to the third line of code to ask the students what it does. They should be aware that it creates a variable called `student` and sets it to the current element of the `students` array.

Point to the next line, and again ask the students what it does. They should see that this second `for` loop initialization does the following:

* Declares and initializes a variable `i` to be set to 0
* Sets a condition for the loop to run only as long as `i` is less than 3
* Increments `i` by 1 after each execution of the loop


Go through the line of students one at a time getting each student to jump three times. It is very important to move slowly through this and to point to the corresponding line of code with each jump and each change of student.

Be sure to point to each segment of the `for` loop (initialization, condition, body, and expression) as it is executed to help the students visually see the flow of control.

It may be helpful to record the values of `studentIndex`, `student`, `i`, and `jumps` on the board as you move through the loops. Note that with each new student, `i` will start again at 0 then be incremented each time the inner `for` loop executes.

Ensure the students understand that, as with nested `while` loops, the inner `for` loop will run for as long as it can, then the code in the outer loop will be run again.

#### Reflect (2 mins)

**How is a `for` loop similar to a `while` loop?** (Both a for loop and a while loop can be used to loop through an array and to execute an action a certain number of times.)

**How is a `for` loop different from a `while` loop?** (In a for loop, you initialize the variable, set the condition, and increment the variable all on the same line. In a while loop, these happen in different lines of code.)


### Coding Time (30-45 mins)

Allow the students to go through the game at their own pace, keeping notes about every level on paper or digital document. We recommend using following format, which you can also print out as templates: [Progress Journal [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal.pdf)

```
Level #: _____  Level Name: ____________________________________
Goal: __________________________________________________________
What I did:

What I learned:

What was challenging:


```

Circulate to assist. Draw students’ attention to the instructions and tips. Remind them that once they set up the `for` loop there is no need to increment variables. Encourage students to work together and write out the answers in English if they are stuck.

### Written Reflection (5 mins)
**How did you use `for` loops in these levels?**

(I used them to loop through allies and to create a certain number of soldiers)

**Which do you think are easier to use, `for` loops or `while` loops? Why?**

(I think for loops are easier because even though there is more set up, there is less to remember for extra variables and it is not easy to end up in an infinite loop.)

##### Module 27
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

#### Optional: Review the Engineering Cycle

If students need a refresher, remind them that engineering is all about solving problems, and the first rule of engineering is that no one gets it right the first time. That’s where the Engineering Cycle comes in:

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

Have students navigate to the last level, **Summation Summit**. They should take a few minutes to complete the Engineering Cycle Worksheet, then complete the level at their own pace.  Circulate and assist as they work.


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

