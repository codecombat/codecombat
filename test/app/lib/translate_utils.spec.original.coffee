solutionsByLanguage = javascript: {}, lua: {}, python: {}, coffeescript: {}, java: {}, cpp: {}
solutionsByLanguage.javascript.dungeonsOfKithgard = """
  // Move towards the gem.
  // Don’t touch the spikes!
  // Type your code below and click Run when you’re done.

  hero.moveRight();
  hero.moveDown();
  hero.moveRight();
  """
solutionsByLanguage.javascript.peekABoom = """
  // Build traps on the path when the hero sees a munchkin!

  while(true) {
      var enemy = hero.findNearestEnemy();
      if(enemy) {
          // Build a "fire-trap" at the Red X (41, 24)
          hero.buildXY("fire-trap", 41, 24);
      }
      // Add an else below to move back to the clearing
      else {
          // Move to the Wooden X (19, 19)
          hero.moveXY(19, 19);
      }
  }
  """
solutionsByLanguage.javascript.woodlandCleaver = """
  // Use your new "cleave" skill as often as you can.

  hero.moveXY(23, 23);
  while(true) {
      var enemy = hero.findNearestEnemy();
      if(hero.isReady("cleave")) {
          // Cleave the enemy!
          hero.cleave(enemy);
      } else {
          // Else (if cleave isn't ready), do your normal attack.
          hero.attack(enemy);
      }
  }
"""
solutionsByLanguage.javascript.aFineMint = """
  // Peons are trying to steal your coins!
  // Write a function to squash them before they can take your coins.

  function pickUpCoin() {
      var coin = hero.findNearestItem();
      if(coin) {
          hero.moveXY(coin.pos.x, coin.pos.y);
      }
  }

  // Write the attackEnemy function below.
  // Find the nearest enemy and attack them if they exist!
  function attackEnemy() {
      var enemy = hero.findNearestEnemy();
      if(enemy) {
          hero.attack(enemy);
      }
  }

  while(true) {
      attackEnemy(); // Δ Uncomment this line after you write an attackEnemy function.
      pickUpCoin();
  }
  """
solutionsByLanguage.javascript.libraryTactician = """
  // Hushbaum has been ambushed by ogres!
  // She is busy healing her soldiers, you should command them to fight!
  // The ogres will send more troops if they think they can get to Hushbaum or your archers, so keep them inside the circle!

  var archerTarget = null;
  // Soldiers spread out in a circle and defend.
  function commandSoldier(soldier, soldierIndex, numSoldiers) {
      var angle = Math.PI * 2 * soldierIndex / numSoldiers;
      var defendPos = {x: 41, y: 40};
      defendPos.x += 10 * Math.cos(angle);
      defendPos.y += 10 * Math.sin(angle);
      hero.command(soldier, "defend", defendPos);
  }

  // Find the strongest target (most health)
  // This function returns something! When you call the function, you will get some value back.
  function findStrongestTarget() {
      var mostHealth = 0;
      var bestTarget = null;
      var enemies = hero.findEnemies();
      // Figure out which enemy has the most health, and set bestTarget to be that enemy.
      for(var i=0; i < enemies.length; i++) {
          var enemy = enemies[i];
          if(enemy.health > mostHealth) {
              bestTarget = enemy;
              mostHealth = enemy.health;
          }
      }
      // Only focus archers' fire if there is a big ogre.
      if (bestTarget && bestTarget.health > 15) {
          return bestTarget;
      } else {
          return null;
      }
  }


  // If the strongestTarget has more than 15 health, attack that target. Otherwise, attack the nearest target.
  function commandArcher(archer) {
      var nearest = archer.findNearestEnemy();
      if(archerTarget) {
          hero.command(archer, "attack", archerTarget);
      } else if(nearest) {
          hero.command(archer, "attack", nearest);
      }
  }


  while(true) {
      // If archerTarget is defeated or doesn't exist, find a new one.
      if(!archerTarget || archerTarget.health <= 0) {
          // Set archerTarget to be the target that is returned by findStrongestTarget()
          archerTarget = findStrongestTarget();
      }
      var soldiers = hero.findByType("soldier");
      // Create a variable containing your archers.
      var archers = hero.findByType("archer");
      for(var i=0; i < soldiers.length; i++) {
          var soldier = soldiers[i];
          commandSoldier(soldier, i, soldiers.length);
      }
      // use commandArcher() to command your archers
      for(i=0; i < archers.length; i++) {
          var archer = archers[i];
          commandArcher(archer);
      }
  }
  """
