{me} = require('lib/auth')

# If we use marked somewhere else, we'll have to make sure to preserve options
marked.setOptions {gfm: true, sanitize: false, smartLists: true, breaks: true}

markedWithImages = (s) ->
  s = s.replace /!\[(.*?)\]\((.+)? (\d+) (\d+) ?(.*?)?\)/g, '<img src="/images/docs/$2" alt="$1" title="$1" style="width: $3px; height: $4px;" class="$5"></img>'  # setting width/height attrs doesn't prevent flickering, but inline css does
  marked(s)

module.exports.getDocsFor = (thang, props, isSnippet=false) ->
  docs = []
  types = {}
  for prop in props ? []
    type = if isSnippet then 'snippet' else typeof thang[prop]
    (types[type] ?= []).push prop
  order = ["function", "object", "string", "number", "boolean", "undefined", "snippet"]
  order.push type for type of types when not (type in order)
  for type in order
    for prop in (types[type] ? [])
      docClass = if D.hasOwnProperty prop then D[prop] else Doc
      docs.push new docClass(thang, prop, type)
  docs

module.exports.hasLevelDocs = (levelID) ->
  D[levelID]?

module.exports.getLevelDocs = (levelID, world) ->
  levelDocsClass = D[levelID] ? Level
  new levelDocsClass world

module.exports.Doc = class Doc
  writable: false
  owner: "this"
  constructor: (@thang, @prop, @type) ->
    if @owner isnt "this"
      @type = typeof window[@owner][@prop]
    @buildShortName()

  buildShortName: ->
    @shortName = @prop
    if @type is 'function' then @shortName += "()"
    if @type isnt 'snippet' then @shortName = "#{@owner}.#{@shortName}"
    @shorterName = @shortName.replace 'this.', ''
    @shortName += ';'

  title: ->
    typeStr = @type
    if @type is 'function' and @owner is 'this'
      typeStr = 'method'
    if @type isnt 'function' and not @writable
      typeStr += ' (read-only)'
    nameStr = @shortName
    """<h4>#{nameStr} - <code class=\"prop-type\">#{typeStr}</code></h4>"""

  html: ->
    s = markedWithImages(@doc())
    if @type in ['function', 'snippet']
      exampleCode = @example()
      if exampleCode.split('\n').length > 1
        exampleCode = "```\n#{exampleCode}```"
      else
        exampleCode = "`#{exampleCode}`"
      s += marked("**Example**:\n#{exampleCode}")
      args = @args?() or []
      if args.length
        s += marked("**Arguments**:")
        s += (arg.html() for arg in args).join('')
    else
      s += @value()
    s

  value: ->
    """
    <strong>Current value</strong>:
    <code class=\"current-value\" data-prop=\"#{@prop}\">#{@formatValue()}</code>
    """

  doc: ->
    """
    This does something. I think.
    """

  example: ->
    s = "#{@owner}.#{@shortName};"
    if @type is 'function'
      exampleArgs = (arg.example ? arg.default ? arg.name for arg in @args?() ? []).join ', '
      s = "#{@owner}.#{@prop}(#{exampleArgs});"
    s

  formatValue: ->
    if @owner is 'this'
      v = @thang[@prop]
    else
      v = window[@owner][@prop]
    if @type is 'number' and not isNaN v
      if v == Math.round v
        return v
      return v.toFixed 2
    if _.isString v
      return "\"#{v}\""
    v

module.exports.Arg = class Arg
  constructor: (@name, @type, @example, @description, @default) ->

  html: ->
    s = "`#{@name}`: `#{@type}`"
    if @example then s += " (ex: `#{@example}`)"
    if @description then s += "\n#{@description}"
    if @default? then s += "\n*Default value*: `#{@default}`"
    marked s

