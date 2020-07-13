##### Chapter 1 Level Solutions
# Levels: Following the Signs - Hungry Hungry Avatars

### Practice Level: Following the Signs

**Python**

```
hero.moveUp()
hero.moveUp()
```

**JavaScript**

```
hero.moveUp();
hero.moveUp();
```

### Practice Level: Around the Pond

**Python**

```
#first correct solution
hero.moveUp()
hero.moveRight()
hero.moveUp()
hero.moveUp()

#second correct solution
hero.moveUp()
hero.moveUp()
hero.moveRight()
hero.moveUp()
```

**JavaScript**

```
//first correct solution
hero.moveUp();
hero.moveRight();
hero.moveUp();
hero.moveUp();


//second correct solution
hero.moveUp();
hero.moveUp();
hero.moveRight();
hero.moveUp()
```

### Practice Level: The Lonely Tower

**Python**

```
hero.moveLeft()
hero.moveUp()
hero.moveRight()
hero.use("door")
```

**JavaScript**

```
hero.moveLeft();
hero.moveUp();
hero.moveRight();
hero.use("door");
```

### Practice Level: The Acodus

**Python**

```
#first correct solution
hero.moveRight()
hero.moveUp()
hero.moveUp()
hero.moveLeft()
hero.use("artifact")

#second correct solution
hero.moveLeft()
hero.moveUp()
hero.moveUp()
hero.moveRight()
hero.use("artifact")
```

**JavaScript**

```
//first correct solution
hero.moveRight();
hero.moveUp();
hero.moveUp();
hero.moveLeft();
hero.use("artifact");


//second correct solution
hero.moveLeft();
hero.moveUp();
hero.moveUp();
hero.moveRight();
hero.use("artifact");
```

### Capstone Level: Hungry Hungry Avatars 
_Your students will have written different code depending on design choices they made for their project, the example below demonstrates the syntax required for each stage._

**Python**

```
#Stage One - set the art for avatars
avatars.setArt("rose")


#Stage Two - set the default speed for avatars
avatars.setSpeed(20)


#Stage Three - set four more properties for avatars
avatars.setMinSpeed(16)
avatars.setSize(3)
avatars.setConsumeMultiplier(1)
avatars.setConsumeThreshold(1)


#Stage Four - set properties for resources and power ups
resources.setArt("star")
resources.setMaxNumber(30)
resources.setSpawnInterval(0)
powerUps.setArt("starfish")
powerUps.setMaxNumber(20)
powerUps.setSpawnInterval(2)


#Stage Five - set game properties
game.setMapSize("medium")
game.setEnvironment("space")


#Stage Six - set game input
game.setInputKeyboard("wasd")
game.setInputMouse("followMouse")
game.setInputSpecialKey("space")


#Stage Seven - set bot AI
game.setBotAI("easy");


#Stage Eight - set score rules
game.setScoreResources(10)
game.setScorePowerUps(50)
game.setScoreAvatars(100)
game.setWinScore(101)


#Stage Nine - set ui elements
ui.setTextDirections("This is how you play the game.")
ui.setTextVictory("You won! Congratulations!")
```

**JavaScript**

```
//Stage One - set the art for avatars
avatars.setArt("rose");

//Stage Two - set the default speed for avatars
avatars.setSpeed(20);

//Stage Three - set four more properties for avatars
avatars.setMinSpeed(16);
avatars.setSize(3);
avatars.setConsumeMultiplier(1);
avatars.setConsumeThreshold(1);

//Stage Four - set properties for resources and power ups
resources.setArt("star");
resources.setMaxNumber(30);
resources.setSpawnInterval(0);
powerUps.setArt("starfish");
powerUps.setMaxNumber(20);
powerUps.setSpawnInterval(2);

//Stage Five - set game properties
game.setMapSize("medium");
game.setEnvironment("space");

//Stage Six - set game input
game.setInputKeyboard("wasd");
game.setInputMouse("followMouse");
game.setInputSpecialKey("space");

//Stage Seven - set bot AI
game.setBotAI("easy");

//Stage Eight - set score rules
game.setScoreResources(10);
game.setScorePowerUps(50);
game.setScoreAvatars(100);
game.setWinScore(101);

//Stage Nine - set ui elements
ui.setTextDirections("This is how you play the game.");
ui.setTextVictory("You won! Congratulations!");

```