solutionsByLanguage.javascript.snowdrops = """
  // We need to clear the forest of traps!
  // The scout prepared a map of the forest.
  // But be careful where you shoot! Don't start a fire.

  // Get the map of the forest.
  var forestMap = hero.findNearest(hero.findFriends()).forestMap;

  // The map is a 2D array where 0 is a trap.
  // The first sure shot.
  hero.say("Row " + 0 + " Column " + 1 + " Fire!");

  // But for the next points, check before shooting.
  // There are an array of points to check.
  var cells = [{row: 0, col: 4}, {row: 1, col: 0}, {row: 1, col: 2}, {row: 1, col: 4},
      {row: 2, col: 1}, {row: 2, col: 3}, {row: 2, col: 5}, {row: 3, col: 0},
      {row: 3, col: 2}, {row: 3, col: 4}, {row: 4, col: 1}, {row: 4, col: 2},
      {row: 4, col: 3}, {row: 5, col: 0}, {row: 5, col: 3}, {row: 5, col: 5},
      {row: 6, col: 1}, {row: 6, col: 3}, {row: 6, col: 4}, {row: 7, col: 0}];

  for (var i = 0; i < cells.length; i++) {
      var row = cells[i].row;
      var col = cells[i].col;
      // If row is less than forestMap length:
      if (row < forestMap.length) {
          // If col is less than forestMap[row] length:
          if (col < forestMap[row].length) {
              // Now, we know the cell exists.
              // If it is 0, say where to shoot:
              if (forestMap[row][col] === 0) {
                  hero.say("Row " + row + " Column " + col + " Fire!");
              }
          }
      }
  }
"""

solutionsByLanguage.lua.dungeonsOfKithgard = """
  -- Move towards the gem.
  -- Don’t touch the spikes!
  -- Type your code below and click Run when you’re done.

  hero:moveRight()
  hero:moveDown()
  hero:moveRight()
  """
solutionsByLanguage.lua.peekABoom = """
  -- Build traps on the path when the hero sees a munchkin!

  while true do
      local enemy = hero:findNearestEnemy()
      if enemy then
          -- Build a "fire-trap" at the Red X (41, 24)
          hero:buildXY("fire-trap", 41, 24)
      -- Add an else below to move back to the clearing
      else
          -- Move to the Wooden X (19, 19)
          hero:moveXY(19, 19)
      end
  end
  """
solutionsByLanguage.lua.woodlandCleaver = """
  -- Use your new "cleave" skill as often as you can.

  hero:moveXY(23, 23)
  while true do
      local enemy = hero:findNearestEnemy()
      if hero:isReady("cleave") then
          -- Cleave the enemy!
          hero:cleave(enemy)
      else
          -- Else (if cleave isn't ready), do your normal attack.
          hero:attack(enemy)
      end
  end
"""
solutionsByLanguage.lua.aFineMint = """
  -- Peons are trying to steal your coins!
  -- Write a function to squash them before they can take your coins.

  function pickUpCoin()
      local coin = hero:findNearestItem()
      if coin then
          hero:moveXY(coin.pos.x, coin.pos.y)
      end
  end

  -- Write the attackEnemy function below.
  -- Find the nearest enemy and attack them if they exist!
  function attackEnemy()
      local enemy = hero:findNearestEnemy()
      if enemy then
          hero:attack(enemy)
      end
  end

  while true do
      attackEnemy() -- Δ Uncomment this line after you write an attackEnemy function.
      pickUpCoin()
  end
  """
solutionsByLanguage.lua.libraryTactician = """
  -- Hushbaum has been ambushed by ogres!
  -- She is busy healing her soldiers, you should command them to fight!
  -- The ogres will send more troops if they think they can get to Hushbaum or your archers, so keep them inside the circle!

  local archerTarget = nil
  -- Soldiers spread out in a circle and defend.
  function commandSoldier(soldier, soldierIndex, numSoldiers)
      local angle = Math.PI * 2 * soldierIndex / numSoldiers
      local defendPos = {x=41, y=40}
      defendPos.x = defendPos.x + 10 * Math.cos(angle)
      defendPos.y = defendPos.y + 10 * Math.sin(angle)
      hero:command(soldier, "defend", defendPos)
  end

  -- Find the strongest target (most health)
  -- This function returns something! When you call the function, you will get some value back.
  function findStrongestTarget()
      local mostHealth = 0
      local bestTarget = nil
      local enemies = hero:findEnemies()
      -- Figure out which enemy has the most health, and set bestTarget to be that enemy.
      for i, enemy in pairs(enemies) do
          if enemy.health > mostHealth then
              bestTarget = enemy
              mostHealth = enemy.health
          end
      end
      -- Only focus archers' fire if there is a big ogre.
      if bestTarget and bestTarget.health > 15 then
          return bestTarget
      else
          return nil
      end
  end


  -- If the strongestTarget has more than 15 health, attack that target. Otherwise, attack the nearest target.
  function commandArcher(archer)
      local nearest = archer:findNearestEnemy()
      if archerTarget then
          hero:command(archer, "attack", archerTarget)
      elseif nearest then
          hero:command(archer, "attack", nearest)
      end
  end


  while true do
      -- If archerTarget is defeated or doesn't exist, find a new one.
      if not archerTarget or archerTarget.health <= 0 then
          -- Set archerTarget to be the target that is returned by findStrongestTarget()
          archerTarget = findStrongestTarget()
      end
      local soldiers = hero:findByType("soldier")
      -- Create a variable containing your archers.
      local archers = hero:findByType("archer")
      for i, soldier in pairs(soldiers) do
          commandSoldier(soldier, i, #soldiers)
      end
      -- use commandArcher() to command your archers
      for i, archer in pairs(archers) do
          commandArcher(archer)
      end
  end
  """