module.exports.Level = class Level
  constructor: (@world) ->

  docID: (docName="doc") ->
    "level-doc-#{docName}"

  html: (docName="doc", title, buttons) ->
    forVictory = docName is "victory"
    docID = @docID docName
    title ?= @world.name + (if forVictory then " Complete" else "")
    docHTML = if @[docName] then markedWithImages(@[docName]()) else "No #{docName}. Wail!"
    if forVictory
      buttonHTML = @victoryButtons()
    else
      buttonHTML = @buttons(buttons ? ["I'm Ready."])
    """<div id="#{docID}" class="level-doc modal hide fade" tabindex="-1">
         <div class="modal-header">
           <button type="button" class="close" data-dismiss="modal">×</button>
           <h3>#{title}</h3>
         </div>
         <div class="modal-body">
           #{docHTML}
         </div>
         <div class="modal-footer">
           #{buttonHTML}
         </div>
       </div>
    """

  doc: ->
    """
    Venusaur? Oh no, counterattack with whatever you feel like, man!
    """

  victory: ->
    """
    Detect it, it it no going and you tell me do things I done runnin'.
    """

  buttons: (names) ->
    buttonHTML = []
    for name in names
      buttonHTML.push(
        """
          <button class="btn btn-primary" data-dismiss="modal">#{name}</button>
        """
      )
    buttonHTML.join ' '

  victoryButtons: ->
    buttons = """
    <button id="victory-stay" data-dismiss="modal" class="btn">Stay A While</button>
    <a href="/" class="btn">Go Home</a>
    """
    if me.get 'anonymous'
      buttons += """
    <button class="btn btn-success sign-up-button">Sign Up for Updates</button>
    """
    if @world.nextLevel
      buttons += """
    <a href="/play/level/#{@world.nextLevel}" class="btn btn-primary" data-dismiss="modal" >Next Level</a>
    """
    buttons += """
    <div class="share-buttons">
      <div class="g-plusone" data-href="http://codecombat.com" data-size="medium"></div>
      <div class="fb-like" data-href="http://codecombat.com" data-send="false" data-layout="button_count" data-width="350" data-show-faces="true"></div>
      </div>
    """
    buttons


D = {}  # save typing for all these things
# Markdown: http://daringfireball.net/projects/markdown/syntax
# GitHub Flavored Markdown: https://help.github.com/articles/github-flavored-markdown
# Our Markdown parser and compiler: https://github.com/chjj/marked
# I have extended the img syntax to take width and height (preventing flicker).

D.ifElse = class IfElse extends Doc
  buildShortName: ->
    @shortName = @shorterName = "if/else"

  doc: ->
    """
    The `if` control statement lets you choose whether to run the following code based on whether the condition evaluates truthily.

    You can add an optional `else` clause to run instead when the condition evaluates falsily.
    """

  example: ->
    """
    if(2 + 2 === 4) {
        // Code here
    }
    else {
        // Code here
    }
    """

D.forLoop = class ForLoop extends Doc
  buildShortName: ->
    @shortName = @shorterName = "for-loop"

  doc: ->
    """
    The `for` loop lets you run code many times. It has four parts:

    * initial setup: `var i = 0;`  (run at the beginning)
    * loop condition: `i < 10;`  (code runs while this is true)
    * loop iteration: `i += 1`  (runs after every iteration)
    * main loop code: `console.log("Counted to", i);`
    """

  example: ->
    """
    for(var i = 0; i < 10; i += 1) {
        // Code here
    }
    """

D.whileLoop = class WhileLoop extends Doc
  buildShortName: ->
    @shortName = @shorterName = "while-loop"

  doc: ->
    """
    The `while` loop lets you run code many times--as long as the condition is true.
    """

  example: ->
    """
    var i = 10;
    while(i < 10) {
        // Code here
        i -= 1;
    }
    """

D.rotateTo = class RotateTo extends Doc
  doc: ->
    """
    The `rotateTo` method rotates the #{@thang.spriteName}. ![Rotation of 0° points to the right, 90° points up, etc.](rotate.png 160 160)

    Use this method to change the direction that the #{@thang.spriteName} shoots.
    """

  args: ->
    [new Arg "degrees", "number", "180", "Desired rotation in degrees"]

D.shoot = class Shoot extends Doc
  doc: ->
    """
    Calling `this.shoot();` makes the #{@thang.spriteName} choose the `shoot` action.

    It's equivalent to: `this.setAction(this.actions.shoot);`
    """

D.pos = class Pos extends Doc
  doc: ->
    """
    The `x` (horizontal) and `y` (vertical) coordinates of the #{@thang.spriteName}'s center.
    """

D.rotation = class Rotation extends Doc
  doc: ->
    """
    The #{@thang.spriteName}'s rotation in radians (`0` to `2 * Math.PI`).

    Use the `rotateTo` method to set this value.
    """

D.degrees = class Degrees extends Doc
  doc: ->
    """
    The #{@thang.spriteName}'s rotation in degrees (`0` to `360`).

    Use the `rotateTo` method to set this value.
    """

D.attackRange = class AttackRange extends Doc
  doc: ->
    """
    How far the #{@thang.spriteName}'s attack reaches, in meters.
    """

D.health = class Health extends Doc
  doc: ->
    """
    How many health points the #{@thang.spriteName} has left.
    """

D.team = class Team extends Doc
  doc: ->
    """
    What team the #{@thang.spriteName} is on.
    """

