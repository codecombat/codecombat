# AP CS Principles Game Development 2 Guide

## Overview

This guide is to be used in conjunction with the Game Dev 2 Curriculum Guide, and shows how to use this course to practice Create Task concepts and goals.

Please refer to the 2018 Scoring Guidelines on [College Board’s site](https://www.google.com/url?q=https://apcentral.collegeboard.org/courses/ap-computer-science-principles/exam?course%3Dap-computer-science-principles&sa=D&ust=1508189450511000&usg=AFQjCNGO9iU6sHqLd5znH6_aLjVBSgaAcw). In these, there are eight rows, broken up into three reporting categories. In Game Development 1, students learned how to satisfy the first reporting category, “Developing a Program With a Purpose”. Game Development 2 will continue to practice those concepts, and also teach how to satisfy the second reporting category, “Applying Algorithms”.

## Algorithmic Complexity

To be graded well on the “Applying Algorithms” rows, students must include code of sufficient complexity. The simplest way to satisfy all requirements is to do the following:

*   Have a function which calls two other functions
*   One of those called functions includes sufficient logical or mathematical concepts
*   The student sufficiently marks and explains these algorithms

As such, Game Development 2 levels are filled with examples of these that can be pointed out to students as they are playing through:

*   Disintegration Arrow’s game loop calls two other functions, checkGoal and checkSpawnTimer, each of which use “if”.
*   Run for Gold’s game loop calls checkSpawns and checkGameOver, each of which use “if”.
*   "Game of Coins Part 5: Balance" includes a function `checkTimers` which runs `checkTimeScore` and `checkPowerTimer`, each of which use `if`.

Point these areas out as students play through the levels. For the project, you and the students should apply the rubric carefully to ensure all the requirements are met. Of course, students probably will create algorithms of greater complexity in their projects; what’s important is to make sure they are sufficiently complex according to the rubric. The Create Task code samples provided by College Board should help guide you in applying the rubric correctly.

Also, note that calling functions indirectly through event handlers does not satisfy the rubric. Functions must be called directly. Assuming the student wrote `func1` and `func2` themselves, and either or both contain mathematical and/or logical concepts, this will satisfy the rubric:

```
while True:
  func1()
  func2()
```

But this does not:

```
munchkin.on("spawn", func1)
munchkin.on("spawn", func2)
```

This is based on our interpretation of the 2018 Scoring Guidelines in rows 5 and 6:

> Do NOT award a point if [...] the selected algorithm consists solely of library calls to existing language functionality.

And the scoring criteria in row 6:

> Selected code segment implements an algorithm that includes at least two or more algorithms.

Our event handling system is a "library call", rather than an algorithm which directly calls other
algorithms. This is also not really an "integration" of two or more algorithms, the two are called
independently of one another through the event handling system. See also 2018 Example C, which has
several functions, but "integrates" them through event handlers, and so does not receive the point for row 6.

Please make sure to read through the 2018 Scoring Guidelines on [College Board’s site](https://www.google.com/url?q=https://apcentral.collegeboard.org/courses/ap-computer-science-principles/exam?course%3Dap-computer-science-principles&sa=D&ust=1508189450517000&usg=AFQjCNF12A0K6236br7sZ0t_2r8d5EKKRQ).

## Mathematical or Logical Concepts

For algorithms to have sufficient complexity, code must use certain concepts. However, at this point your students will only have been taught if/else statements. In Computer Science 3 and later Game Development courses, students will learn how to incorporate iteration, mathematical concepts and boolean algebra, but for the meantime encourage students to experiment with if/else in their programs.

## Iteration

The Game of Coins levels serve as an example of the iterative process. Take the time to emphasize how having the program working at various points in various ways exemplifies iteration, and why it’s useful: it can be demonstrated to others, what you learn as you build it can affect what and how you build your project, and you are able to change what you end up building more easily. It’s also important for students to demonstrate in their journals how various points in the iterative process are connected to one another (see row 2 of the Scoring Guidelines). Show how each of these levels build on one another, and how that sort of story is required in their written responses. This is an easy row to miss, so extra focus on it will be well spent!

## Written Response

Students should practice Written Response part 2c after they have finished their GD2 project:

> Capture and paste a program code segment that implements an algorithm (marked with an **oval** in **section 3** below) and that is fundamental for your program to achieve its intended purpose. This code segment must be an algorithm you developed individually on your own, must include two or more algorithms, and must integrate mathematical and/or logical concepts. Describe how each algorithm within your selected algorithm functions independently, as well as in combination with others, to form a new algorithm that helps to achieve the intended purpose of the program. *(Must not exceed 200 words)*.

They should at least do this for their own Game Development 2 Project. They can also practice identifying and describing algorithms on levels listed in Algorithmic Complexity, or on each other’s Game Development 2 Projects.