solutionsByLanguage.lua.snowdrops = """
  -- We need to clear the forest of traps!
  -- The scout prepared a map of the forest.
  -- But be careful where you shoot! Don't start a fire.

  -- Get the map of the forest.
  local forestMap = hero:findNearest(hero:findFriends()).forestMap

  -- The map is a 2D array where 0 is a trap.
  -- The first sure shot.
  hero:say("Row " + 0 + " Column " + 1 + " Fire!")

  -- But for the next points, check before shooting.
  -- There are an array of points to check.
  local cells = {{row=0, col=4}, {row=1, col=0}, {row=1, col=2}, {row=1, col=4},
      {row=2, col=1}, {row=2, col=3}, {row=2, col=5}, {row=3, col=0},
      {row=3, col=2}, {row=3, col=4}, {row=4, col=1}, {row=4, col=2},
      {row=4, col=3}, {row=5, col=0}, {row=5, col=3}, {row=5, col=5},
      {row=6, col=1}, {row=6, col=3}, {row=6, col=4}, {row=7, col=0}}

  for i in pairs(cells) do
      local row = cells[i].row
      local col = cells[i].col
      -- If row is less than forestMap length:
      if row < #forestMap then
          -- If col is less than forestMap[row] length:
          if col < #forestMap[row + 1] then
              -- Now, we know the cell exists.
              -- If it is 0, say where to shoot:
              if forestMap[row + 1][col + 1] == 0 then
                  hero:say("Row " + row + " Column " + col + " Fire!")
              end
          end
      end
  end
"""

solutionsByLanguage.python.dungeonsOfKithgard = """
  # Move towards the gem.
  # Don’t touch the spikes!
  # Type your code below and click Run when you’re done.

  hero.moveRight()
  hero.moveDown()
  hero.moveRight()
  """
solutionsByLanguage.python.peekABoom = """
  # Build traps on the path when the hero sees a munchkin!

  while True:
      enemy = hero.findNearestEnemy()
      if enemy:
          # Build a "fire-trap" at the Red X (41, 24)
          hero.buildXY("fire-trap", 41, 24)
      # Add an else below to move back to the clearing
      else:
          # Move to the Wooden X (19, 19)
          hero.moveXY(19, 19)
  """
solutionsByLanguage.python.woodlandCleaver = """
  # Use your new "cleave" skill as often as you can.

  hero.moveXY(23, 23)
  while True:
      enemy = hero.findNearestEnemy()
      if hero.isReady("cleave"):
          # Cleave the enemy!
          hero.cleave(enemy)
      else:
          # Else (if cleave isn't ready), do your normal attack.
          hero.attack(enemy)
"""
solutionsByLanguage.python.aFineMint = """
  # Peons are trying to steal your coins!
  # Write a function to squash them before they can take your coins.

  def pickUpCoin():
      coin = hero.findNearestItem()
      if coin:
          hero.moveXY(coin.pos.x, coin.pos.y)

  # Write the attackEnemy function below.
  # Find the nearest enemy and attack them if they exist!
  def attackEnemy():
      enemy = hero.findNearestEnemy()
      if enemy:
          hero.attack(enemy)

  while True:
      attackEnemy() # Δ Uncomment this line after you write an attackEnemy function.
      pickUpCoin()
  """
solutionsByLanguage.python.libraryTactician = """
  # Hushbaum has been ambushed by ogres!
  # She is busy healing her soldiers, you should command them to fight!
  # The ogres will send more troops if they think they can get to Hushbaum or your archers, so keep them inside the circle!

  archerTarget = None
  # Soldiers spread out in a circle and defend.
  def commandSoldier(soldier, soldierIndex, numSoldiers):
      angle = Math.PI * 2 * soldierIndex / numSoldiers
      defendPos = {"x": 41, "y": 40}
      defendPos.x += 10 * Math.cos(angle)
      defendPos.y += 10 * Math.sin(angle)
      hero.command(soldier, "defend", defendPos)

  # Find the strongest target (most health)
  # This function returns something! When you call the function, you will get some value back.
  def findStrongestTarget():
      mostHealth = 0
      bestTarget = None
      enemies = hero.findEnemies()
      # Figure out which enemy has the most health, and set bestTarget to be that enemy.
      for i in range(len(enemies)):
          enemy = enemies[i]
          if enemy.health > mostHealth:
              bestTarget = enemy
              mostHealth = enemy.health
      # Only focus archers' fire if there is a big ogre.
      if bestTarget and bestTarget.health > 15:
          return bestTarget
      else:
          return None


  # If the strongestTarget has more than 15 health, attack that target. Otherwise, attack the nearest target.
  def commandArcher(archer):
      nearest = archer.findNearestEnemy()
      if archerTarget:
          hero.command(archer, "attack", archerTarget)
      elif nearest:
          hero.command(archer, "attack", nearest)


  while True:
      # If archerTarget is defeated or doesn't exist, find a new one.
      if not archerTarget or archerTarget.health <= 0:
          # Set archerTarget to be the target that is returned by findStrongestTarget()
          archerTarget = findStrongestTarget()
      soldiers = hero.findByType("soldier")
      # Create a variable containing your archers.
      archers = hero.findByType("archer")
      for i in range(len(soldiers)):
          soldier = soldiers[i]
          commandSoldier(soldier, i, len(soldiers))
      # use commandArcher() to command your archers
      for i in range(len(archers)):
          archer = archers[i]
          commandArcher(archer)
  """