D.actions = class Actions extends Doc
  doc: ->
    """
    The #{@thang.spriteName}'s available actions.

    To, say, move, use: `this.setAction("move");`
    """

  formatValue: () ->
    v = @thang[@prop]
    '[' + ("\"#{actionName}\"" for actionName of v).join(', ') + ']'

D.action = class Action extends Doc
  doc: ->
    """
    The current action the #{@thang.spriteName} is running.

    To change this, use the `setAction` method.
    """

D.setAction = class SetAction extends Doc
  doc: ->
    """
    Sets the action that the #{@thang.spriteName} is running. Only actions in `this.actions` are valid.
    """
    #For example, if `this.action` is currently `"idle"` and you want it to move instead, you'd set a target location, then: `this.setAction("move");`

  args: ->
    exampleAction = "idle"
    for action in ["move", "shoot", "attack"]
      if @thang.actions[action]
        exampleAction = action
        break
    unless exampleAction
      exampleAction = _.some @thang.actions, "name"
    exampleAction = "\"#{exampleAction}\""
    [new Arg "action", "object", exampleAction, "The action to perform (must be one of `this.actions`)."]

D.target = class Target extends Doc
  doc: ->
    """
    The current target upon which the #{@thang.spriteName} is running its `action`.

    To change this, use the `setTarget` method.
    """

  formatValue: () ->
    v = @thang[@prop]
    if v? then v.toString() else 'null'

D.setTarget = class SetTarget extends Doc
  doc: ->
    """
    Sets what the #{@thang.spriteName} is targeting with its current `action`, such as an enemy to attack or a position to move to.
    """
    #For example, if `this.action` is currently `this.actions.move`, the #{@thang.spriteName} will move toward its `target`; if its action is `this.actions.attack`, it will try to attack its target.
    #For some actions, you can also pass `x` and `y` coordinates as a target instead of another unit: `this.setTarget(65, 40);`

  args: ->
    exampleTarget = "65, 40"
    for [methods, code] in [[["getNearestEnemy"], "this.getNearestEnemy()"],
                            [["pos", "move"], "this.pos.x + 20, this.pos.y - 20"],
                            [["attack"], "enemy"],
                            [["shoot"], "enemy"]]
      if (m for m in methods when m in @thang.programmableProperties).length
        exampleTarget = code
        break

    [new Arg "target", "object", exampleTarget, "The new target upon which to act."]

D.chooseAction = class ChooseAction extends Doc
  doc: ->
    """
    The `chooseAction` method is run every frame, allowing the #{@thang.spriteName} a chance to look at the world and decide what action to pursue this frame.

    To see available actions, hover over the `actions` property below. To choose an action, say `attack`, you can write: `this.setAction(this.actions.attack);`
    """

D.plan = class Plan extends Doc
  doc: ->
    """
    The `plan` method (spell) is where you write a sequence of methods (spells) to command the #{@thang.spriteName}.

    Type your methods into the Spell Editor below. Hover over your available methods at the bottom to see what they do.
    """

  example: ->
    """
    this.moveRight();
    this.moveRight();
    this.attackNearbyEnemy();
    """

D.attack = class Attack extends Doc
  doc: ->
    """
    The `attack` method takes an enemy `target`, sets the #{@thang.spriteName}'s `target` to that `target` with the `setTarget` method, and sets the #{@thang.spriteName}'s `action` to the `this.actions.attack` action with the `setAction` method.
    """

  args: ->
    exampleTarget = "enemy"
    for [methods, code] in [[["getNearestEnemy"], "this.getNearestEnemy()"],
                            [["getEnemies"], "this.getEnemies()[0]"]]
      if (m for m in methods when m in @thang.programmableProperties).length
        exampleTarget = code
        break

    [new Arg "target", "object", exampleTarget, "The target enemy to attack."]

D.moveXY = class MoveXY extends Doc
  doc: ->
    """
    The `moveXY` method sets the #{@thang.spriteName}'s `targetPos` to the given `(x, y)` coordinates and also sets the #{@thang.spriteName}'s `action` to `move`.
    """

  args: ->
    [
      new Arg "x", "number", "24", "The x coordinate toward which to move."
      new Arg "y", "number", "35", "The y coordinate toward which to move."
    ]

D.distanceTo = class DistanceTo extends Doc
  doc: ->
    """
    Returns the distance in meters to the `target` unit from the center of the #{@thang.spriteName}.
    """

  args: ->
    exampleTarget = "enemy"
    for [methods, code] in [#[["getNearestEnemy"], "this.getNearestEnemy()"],
                            [["getEnemies"], "this.getEnemies()[0]"],
                            [["getFriends"], "this.getFriends()[0]"]]
      if (m for m in methods when m in @thang.programmableProperties).length
        exampleTarget = code
        break

    [new Arg "target", "object", exampleTarget, "The target unit whose distance you want to measure."]

