# Levels Module 3 Solutions (Double Security - Showtime)

## Double Security

Python

```
password = "peanut butter"

#Say the password to the guard
hero.say(password)

#Move past the guard
hero.moveRight()
hero.moveRight()

#Reassign password based on what Octans tells you
password = "jelly"

#Say the password
hero.say(password)

#Move to the artifacts
hero.moveRight()
hero.moveRight()

```

JavaScript

```
var password = "peanut butter";

//Say the password to the guard
hero.say(password);

//Move past the guard
hero.moveRight();
hero.moveRight();

//Reassign password based on what Octans tells you
password = "jelly";

//Say the password
hero.say(password);

//Move to the artifacts
hero.moveRight();
hero.moveRight();
```

## Stand in Line

Python

```
personName = "Rigel"
hero.say(personName)
hero.use("button")

# Update variable to next person's name
personName = "Persei"

# Say the next person's name and open the gate
hero.say(personName)
hero.use("button")


# Update variable to last person's name
personName = "Sigma"

# Say the last person's name and open the gate
hero.say(personName)
hero.use("button")
```

JavaScript

```
var personName = "Rigel";
hero.say(personName);
hero.use("button");

//Update variable to next person's name
personName = "Persei";

//Say the next person's name and open the gate
hero.say(personName);
hero.use("button");


//Update variable to last person's name
personName = "Sigma";

//Say the last person's name and open the gate
hero.say(personName);
hero.use("button");
```

## High Traffic

Python

```
button = "button1"

# Someone wants into Gate 1.  Assign their name to personName
personName = "Bootes"

# Open Gate 1 and say the person's name
hero.use(button)
hero.say(personName)

# Reassign personName to name of next Gate 1 person
personName = "Canis"

# Say the next person's name and open Gate 1
hero.use(button)
hero.say(personName)

# Someone wants into Gate 2.  Switch which button to use
button = "button2"

# Reassign personName to the name of Gate 2 person
personName = "Leo"

# Open Gate 2 and say the person's name
hero.use(button)
hero.say(personName)

# Reassign personName to name of next Gate 2 person
personName = "Ursa"

# Say the next person's name and open Gate 2
hero.use(button)
hero.say(personName)
```

JavaScript

```
var button = "button1";

//Someone wants into Gate 1.  Assign their name to personName
personName = "Bootes";

//Open Gate 1 and say the person's name
hero.use(button);
hero.say(personName);

//Reassign personName to name of next Gate 1 person
personName = "Canis"

//Say the next person's name and open Gate 1
hero.use(button);
hero.say(personName);

//Someone wants into Gate 2.  Switch which button to use
button = "button2";

//Reassign personName to the name of Gate 2 person
personName = "Leo";

//Open Gate 2 and say the person's name
hero.use(button);
hero.say(personName);

//Reassign personName to name of next Gate 2 person
personName = "Ursa";

//Say the next person's name and open Gate 2
hero.use(button);
hero.say(personName);
```

## Forest of Illusions

Python

```
# Find the Mist totem, move to and use it
mistTotem = hero.findNearestTotem()
hero.moveTo(mistTotem)
hero.use(mistTotem)

# Find the next totem and assign it to a variable treeTotem
treeTotem = hero.findNearestTotem()

# Move to the treeTotem
hero.moveTo(treeTotem)

# Use the treeTotem
hero.use(treeTotem)

```

JavaScript

```
//Find the Mist totem, move to and use it
var mistTotem = hero.findNearestTotem();
hero.moveTo(mistTotem);
hero.use(mistTotem);

//Find the next totem and assign it to a variable treeTotem
var treeTotem = hero.findNearestTotem();

//Move to the treeTotem
hero.moveTo(treeTotem);

//Use the treeTotem
hero.use(treeTotem);
```

## Wooden Noise

Python

```
# Assign firstTotem from hero.findNearestTotem()
firstTotem = hero.findNearestTotem()

# Move to the first totem
hero.moveTo(firstTotem)

# Use firstTotem to change the illusion
hero.use(firstTotem)

# There's one more.
# Find the next totem using hero.findNearestTotem()
nextTotem = hero.findNearestTotem()

# moveTo nextTotem
hero.moveTo(nextTotem)

```