solutionsByLanguage.python.snowdrops = """
  # We need to clear the forest of traps!
  # The scout prepared a map of the forest.
  # But be careful where you shoot! Don't start a fire.

  # Get the map of the forest.
  forestMap = hero.findNearest(hero.findFriends()).forestMap

  # The map is a 2D array where 0 is a trap.
  # The first sure shot.
  hero.say("Row " + 0 + " Column " + 1 + " Fire!")

  # But for the next points, check before shooting.
  # There are an array of points to check.
  cells = [{"row": 0, "col": 4}, {"row": 1, "col": 0}, {"row": 1, "col": 2}, {"row": 1, "col": 4},
      {"row": 2, "col": 1}, {"row": 2, "col": 3}, {"row": 2, "col": 5}, {"row": 3, "col": 0},
      {"row": 3, "col": 2}, {"row": 3, "col": 4}, {"row": 4, "col": 1}, {"row": 4, "col": 2},
      {"row": 4, "col": 3}, {"row": 5, "col": 0}, {"row": 5, "col": 3}, {"row": 5, "col": 5},
      {"row": 6, "col": 1}, {"row": 6, "col": 3}, {"row": 6, "col": 4}, {"row": 7, "col": 0}]

  for i in range(len(cells)):
      row = cells[i].row
      col = cells[i].col
      # If row is less than forestMap length:
      if row < len(forestMap):
          # If col is less than forestMap[row] length:
          if col < len(forestMap[row]):
              # Now, we know the cell exists.
              # If it is 0, say where to shoot:
              if forestMap[row][col] == 0:
                  hero.say("Row " + row + " Column " + col + " Fire!")
"""

solutionsByLanguage.coffeescript.dungeonsOfKithgard = """
  # Move towards the gem.
  # Don’t touch the spikes!
  # Type your code below and click Run when you’re done.

  hero.moveRight()
  hero.moveDown()
  hero.moveRight()
  """
solutionsByLanguage.coffeescript.peekABoom = """
  # Build traps on the path when the hero sees a munchkin!

  loop
      enemy = hero.findNearestEnemy()
      if enemy
          # Build a "fire-trap" at the Red X (41, 24)
          hero.buildXY "fire-trap", 41, 24
      # Add an else below to move back to the clearing
      else
          # Move to the Wooden X (19, 19)
          hero.moveXY 19, 19
  """
solutionsByLanguage.coffeescript.woodlandCleaver = """
  # Use your new "cleave" skill as often as you can.

  hero.moveXY 23, 23
  loop
      enemy = hero.findNearestEnemy()
      if hero.isReady "cleave"
          # Cleave the enemy!
          hero.cleave enemy
      else
          # Else (if cleave isn't ready), do your normal attack.
          hero.attack enemy
"""
solutionsByLanguage.coffeescript.aFineMint = """
  # Peons are trying to steal your coins!
  # Write a function to squash them before they can take your coins.

  pickUpCoin = ->
      coin = hero.findNearestItem()
      if coin
          hero.moveXY coin.pos.x, coin.pos.y

  # Write the attackEnemy function below.
  # Find the nearest enemy and attack them if they exist!
  attackEnemy = ->
      enemy = hero.findNearestEnemy()
      if enemy
          hero.attack enemy

  loop
      attackEnemy() # Δ Uncomment this line after you write an attackEnemy function.
      pickUpCoin()
  """