D.getEnemies = class GetEnemies extends Doc
  doc: ->
    """
    Returns an array of all living enemies within eyesight.
    """

  example: ->
    """
    var enemies = this.getEnemies();
    for(var i = 0; i < enemies.length; ++i) {
      var enemy = enemies[i];
      // Do something with each enemy here
      this.attack(enemy);  // Example
    }
    """

D.getFriends = class GetFriends extends Doc
  doc: ->
    """
    Returns an array of all living friends within eyesight.
    """

  example: ->
    """
    var friends = this.getFriends();
    for(var i = 0; i < friends.length; ++i) {
      var friend = friends[i];
      // Do something with each friend here
      this.follow(friend);  // Example
    }
    """

D.getItems = class GetItems extends Doc
  doc: ->
    """
    Returns an array of all living items within eyesight.
    """

  example: ->
    """
    var items = this.getItems()
    for(var i = 0; i < items.length; ++i) {
      var item = items[i];
      // Do something with each item here
      this.move(item.pos);  // Example
    }
    """

D.attackNearbyEnemy = class GetNearbyEnemy extends Doc
  doc: ->
    """
    Attacks any enemy within #{@thang.attackNearbyEnemyRange ? 5} meters of the #{@thang.spriteName}.
    """

D.getNearestEnemy = class GetNearestEnemy extends Doc
  doc: ->
    """
    Returns the closest living enemy, or `null` if there aren\'t any.
    """

  example: ->
    """
    var enemy = this.getNearestEnemy();
    """

D.getNearestFriend = class GetNearestFriend extends Doc
  doc: ->
    """
    Returns the closest living friend, or `null` if there aren\'t any.
    """

  example: ->
    """
    var friend = this.getNearestFriend();
    """

D.getNearestCombtaant = class GetNearestCombatant extends Doc
  doc: ->
    """
    Returns the closest living friend or foe, or `null` if there aren\'t any.
    """

  example: ->
    """
    var enemy = this.getNearestCombatant();
    """

D.attackXY = class AttackXY extends Doc
  doc: ->
    """
    The `attackXY` method makes the #{@thang.spriteName} attack the ground at the given `(x, y)` coordinates.
    """

  args: ->
    [
      new Arg "x", "number", "24", "The x coordinate to attack."
      new Arg "y", "number", "35", "The y coordinate to attack."
    ]

D.patrol = class Patrol extends Doc
  doc: ->
    """
    The `patrol` method causes the #{@thang.spriteName} to move between the given waypoints in a loop. When combined with code to `attack` nearby enemies, you can use it to guard an area.
    """

  args: ->
    [new Arg "patrolPoints", "array", "[{x: 15, y: 45}, {x: 30, y: 40}, {x: 25, y: 35}]", "An array of positions to move between."]

D.attackNearestEnemy = class AttackNearestEnemy extends Doc
  doc: ->
    """
    The `attackNearestEnemy` method causes the #{@thang.spriteName} to charge at the nearest enemy and try to slay it.
    """

D.moveRight = class MoveRight extends Doc
  doc: ->
    """
    Moves the #{@thang.spriteName} right by #{@thang.simpleMoveDistance} meters.
    """

  example: ->
    """
    this.moveRight();
    """

D.moveLeft = class MoveLeft extends Doc
  doc: ->
    """
    Moves the #{@thang.spriteName} left by #{@thang.simpleMoveDistance} meters.
    """

  example: ->
    """
    this.moveLeft();
    """

D.moveUp = class MoveUp extends Doc
  doc: ->
    """
    Moves the #{@thang.spriteName} up by #{@thang.simpleMoveDistance} meters.
    """

  example: ->
    """
    this.moveUp();
    """

D.moveDown = class MoveDown extends Doc
  doc: ->
    """
    Moves the #{@thang.spriteName} down by #{@thang.simpleMoveDistance} meters.
    """

  example: ->
    """
    this.moveDown();
    """

D.say = class Say extends Doc
  doc: ->
    """
    Makes the #{@thang.spriteName} say the given message. Anything within #{@thang.voiceRange ? 20} meters will hear it.
    """

  args: ->
    [new Arg "message", "string", "\"Follow me!\"", "The message to say."]

D.chaseAndAttack = class ChaseAndAttack extends Doc
  doc: ->
    """
    Makes the #{@thang.spriteName} attack `target` if in range, otherwise move to `target`.
    """

  args: ->
    [new Arg "target", "object", "this.getNearestEnemy()", "The unit to chase and attack."]


