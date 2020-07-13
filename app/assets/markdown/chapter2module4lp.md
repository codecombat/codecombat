_Time: 75-120 in-game minutes_


# Chapter 2: Module 4 Lesson Plan

# Overview
Module 4 consists of all the content from **Xing'chen** to **The City Saved**.

**Learning Objectives**

   - Use pseudocode as a tool to plan code and understand algorithms.
   - Explain how conditions and decision points result in different algorithm execution.
   - Explain Boolean logic and simple Boolean expressions.
   - Use if/else statements to provide varied paths based on conditional logic.

**Standards**

This module was designed to align to the following K-12 CSTA standards:

   - 1A-AP-08: Model daily processes by creating and following algorithms (sets of step-by-step instructions) to complete tasks.
   - 1A-AP-10: Develop programs with sequences and simple loops, to express ideas or address a problem.
   - 1A-AP-11: Decompose (break down) the steps needed to solve a problem into a precise sequence of instructions.
   - 1A-AP-12: Develop plans that describe a program&#39;s sequence of events, goals, and expected outcomes.
   - 1A-AP-15: Using correct terminology, describe steps taken and choices made during the iterative process of program development.
   - 1B-AP-10: Create programs that include sequences, events, loops, and conditionals.

# Materials

- [Module Overview](https://www.ozaria.com/teachers/resources/chapter1module4overview)
- Teacher Guide to Systems (coming soon)
    - See the Chapter 1 Lesson Plan for an explanation of important in-game student supports.
- Solutions: To view solutions for levels, navigate to the Unit Guides tab and click on the &quot;Level Overviews and Solutions — Module 4&quot; link.

# Content Background

- Key Terms
    - **Boolean logic**: Logic  that uses &quot;and,&quot; &quot;or,&quot; and &quot;not&quot; to determine whether things are true or false. In this Module, we&#39;ll only introduce students to determining whether simple expressions are true/false, and we will introduce concepts of &quot;and,&quot; &quot;or,&quot; and &quot;not&quot; later on.
    - **Operators**: Characters the represent either an action or a relationship. In this module, we look at the relational operators:
        - &lt; (less than)
        - &gt; (greater than)
        - &lt;= (less than or equal to)
        - &gt;= (greater than or equal to)
        - == (equal to in Python)
        - === (equal to in JavaScript)
        - != (not equal in Python)
        - !== (not equal in JavaScript)
    - **Pseudocode:** Algorithms written in plain language, not in programming language syntax, used to plan logic before writing code.
    - **Conditional**: A statement that leads the program to take different courses of action depending on whether the condition is true or false.
    - **If statement**: A type of conditional in which the keyword &quot;if&quot; is used before the condition.

```
distance = getDistanceTo(enemy)

#if the distance is lower than 10, move to the enemy
if distance < 10:
  hero.moveTo(enemy)
```

   - **If/else statement**: A type of conditional in which one set of statements runs if the condition is true, and a    different one runs if the condition is false.

```
distance = getDistanceTo(enemy)

#if the distance is lower than 10, move to the enemy
if distance < 10:
  hero.moveTo(enemy)
else:
  hero.moveRight(10)
```

- Explanation of instructional pathway
    - Module 4 comes after students learn about variables and before students learn tools to apply to their Capstone final projects.

# Narrative Background

The hero and Vega head into Xing&#39;chen to find the Academy. Along the way, Vega teaches the hero about Boolean logic and conditionals. When they arrive, they find out that someone stole the Earth Totems and the leader of the Earth Magic Academy, Luten, blames the hero. They have to find the totems to get back in Luten&#39;s good graces. The hero finds the totems and learns that Eridani, Luten&#39;s son, has stolen them to help people grow food. The hero returns to the Academy to tell Luten, and he allows the hero in.

# Instructional Tips

**Common Student Misconceptions**

- Students may have trouble understanding the difference between assignment (using a single equals sign) and checking for equality (using two equals signs in Python and three in JavaScript). 
- Students may have trouble understanding that the code indented within if statements will only execute if the condition is true, and that anything that is outside of the if or else statement indentation will always execute. 

**Differentiation**

- Students who finish early should answer these reflection questions:
    - What is a time in everyday life when you have to make a decision about what to do based on whether something is true or false?
    - How would you explain to a friend what an if statement is?
    - Why would we need an &quot;else&quot; statement rather than just using a lot of different if statements?
- Go over the Intro content as a group with students who are having trouble grasping the concept of conditionals.