solutionsByLanguage.coffeescript.libraryTactician = """
  # Hushbaum has been ambushed by ogres!
  # She is busy healing her soldiers, you should command them to fight!
  # The ogres will send more troops if they think they can get to Hushbaum or your archers, so keep them inside the circle!

  archerTarget = null
  # Soldiers spread out in a circle and defend.
  commandSoldier = (soldier, soldierIndex, numSoldiers) ->
      angle = Math.PI * 2 * soldierIndex / numSoldiers
      defendPos = {x: 41, y: 40}
      defendPos.x += 10 * Math.cos angle
      defendPos.y += 10 * Math.sin angle
      hero.command soldier, "defend", defendPos

  # Find the strongest target (most health)
  # This function returns something! When you call the function, you will get some value back.
  findStrongestTarget = ->
      mostHealth = 0
      bestTarget = null
      enemies = hero.findEnemies()
      # Figure out which enemy has the most health, and set bestTarget to be that enemy.
      for enemy, i in enemies
          if enemy.health > mostHealth
              bestTarget = enemy
              mostHealth = enemy.health
      # Only focus archers' fire if there is a big ogre.
      if bestTarget and bestTarget.health > 15
          return bestTarget
      else
          return null


  # If the strongestTarget has more than 15 health, attack that target. Otherwise, attack the nearest target.
  commandArcher = (archer) ->
      nearest = archer.findNearestEnemy()
      if archerTarget
          hero.command archer, "attack", archerTarget
      else if nearest
          hero.command archer, "attack", nearest


  loop
      # If archerTarget is defeated or doesn't exist, find a new one.
      if not archerTarget or archerTarget.health <= 0
          # Set archerTarget to be the target that is returned by findStrongestTarget()
          archerTarget = findStrongestTarget()
      soldiers = hero.findByType "soldier"
      # Create a variable containing your archers.
      archers = hero.findByType "archer"
      for soldier, i in soldiers
          commandSoldier soldier, i, soldiers.length
      # use commandArcher() to command your archers
      for archer, i in archers
          commandArcher archer
  """
solutionsByLanguage.coffeescript.snowdrops = """
  # We need to clear the forest of traps!
  # The scout prepared a map of the forest.
  # But be careful where you shoot! Don't start a fire.

  # Get the map of the forest.
  forestMap = hero.findNearest(hero.findFriends()).forestMap

  # The map is a 2D array where 0 is a trap.
  # The first sure shot.
  hero.say "Row " + 0 + " Column " + 1 + " Fire!"

  # But for the next points, check before shooting.
  # There are an array of points to check.
  cells = [{row: 0, col: 4}, {row: 1, col: 0}, {row: 1, col: 2}, {row: 1, col: 4},
      {row: 2, col: 1}, {row: 2, col: 3}, {row: 2, col: 5}, {row: 3, col: 0},
      {row: 3, col: 2}, {row: 3, col: 4}, {row: 4, col: 1}, {row: 4, col: 2},
      {row: 4, col: 3}, {row: 5, col: 0}, {row: 5, col: 3}, {row: 5, col: 5},
      {row: 6, col: 1}, {row: 6, col: 3}, {row: 6, col: 4}, {row: 7, col: 0}]

  for i in [0...cells.length]
      row = cells[i].row
      col = cells[i].col
      # If row is less than forestMap length:
      if row < forestMap.length
          # If col is less than forestMap[row] length:
          if col < forestMap[row].length
              # Now, we know the cell exists.
              # If it is 0, say where to shoot:
              if forestMap[row][col] is 0
                  hero.say "Row " + row + " Column " + col + " Fire!"
"""

solutionsByLanguage.java.dungeonsOfKithgard = """
  // Move towards the gem.
  // Don’t touch the spikes!
  // Type your code below and click Run when you’re done.

  public class AI {
      public static void main(String[] args) {
          hero.moveRight();
          hero.moveDown();
          hero.moveRight();
      }
  }
  """
solutionsByLanguage.java.peekABoom = """
  // Build traps on the path when the hero sees a munchkin!

  public class AI {
      public static void main(String[] args) {
          while(true) {
              var enemy = hero.findNearestEnemy();
              if(enemy) {
                  // Build a "fire-trap" at the Red X (41, 24)
                  hero.buildXY("fire-trap", 41, 24);
              }
              // Add an else below to move back to the clearing
              else {
                  // Move to the Wooden X (19, 19)
                  hero.moveXY(19, 19);
              }
          }
      }
  }
  """
solutionsByLanguage.java.woodlandCleaver = """
  // Use your new "cleave" skill as often as you can.

  public class AI {
      public static void main(String[] args) {
          hero.moveXY(23, 23);
          while(true) {
              var enemy = hero.findNearestEnemy();
              if(hero.isReady("cleave")) {
                  // Cleave the enemy!
                  hero.cleave(enemy);
              } else {
                  // Else (if cleave isn't ready), do your normal attack.
                  hero.attack(enemy);
              }
          }
      }
  }
"""
solutionsByLanguage.java.aFineMint = """
  // Peons are trying to steal your coins!
  // Write a function to squash them before they can take your coins.

  public class AI {
      public static void pickUpCoin() {
          var coin = hero.findNearestItem();
          if(coin) {
              hero.moveXY(coin.pos.x, coin.pos.y);
          }
      }

      // Write the attackEnemy function below.
      // Find the nearest enemy and attack them if they exist!
      public static void attackEnemy() {
          var enemy = hero.findNearestEnemy();
          if(enemy) {
              hero.attack(enemy);
          }
      }

      public static void main(String[] args) {
          while(true) {
              attackEnemy(); // Δ Uncomment this line after you write an attackEnemy function.
              pickUpCoin();
          }
      }
  }
  """
