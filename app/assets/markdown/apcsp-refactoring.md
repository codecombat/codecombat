##### Activity

# Introduction to Refactoring
Inquiry Activity

### Learning Objectives
- [LO 2.2.1] Develop an abstraction when writing a program or creating other computational artifacts. [P2]
- [LO 2.2.3] Identify multiple levels of abstractions that are used when writing programs. [P3]

## Refactoring Code

**Activity:**

Have the students play [The Agrippa Defense](https://codecombat.com/play/level/the-agrippa-defense), which can be found in Computer Science 2.

The obvious solution to this level uses an algorithm consisting of three levels of nested IF/ELSE statements:

```
while True:
    enemy = hero.findNearestEnemy()
    if enemy:
        distance = hero.distanceTo(enemy)
        if distance < 5:
            if hero.isReady("cleave"):
                hero.cleave(enemy)
            else:
                hero.attack(enemy)
```

Using multiple levels of abstraction, students can eventually simplify the core logic of the level to just three lines:

```
while True:
    enemy = hero.findNearestEnemy()
    cleaveOrAttack(enemy)
```

This code is much easier to understand at a glance, because it is a higher level of abstraction!

Instruct the students to identify the pieces of logic that can be abstracted out in order to get from the first program to the second program. If they need help, you can guide them to two core abstractions:

1. Determining if there is an appropriate enemy to target.
2. Determining the appropriate attack to use.

### Abstraction 1: Determining if there is an appropriate enemy to target.

The key to this abstraction is to create a function that accepts the `enemy` as a parameter, and returns false if the enemy is null (there is no enemy) or if the enemy is 5 or more meters away. It should return true if the enemy exists, and is closer than 5 meters.

The code should look something like this:

```
def enemyInRange(enemy):
	if not enemy:
		return False
	if hero.distanceTo(enemy) < 5:
		return True
	else:
		return False
```

### Abstraction 2: Determining the appropriate attack to use.

The key to this abstraction is to create a function that accepts the `enemy` as a parameter, and then uses the function from abstraction 1 in an `if` statement to make sure the enemy is appropriate to attack. If so, then use the `cleave` attack if it's ready, otherwise use a normal `attack`. The code should look something like this:

```
def cleaveOrAttack(enemy):
    if enemyInRange(enemy):
        if hero.isReady('cleave'):
            hero.cleave(enemy)
        else:
            hero.attack(enemy)
```

To wrap up, guide the discussion toward how these functions could be used in other contexts. How generally usable is `enemyInRange` or `cleaveOrAttack`, for example? Can these be used in other contexts of other levels? Guide students toward the realization that abstraction often occurs when you ask the questions “what logic in this code could I use elsewhere?” and then figuring out how to structure the code so that it can be used in various circumstances.


### Discussion Questions:
- How does using abstraction to break a problem into smaller, separate, problems help make programs better?
- How does using abstractions make programs easier to understand?
- What other abstractions are used in computer programming?

### Assessment Questions:
For each of the following pieces of pseudocode:
- Circle a piece that can be abstracted out
- Give it a descriptive function name and any necessary parameters
- Describe how it could be used in another function elsewhere.

```
def userSignsUp(email, password):
  emailIsLongEnough = email length is greater than 5
  emailHasAtSymbol = email contains “@”
  if emailIsLongEnough and emailHasAtSymbol
    userExists = lookup user by email
    if userExists
      Tell user they have already signed up
    else
      Sign user up
  else
    Tell user email is invalid
```

```
def driveCarInCircles():
  if sensor 1 says something is in front of us
    stop
  else if sensor 2 says something is in front of us
    stop
  else if sensor 3 says something is in front of us
    stop
  else if at intersection
    Turn right
  else 
    if closest object is over 100 feet away
      Drive forward fast
    else
      Drive forward slow
```