D.wait = class Wait extends Doc
  doc: ->
    """
    The `wait()` method makes the #{@thang.spriteName} wait for a moment before continuing to execute the rest of the code.

    It currently doesn't work inside nested functions in a `plan()` method.
    """

  args: ->
    [
      new Arg "duration", "number", "0.1", "Number of seconds to wait."
    ]

D.addRect = class AddRect extends Doc
  doc: ->
    """
    The `addRect()` method adds a rectangle centered at the given `(x, y)` coordinate with the given `width` and `height`.
    """

  args: ->
    [
      new Arg "x", "number", "30", "x-coordinate of center of the rectangle."
      new Arg "y", "number", "12", "y-coordinate of center of the rectangle."
      new Arg "width", "number", "4", "width of the rectangle."
      new Arg "height", "number", "24", "height of the rectangle."
    ]

D.removeRectAt = class RemoveRectAt extends Doc
  doc: ->
    """
    The `removeRectAt()` method removes a previously added rectangle centered at the given `(x, y)` coordinate.
    """

  args: ->
    [
      new Arg "x", "number", "30", "x-coordinate of center of the rectangle to remove."
      new Arg "y", "number", "12", "y-coordinate of center of the rectangle to remove."
    ]

D.getNavGrid = class GetNavGrid extends Doc
  doc: ->
    """
    The `getNavGrid()` method returns an undocumented data structure CodeCombat uses in its pathfinding system. Sorry--will improve.

    Just use its `grid` property, which is a two-dimensional array with one-meter resolution indicating where the walls are:

    ```
    var grid = this.getNavGrid().grid;
    var y = 12;
    var x = 30;
    var occupied = grid[y][x].length > 0;
    ```
    """

D.spawnedRectangles = class SpawnedRectangles extends Doc
  doc: ->
    """
    An array of rectangle objects which have been added with the `addRect()` method.

    You can get a rectangle's dimensions, like this:

    ```
    for(var i = 0; i < this.spawnedRectangles.length; ++i) {
        var rect = this.spawnedRectangles[i];
        // rect.pos.x, rect.pos.y, rect.width, rect.height
    }
    ```
    """


D.pow = class Pow extends Doc
  owner: "Math"
  doc: ->
    """
    Returns `base` to the `exponent` power, that is, <code>base<sup>exponent</sup></code>.
    """

  example: ->
    """
    Math.pow(7, 2);  // returns 49
    """

  args: ->
    [
      new Arg "base", "number", "7", "The base number."
      new Arg "exponent", "number", "2", "The exponent used to raise the `base`."
    ]

D.sqrt = class Sqrt extends Doc
  owner: "Math"
  doc: ->
    """
    Returns the square root of a non-negative number. Equivalent to `Math.pow(x, 0.5)`.
    """

  example: ->
    """
    Math.sqrt(49);  // returns 7
    """

  args: ->
    [new Arg "x", "number", "49", ""]

D.sin = class Sin extends Doc
  owner: "Math"
  doc: ->
    """
    Returns the sine of a number (between -1 and 1).
    """

  example: ->
    """
    Math.sin(Math.PI / 4);  // returns √2
    """

  args: ->
    [new Arg "x", "number", "Math.PI / 2", "A number in radians."]

D.cos = class Cos extends Doc
  owner: "Math"
  doc: ->
    """
    Returns the cosine of a number (between -1 and 1).
    """

  example: ->
    """
    Math.cos(3 * Math.PI / 4);  // returns -√2
    """

  args: ->
    [new Arg "x", "number", "Math.PI / 2", "A number in radians."]

D.tan = class Tan extends Doc
  owner: "Math"
  doc: ->
    """
    Returns the tangent of a number (between -1 and 1).
    """

  example: ->
    """
    Math.tan(Math.PI / 4);  // returns 0.9999999999999999
    """

  args: ->
    [new Arg "x", "number", "Math.PI / 2", "A number in radians."]

D.atan2 = class Atan2 extends Doc
  owner: "Math"
  doc: ->
    """
    Returns the arctangent of the quotient of its arguments--a numeric value between -π and π representing the counterclockwise angle theta of an (x, y) point and the positive X axis.
    """

  args: ->
    [
      new Arg "y", "number", "90", ""
      new Arg "x", "number", "15", ""
    ]

D.PI = class PI extends Doc
  owner: "Math"
  doc: ->
    """
    The ratio of the circumference of a circle to its diameter, approximately 3.14159.
    """

D.random = class Random extends Doc
  owner: "Math"
  doc: ->
    """
    Returns a random number x such that 0 <= x < 1.
    """