solutionsByLanguage.java.libraryTactician = """
  // Hushbaum has been ambushed by ogres!
  // She is busy healing her soldiers, you should command them to fight!
  // The ogres will send more troops if they think they can get to Hushbaum or your archers, so keep them inside the circle!

  public class AI {
      var archerTarget = null;
      // Soldiers spread out in a circle and defend.

      public static void commandSoldier(Object soldier, Object soldierIndex, Object numSoldiers) {
          var angle = Math.PI * 2 * soldierIndex / numSoldiers;
          var defendPos = {41, 40};
          defendPos.x += 10 * Math.cos(angle);
          defendPos.y += 10 * Math.sin(angle);
          hero.command(soldier, "defend", defendPos);
      }

      public static Object findStrongestTarget() {
          var mostHealth = 0;
          var bestTarget = null;
          var enemies = hero.findEnemies();
          // Figure out which enemy has the most health, and set bestTarget to be that enemy.
          for(int i=0; i < enemies.length; i++) {
              var enemy = enemies[i];
              if(enemy.health > mostHealth) {
                  bestTarget = enemy;
                  mostHealth = enemy.health;
              }
          }
          // Only focus archers' fire if there is a big ogre.
          if (bestTarget && bestTarget.health > 15) {
              return bestTarget;
          } else {
              return null;
          }
      }

      public static void commandArcher(Object archer) {
          var nearest = archer.findNearestEnemy();
          if(archerTarget) {
              hero.command(archer, "attack", archerTarget);
          } else if(nearest) {
              hero.command(archer, "attack", nearest);
          }
      }

      public static void main(String[] args) {
          while(true) {
              // If archerTarget is defeated or doesn't exist, find a new one.
              if(!archerTarget || archerTarget.health <= 0) {
                  // Set archerTarget to be the target that is returned by findStrongestTarget()
                  archerTarget = findStrongestTarget();
              }
              var soldiers = hero.findByType("soldier");
              // Create a variable containing your archers.
              var archers = hero.findByType("archer");
              for(int i=0; i < soldiers.length; i++) {
                  var soldier = soldiers[i];
                  commandSoldier(soldier, i, soldiers.length);
              }
              // use commandArcher() to command your archers
              for(i=0; i < archers.length; i++) {
                  var archer = archers[i];
                  commandArcher(archer);
              }
          }
      }
  }
  """
solutionsByLanguage.java.snowdrops = """
  int main() {
      // We need to clear the forest of traps!
      // The scout prepared a map of the forest.
      // But be careful where you shoot! Don't start a fire.

      // Get the map of the forest.
      auto forestMap = hero.findNearest(hero.findFriends()).forestMap;

      // The map is a 2D array where 0 is a trap.
      // The first sure shot.
      hero.say("Row " + 0 + " Column " + 1 + " Fire!");

      // But for the next points, check before shooting.
      // There are an array of points to check.
      auto cells = {{0, 4}, {1, 0}, {1, 2}, {1, 4},
          {2, 1}, {2, 3}, {2, 5}, {3, 0},
          {3, 2}, {3, 4}, {4, 1}, {4, 2},
          {4, 3}, {5, 0}, {5, 3}, {5, 5},
          {6, 1}, {6, 3}, {6, 4}, {7, 0}};

      for (int i = 0; i < cells.size(); i++) {
          auto row = cells[i].x;
          auto col = cells[i].y;
          // If row is less than forestMap length:
          if (row < forestMap.length) {
              // If col is less than forestMap[row] length:
              if (col < forestMap[row].size()) {
                  // Now, we know the cell exists.
                  // If it is 0, say where to shoot:
                  if (forestMap[row][col] == 0) {
                      hero.say("Row " + row + " Column " + col + " Fire!");
                  }
              }
          }
      }
      return 0;
  }
"""

solutionsByLanguage.cpp.dungeonsOfKithgard = """
  // Move towards the gem.
  // Don’t touch the spikes!
  // Type your code below and click Run when you’re done.

  int main() {
      hero.moveRight();
      hero.moveDown();
      hero.moveRight();
      return 0;
  }
  """
solutionsByLanguage.cpp.peekABoom = """
  // Build traps on the path when the hero sees a munchkin!

  int main() {
      while(true) {
          auto enemy = hero.findNearestEnemy();
          if(enemy) {
              // Build a "fire-trap" at the Red X (41, 24)
              hero.buildXY("fire-trap", 41, 24);
          }
          // Add an else below to move back to the clearing
          else {
              // Move to the Wooden X (19, 19)
              hero.moveXY(19, 19);
          }
      }
      return 0;
  }
  """
solutionsByLanguage.cpp.woodlandCleaver = """
  // Use your new "cleave" skill as often as you can.

  int main() {
      hero.moveXY(23, 23);
      while(true) {
          auto enemy = hero.findNearestEnemy();
          if(hero.isReady("cleave")) {
              // Cleave the enemy!
              hero.cleave(enemy);
          } else {
              // Else (if cleave isn't ready), do your normal attack.
              hero.attack(enemy);
          }
      }
      return 0;
  }
"""
solutionsByLanguage.cpp.aFineMint = """
  // Peons are trying to steal your coins!
  // Write a function to squash them before they can take your coins.

  auto pickUpCoin() {
      auto coin = hero.findNearestItem();
      if(coin) {
          hero.moveXY(coin.pos.x, coin.pos.y);
      }
  }

  // Write the attackEnemy function below.
  // Find the nearest enemy and attack them if they exist!
  auto attackEnemy() {
      auto enemy = hero.findNearestEnemy();
      if(enemy) {
          hero.attack(enemy);
      }
  }

  int main() {
      while(true) {
          attackEnemy(); // Δ Uncomment this line after you write an attackEnemy function.
          pickUpCoin();
      }
      return 0;
  }
  """
