# Overview

This guide is to be used in conjunction with the Game Dev 3 Curriculum Guide, and shows how to use this course to practice Create Task concepts and goals.

Please refer to the 2018 Scoring Guidelines on [College Board’s site](https://www.google.com/url?q=https://apcentral.collegeboard.org/courses/ap-computer-science-principles/exam?course%3Dap-computer-science-principles&sa=D&ust=1510958865852000&usg=AFQjCNG_heyLi5v7J9Q1-DUzw7wYKKLqug). In these, there are eight rows, broken up into three reporting categories. In Game Development 1, students learned how to satisfy the first reporting category, “Developing a Program With a Purpose”. Game Development 2 focused on the second reporting category, “Applying Algorithms”. Game Development 3 focuses on the final reporting category, “Applying Abstraction”.

## Abstraction

To be graded well on the “Applying Abstraction” rows, students must develop and identify their own abstraction which helps manage the complexity of their program. An example abstraction is a function which is called in various contexts or repeatedly, especially one that includes parameters.

Game Development 3 levels are filled with examples of these that can be pointed out to students as they are playing through:

* The Rule of the Square: `spawnRandomUnit` and `shouldAttack` functions
* The Big Guy: `spawnRandomXY`
* Quantum Jump: `spawnRandomX`
* Looney Gems: `spawnRandomGem`
* Runner (Part 4): `spawnRandomY`

Note that these are NOT valid student-created abstractions:

* Event functions such as `onUpdateOgre` in Runner
* Game parameter variables in the final Runner level
* Functions that are only called once or in one place, such as `spawnOgre`

Event functions ARE abstractions, and very good examples of abstractions, but these are created and provided by CodeCombat. If a student were to submit an event handler as an abstraction, they may get a point for row 8 (Explains how the selected abstraction manages the complexity of the program) but not row 7 (Selected code segment is a student-developed abstraction).

Variables are also an abstraction, but one that is provided by programming languages. The final level of Runner revolves around several variables which abstract out the parameters which affect the game behavior. These are abstractions, but they are not student-generated abstractions.

Functions which are called once or in one place are arguably not managing complexity. One could simply take the code written in one function and have it where the function is called once. Much better are functions which are used in various places or with variable inputs, such that NOT having the abstraction would mean much more verbose or complicated code. The more clearly the abstraction is improving the code, by keeping it cleaner or more concise, the better.

Complex data structures such as lists and objects are another way to demonstrate abstraction, but at this point students will not have been introduced to these data structures. If students are further than Computer Science 3 when they work on their project, they can certainly be encouraged to explore other forms of abstraction, but this is not strictly necessary.

## Iteration

As in Game Development 2, the Runner project tutorial levels are a good example of iteration, the sort of iteration that students are expected to go through and communicate for the reporting category “Developing a Program with a Purpose”. Be sure to set aside time to analyze this example with the class to help communicate what iteration means.

## Written Response

Students should practice the entire written response after they have finished their Game Development 3 project<sup>[[a]](#cmnt1)</sup>. In particular, they are now able to respond to part 2d which addresses Abstractions.

*2d. Capture and paste a program code segment that contains an abstraction you developed individually on your own (marked with a **rectangle** in **section 3** below). This abstraction must integrate mathematical and logical concepts. Explain how your abstraction helped manage the complexity of your program. (Must not exceed 200 words)*

They should at least do this for their own Game Development 3 Project. They can also practice identifying and describing abstractions on levels listed in **Abstraction**, or on each other’s Game Development 3 Projects.