JavaScript

```
//Assign firstTotem from hero.findNearestTotem()
var firstTotem = hero.findNearestTotem()

//Move to the first totem
hero.moveTo(firstTotem)

//Use firstTotem to change the illusion
hero.use(firstTotem)

//There's one more.
//Find the next totem using hero.findNearestTotem()
var nextTotem = hero.findNearestTotem()

//moveTo nextTotem
hero.moveTo(nextTotem)
```

## Hide and Hide

Python

```
# This artifact you should use the last
# Don't overwrite this variable
lastArtifact = "Inuisibilitas"

# Find a nearest artifact and say its name for your friend
firstTotem = hero.findNearestTotem()
hero.say(firstTotem)

# Repeat "find and say" for the second friend
secondTotem = hero.findNearestTotem()
hero.say(secondTotem)

# Move to and use the lastArtifact
hero.moveTo(lastArtifact)
hero.use(lastArtifact)
```

JavaScript

```
//This artifact you should use the last
//Don't overwrite this variable
var lastArtifact = "Inuisibilitas";

//Find a nearest artifact and say its name for your friend
var firstTotem = hero.findNearestTotem();
hero.say(firstTotem);

//Repeat "find and say" for the second friend
var secondTotem = hero.findNearestTotem();
hero.say(secondTotem);

//Move to and use the lastArtifact
hero.moveTo(lastArtifact);
hero.use(lastArtifact);
```

## Ignition

Python

```
# Find two nearest artifact and say their names for your friends

# Move to one of the red X marks
firstTotem = hero.findNearestTotem()
hero.say(firstTotem)

secondTotem = hero.findNearestTotem()
hero.say(secondTotem)

hero.moveLeft()
hero.moveUp()
hero.moveLeft()
```

JavaScript

```
//Find two nearest artifact and say their names for your friends

//Move to one of the red X marks
var firstTotem = hero.findNearestTotem()
hero.say(firstTotem)

var secondTotem = hero.findNearestTotem()
hero.say(secondTotem)

hero.moveLeft()
hero.moveUp()
hero.moveLeft()
```

## Phantom Fire

Python

```
# This is the name of the amplifier totem
amplifierTotem = "Amplificatus"

# Find, move to and use the nearest fire illusion totem
totem = hero.findNearestTotem()
hero.moveTo(totem)
hero.use(totem)

# Repeat it for the second totem
totem2 = hero.findNearestTotem()
hero.moveTo(totem2)
hero.use(totem2)

# Say the name of the amplifier totem for your friends.
hero.say(amplifierTotem)

```

JavaScript

```
//This is the name of the amplifier totem
var amplifierTotem = "Amplificatus"

//Find, move to and use the nearest fire illusion totem
var totem = hero.findNearestTotem()
hero.moveTo(totem)
hero.use(totem)

//Repeat it for the second totem
var totem2 = hero.findNearestTotem()
hero.moveTo(totem2)
hero.use(totem2)

//Say the name of the amplifier totem for your friends.
hero.say(amplifierTotem)
```

## Showtime

Python

```
# The secret number
secretNumber = 15485863

# Find, move to and use three (3) artifacts.
# Then say the secret number to start the show.
totem = hero.findNearestTotem()
hero.moveTo(totem)
hero.use(totem)

totem = hero.findNearestTotem()
hero.moveTo(totem)
hero.use(totem)

totem = hero.findNearestTotem()
hero.moveTo(totem)
hero.use(totem)

hero.say(secretNumber)

```

JavaScript

```
//The secret number
var secretNumber = 15485863;

//Find, move to and use three (3) artifacts.
//Then say the secret number to start the show.
var totem = hero.findNearestTotem()
hero.moveTo(totem)
hero.use(totem)

totem = hero.findNearestTotem()
hero.moveTo(totem)
hero.use(totem)

totem = hero.findNearestTotem()
hero.moveTo(totem)
hero.use(totem)

hero.say(secretNumber)
```