solutionsByLanguage.cpp.libraryTactician = """
  // Hushbaum has been ambushed by ogres!
  // She is busy healing her soldiers, you should command them to fight!
  // The ogres will send more troops if they think they can get to Hushbaum or your archers, so keep them inside the circle!

  // Soldiers spread out in a circle and defend.
  auto commandSoldier(auto soldier, auto soldierIndex, auto numSoldiers) {
      auto angle = Math.PI * 2 * soldierIndex / numSoldiers;
      auto defendPos = {41, 40};
      defendPos.x += 10 * Math.cos(angle);
      defendPos.y += 10 * Math.sin(angle);
      hero.command(soldier, "defend", defendPos);
  }

  // Find the strongest target (most health)
  // This function returns something! When you call the function, you will get some value back.
  auto findStrongestTarget() {
      auto mostHealth = 0;
      auto bestTarget = null;
      auto enemies = hero.findEnemies();
      // Figure out which enemy has the most health, and set bestTarget to be that enemy.
      for(int i=0; i < enemies.size(); i++) {
          auto enemy = enemies[i];
          if(enemy.health > mostHealth) {
              bestTarget = enemy;
              mostHealth = enemy.health;
          }
      }
      // Only focus archers' fire if there is a big ogre.
      if (bestTarget && bestTarget.health > 15) {
          return bestTarget;
      } else {
          return null;
      }
  }

  // If the strongestTarget has more than 15 health, attack that target. Otherwise, attack the nearest target.
  auto commandArcher(auto archer) {
      auto nearest = archer.findNearestEnemy();
      if(archerTarget) {
          hero.command(archer, "attack", archerTarget);
      } else if(nearest) {
          hero.command(archer, "attack", nearest);
      }
  }


  auto archerTarget = null;



  int main() {
      while(true) {
          // If archerTarget is defeated or doesn't exist, find a new one.
          if(!archerTarget || archerTarget.health <= 0) {
              // Set archerTarget to be the target that is returned by findStrongestTarget()
              archerTarget = findStrongestTarget();
          }
          auto soldiers = hero.findByType("soldier");
          // Create a variable containing your archers.
          auto archers = hero.findByType("archer");
          for(int i=0; i < soldiers.size(); i++) {
              auto soldier = soldiers[i];
              commandSoldier(soldier, i, soldiers.size());
          }
          // use commandArcher() to command your archers
          for(i=0; i < archers.size(); i++) {
              auto archer = archers[i];
              commandArcher(archer);
          }
      }
      return 0;
  }
"""
solutionsByLanguage.cpp.snowdrops = """
  // We need to clear the forest of traps!
  // The scout prepared a map of the forest.
  // But be careful where you shoot! Don't start a fire.

  int main() {
      // Get the map of the forest.
      auto forestMap = hero.findNearest(hero.findFriends()).forestMap;

      // The map is a 2D array where 0 is a trap.
      // The first sure shot.
      hero.say("Row " + 0 + " Column " + 1 + " Fire!");

      // But for the next points, check before shooting.
      // There are an array of points to check.
      auto cells = {{0, 4}, {1, 0}, {1, 2}, {1, 4},
          {2, 1}, {2, 3}, {2, 5}, {3, 0},
          {3, 2}, {3, 4}, {4, 1}, {4, 2},
          {4, 3}, {5, 0}, {5, 3}, {5, 5},
          {6, 1}, {6, 3}, {6, 4}, {7, 0}};

      for (int i = 0; i < cells.size(); i++) {
          auto row = cells[i].x;
          auto col = cells[i].y;
          // If row is less than forestMap length:
          if (row < forestMap.size()) {
              // If col is less than forestMap[row] length:
              if (col < forestMap[row].size()) {
                  // Now, we know the cell exists.
                  // If it is 0, say where to shoot:
                  if (forestMap[row][col] == 0) {
                      hero.say("Row " + row + " Column " + col + " Fire!");
                  }
              }
          }
      }
      return 0;
  }
"""

levenshteinDistance = (str1, str2) ->
  # Simple edit distance measurement between two strings
  m = str1.length
  n = str2.length
  d = []

  return n  unless m
  return m  unless n

  d[i] = [i] for i in [0..m]
  d[0][j] = j for j in [1..n]

  for i in [1..m]
    for j in [1..n]
      if str1[i-1] is str2[j-1]
        d[i][j] = d[i-1][j-1]
      else
        d[i][j] = Math.min(
          d[i-1][j]
          d[i][j-1]
          d[i-1][j-1]
        ) + 1

  d[m][n]

xdescribe 'Aether / code transpilation utility library', ->
  translateUtils = require '../../../app/lib/translate-utils'

  describe 'translateJS(jsCode, "cpp", fullCode)', ->
    describe 'do not add int main if fullCode set false', ->
      it 'if there is no pattern needing translation', ->
        expect(translateUtils.translateJS('hero.moveRight()', 'cpp', false)).toBe('hero.moveRight()')
      it 'if there is var x or var y', ->
        expect(translateUtils.translateJS('var x = 2;\nvar y = 3', 'cpp', false)).toBe('float x = 2;\nfloat y = 3')
      it 'if there is ===/!==', ->
        expect(translateUtils.translateJS('if (a === 2 && b !== 1)', 'cpp', false)).toBe('if (a == 2 && b != 1)')
      it 'if there is other var', ->
        expect(translateUtils.translateJS('var enemy = hero...', 'cpp', false)).toBe('auto enemy = hero...')
      it 'if there is a function definition', ->
        expect(translateUtils.translateJS('function a() {}\n', 'cpp', false)).toBe('auto a() {}\n')

    describe 'add int main if fullCode set true', ->
      it 'if there is no pattern needing translation', ->
        expect(translateUtils.translateJS('hero.moveRight();'), 'cpp').toBe('int main() {\n    hero.moveRight();\n    return 0;\n}')
      it 'if there is var x or var y', ->
        expect(translateUtils.translateJS('var x = 2;\nvar y = 3;', 'cpp')).toBe('int main() {\n    float x = 2;\n    float y = 3;\n    return 0;\n}')
      it 'if there is ===/!==', ->
        expect(translateUtils.translateJS('while (a === 2 && b !== 1)', 'cpp')).toBe('int main() {\n    while (a == 2 && b != 1)\n    return 0;\n}')
      it 'if there is other var', ->
        expect(translateUtils.translateJS('var enemy = hero...', 'cpp')).toBe('int main() {\n    auto enemy = hero...\n    return 0;\n}')
      it 'if there is a function definition', ->
        expect(translateUtils.translateJS('function a() {}\n', 'cpp')).toBe('auto a() {}\n\nint main() {\n    \n    return 0;\n}')
      it 'if there is a function definition with parameter', ->
        expect(translateUtils.translateJS('function a(b) {}\n', 'cpp')).toBe('auto a(auto b) {}\n\nint main() {\n    \n    return 0;\n}')
      it 'if there is a function definition with parameters', ->
        expect(translateUtils.translateJS('function a(b, c) {}\na();', 'cpp')).toBe('auto a(auto b, auto c) {}\n\nint main() {\n    a();\n    return 0;\n}')

    describe 'if there are start comments', ->
      it 'if there is no code', ->
        expect(translateUtils.translateJS('//abc\n//def\n\n', 'cpp')).toBe('//abc\n//def\n\nint main() {\n    \n    return 0;\n}')
      it 'if there is code without function definition', ->
        expect(translateUtils.translateJS('//abc\n\nhero.moveRight()', 'cpp')).toBe('//abc\n\nint main() {\n    hero.moveRight()\n    return 0;\n}')
      it 'if there is code with function definition', ->
        expect(translateUtils.translateJS('//abc\n\nfunction a(b, c) {}\nhero.moveRight()', 'cpp')).toBe('//abc\n\nauto a(auto b, auto c) {}\n\nint main() {\n    hero.moveRight()\n    return 0;\n}')

  describe 'translateJS can handle full solutions', ->
    unsupported = [
      # Permanent (must write these solutions manually)
      ['lua', 'snowdrops']  # manual rewriting needed for off-by-one error with 1-indexed arrays for row/col in the map
      ['cpp', 'snowdrops']  # row/col literals need to be manually rewritten to x/y for our {x, y} Vector hack
      ['java', 'snowdrops']  # row/col literals need to be manually rewritten to [row, col] arrays, also indexed with [0] and [1]
      # Temporary (should fix the code generation to be smarter)
      ['java', 'libraryTactician']  # Need to auto-detect self-defined function return type
      ['java', 'aFineMint']  # Need to not strip out each hoisted function's start comments
      ['cpp', 'aFineMint']  # Need to not strip out each hoisted function's start comments
    ]
    targetLanguage = ''
    targetLevel = ''
    for language, solutions of solutionsByLanguage when language isnt 'javascript'
      do (language, solutions) ->
        describe 'in ' + language, ->
          for level, code of solutions
            do (level, code) ->
              if _.find(unsupported, ([lang, lev]) -> lang is language and lev is level)
                f = xit
              else if not targetLevel and not targetLanguage
                f = it
              else if (targetLevel and level is targetLevel) or (targetLanguage and language is targetLanguage)
                f = fit
              else
                f = it
              f 'properly translates ' + level, ->
                js = solutionsByLanguage.javascript[level]
                translated = translateUtils.translateJS js, language, true
                editDistance = levenshteinDistance translated, code
                expect('\n' + translated).toEqual('\n' + code)
                expect(editDistance).toEqual(0)
