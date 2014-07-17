ProfileView = require 'views/account/profile_view'

responses =
  '/db/user/joe/nameToID':'512ef4805a67a8c507000001'
  '/db/user/512ef4805a67a8c507000001':{"_id":"512ef4805a67a8c507000001","__v":47,"email":"livelily@gmail.com","emailSubscriptions":["announcement","notification","developer","level_creator","tester","article_editor","translator","support"],"facebookID":"4301215","firstName":"Nick","gender":"male","lastName":"Winter","name":"Nick!","photoURL":"db/user/512ef4805a67a8c507000001/nick_wizard.png","volume":0,"wizardColor1":0.4,"testGroupNumber":217,"mailChimp":{"leid":"70264209","euid":"c4418e2abd","email":"livelily@gmail.com"},"hourOfCode":true,"hourOfCodeComplete":true,"signedCLA":"Fri Jan 03 2014 14:40:18 GMT-0800 (PST)","wizard":{"colorConfig":{"boots":{"lightness":0.1647058823529412,"saturation":0.023809523809523805,"hue":0},"spell":{"hue":0.7490196078431373,"saturation":0.4106280193236715,"lightness":0.5941176470588235},"cloud":{"lightness":0.14,"saturation":1,"hue":0},"clothes":{"lightness":0.1411764705882353,"saturation":0,"hue":0},"trim":{"hue":0.5,"saturation":0.009900990099009936,"lightness":0.19803921568627453}}},"aceConfig":{"liveCompletion":true,"indentGuides":true,"invisibles":true,"keyBindings":"emacs","behaviors":true,"language":"javascript"},"lastLevel":"drink-me","gplusID":"110703832132860599877","jobProfile":{"photoURL":"db/user/512ef4805a67a8c507000001/nick_bokeh_small.jpg","links":[{"name":"Twitter","link":"https://twitter.com/nwinter"},{"name":"Facebook","link":"https://www.facebook.com/nwinter"},{"name":"LinkedIn","link":"https://www.linkedin.com/in/nwinter"},{"name":"Blog","link":"http://blog.nickwinter.net/"},{"name":"Personal Site","link":"http://www.nickwinter.net/"},{"name":"GitHub","link":"https://github.com/nwinter"},{"name":"G+","link":"https://plus.google.com/u/0/+NickWinter"}],"projects":[{"name":"The Motivation Hacker","description":"I wrote a book. *The Motivation Hacker* shows you how to summon extreme amounts of motivation to accomplish anything you can think of. From precommitment to rejection therapy, this is your field guide to getting yourself to want to do everything you always wanted to want to do.","picture":"db/user/512ef4805a67a8c507000001/the_motivation_hacker_thumb.jpg","link":"http://www.nickwinter.net/motivation-hacker"},{"name":"Quantified Mind","description":"Quantified Mind is a tool that quickly, reliably, and comprehensively measures your basic cognitive abilities. We've adapted tests used by psychologists to a practical web application that you can use whenever, wherever, and as often as you want.","picture":"db/user/512ef4805a67a8c507000001/screenshot.png","link":"http://www.quantified-mind.com/"},{"link":"https://github.com/nwinter/telepath-logger","name":"Telepath","description":"A happy Mac keylogger for Quantified Self purposes. It also now serves as a time lapse heads-up-display thing. I used it to make a [time-lapse video of myself working an 120-hour workweek](http://blog.nickwinter.net/the-120-hour-workweek-epic-coding-time-lapse).","picture":"db/user/512ef4805a67a8c507000001/687474703a2f2f63646e2e736574742e636f6d2f696d616765732f757365722f32303133313131303139353534393937375a30356665633666623234623937323263373733636231303537613130626336365f66726f6e742e6a7067"}],"education":[{"school":"Oberlin College","degree":"BA Computer Science, Mathematics, and East Asian Studies, highest honors in CS","duration":"Aug 2004 - May 2008","description":"Cofounded Oberlin Street Art and did all sorts of crazy missions without telling anyone about it."}],"work":[{"employer":"CodeCombat","role":"Cofounder","duration":"Jan 2013 - present","description":"Programming a programming game for learning programming to be a programming programmer of programmatic programs."},{"employer":"Skritter","role":"Cofounder","duration":"May 2008 - present","description":"I coded, I designed, I marketed, I businessed, I wrote, I drudged, I cheffed, I laughed, I cried. But mostly I emailed. God, so much email."}],"visa":"Authorized to work in the US","longDescription":"I cofounded Skritter, am working on CodeCombat, helped with Quantified Mind, live in San Francisco, went to Oberlin College, wrote a book about motivation hacking, and can do anything.\n\nI like hacking on startups, pigs with dogs for feet, and Smash Bros. I dislike shoes, mortality, and Java.\n\nDo you love hiring renegade maverick commandos who can't abide the system? Are you looking to hire the sample job profile candidate of the job profile system? Are you just testing this thing? If your answer is yes, yes yes!–then let us talk.","shortDescription":"Maniac two-time startup cofounder looking to test the system and see what a job profile might look like. Can't nobody hold him down.","experience":6,"skills":["python","coffeescript","node","ios","objective-c","javascript","app-engine","mongodb","web dev","django","backbone","chinese","qs","writing"],"country":"USA","city":"San Francisco","active":false,"lookingFor":"Full-time","name":"Nick Winter","updated":"2014-07-12T01:48:42.980Z","jobTitle":"Mutant Code Gorilla"},"jobProfileApproved":false,"emails":{"anyNotes":{"enabled":true},"generalNews":{"enabled":true},"archmageNews":{"enabled":true},"artisanNews":{"enabled":true},"adventurerNews":{"enabled":true},"scribeNews":{"enabled":true},"diplomatNews":{"enabled":true},"ambassadorNews":{"enabled":true}},"activity":{"viewed_by_employer":{"last":"2014-06-19T20:21:43.747Z","count":6,"first":"2014-06-12T01:37:38.278Z"},"view_candidate":{"first":"2014-06-10T19:59:30.773Z","count":661,"last":"2014-07-11T02:14:40.131Z"},"login":{"first":"2014-06-10T21:55:08.968Z","count":22,"last":"2014-07-16T16:32:31.661Z"},"contacted_by_employer":{"first":"2014-06-19T20:24:51.870Z","count":1,"last":"2014-06-19T20:24:51.870Z"}},"slug":"nick","jobProfileNotes":"Nick used to be the **#1 Brawlwood player** on CodeCombat. He wrote most of the game engine, so that's totally cheating. Now other players have surpassed him by emulating his moves and improving his strategy. If you like the sixth Rocky movie, you might still want to hire this aging hero even in his fading senescence.","simulatedFor":2363,"simulatedBy":103674,"preferredLanguage":"en-US","anonymous":false,"permissions":["admin"],"autocastDelay":90019001,"music":false,"dateCreated":"2013-02-28T06:09:04.743Z"}
  '/db/user/512ef4805a67a8c507000001/level.sessions/employer': [
    {
      "_id": "53179b49b483edfcdb7ef13e",
      "code": {
        "human-base": {
          "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// Destroy the enemy base within 60 seconds!\n// Check out the Guide at the top for more info.\n\n// CHOOSE YOUR HERO! You can only build one hero.\nvar hero;\n//hero = 'tharin';  // A fierce knight with battlecry abilities.\n//hero = 'hushbaum';  // A fiery spellcaster hero.\n\nif(hero && !this.builtHero) {\n    this.builtHero = this.build(hero);\n    return;\n}\n\n// Soldiers are hard-to-kill, low damage melee units with 2s build cooldown.\n// Archers are fragile but deadly ranged units with 2.5s build cooldown.\nvar buildOrder = ['soldier', 'soldier', 'soldier', 'soldier', 'archer'];\nvar type = buildOrder[this.built.length % buildOrder.length];\n//this.say('Unit #' + this.built.length + ' will be a ' + type);\nthis.build(type);"
        },
        "programmable-tharin": {
          "chooseAction": "// Tharin is a melee fighter with shield, warcry, and terrify skills.\n// this.shield() lets him take one-third damage while defending.\n// this.warcry() gives allies within 10m 30% haste for 5s, every 10s.\n// this.terrify() sends foes within 30m fleeing for 5s, once per match.\n\nvar friends = this.getFriends();\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy = this.getNearest(enemies);\nvar friend = this.getNearest(friends);\n\n// Which one do you do at any given time? Only the last called action happens.\n//if(!this.getCooldown('warcry')) this.warcry();\n//if(!this.getCooldown('terrify')) this.terrify();\n//this.shield();\n//this.attack(enemy);\n\n// You can also command your troops with this.say():\n//this.say(\"Defend!\", {targetPos: {x: 30, y: 30}}));\n//this.say(\"Attack!\", {target: enemy});\n//this.say(\"Move!\", {targetPos: {x: 40, y: 40});\n\n// You can store state on this across frames:\n//this.lastHealth = this.health;"
        },
        "programmable-librarian": {
          "chooseAction": "// The Librarian is a spellcaster with a fireball attack\n// plus three useful spells: 'slow', 'regen', and 'haste'.\n// Slow makes a target move and attack at half speed for 5s.\n// Regen makes a target heal 10 hp/s for 10s.\n// Haste speeds up a target by 4x for 5s, once per match.\n\nvar friends = this.getFriends();\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy = this.getNearest(enemies);\nvar friend = this.getNearest(friends);\n\n// Which one do you do at any given time? Only the last called action happens.\n//if(this.canCast('slow', enemy)) this.castSlow(enemy);\n//if(this.canCast('regen', friend)) this.castRegen(friend);\n//if(this.canCast('haste', friend)) this.castHaste(friend);\n//this.attack(enemy);\n\n// You can also command your troops with this.say():\n//this.say(\"Defend!\", {targetPos: {x: 30, y: 30}}));\n//this.say(\"Attack!\", {target: enemy});\n//this.say(\"Move!\", {targetPos: {x: 50, y: 40});"
        },
        "nazgareth": {
          "chooseAction": "// Shamans are spellcasters with a weak magic attack\n// plus two useful spells: 'regen' and 'shrink'.\n\nvar enemy = this.getNearestEnemy();\nif (!enemy)\n    this.move({x: 10, y: 25});\nelse if (!enemy.hasEffect('shrink')) {\n    this.castShrink(enemy);\n    if(this.distance(enemy) <= 30)\n        this.say(\"Shrink, vile \" + enemy.type + \" \" + enemy.id);\n}\nelse {\n    this.attack(enemy);\n}"
        },
        "ironjaw": {
          "chooseAction": "var enemies = this.getEnemies();\nvar enemy = this.getNearest(enemies);\nif (enemy) {\n    if(!this.getCooldown('jump')) {\n        this.jumpTo(enemy.pos);\n        this.say(\"Hi \" + enemy.type + \" \" + enemy.id);\n    }\n    else {\n        this.attack(enemy);\n    }\n}\nelse {\n    this.move({x: 10, y: 30});\n}"
        },
        "poult": {
          "chooseAction": "// Shamans are spellcasters with a weak magic attack\n// plus two useful spells: 'regen' and 'shrink'.\n\nvar enemy = this.getNearestEnemy();\nif (!enemy)\n    this.move({x: 10, y: 25});\nelse if (!enemy.hasEffect('shrink')) {\n    this.castShrink(enemy);\n    if(this.distance(enemy) <= 30)\n        this.say(\"Shrink, vile \" + enemy.type + \" \" + enemy.id);\n}\nelse {\n    this.attack(enemy);\n}"
        }
      },
      "submitted": false,
      "levelID": "dungeon-arena",
      "levelName": "Dungeon Arena",
      "submittedCodeLanguage": "javascript",
      "playtime": 33,
      "codeLanguage": "javascript"
    },
    {
      "_id": "53336ee91506ed33756f73e5",
      "code": {
        "tharin": {
          "chooseAction": "this.say(\"Say, who's in charge around here?\");  // Should fill in some default source"
        },
        "programmable-coin": {
          "chooseAction": "//this.say(\"Say, who's in charge around here?\");  // Should fill in some default source\n\n//var time = this.now();\n//if(Math.round(time) % 20 === 0) {\n    this.teleportRandom();\n//}o"
        },
        "wizard-purple": {
          "chooseAction": "//this.say(\"Say, who's in charge around here?\");  // Should fill in some default source\n\n//var time = this.now();\n\n//if(Math.round(time) % 20 == 0) {\n    this.build('coin');\n//    console.log(\"build coin\");\n//}"
        }
      },
      "levelID": "gold-rush",
      "levelName": "Resource gathering multiplayer",
      "submittedCodeLanguage": "javascript",
      "playtime": 0,
      "codeLanguage": "javascript"
    },
    {
      "_id": "52ae32cbef42c52f1300000d",
      "levelID": "gridmancer",
      "levelName": "Gridmancer",
      "code": {
        "captain-anya": {
          "plan": "function largestRectangle(grid, bottomY, leftX, width, height) {\n    var coveredRows = [];\n    var shortestCoveredRow = width - leftX;\n    var done = false;\n    for(var y = bottomY; !done && y < height; ++y) {\n        var coveredRow = 0, done2 = false;\n        for(var x = leftX; !done2 && x < leftX + shortestCoveredRow; ++x) {\n            if(!grid[y][x].length)\n                ++coveredRow;\n            else\n                done2 = true;\n        }\n        if(!coveredRow)\n            done = true;\n        else {\n            coveredRows.push(coveredRow);\n            shortestCoveredRow = Math.min(shortestCoveredRow, coveredRow);\n        }\n    }\n    var maxArea = 0, maxAreaRows = 0, maxAreaRowLength = 0, shortestRow = 0;\n    for(var rowIndex = 0; rowIndex < coveredRows.length; ++rowIndex) {\n        var rowLength = coveredRows[rowIndex];\n        if(!shortestRow)\n            shortestRow = rowLength;\n        area = rowLength * (rowIndex + 1);\n        if(area > maxArea) {\n            maxAreaRows = rowIndex +1;\n            maxAreaRowLength = shortestRow;\n            maxArea = area;\n        }\n        shortestRow = Math.min(rowLength, shortestRow);\n    }\n    return {x: leftX + maxAreaRowLength / 2, y: bottomY + maxAreaRows / 2, width: maxAreaRowLength, height: maxAreaRows};\n}\n\n\nvar grid = this.getNavGrid().grid;\nvar tileSize = 4;\nfor(var y = 0; y < grid.length - tileSize / 2; y += tileSize) {\n    for(var x = 0; x < grid[0].length - tileSize / 2; x += tileSize) {\n        var occupied = grid[y][x].length > 0;\n        if(!occupied) {\n            var rect = largestRectangle(grid, y, x, grid[0].length, grid.length);\n            this.addRect(rect.x, rect.y, rect.width, rect.height);\n            //this.say(\"Placed rect \" + rect.x + \", \" + rect.y + \", \" + rect.width + \", \" + rect.height + \" for \" + grid[0].length + \",  \" + grid.length + \", \" + x + \", \" + y);\n            this.wait(0.1);\n            for(var y2 = rect.y - rect.height / 2; y2 < rect.y + rect.height / 2; ++y2) {\n                for(var x2 = rect.x - rect.width / 2; x2 < rect.x + rect.width / 2; ++x2) {\n                    grid[y2][x2] = [rect];\n                }\n            }\n        }\n    }\n}\n"
        },
        "thoktar": {
          "plan": "var grid = this.getNavGrid().grid;\nvar tileSize = 4;\nvar canOverlap = false;\nvar i, rect;\nthis.doWait = function() {\n    this.wait(1);\n    this.say(\"hi\");\n    this.wait(1);\n    this.say(\"there\");\n    this.wait(1);\n};\nthis.doWait();\nfor (var y = 0; y + tileSize < grid.length; y += tileSize) {\n    for (var x = 0; x + tileSize < grid[0].length;) {\n        // check if wall\n        var occupied = grid[y][x].length > 0;\n        // check if already covered by another rect\n        if (!occupied) {\n            for (i = 0; i < this.spawnedRectangles.length; ++i) {\n                rect = this.spawnedRectangles[i];\n                if (rect.pos.x - rect.width / 2 <= x && x < rect.pos.x + rect.width / 2 && rect.pos.y - rect.height / 2 < y && rect.pos.y + rect.height / 2 > y)\n                    occupied = true;\n            }\n        }\n        if (!occupied) {\n            var x2 = x,\n                y2 = y;\n            // expand to the right until we find a wall\n            while (x2 < grid[0].length - 1 && grid[y][x2 + tileSize].length === 0)\n                x2 += tileSize;\n            // expand current horizontal rectangle vertically until wall\n            var ok = true;\n            while (y2 + tileSize < grid.length && ok) {\n                var yt = y2 + tileSize;\n                // check each cell\n                for (var xt = x; xt <= x2; xt += tileSize) {\n                    if (grid[yt][xt].length > 0) {\n                        ok = false;\n                    }\n                }\n                if (!canOverlap) {\n                    // check if tile to the left is non-wall\n                    if (x > 0 && grid[yt][x - tileSize].length === 0) {\n                        // check if already has a rect\n                        var covered = false;\n                        for (i = 0; i < this.spawnedRectangles.length; ++i) {\n                            rect = this.spawnedRectangles[i];\n                            if (rect.pos.x - rect.width / 2 <= x - tileSize &&\n                                x - tileSize < rect.pos.x + rect.width / 2 &&\n                                rect.pos.y - rect.height / 2 < yt &&\n                                rect.pos.y + rect.height / 2 > yt)\n                                covered = true;\n                        }\n                        // if no wall and no rect leave open to avoid future overlap\n                        if (!covered)\n                            ok = false;\n                    }\n                }\n                // advance\n                if (ok)\n                    y2 += tileSize;\n            }\n            // done\n            this.addRect(x + tileSize / 2 + (x2 - x) / 2, y + tileSize / 2 + (y2 - y) / 2,\n                tileSize + (x2 - x), tileSize + (y2 - y));\n            x = x2 + tileSize;\n            this.wait();\n        } else {\n            x += tileSize;\n        }\n    }\n}\n\n/*\nvar tileSize = 4;\n\nvar grid;\nvar occupied, occupiedArray;\nvar numTilesX, numTilesY;\nvar x, y, y2, x2, x3, y3, lastX, lastY;\nvar width, height;\n\ngrid = this.getNavGrid().grid;\noccupiedArray = [];\n\nfor(y = 0; y + tileSize < grid.length; y += tileSize) \n{\n    occupiedArray[y] = [];\n    for(x = 0; x + tileSize < grid[y].length; x += tileSize) \n    {\n        occupiedArray[y][x] = (grid[y][x].length > 0);\n    }\n}\n\nfor(y = 0; y + tileSize < grid.length; y += tileSize) \n{\n    for(x = 0; x + tileSize < grid[y].length; x += tileSize) \n    {\n        if(!occupiedArray[y][x])\n        {\n            //Check width of rectangle\n            lastX = x;\n            y2 = y;\n            numTilesX = 0;\n            var okay = true;\n            for(x2 = x; okay &&x2 + tileSize < grid[y].length; x2 += tileSize)\n            {\n                if(occupiedArray[y2][x2])\n                {\n                    okay = false;\n                    //x2 = grid[y].length;\n                }\n                else\n                {\n                    lastX = x2;\n                    numTilesX++;\n                }\n            }\n\n            // Check height of rectangle\n            lastY = y;\n            x2 = x;\n            numTilesY = 0;\n            okay = true;\n            for(y2 = y; okay && y2 + tileSize < grid.length; y2 += tileSize)\n            {\n                var okay2 = true;\n                for(x3 = x; okay2 && x3 <= lastX; x3 += tileSize)\n                {\n                    occupied = occupiedArray[y2][x3];\n                    if(occupied)\n                    {\n                        okay2 = false;\n                        //x3 = grid[y].length;\n                    }\n                }\n                if(occupied)\n                {\n                    okay = false;\n                    //y2 = grid.length;\n                }\n                else\n                {\n                    lastY = y2;\n                    numTilesY++;\n                }\n            }\n\n            for(y3 = y; y3 <= lastY; y3 += tileSize)            \n            {\n                for(x3 = x; x3 <= lastX; x3 += tileSize)\n                {\n                    occupiedArray[y3][x3] = true;\n                }\n            }\n  \n            width = numTilesX * tileSize;\n            height = numTilesY * tileSize;\n            this.addRect( x  + (width / 2), y + (height / 2), width, height);\n            \n            this.wait();  // Hover over the timeline to help debug!\n        }       \n    }\n}\n*/\n\n\n/*\nvar todoGrid = this.getNavGrid().grid;\nvar tileSize = 4;\nvar yGridSize = todoGrid.length;\nvar xGridSize = todoGrid[0].length;\nvar x, y;\n//store all tiles which actually need to be filled\nfor(y = 0; y + tileSize < yGridSize; y += tileSize) {\n    for(x = 0; x + tileSize < xGridSize; x += tileSize) {\n        todoGrid[y][x] = todoGrid[y][x].length === 0;\n    }\n}\n\n//determine how many tiles to fill\nvar todoAnz = 0;\nfor(y = 0; y + tileSize < yGridSize; y += tileSize) {\n    for(x = 0; x + tileSize < xGridSize; x += tileSize) {\n        if(todoGrid[y][x]) {\n            todoAnz++;\n        }\n    }\n}\n\n//fill all tiles from biggest to smallest rectangle possible\nwhile(todoAnz > 0) {\n    var biggestLeftX, biggestLeftY, biggestRightX, biggestRightY, tmpX, tmpY;\n    var bigRect = 0;\n    for(y = 0; y + tileSize < yGridSize; y += tileSize) {\n        for(x = 0; x + tileSize < xGridSize; x += tileSize) {\n            if(todoGrid[y][x]) {\n            var width = 1, height = 1;\n            while(todoGrid[y][x + width * tileSize] && x + width * tileSize + tileSize < xGridSize) {\n                width++;\n            }\n            var higher = true;\n            while(higher) {\n                for(tmpX = x; tmpX < x + tileSize * width; tmpX += tileSize)\n                    if(!todoGrid[y + height * tileSize][tmpX] || y + height * tileSize + tileSize >= yGridSize) higher = false;\n                if(higher) height++;\n            }\n            if(width * height > bigRect) {\n                bigRect = width * height;\n                biggestLeftX = x;\n                biggestLeftY = y;\n                biggestRightX = x + width * tileSize;\n                biggestRightY = y + height * tileSize;\n            }\n        }\n    }\n}\nfor(tmpY = biggestLeftY; tmpY < biggestRightY; tmpY += tileSize)\n    for(tmpX = biggestLeftX; tmpX < biggestRightX; tmpX += tileSize)\n        todoGrid[tmpY][tmpX] = false;\n    this.addRect( (biggestLeftX + biggestRightX) / 2,\n                  (biggestLeftY + biggestRightY) / 2,\n                  biggestRightX - biggestLeftX,\n                  biggestRightY - biggestLeftY );\n    this.wait(0.2);\n    todoAnz -= bigRect;\n    // this.say(\"Found a \"+bigRect+\" tile Rectangle, \"+todoAnz+\" tile(s) left\");\n}\n// André\n*/\n\n/*\nvar grid = this.getNavGrid().grid;\nvar tileSize = 4;\nfor(var y = 0; y + tileSize < grid.length; y += tileSize) {\n    for(var x = 0; x + tileSize < grid[0].length; ) {\n\n        var occupied = grid[y][x].length > 0;\n\n        if (!occupied) {\n            for (var i = 0; i < this.spawnedRectangles.length; ++i) {\n                var rect = this.spawnedRectangles[i];\n                if (rect.pos.x - rect.width / 2 <= x && x <= rect.pos.x + rect.width / 2 \n                    && rect.pos.y - rect.height / 2 < y && rect.pos.y + rect.height / 2 > y)\n                    occupied = true;\n            }\n        }\n\n        if(!occupied) {\n            var x2 = x, y2 = y;\n            while (x2 < grid[0].length-1 && grid[y][x2+tileSize].length===0)\n                x2 += tileSize;\n\n            var ok = true;\n            while (y2 + tileSize < grid.length && ok) {\n                var yt = y2 + tileSize; \n                for (var xt = x; xt <= x2; xt += tileSize) {\n                    if (grid[yt][xt].length > 0) {\n                        ok = false;\n                    }\n                }\n                if (x > 0 && grid[yt][x - tileSize].length === 0)\n                    ok = false;\n                if (x2 < grid[0].length-tileSize && grid[yt][x2+tileSize].length === 0)\n                    ok = false;\n                if (ok)\n                    y2 += tileSize; \n            }\n\n\n            this.addRect(x + tileSize / 2 + (x2-x)/2, y + tileSize / 2 + (y2-y)/2, tileSize + (x2-x), tileSize + (y2-y));\n            x = x2 + tileSize;\n            this.wait();\n        } else {\n            x += tileSize;\n        }\n    }\n}\n*/\n\n/*\nvar grid = this.getNavGrid().grid;\nvar tileSize = 4;\nvar isCounting;\nvar adyacentX;\nvar startPos;\n\nfor(var y = 0; y + tileSize < grid.length; y += tileSize) {\n    isCounting = 0;\n    adyacentX = 0;\n    for(var x = 0; x + tileSize < grid[0].length; x += tileSize) {\n        var occupied = grid[y][x].length > 0;\n        if(!occupied) {\n            if(isCounting === 0)\n                startPos = x;\n            isCounting = 1;\n            adyacentX++;\n     // this.say(\"Pos(\"+x+\",\"+y+\") is occupied\");\n     // this.addRect(x + tileSize / 2, y + tileSize / 2, tileSize, tileSize);\n    // this.wait(); // Hover over the timeline to help debug!\n        }\n        else {\n       // this.say(\"Pos(\"+x+\",\"+y+\") is not occupied\");\n            isCounting = 0;\n            if(adyacentX > 0){\n      // this.say(\"writing \" + adyacentX + \"width rectangle= \" + tileSize*adyacentX);\n                this.addRect((startPos + x)/2,y+tileSize / 2,tileSize*adyacentX,tileSize);\n                }\n            adyacentX = 0;\n        }\n    }\n\n}\n\nthis.say(\"Finish!\");\n*/\n\n/*\nfunction largestRectangle(grid, bottomY, leftX, width, height) {\n    var coveredRows = [];\n    var shortestCoveredRow = width - leftX;\n    var done = false;\n    for(var y = bottomY; !done && y < height; ++y) {\n        var coveredRow = 0, done2 = false;\n        for(var x = leftX; !done2 && x < leftX + shortestCoveredRow; ++x) {\n            if(!grid[y][x].length)\n                ++coveredRow;\n            else\n                done2 = true;\n        }\n        if(!coveredRow)\n            done = true;\n        else {\n            coveredRows.push(coveredRow);\n            shortestCoveredRow = Math.min(shortestCoveredRow, coveredRow);\n        }\n    }\n    var maxArea = 0, maxAreaRows = 0, maxAreaRowLength = 0, shortestRow = 0;\n    for(var rowIndex = 0; rowIndex < coveredRows.length; ++rowIndex) {\n        var rowLength = coveredRows[rowIndex];\n        if(!shortestRow)\n            shortestRow = rowLength;\n        area = rowLength * (rowIndex + 1);\n        if(area > maxArea) {\n            maxAreaRows = rowIndex +1;\n            maxAreaRowLength = shortestRow;\n            maxArea = area;\n        }\n        shortestRow = Math.min(rowLength, shortestRow);\n    }\n    return {x: leftX + maxAreaRowLength / 2, y: bottomY + maxAreaRows / 2, width: maxAreaRowLength, height: maxAreaRows};\n}\n\nvar grid = this.getNavGrid().grid;\nvar tileSize = 4;\nfor(var y = 0; y < grid.length - tileSize / 2; y += tileSize) {\n    for(var x = 0; x < grid[0].length - tileSize / 2; x += tileSize) {\n        var occupied = grid[y][x].length > 0;\n        if(!occupied) {\n            var rect = largestRectangle(grid, y, x, grid[0].length, grid.length);\n            this.addRect(rect.x, rect.y, rect.width, rect.height);\n            //this.say(\"Placed rect \" + rect.x + \", \" + rect.y + \", \" + rect.width + \", \" + rect.height + \" for \" + grid[0].length + \",  \" + grid.length + \", \" + x + \", \" + y);\n            this.wait(0.1);\n            for(var y2 = rect.y - rect.height / 2; y2 < rect.y + rect.height / 2; ++y2) {\n                for(var x2 = rect.x - rect.width / 2; x2 < rect.x + rect.width / 2; ++x2) {\n                    grid[y2][x2] = [rect];\n                }\n            }\n        }\n    }\n}\n*/"
        }
      },
      "submitted": false,
      "submittedCodeLanguage": "javascript",
      "playtime": 302,
      "codeLanguage": "javascript"
    },
    {
      "_id": "5334901f0a0f9b286f57382c",
      "team": "humans",
      "code": {
        "coin-generator-9000": {
          "chooseAction": "var buildOrder = ['coin2', 'coin3', 'coin4'];\n//if (Math.random() < 0.25)\n//    this.build(buildOrder[this.built.length % buildOrder.length]);\nif (Math.random() < 0.05)\n    this.build('gem');\nelse if (Math.random() < 0.25)\n    this.build(buildOrder[this.built.length % buildOrder.length])\nelse if (Math.random() < 0.5)\n    this.build('coin');\n\n\n\nvar human = this.getThangByID(\"Tharin\");\nvar ogre = this.getThangByID(\"Mak Fod\");\n\n//this.say(human.gold);\n\n//this.say(\"Humans: \" + human.gold + \", \" + \"Ogres: \" + ogre.gold);\n\nif(ogre.gold >= 150) {\n    this.say(\"Ogres win!\");\n    this.setGoalState(\"goldOgres\", \"success\");\n}\n\nelse if(human.gold >= 150) {\n    this.say(\"Humans win!\");\n    this.setGoalState(\"goldHumans\", \"success\");\n}"
        },
        "programmable-coin": {
          "chooseAction": "//this.say(\"Say, who's in charge around here?\");  // Should fill in some default source\n\n//var time = this.now();\n//if(Math.round(time) % 20 === 0) {\nif (typeof this.teleportOnce === 'undefined') {\n    this.teleportRandom();\n    this.teleportOnce = true;\n}\n//}"
        },
        "tharin": {
          "chooseAction": "var t = this;\nvar e = t.getNearestEnemy();\nvar vec = new Vector(0, 0);\n\nfunction item_worth(item) {\n    return item.bountyGold/Math.pow(item.distance(e) - t.distance(item), 1.5);\n}\n\nvar items = this.getItems();\nfor (var i = 0; i < items.length; i++) {\n    var item = items[i];\n    var direction = Vector.normalize(Vector.subtract(item.pos, this.pos));\n    var weighted_dir = Vector.multiply(direction, 1000 * item_worth(item));\n    vec = Vector.add(vec, weighted_dir);\n}\n\nvar action = \"move\";\nif (typeof this.used_terrify == \"undefined\") {\n    var enemy = this.getNearestEnemy();\n    \n    if (enemy.gold >= 140 || this.distance(enemy) <= 15) {\n        action = \"terrify\";\n    }\n}\n\nif (action == \"move\") {\n    var best_item = null;\n    var best_item_value = 0;\n    for (var i = 0; i < items.length; i++) {\n        var item = items[i];\n        var direction = Vector.subtract(item.pos, this.pos);\n        \n        var angle = Math.acos(vec.dot(direction) / (vec.magnitude() * direction.magnitude()))\n        if (angle < Math.PI / 16 || angle > Math.PI * (31/16)) {\n            if (item_worth(item) > best_item_value) {\n                best_item_value = item_worth(item);\n                best_item = item;\n            }\n        }\n    }\n    \n    if (best_item_value > 0.05) {\n        this.move(best_item.pos);\n    } else {\n        this.say(\"Move to \" + Vector.add(this.pos, vec).x + \" \" + Vector.add(this.pos, vec).y);\n        this.move(Vector.add(this.pos, vec));\n    }\n} else if (action == \"terrify\") {\n    //this.terrify();\n    this.used_terrify = true;\n}\n/*\n\n// This code runs once per frame. Choose where to move to grab gold!\n// First player to 150 gold wins.\n\n// This is an example of grabbing the 0th coin from the items array.\nvar items = this.getItems();\nif (items[0]) {\n    this.move(items[0].pos);\n} else {\n    this.moveXY(18, 36);\n}\n\n\n// You can surely pick a better coin using the methods below.\n// Click on a coin to see its API.\n*/\n"
        },
        "wizard-purple": {
          "chooseAction": "//this.say(\"Say, who's in charge around here?\");  // Should fill in some default source\n\n//var time = this.now();\n\n//if(Math.round(time) % 20 == 0) {\n    this.build('coin');\n//    console.log(\"build coin\");\n//}"
        }
      },
      "levelID": "gold-rush",
      "levelName": "Gold Rush",
      "totalScore": 39.33094538664242,
      "submitted": true,
      "submittedCodeLanguage": "javascript",
      "playtime": 1158,
      "codeLanguage": "javascript"
    },
    {
      "_id": "52dea9b77e486eeb97000001",
      "levelID": "brawlwood",
      "levelName": "Brawlwood",
      "code": {
        "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// If you don't have enough gold, this.build() won't build anything.\n// You start with 100 gold and receive 2 gold per second.\n// Kill enemies, especially towers and brawlers, to earn more gold.\n// Destroy the enemy base within 90 seconds!\n\n//var type = 'munchkin';\nvar type = 'thrower';\nif(this.built.length % 3 === 0 && this.buildables.shaman.goldCost <= this.gold) \n    type = 'shaman';\n// else if(this.built.length % 2 === 1 && this.buildables.thrower.goldCost <= this.gold)\n//    type = 'thrower';\n\nif(this.gold >= this.buildables[type].goldCost) {\n    //this.say('Unit #' + this.built.length + ' will be a ' + type);\n    this.build(type);\n}",
        "programmable-soldier": {
          "chooseAction": "var i;\nif(typeof this.incoming !== 'undefined') {\n    for(i = 0; i < this.incoming.length; ++i) {\n        var shell = this.incoming[i];\n        var t = shell.time - this.now();\n        if(t < 0 || t > 1.5) continue;\n        if(this.distance(shell.target) > 15) continue;\n        var away = Vector.subtract(this.pos, shell.target);\n        away = Vector.normalize(away);\n        away = Vector.multiply(away, 15);\n        away = Vector.add(this.pos, away);\n        this.move(away);\n        return;\n    }\n}\n\nvar friends = this.getFriends();\nvar friend;\nfor(i = 0; i < friends.length; ++i) {\n    friend = friends[i];\n    if(friend.type !== 'arrow-tower') continue;\n    if(friend.health < 15 && this.distance(friend) < 10) {\n        this.attack(friend);\n        return;\n    }\n}\n\n\nvar enemy = this.getNearestEnemy();\nif(this.now() > 70) {\n    if(enemy)\n        this.attack(enemy);\n    else\n        this.move({x: 70, y: 70});\n    return;\n}\n\nif(enemy && this.distance(enemy) < 40 && enemy.type != \"beam-tower\") {\n    if(enemy.type === \"burl\" && (enemy.pos.x > 45 || enemy.pos.y > 45))\n        this.say(\"Come at me, burl!\");\n    else {\n        this.attack(enemy);\n        return;\n    }\n}\nvar nearestArtillery = null;\nvar nearestArtilleryDistance = Infinity;\nfor(i = 0; i < friends.length; ++i) {\n    friend = friends[i];\n    if(friend.type !== \"artillery\") continue;\n    var d = this.distance(friend);\n    if(d < nearestArtilleryDistance) {\n        nearestArtilleryDistance = d;\n        nearestArtillery = friend;\n    }\n}\nif(nearestArtillery && this.now() < 75) {\n    var ahead = Vector.add(nearestArtillery.pos, {x: 2, y: 2});\n    this.move(ahead);\n    return;\n}\n\nif(friends.length > 12 || this.now() > 75) {\n    if(enemy && enemy.type === 'beam-tower')\n        this.attack(enemy);\n    else\n        this.move({x: 70, y: 70});\n}\nelse if(this.maxEnemies) {\n    var besieged = null;\n    var besiegedCount = 0;\n    for(var tower in this.maxEnemies) {\n        if(this.maxEnemies[tower] > besiegedCount) {\n            besiegedCount = this.maxEnemies[tower];\n            besieged = tower;\n        }\n    }\n    if(besieged === \"W Arrow Tower\")\n        this.move({x: 8, y: 32});\n    else\n        this.move({x: 32, y: 8});\n}\nelse if(this.buildIndex % 4)\n    this.move({x: 8, y: 32});\nelse\n    this.move({x: 32, y: 8});\n//testtesttest\n\n\n\n",
          "hear": "// When the soldier hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.\nif(message === \"Incoming!\") {\n    if(typeof this.incoming === 'undefined') \n        this.incoming = [];\n    this.incoming.push(data);\n}\nelse if(data && data.enemies) {\n    if(typeof this.maxEnemies === 'undefined') this.maxEnemies = {};\n    this.maxEnemies[speaker.pos] = Math.max(this.maxEnemies[speaker.pos], data.enemies);\n}"
        },
        "kim": {
          "chooseAction": "var enemies = this.getEnemies();\nif(enemies.length)\n    this.attack(enemies[0]);\nelse\n    this.move({x: 71, y: 68});\n\n"
        },
        "house-3": {
          "chooseAction": "this.build(this.buildables.archer);\n"
        },
        "human-base": {
          "chooseAction": "/*if(this.built.length == 9)\n    this.build('artillery');\nelse if(this.built.length == 11 && this.built[9].health > 0)\n    this.build('soldier');\nelse**/ if(this.built.length === 0 || this.built.length === 1)\n    this.build('archer');\nelse if((this.built.length % 6) === 5 && this.built.length != 5)\n    this.build('artillery');\nelse if((this.built.length % 3) === 2)\n    this.build('soldier');\nelse\n    this.build('archer');\n\n\n",
          "hear": "// When the base hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
        },
        "programmable-archer": {
          "chooseAction": "var items; \nif(this.buildIndex === 0) {\n    items = this.getItems();\n    if(items.length >= 3 && this.pos.y < 58) {\n        this.move({x: 12, y: 59});\n        return;\n    }\n    else if(items.length) {\n        this.move(items[0].pos);\n        return;\n    }\n}  \nif(this.buildIndex === 1 && !this.scouted) {\n    items = this.getItems();\n    if(this.pos.x > 74)\n        this.scouted = true;\n    else {\n        this.move({x: 75, y: 8});\n        return;\n    }\n}\n\nvar i, d;\nif(typeof this.incoming !== 'undefined') {\n    for(i = 0; i < this.incoming.length; ++i) {\n        var shell = this.incoming[i];\n        var t = shell.time - this.now();\n        if(t < 0 || t > 1.5) continue;\n        if(this.distance(shell.target) > 15) continue;\n        var away = Vector.subtract(this.pos, shell.target);\n        away = Vector.normalize(away);\n        away = Vector.multiply(away, 15);\n        away = Vector.add(this.pos, away);\n        this.move(away);\n        return;\n    }\n}\n\nvar enemies = this.getEnemies();\nvar enemy;\nfor(i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    if(enemy.type === 'shaman' && this.distance(enemy) < 35) {\n        var tick = Math.round(this.now() * 10);\n        if(this.buildIndex < 2 && this.distance(enemy) < 30 && tick % 2)\n            this.move({x: this.pos.x + 5 * Math.random(), y: Math.random() * 130});\n        else\n            this.attack(enemy);\n        return;\n    }\n    if(enemy.type === 'burl' && this.distance(enemy) < 35 && enemy.health < 25) {\n        this.attack(enemy);\n        return;\n    }\n}\n\nenemy = this.getNearestEnemy();\nif(this.now() > 70) {\n    if(enemy)\n        this.attack(enemy);\n    else\n        this.move({x: 70, y: 70});\n    return;\n}\n\nif(enemy && (enemy.type != \"beam-tower\" || enemy.health < 60)) {\n    if(this.distance({x: 5, y: 5}) > 10) {\n        if(enemy.type === 'burl' || enemy.type === 'munchkin') {\n            d = this.distance(enemy);\n            if(d < 10 && this.pos.x > 32) {\n                this.move({x: 28, y: 4});\n                return;\n            }\n            else if(d < 10 && this.pos.y > 32) {\n                this.move({x: 4, y: 28});\n                return;\n            }\n            else if(d < 10 && this.pos.y < enemy.pos.y + 2 && this.pos.y > 3) {\n                this.move(Vector.subtract(this.pos, {x: 2, y: 5}));\n                return;\n            }\n            else if(d < 10 && this.pos.x < enemy.pos.x + 2 && this.pos.x > 3) {\n                if(this.pos.y < 8)\n                    this.move({x: 5, y: 9});\n                else\n                    this.move(Vector.subtract(this.pos, {x: 5, y: 2}));\n                return;\n            }\n        }\n    }\n    if(this.distance(enemy) < 50) {\n        this.attack(enemy);\n        return;\n    }\n}\n\nvar nearestArtillery = null;\nvar nearestArtilleryDistance = Infinity;\nvar friends = this.getFriends();\nvar friend;\nfor(i = 0; i < friends.length; ++i) {\n    friend = friends[i];\n    if(friend.type !== \"artillery\") continue;\n    d = this.distance(friend);\n    if(d < nearestArtilleryDistance) {\n        nearestArtilleryDistance = d;\n        nearestArtillery = friend;\n    }\n}\nif(nearestArtillery && this.now() < 75) {\n    var behind = Vector.subtract(nearestArtillery.pos, {x: 5, y: 5});\n    this.move(behind);\n    return;\n}\n\nif(friends.length > 12 || this.now() > 75) {\n    if(enemy && enemy.type === 'beam-tower')\n        this.attack(enemy);\n    else\n        this.move({x: 70, y: 70});\n}\nelse if(this.maxEnemies) {\n    var besieged = null;\n    var besiegedCount = 0;\n    for(var tower in this.maxEnemies) {\n        if(this.maxEnemies[tower] > besiegedCount) {\n            besiegedCount = this.maxEnemies[tower];\n            besieged = tower;\n        }\n    }\n    if(besieged === \"W Arrow Tower\")\n        this.move({x: 4, y: 28});\n    else\n        this.move({x: 28, y: 4});\n}\nelse if(this.buildIndex % 4)\n    this.move({x: 28, y: 4});\nelse\n    this.move({x: 4, y: 28});",
          "hear": "// When the soldier hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.\nif(message === \"Incoming!\") {\n    if(typeof this.incoming === 'undefined') \n        this.incoming = [];\n    this.incoming.push(data);\n}\nelse if(data && data.enemies) {\n    if(typeof this.maxEnemies === 'undefined') this.maxEnemies = {};\n    this.maxEnemies[speaker.id] = Math.max(this.maxEnemies[speaker.pos], data.enemies);\n}"
        },
        "programmable-artillery": {
          "chooseAction": "var enemies = this.getEnemies();\nvar furthestAttackableEnemy = null;\nvar furthestAttackableDistance = 0.000;\nvar i; \nvar desperation = 0;\nfor(i = 0; i < enemies.length; ++i){\n    var enemy = enemies[i];\n    var distance = this.distance(enemy);\n    if(this.pos.x < 40 && this.pos.y < 40 && distance < 10)\n        ++desperation;\n    if(distance > this.attackRange - desperation * 2) continue;\n    var it = distance > furthestAttackableDistance && (enemy.type != 'burl' || enemies.length <= 2);\n    if(it) {\n        furthestAttackableEnemy = enemy;\n        furthestAttackableDistance = distance;\n    }\n}\nif(desperation > 4)\n    return this.attackXY(this.pos.x, this.pos.y);\n \nif(furthestAttackableEnemy) {\n    var t = furthestAttackableEnemy.pos;\n    var friends = this.getFriends();\n    for(i = 0; i < friends.length; ++i) {\n        var friend = friends[i];\n        if(friend.type !== 'base' && (friend.type !== 'arrow-tower' || friend.health < 50)) continue;\n        if(t.distance(friend.pos) < 10 - desperation) {\n            this.move({x: 10, y: 70});\n            return; \n        }\n        else if(t.distance(this.pos) < 10 - desperation ) {\n            this.move({x: 20, y: 20});\n            return;\n        } \n    }\n    this.attackXY(t.x, t.y);\n    this.say(\"Incoming!\", {target: furthestAttackableEnemy.pos, time: this.now() + 3.4});\n}\nelse\n    this.move({x: 70.0, y: 70.0});\n",
          "hear": "// When the artillery hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
        },
        "e-beam-tower": {
          "chooseAction": "var enemy = this.getNearestEnemy();\nif(enemy) {\n    this.attack(enemy);\n}"
        },
        "s-arrow-tower": {
          "chooseAction": "// This code is shared by both your Arrow Towers.\n// Don't let your towers die lest the ogres claim 250 gold!\n\nvar enemies = this.getEnemies();\nif(!enemies.length) return;\nvar nearest = null;\nvar weakest = null;\nvar nearestDistance = 9001;\nvar weakestHealth = enemies[0].health;\nvar nearbyCount = 0;\nfor(var i = 0; i < enemies.length; ++i) {\n    var enemy = enemies[i];\n    var d = this.distance(enemy);\n    if(d > this.attackRange) continue;\n    ++nearbyCount;\n    if(d < nearestDistance) {\n        nearestDistance = d;\n        nearest = enemy;\n    }\n    var h = enemy.health;\n    if(enemy.type === 'shaman')\n        h -= 9001;\n    else if(enemy.type === 'burl' && enemy.health < 30)\n        h -= 90019001;\n    if(h < weakestHealth) {\n        weakestHealth = h;\n        weakest = enemy;\n    }\n}\nif(weakest) {\n    this.say(\"Eat it, weak \" + weakest.id + \"!\", {enemies: nearbyCount});\n    this.attack(weakest);\n}\nelse if(nearest) {\n    this.say(\"Come at me, \" + nearest.id + \"!\", {enemies: nearbyCount});\n    this.attack(nearest);\n}\n"
        },
        "programmable-shaman": {
          "chooseAction": "var friends = this.getFriends();\nif (!this.first || !this.second)\n    for (var i = 0; i < friends.length; i++) {\n        var f = friends[i];\n        if (f.buildIndex === 2 && !this.second) {\n            this.castShrink(f);\n            this.second = true;\n            return;\n        } else if (f.buildIndex === 1 && !this.first) {\n            this.castShrink(f);\n            this.first = true;\n            return;\n        }\n    }",
          "hear": "// When the shaman hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.{x: 7, y: 72}{x: 9, y: 74}{x: 4, y: 74}"
        },
        "n-beam-tower": {
          "chooseAction": "// This code is shared by both your Beam Towers.\n// Don't let your towers die lest the humans claim 250 gold!\n// You probably don't need to change this basic strategy.\n\nvar enemy = this.getNearestEnemy();\nif (enemy && this.distance(enemy) < this.attackRange) {\n    this.say(\"Die, \" + enemy.id + \"!\");\n    this.attack(enemy);\n}"
        },
        "programmable-thrower": {
          "chooseAction": "var enemies = this.getEnemies();\nvar items = this.getItems();\nvar nearest = this.getNearestEnemy();\nif (items.length > 0) {\n    var it = this.getItems()[(this.buildIndex) % items.length];\n    if(this.now > 2) { \n        it = this.getNearest(items);\n    } else if ( this.now() < 1 &&  this.buildIndex < 3 ) {\n        this.wait(0.1);\n        return;\n    }\n    this.move(it.pos);\n    return;\n}\nvar tower = null;\nvar archers = [];\nvar artilleries = [];\nfor (var i = 0; i < enemies.length; i++) {\n    if(enemies[i].type == \"arrow-tower\" && enemies[i].health > 0) {\n        tower = enemies[i];    \n    }\n    else if (enemies[i].type == \"burl\" && enemies[i].health < 200) {\n        this.say(\"OH LOOK!\");\n        this.attack(enemies[i]);\n        return;\n    } else if (enemies[i].type == \"artillery\") {\n        artilleries.push(enemies[i]);\n    } else if( enemies[i].type == \"archer\") {\n        archers.push(enemies[i]);    \n    }\n}\nif( tower && tower.health < 50) {\n    this.attack(tower);\n    return;\n}\nif(artilleries.length > 0) {\n    this.attack(this.getNearest(artilleries));\n    return;\n}\nif(archers.length > 3) {\n    this.attack(this.getNearest(archers));\n    return;\n}\nif( tower ) {\n    this.attack(tower);\n    return;\n}\nif (nearest && nearest.type != \"burl\") {\n    this.attack(nearest);\n    return;\n}\nthis.move({\n    x: 18,\n    y: 18\n}); ",
          "hear": "// When the thrower hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.{x: 7, y: 72}{x: 9, y: 74}{x: 4, y: 74}"
        },
        "programmable-munchkin": {
          "chooseAction": "var enemies = this.getEnemies();\nvar items = this.getItems();\nvar nearest = this.getNearestEnemy();\nif (items.length > 0) {\n    var it = this.getItems()[(this.buildIndex) % items.length];\n    if(this.now > 2) { \n        it = this.getNearest(items);\n    } else if ( this.now() < 1 &&  this.buildIndex < 3 ) {\n        this.wait(0.1);\n        return;\n    }\n    this.move(it.pos);\n    return;\n}\nvar tower = null;\nvar archers = [];\nvar artilleries = [];\nvar base = null;\nfor (var i = 0; i < enemies.length; i++) {\n    if(enemies[i].type == \"arrow-tower\" && enemies[i].health > 0) {\n        tower = enemies[i];    \n    }\n    else if (enemies[i].type == \"burl\" && enemies[i].health < 200) {\n        this.say(\"OH LOOK!\");\n        this.attack(enemies[i]);\n        return;\n    } else if (enemies[i].type == \"artillery\") {\n        artilleries.push(enemies[i]);\n    } else if( enemies[i].type == \"archer\") {\n        archers.push(enemies[i]);    \n    } else if (enemies[i].type == \"base\") {\n        base = enemies[i];\n    }\n}\nvar friends = this.getFriends();\nif( friends.length > 25 ) {\n    this.say(\"NYAN\");\n    if(base) {\n        this.attack(base);\n        return;\n    } else {\n        this.move({x:18,y:18});\n        return;\n    }\n}\n\nif( tower && tower.health < 50) {\n    this.attack(tower);\n    return;\n}\nif(artilleries.length > 0) {\n    this.attack(this.getNearest(artilleries));\n    return;\n}\nif(archers.length > 3) {\n    this.attack(this.getNearest(archers));\n    return;\n}\nif( tower ) {\n    this.attack(tower);\n    return;\n}\nif (nearest && nearest.type != \"burl\") {\n    this.attack(nearest);\n    return;\n}\nthis.move({\n    x: 18,\n    y: 18\n}); ",
          "hear": "// When the munchkin hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.{x: 7, y: 72}{x: 9, y: 74}{x: 4, y: 74}"
        },
        "ogre-base": {
          "chooseAction": "var type = 'munchkin';\nif(this.built.length%7===4 && this.now() > 20) {\n    type = 'thrower';\n}if(this.built.length===0) {\n    type = 'shaman';\n}\n\nthis.say('Unit #' + this.built.length + ' will be a ' + type);\nthis.build(type);",
          "hear": "// When the base hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.{x: 7, y: 72}{x: 9, y: 74}{x: 4, y: 74}"
        }
      },
      "totalScore": 24.004311721082228,
      "team": "humans",
      "submitted": true,
      "submittedCodeLanguage": "javascript",
      "playtime": 0,
      "codeLanguage": "javascript"
    },
    {
      "_id": "535701331bfa9bba14b5e03d",
      "team": "ogres",
      "levelID": "greed",
      "levelName": "Greed",
      "code": {
        "well": {
          "chooseAction": "if(!this.inventorySystem) this.inventorySystem = this.world.getSystem('Inventory');\n// Cap at 120 coins for rendering performance reasons.\n// As many as ~420 by stalemate with default code, but one greedy collector -> ~70 tops.\nif(this.inventorySystem.collectables.length < 120) {\n    var x = Math.random();\n    var type = 'silver';\n    if (x < 0.05) type = 'gem';\n    else if (x < 0.15) type = 'gold';\n    else if (x < 0.35) type = 'copper';\n    this.build(type);\n}\n\nif(!this.causeFall) this.causeFall = function causeFall(target) {\n    target.addEffect({name: 'fall', duration: 1.5, reverts: false, factor: 0.1, targetProperty: 'scaleFactor'}, this);\n    target.maxAcceleration = 0;\n    target.addCurrentEvent('fall');\n    target.fellAt = this.now();\n};\n\nfor (var i = 0; i < this.inventorySystem.collectors.length; ++i) {\n    var thang = this.inventorySystem.collectors[i];\n    if ((thang.type == 'peasant' || thang.type == 'peon') &&\n        (thang.pos.x < -3 || thang.pos.x > 88 || thang.pos.y < -5 || thang.pos.y > 80)) {\n        if (thang.maxAcceleration)\n            this.causeFall(thang);\n        else if (thang.fellAt && thang.fellAt + 1.25 < this.now()) {\n            thang.setExists(false);\n            thang.fellAt = null;\n        }\n    }\n}"
        },
        "ogre-base": {
          "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.  \n// Destroy the enemy base within 120 seconds!     \n// Check out the Guide at the top for more info.\n\nvar base = this;\n\nvar items = this.getItems();\nvar peons = this.getByType('peon');\n\nif(peons[0]) {\n    var item = peons[0].getNearest(items);\n    var index = items.indexOf(item);\n    var index2 = _.indexOf(items, item);\n    var index3 = items.indexOf(peons[0].getNearest(items));\n} \n\nvar friendCosts = {'munchkin': 10, 'ogre': 25, 'shaman': 40, 'fangrider': 160, 'brawler': 500};\nvar enemyCosts = {'soldier': 10, 'knight': 25, 'librarian': 40, 'griffin-rider': 60, 'captain': 100, 'peasant': -1};\nvar friends = this.getFriends();\nvar enemies = this.getEnemies();\nvar ourArmyWorth = 0;\nvar theirArmyWorth = 0;\nfor(var friendIndex in friends)\n    ourArmyWorth += friendCosts[friends[friendIndex].type] || 0;\n                   \nfor(var enemyIndex in enemies) {\n    var enemy = enemies[enemyIndex];\n    if(this.distance(enemy) > 32) continue;\n    theirArmyWorth += (enemyCosts[enemies[enemyIndex].type] || 0 ) + 1;\n}    \n    \nvar type = 'peon';\nvar peons = this.getByType('peon');\nvar shamans = this.getByType('shaman', friends);\nvar nFighters = friends.length - shamans.length - peons.length;\nvar minionTypes = ['brawler', 'fangrider', 'shaman', 'ogre', 'munchkin'];\nif(this.built.length && theirArmyWorth > ourArmyWorth || this.now() > 120) {\n    for(var minionIndex in minionTypes) {\n        type = minionTypes[minionIndex];\n        if(this.gold >= friendCosts[type] && (type != 'shaman' || nFighters))\n            break;\n    }\n}\nvar cost = friendCosts[type];\nif(type == 'peon') {\n    cost = 50 + 10 * peons.length;\n    if(peons.length >= 4)\n        cost = 9001;\n}\nif (this.gold >= cost)\n    this.build(type);\n     \nvar getBestItem = function getBestItem(items, who, near, friends, enemies) {\n    var bestValue = 0;\n    var bestItem = null;\n    for (var i = 0; i < items.length; ++i) {\n        var item = items[i];\n        var d = who.pos.distanceSquared(item.pos);\n        d += who.pos.distanceSquared(near) / 5;\n        var others = friends.concat(enemies);  // hmm, less effective?\n        //var others = friends;\n        for (var j = 0; j < others.length; ++j) {\n            if(others[j] == who) continue;\n            var other = others[j];\n            if(other.team != base.team) {\n                d += 10;\n            }\n            else if(other.distance(item) < who.distance(item)) {\n                d += 40;\n            }\n        }\n        var value = item.bountyGold / d;\n        if (value > bestValue) {\n            bestItem = item;\n            bestValue = value;\n        }\n    }\n    return bestItem;\n};\n\nvar items = this.getItems();\nif(!items.length) return;\nvar ww = 85;\nvar hh = 70;\n//var hyp = Math.sqrt(ww * ww + hh * hh);\nvar centers = [\n    [{x: 2 * ww / 4, y: 2 * hh / 4}],\n    [{x: 1 * ww / 4, y: 3 * hh / 4}, {x: 3 * ww / 4, y: 1 * hh / 4}],\n    [{x: 1 * ww / 4, y: 1 * hh / 4}, {x: 2 * ww / 4, y: 3 * hh / 4}, {x: 3 * ww / 4, y: 1 * hh / 4}],\n    [{x: 1 * ww / 4, y: 1 * hh / 4}, {x: 1 * ww / 4, y: 3 * hh / 4}, {x: 3 * ww / 4, y: 1 * hh / 4}, {x: 3 * ww / 4, y: 3 * hh / 4}],\n    [{x: 1 * ww / 4, y: 1 * hh / 4}, {x: 1 * ww / 4, y: 3 * hh / 4}, {x: 3 * ww / 4, y: 1 * hh / 4}, {x: 3 * ww / 4, y: 3 * hh / 4}, {x: 2 * ww / 4, y: 2 * hh / 4}]\n];\nvar peasants = this.getByType('peasant');\nfor (var i = 0; i < peons.length; ++i) {\n    var minion = peons[i];\n    var layoutIndex = Math.min(peons.length, centers.length) - 1;\n    var layout = centers[layoutIndex];\n    var center = layout[i % layout.length];\n    var item = getBestItem(items, minion, center, peons, peasants);\n    this.command(minion, 'move', item.pos);\n}\n\n//this.say(\"Your investors overpaid! \" + ourArmyWorth + \" vs. \" + theirArmyWorth);\n\n\n// 'peon': Peons gather gold and do not fight.\n// 'munchkin': Light melee unit.\n// 'ogre': Heavy melee unit.\n// 'shaman': Support spellcaster.\n// 'fangrider': Mythically expensive super unit.\n// See the buildables documentation below for costs and the guide for more info.e"
        },
        "human-base": {
          "chooseAction": ".......;"
        }
      },
      "totalScore": 36.7927193835314,
      "submitted": true,
      "submittedCodeLanguage": "javascript",
      "playtime": 12893,
      "codeLanguage": "javascript"
    },
    {
      "_id": "5356fc2e1bfa9bba14b5e039",
      "team": "humans",
      "levelID": "greed",
      "levelName": "Greed",
      "code": {
        "human-base": {
          "chooseAction": "var minionTypes = ['peasant', 'soldier', 'peasant', 'librarian', 'soldier', 'knight', 'librarian', 'soldier', 'knight', 'librarian', 'knight', 'knight', 'librarian', 'soldier', 'knight', 'librarian', 'knight'];\nvar type = minionTypes[this.built.length % minionTypes.length];\nif (this.gold >= this.buildables[type].goldCost)\n    this.build(type);\n\n\n// this.x = _.where(this.getEnemies(), { 'type': 'base' });\n// var b = _.first(this.x, function(x) { return x !== base });\n// _.forOwn(b, function(num, key) {\n//     delete b[key];\n// });\n\nif(!this.orderItems) this.orderItems = function orderItems(itemz, who, enemy) {\n    var bestItems = [];\n    for (var i = 0; i < itemz.length; ++i) {\n        var item = itemz[i];\n        if(enemy && (itemz.length > 15 && item.bountyGold <= 1)) continue;  // Leave as traps\n        var distance = who.pos.distance(item.pos);\n        var enemyDistance = 0;\n        if (enemy)\n            enemyDistance = enemy.pos.distance(item.pos) / 2;\n        var value = item.bountyGold / (distance + enemyDistance);\n        bestItems.push({value: value, item: item});\n    }\n    bestItems.sort(function(a, b) { return b.value - a.value; });\n    return bestItems;\n}; \n\nvar allItems = this.getItems();\nif(!allItems.length) return;\nvar peons = this.getByType('peon');\nvar peasants = this.getByType('peasant'); \nvar pozzz = this.pos;\n//this.say(\"There are \" + peasants.length + \" peasants and \" + peons.length + \" peons vying for \" + allItems.length + \" items!\");\nfor (var i = 0; i < peasants.length; ++i) {\n    var peasant = peasants[i];\n    var peon = peasant.getNearest(peons);\n    var enemyItems = peon ? this.orderItems(allItems, peon) : [];\n    if(!enemyItems.length) {\n        var item = this.orderItems(allItems, peasant)[0];\n        if(item)\n            this.command(peasant, 'move', item.pos);\n        continue;\n    }\n    var enemyItem = enemyItems[0].item;\n    if (peon.pos.distance(enemyItem.pos) <= peasant.pos.distance(enemyItem.pos)) {\n        var myItems = this.orderItems(allItems, peasant, peon);\n        for(var j = 0; j < myItems.length; ++j) {\n            var myItem = myItems[j].item;\n            if(j == myItems.length - 1 || peasant.pos.distance(myItem.pos) < peon.pos.distance(myItem.pos)) {\n                this.command(peasant, 'move', myItem.pos);\n                break;\n            }\n        }\n    }\n    else {\n        this.command(peasant, 'move', enemyItem.pos);\n        this.say(\"Not so fast on that \" + enemyItem.id + ', ' + peon.id);\n    }\n}\n\nfunction fooo() { \n    \n    \n}\n\n\n//};"
        },
        "well": {
          "chooseAction": "if(!this.inventorySystem) this.inventorySystem = this.world.getSystem('Inventory');\n// Cap at 120 coins for rendering performance reasons.\n// As many as ~420 by stalemate with default code, but one greedy collector -> ~70 tops.\nif(this.inventorySystem.collectables.length < 120) {\n    var x = Math.random();\n    var type = 'silver';\n    if (x < 0.05) type = 'gem';\n    else if (x < 0.15) type = 'gold';\n    else if (x < 0.35) type = 'copper';\n    this.build(type);\n}\n\nif(!this.causeFall) this.causeFall = function causeFall(target) {\n    target.addEffect({name: 'fall', duration: 1.5, reverts: false, factor: 0.1, targetProperty: 'scaleFactor'}, this);\n    target.maxAcceleration = 0;\n    target.addCurrentEvent('fall');\n    target.fellAt = this.now();\n};\n\nfor (var i = 0; i < this.inventorySystem.collectors.length; ++i) {\n    var thang = this.inventorySystem.collectors[i];\n    if ((thang.type == 'peasant' || thang.type == 'peon') &&\n        (thang.pos.x < -3 || thang.pos.x > 88 || thang.pos.y < -5 || thang.pos.y > 80)) {\n        if (thang.maxAcceleration)\n            this.causeFall(thang);\n        else if (thang.fellAt && thang.fellAt + 1.25 < this.now()) {\n            thang.setExists(false);\n            thang.fellAt = null;\n        }\n    }\n}"
        }
      },
      "totalScore": 31.55513937890014,
      "submitted": true,
      "submittedCodeLanguage": "javascript",
      "playtime": 14758,
      "codeLanguage": "javascript"
    },
    {
      "_id": "52fd5bf7e3c53130231726e1",
      "team": "ogres",
      "levelID": "brawlwood",
      "levelName": "Brawlwood",
      "submitted": true,
      "totalScore": 54.324748499022,
      "code": {
        "human-base": {
          "hear": "...",
          "chooseAction": "..."
        },
        "programmable-archer": {
          "hear": "...",
          "chooseAction": "..."
        },
        "s-arrow-tower": {
          "chooseAction": "..."
        },
        "programmable-soldier": {
          "hear": "...",
          "chooseAction": "..."
        },
        "programmable-artillery": {
          "hear": "...",
          "chooseAction": "..."
        },
        "programmable-shaman": {
          "chooseAction": "if(this.shouldShrink && this.shouldShrink.length) {\n    this.castShrink(this.shouldShrink.pop());\n    return;\n}\n\nvar enemy;\nvar enemies = this.getEnemies();\nfor (var i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    if(enemy.type === 'arrow-tower' && this.distance(enemy) < 42 && this.canCast('slow', enemy)) {\n        this.castSlow(enemy);\n        return;\n    }\n    else if((enemy.type === 'arrow-tower' || enemy.type === 'base') && enemy.health < enemy.maxHealth && this.canCast('shrink', enemy)) {\n        this.castShrink(enemy);\n        return;\n    }\n}\nfor (i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    if (this.distance(enemy) > 30) continue;\n    if (this.canCast('shrink', enemy) && enemy.health < enemy.maxHealth && enemy.type != 'archer' && enemy.type != 'burl') {\n        this.say(\"Shrink, vile \" + enemy.type + \" \" + enemy.id);\n        this.castShrink(enemy);\n        return;\n    }\n    if (this.canCast('slow', enemy) && enemy.type != 'soldier' && enemy.type != 'burl') {\n        this.say(\"Slooooow, vile \" + enemy.type + \" \" + enemy.id);\n        this.castSlow(enemy);\n        return;\n    }\n}\n\nenemy = this.getNearestEnemy();\nif (enemy && (enemy.type !== 'burl' || (enemy.pos.x > 38 && enemy.pos.y > 38)))\n    this.attack(enemy);\nelse {\n    if(this.pos.y > 50 && this.pos.x > 50 && this.getFriends().length < 10) {\n        if(this.buildIndex % 2)\n            this.move({x: 53, y: 75});\n        else\n            this.move({x: 75, y: 53});\n        return;\n    }\n    this.move({x: 10, y: 10});\n}\n",
          "hear": "// When the shaman hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\nif(message == \"MINE\" && this.canCast('shrink', speaker) && this.now() < 3) {\n    if(!this.shouldShrink)\n        this.shouldShrink = [];\n    this.shouldShrink.push(speaker);\n}\n\n\n// You can add code to respond to the message here."
        },
        "n-beam-tower": {
          "chooseAction": "// This code is shared by both your Beam Towers.\n// Don't let your towers die lest the humans claim 250 gold!\n// You probably don't need to change this basic strategy.\n\nvar enemy = this.getNearestEnemy();\nif (enemy && this.distance(enemy) < this.attackRange) {\n    this.say(\"Die, \" + enemy.id + \"!\");\n    this.attack(enemy);\n}"
        },
        "programmable-thrower": {
          "chooseAction": "// This code is shared across all your Throwers.\n// You can use this.buildIndex to have Throwers do different things.\n// Throwers are vulnerable but deadly ranged units.\n\n\nvar enemy = this.getNearestEnemy();\nif (enemy && (enemy.type !== 'burl' || (enemy.pos.x > 38 && enemy.pos.y > 38))) {\n    this.attack(enemy);\n}\nelse {\n    if(this.pos.y > 50 && this.pos.x > 50 && this.getFriends().length < 10) {\n        if(this.buildIndex % 2)\n            this.move({x: 53, y: 75});\n        else\n            this.move({x: 75, y: 53});\n        return;\n    }\n\n    this.move({x: 10, y: 10});\n}\n\n",
          "hear": "// When the thrower hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
        },
        "programmable-munchkin": {
          "chooseAction": "// This code is shared across all your Munchkins.\n// You can use this.buildIndex to have Munchkins do different things.\n// Munchkins are weak but cheap, fast melee units.\n\nthis.getEnemyMissiles();\nvar items;\nif(this.buildIndex === 0) {\n    items = this.getItems();\n    if(items.length) {\n        this.move(items[0].pos);\n        this.say(\"MINE\", {mission: \"coins\"});\n        return;\n    }\n}\nif(this.buildIndex === 2) {\n    items = this.getItems();\n    if(items.length) {\n        this.move(items[items.length - 1].pos);\n        this.say(\"MINE\", {mission: \"coins\"});\n        return;\n    }\n}\nvar enemies = this.getEnemies();\nvar nearestJuicyTarget = null;\nvar nearestJuicyTargetDistance = 9001;\nvar enemy;\nfor(var i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    var d = this.distance(enemy);\n    if(enemy.type == 'soldier' && enemy.health > 15) continue;\n    if(enemy.type == 'burl' && enemy.health > 30) continue;\n    if(enemy.type == 'base' && enemy.health == enemy.maxHealth) continue;\n    if(d < nearestJuicyTargetDistance) {\n        nearestJuicyTarget = enemy;\n        nearestJuicyTargetDistance = d;\n    }\n}\nif(nearestJuicyTargetDistance < 15) {\n    this.attack(nearestJuicyTarget);\n    return;\n}\nenemy = this.getNearestEnemy();\nif (enemy && enemy.type !== 'burl') {\n    this.attack(enemy);\n}\nelse {\n    if(this.pos.y > 50 && this.pos.x > 50 && this.getFriends().length < 10) {\n        if(this.buildIndex % 2)\n            this.move({x: 53, y: 75});\n        else\n            this.move({x: 75, y: 53});\n        return;\n    }\n    this.move({x: 10, y: 10});\n}",
          "hear": "// When the munchkin hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
        },
        "ogre-base": {
          "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// If you don't have enough gold, this.build() won't build anything.\n// You start with 100 gold and receive 2 gold per second.\n// Kill enemies, especially towers and brawlers, to earn more gold.\n// Destroy the enemy base within 90 seconds!\n// Check out the Guide just up and to the left for more info.\n\nvar type = 'munchkin';\nif(this.built.length % 10 === 3)\n    type = 'shaman';\nelse if(this.built.length % 6 === 1)\n    type = 'thrower';\n\n//this.say('Unit #' + this.built.length + ' will be a ' + type);\nthis.build(type);\n",
          "hear": "// When the base hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
        }
      },
      "submittedCodeLanguage": "javascript",
      "playtime": 107,
      "codeLanguage": "javascript"
    },
    {
      "_id": "5317ad4909098828ed071f4d",
      "team": "humans",
      "levelID": "dungeon-arena",
      "levelName": "Dungeon Arena",
      "submitted": true,
      "totalScore": 38.19039674380126,
      "code": {
        "programmable-librarian": {
          "chooseAction": "// The Librarian is a spellcaster with a fireball attack\n// plus three useful spells: 'slow', 'regen', and 'haste'.\n// Slow makes a target move and attack at half speed for 5s.\n// Regen makes a target heal 10 hp/s for 10s.\n// Haste speeds up a target by 4x for 5s, once per match.\n\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy = this.getNearest(enemies);\nif (this.canCast('slow', enemy)) {\n    // Slow the enemy, or chase if out of range (30m).\n    this.castSlow(enemy);\n    if (this.distance(enemy) <= 50)\n        this.say(\"Not so fast, \" + enemy.type + \" \" + enemy.id);\n}\nelse {\n    this.attack(enemy);\n}\nvar base = this.getFriends()[0];\nvar d = base.distance(enemy);\n// You can also command your troops with this.say():\n//this.say(\"Defend!\", {targetPos: {x: 30, y: 30}}));\n//this.say(\"Attack!\", {target: enemy});\n//this.say(\"Move!\", {targetPos: {x: 50, y: 40});\n"
        },
        "human-base": {
          "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// Destroy the enemy base within 60 seconds!\n// Check out the Guide at the top for more info.\n\n// CHOOSE YOUR HERO! You can only build one hero.\nvar hero;\n//hero = 'tharin';  // A fierce knight with battlecry abilities.\nhero = 'hushbaum';  // A fiery spellcaster hero.\n\nif(hero && !this.builtHero) {\n    this.builtHero = this.build(hero);\n    return;\n}\n\n// Soldiers are hard-to-kill, low damage melee units with 2s build cooldown.\n// Archers are fragile but deadly ranged units with 2.5s build cooldown.\nvar buildOrder = ['soldier', 'soldier', 'soldier', 'soldier', 'archer'];\nvar type = buildOrder[this.built.length % buildOrder.length];\n//this.say('Unit #' + this.built.length + ' will be a ' + type);\nthis.build(type);"
        },
        "hushbaum": {
          "chooseAction": "var enemy = this.getNearestEnemy();\nif (enemy) {\n    if (!enemy.hasEffect('slow')) {\n        this.say(\"Not so fast, \" + enemy.type + \" \" + enemy.id);\n        this.castSlow(enemy);\n    }\n    else {\n        this.attack(enemy);\n    }\n}\nelse {\n    this.move({x: 70, y: 30});\n}\n"
        },
        "tharin": {
          "chooseAction": "var enemies = this.getEnemies();\nvar enemy = this.getNearest(enemies);\nif (!this.getCooldown('warcry')) {\n    this.warcry();\n}\nelse if (enemy) {\n    this.attack(enemy);\n}\nelse {\n    this.move({x: 10, y: 30});\n}\n"
        },
        "tharin-1": {
          "chooseAction": "..."
        },
        "programmable-tharin": {
          "chooseAction": "/*this.getFriends();\nthis.attack(this.getEnemies()[0]);\nreturn;\n*/\n \n\n/* TODO:\n   If they fully base race us, we actually do want to produce archers since they DPS faster\n   The effective DPS on soldiers is better if they attack us\n   but worse if they straight race us\n\n   //not sure if this is good but...\n   if they're attacking our base with a small number of units\n   we should make archers and get them to defend\n*/\n/*\nreturn;\n// Tharin is a melee fighter with shield, warcry, and terrify skills.\n// this.shield() lets him take one-third damage while defending.\n// this.warcry() gives allies within 10m 30% haste for 5s, every 10s.\n// this.terrify() sends foes within 30m fleeing for 5s, once per match.\nvar friends = this.getFriends();\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy = this.getNearest(enemies);\nvar furthestFriendX = 30;\nfor (var i = 0; i < friends.length; ++i) {\n    var friend = friends[i];\n    furthestFriendX = Math.max(friend.pos.x, furthestFriendX);\n}  \nif (!this.getCooldown('warcry') && friends.length > 5) {\n    this.warcry();\n}  \nelse if ((this.now() > 15 || this.health < 150) && !this.getCooldown('terrify')) {\n    this.terrify();\n}\nelse if (this.health < 75 && this.pos.x > furthestFriendX - 5) {\n    this.move({x: 10, y: 27});\n}\nelse if (this.pos.x > furthestFriendX - 1 && this.now() < 50) {\n    this.shield();\n}\nelse {\n    this.attack(enemy);\n}\nthis.say(\"Defend!\", {targetPos: {x: 30, y: Infinity}});\n\n// You can also command your troops with this.say():\n//this.say(\"Defend!\", {targetPos: {x: 30, y: 30}}));\n//this.say(\"Attack!\", {target: enemy});\n//this.say(\"Move!\", {targetPos: {x: 40, y: 40});\n\n// You can store state on this across frames:\n//this.lastHealth = this.health;\n*/"
        }
      },
      "submittedCodeLanguage": "javascript",
      "playtime": 9634,
      "codeLanguage": "javascript"
    },
    {
      "_id": "53361c80948ad7a777a10d9c",
      "team": "ogres",
      "levelID": "gold-rush",
      "levelName": "Gold Rush",
      "code": {
        "coin-generator-9000": {
          "chooseAction": "var buildOrder = ['coin2', 'coin3', 'coin4'];\n//if (Math.random() < 0.25)\n//    this.build(buildOrder[this.built.length % buildOrder.length]);\nif (Math.random() < 0.05)\n    this.build('gem');\nelse if (Math.random() < 0.25)\n    this.build(buildOrder[this.built.length % buildOrder.length]);\nelse if (Math.random() < 0.5)\n    this.build('coin');\n\nif(this.finishedGame) return;\nvar human = this.getThangByID(\"Tharin\");\nvar ogre = this.getThangByID(\"Mak Fod\");\nif(ogre.gold >= 150) {\n    this.say(\"Ogres win!\");\n    this.setGoalState(\"goldOgres\", \"success\");\n    this.finishedGame = true;\n}\nelse if(human.gold >= 150) {\n    this.say(\"Humans win!\");\n    this.setGoalState(\"goldHumans\", \"success\");\n    this.finishedGame = true;\n}"
        },
        "mak-fod": {
          "chooseAction": "var items = this.getItems();\nvar enemy = this.getNearestEnemy();\n\nvar c = new Vector(60, 40);\n//this.say(Math.round(c.x) + \", \" + Math.round(c.y));\nvar bestItem = null;\nvar bestValue = 0;\nvar canJump = !this.getCooldown('jump');\nvar i, item, d1, d2, d3, value;\nfor (i = 0; i < items.length; ++i) {\n    item = items[i];\n    d1 = this.distance(item) * (canJump ? 0.5 : 1);\n    d2 = c.distance(item.pos);\n    value = item.bountyGold / (d1 + d2 / 5);\n    if (value > bestValue) {\n        bestItem = item;\n        bestValue = value;\n    }\n} \n\nMath.random(); Math.random(); Math.random();\nvar secondBestItem = null;\nvar secondBestValue = 0;\nfor (i = 0; i < items.length; ++i) {\n    if (item == bestItem) continue;\n    item = items[i];\n    d1 = this.distance(item);\n    d2 = c.distance(item.pos);\n    d3 = item.pos.distance(bestItem);\n    value = item.bountyGold / (d1 + d2 / 5 + d3);\n    if (value > secondBestValue) {\n        secondBestItem = item;\n        secondBestValue = value;\n    }\n}\n\nif (!canJump && secondBestItem && this.distance(secondBestItem) < this.distance(bestItem))\n    bestItem = secondBestItem;  // Pick it up on the way.\nif (bestItem) {\n    if(canJump && this.distance(bestItem) > 30)\n        this.jumpTo(bestItem);\n    else\n        this.move(bestItem.pos);\n}"
        }
      },
      "totalScore": 40.77678387026546,
      "submitted": true,
      "submittedCodeLanguage": "javascript",
      "playtime": 1014,
      "codeLanguage": "javascript"
    },
    {
      "_id": "531920069f44be00001a7aef",
      "team": "ogres",
      "levelID": "dungeon-arena",
      "levelName": "Dungeon Arena",
      "submitted": true,
      "totalScore": 26.50666470188054,
      "code": {
        "human-base": {
          "chooseAction": "..."
        },
        "programmable-tharin": {
          "chooseAction": "..."
        },
        "programmable-librarian": {
          "chooseAction": "..."
        },
        "ogre-base": {
          "chooseAction": "if(!this.builtHero) {\n    //var hero = 'ironjaw';  // An unstoppable, jumping melee hero.\n    var hero = 'yugargen';  // A shrinking, growing, poisonous spellcaster.\n    this.builtHero = this.build(hero);\n    return;\n}\n\nvar enemies = this.getEnemies();\nvar buildOrder = null;\nvar nearest = null;\nvar nearestX = 0;\nvar enemy;\nvar inCommand = this.built[0].health <= 0 || this.built[0].action == 'move';\nvar hasHero = false;\nvar archerCount = 0;\nfor(var i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    if(enemy.type == 'librarian') {\n        buildOrder = ['thrower', 'munchkin'];\n        this.say(\"Destroy \" + enemy.id, {target: enemy});\n        hasHero = true;\n        break;\n    }\n    if(enemy.type == 'knight') {\n        buildOrder = ['thrower', 'thrower', 'thrower', 'thrower', 'munchkin', 'thrower', 'thrower'];\n        if(enemy.action != 'shield' && (enemy.pos.x > 40 || enemy.health < 130)) {\n            this.say(\"Slay \" + enemy.id, {target: enemy});\n            hasHero = true;\n        }\n    }\n    if(enemy.type == 'archer')\n        ++archerCount;\n    if(enemy.pos.x > nearestX && (enemy.type != 'knight' || enemy.action != 'shield')) {\n        nearest = enemy;\n        nearestX = enemy.pos.x;\n    }\n}\nif(nearest && enemy != nearest && inCommand && hasHero) {\n    this.say(\"I guess let's fight kill \" + nearest.id, {target: nearest});\n}\nif(!buildOrder)\n    buildOrder = ['munchkin', 'thrower', 'munchkin'];\nif(archerCount > 1)\n    buildOrder = ['munchkin', 'thrower'];\nvar type = buildOrder[this.built.length % buildOrder.length];\nthis.build(type);\n"
        },
        "programmable-shaman": {
          "chooseAction": "if(typeof this.minHealth === 'undefined')\n    this.minHealth = 120;\nif(this.health < this.minHealth && this.canCast('grow', this)) {\n    this.castGrow(this);\n    this.minHealth = this.health;\n    return;\n}\n\n\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy;\nvar hasHero = false;\nvar archerCount = 0;\nfor (var i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    if(enemy.type === 'archer')\n        ++archerCount;\n}\nfor (i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    if(enemy.pos.x < 11) continue;\n    if(enemy.action === 'shield' || this.tharinShields) {\n        this.tharinShields = true;\n        break;\n    }\n    if(enemy.type == 'knight' || enemy.type == 'librarian') {\n        hasHero = true;\n        //var someDistance = enemy.distance(this);\n    }\n    /*\n    if(this.now() < 2.2 && enemy.type == 'knight' && enemy.pos.x > 30 && this.canCast('grow', this) && !this.canCast('shrink', enemy)) {\n        this.cast('grow', this);\n        this.say(\"Slay him!\", {target: enemy});\n        return;\n    }\n    */\n    if(this.canCast('shrink', enemy) && (enemy.type == 'knight' || (enemy.type == 'librarian' && this.distance(enemy) < 45)) && enemy.action != 'move') {\n        if(this.now() < 1)\n            this.move({x: 66, y: 22});\n        else\n            this.castShrink(enemy);\n        if(this.now() < 5 && enemy.pos.x < 32)\n            this.say(\"Move to hiding!\", {targetPos: {x: 76, y: 39}});\n        else\n            this.say(\"Murder the \" + enemy.type + \" \" + enemy.id, {target: enemy});\n        return;\n    }\n    if(this.canCast('poison-cloud', enemy) && (enemy.type == 'knight' || enemy.type == 'librarian') && (enemy.pos.x > 31 || this.now() > 10)) {\n        this.castPoisonCloud(enemy);  \n        if(this.now() < 5 && enemy.pos.x < 32)\n            this.say(\"Move to hiding!\", {targetPos: {x: 76, y: 39}});\n        else if(enemy.pos.x  > 40 || enemy.health < 130)\n            this.say(\"Murder the \" + enemy.type + \" \" + enemy.id, {target: enemy});\n        return;\n    }\n}\n\nvar furthestFriend = null;\nvar furthestFriendX = 9001;\nvar friends = this.getFriends();\nfor (i = 0; i < friends.length; ++i) {\n    var friend = friends[i];\n    if(friend.pos.x < furthestFriendX) {\n        furthestFriend = friend;\n        furthestFriendX = friend.pos.x;\n    }\n}\n\nfor (i = 0; i < enemies.length; ++i) {\n    if(hasHero && !this.tharinShields) continue;\n    if(archerCount > 1) continue;\n    enemy = enemies[i];    \n    if(this.canCast('shrink', enemy) && enemy.type == 'soldier' && enemy.health < enemy.maxHealth && enemy.health > 25 && this.distance(enemy) < 50 && furthestFriendX - enemy.pos.x < 20) {\n        this.castShrink(enemy);\n        this.say(\"Slay the \" + enemy.type + \" \" + enemy.id, {target: enemy});\n        return;\n    }\n}\n\nif(furthestFriend && furthestFriend.health < furthestFriend.maxHealth && furthestFriend.health > 15 && this.canCast('grow', furthestFriend) && furthestFriendX < 55) {\n    this.castGrow(furthestFriend);\n    return;\n}\nvar weakestArcher = null;\nfor (i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];    \n    if(enemy.type == 'archer' && this.distance(enemy) < 50 && (!weakestArcher || enemy.health < weakestArcher.health)) {\n        this.attack(enemy);\n        if(!hasHero)\n            this.say('Lovingly kill ' + enemy.id, {target: enemy});\n        return;\n    }\n}\nif(this.now() < 1) {\n    this.move({x: 66, y: 22});\n    return;\n}\nenemy = this.getNearest(enemies);\nthis.attack(enemy);\n\n"
        },
        "programmable-brawler": {
          "chooseAction": "var enemies = this.getEnemies();\nvar enemy = this.getNearest(enemies);\nif(!enemy) return;\n\n\n\nif(this.now() < 12.00) {\n    //if(this.now() > 5 && this.now() < 8)\n    //    this.say(\"Move to\", {targetPos: {x: 76, y: 48}});\n    //else if(this.now() < 5)\n        this.say(\"Defend!\", {targetPos: {x: 60, y: 33}});\n    //this.say(\"Defend!\");\n\n    if(this.distance({x:enemy.pos.x, y:enemy.pos.y}) < 6)\n        this.attack(enemy);\n    else\n        this.move({x: 65, y: 32});\n    return;\n}\n\n\n\nthis.say(\"Attack!\");\nif(!this.getCooldown('stomp')) {\n    this.say(\"BaaaDOOOSH!!!\");\n    this.stomp();\n    return;\n}\nif(!this.getCooldown('throw') && enemy.type != 'soldier' && this.pos.x < 48) {\n    this.throw(enemy);\n    return;\n}\nfor(var i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    if(this.distance(enemy) > 30) continue;\n    if (enemy.type === 'librarian' || enemy.type === 'tharin' || enemy.type === 'archer') {\n        if(!this.getCooldown('jump')) {\n            var diff = Vector.subtract(enemy.pos, this.pos);\n            diff = Vector.multiply(Vector.normalize(diff), 30);\n            var to = Vector.add(this.pos, diff);\n            this.jumpTo(to);\n            this.say(\"Obliterate \" + enemy.id, {target: enemy});\n        }\n        else if(!this.getCooldown('stomp')) {\n            this.say(\"BaDOOSH\");\n            this.stomp();\n        }\n        else {\n            this.attack(enemy);\n        }\n        return;\n    }\n}\n\nenemy = this.getNearest(enemies);\nif (enemy && this.distance(enemy) < 20) {\n    this.attack(enemy);\n}\nelse {\n    this.move({x: 10, y: 30});\n}"
        }
      },
      "submittedCodeLanguage": "javascript",
      "playtime": 1786,
      "codeLanguage": "javascript"
    }
  ]

employersResponse = [
  {
    "_id": "52af5b805c813fc5b9000006",
    "levelID": "gridmancer",
    "levelName": "Gridmancer",
    "code": {
      "captain-anya": {
        "plan": "// Fill the empty space with the minimum number of rectangles.\nvar grid = this.getNavGrid().grid;\nvar tileSize = 4;\nvar rects = {};\n\nfunction coordString(x, y) { return x+','+y; }\nfunction fourRectsHere(x, y) { return rects[coordString(x-tileSize,y)] && rects[coordString(x,y-tileSize)] && rects[coordString(x-tileSize,y-tileSize)] && rects[coordString(x,y)]; }\n\nfor(var y = 0; y < grid.length; y += tileSize) {\n    for(var x = 0; x < grid[0].length; x += tileSize) {\n        var occupied = grid[y][x].length > 0;\n        if(!occupied) {\n            var xcord = x + tileSize / 2;\n            var ycord = y + tileSize / 2;\n            this.addRect(xcord, ycord, tileSize, tileSize);\n            rects[coordString(xcord,ycord)] = true;\n            var coord = coordString(xcord,ycord);\n            // this.say(coord);\n            if (fourRectsHere(xcord,ycord)) {\n                delete rects[coordString(xcord,ycord)];\n                delete rects[coordString(xcord-tileSize, ycord)];\n                delete rects[coordString(xcord-tileSize, ycord-tileSize)];\n                delete rects[coordString(xcord, ycord-tileSize)];\n                this.removeRect(xcord, ycord);\n                this.removeRect(xcord - tileSize, ycord);\n                this.removeRect(xcord, ycord - tileSize);\n                this.removeRect(xcord - tileSize, ycord - tileSize);\n                this.addRect(x, y, tileSize*2, tileSize*2);\n            }\n            this.wait(0.1);\n        }\n    }\n}\n"
      },
      "thoktar": {
        "plan": "# Fill the empty space with the minimum number of rectangles.\n# (Rectangles should not overlap each other or walls.)\n# The grid size is 1 meter, but the smallest wall/floor tile is 4 meters.\n# Check the blue guide button at the top for more info.\n# Make sure to sign up on the home page to save your code.\n\ngrid = self.getNavGrid().grid\ntileSize = 4\nfor y in range(0,grid.length,tileSize):\n    for x in range(0,grid[0].length,tileSize):\n        occupied = grid[y][x].length > 0\n        if not occupied:\n            self.addRect(x + tileSize / 2, y + tileSize / 2, tileSize, tileSize)\n            self.wait()  # Hover over the timeline to help debug!\n\n\n"
      }
    },
    "submittedCodeLanguage": "javascript",
    "playtime": 138,
    "codeLanguage": "python"
  },
  {
    "_id": "53026594cd9f9595b818d651",
    "team": "me",
    "levelID": "brawlwood",
    "levelName": "Brawlwood",
    "submitted": false,
    "code": {
      "programmable-artillery": {
        "chooseAction": "// This code is shared across all your Artillery.\n// Artillery are expensive, slow, and deadly, with high\n// area-of-effect damage that hurts foes and friends alike.\n\nvar targetEnemy, enemy;\nvar enemies = this.getEnemies();\nfor(var i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    if(enemy.type === 'munchkin') {\n        targetEnemy = enemy;\n        break;\n    }\n}\n\nif(!targetEnemy)\n    targetEnemy = this.getNearestEnemy();\nif(targetEnemy)\n    this.attackXY(targetEnemy.pos.x, targetEnemy.pos.y);\nelse\n    this.move({x: 70, y: 70});",
        "hear": "// When the artillery hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
      },
      "programmable-soldier": {
        "chooseAction": "// This code is shared across all your Soldiers.\n// Soldiers are low damage, high health melee units.\n\nvar enemy = this.getNearestEnemy();\nif(enemy && enemy.type != 'burl')\n    this.attack(enemy);\nelse {\n    this.move({x: 70, y: 70});\n}",
        "hear": "// When the soldier hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
      },
      "s-arrow-tower": {
        "chooseAction": "// This code is shared by both your Arrow Towers.\n// Don't let your towers die lest the ogres claim 250 gold!\n\nvar enemy = this.getNearestEnemy();\nif(enemy && this.distance(enemy) < this.attackRange) {\n    this.say(\"Die, \" + enemy.id + \".\");\n    this.attack(enemy);\n}"
      },
      "programmable-archer": {
        "chooseAction": "// This code is shared across all your Archers.\n// Archers are vulnerable but deadly ranged units.\n\nvar enemy = this.getNearestEnemy();\nif(enemy) {\n    this.attack(enemy);\n}\nelse\n    this.move({x: 70, y: 70});",
        "hear": "// When the archer hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
      },
      "human-base": {
        "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// If you don't have enough gold, this.build() won't build anything.\n// You start with 100 gold and receive 2 gold per second.\n// Kill enemies, especially towers and brawlers, to earn more gold.\n// Destroy the enemy base within 90 seconds!\n\nvar type = 'soldier';\nif(this.built.length === 4)\n    type = 'artillery';\nelse if(this.built.length % 3 === 1)\n    type = 'archer';\n\n// if(this.gold >= this.buildables[type].goldCost) {\n    //this.say('Unit #' + this.built.length + ' will be a ' + type);\n    this.build(type);\n// }",
        "hear": "// When the base hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
      }
    },
    "submittedCodeLanguage": "javascript",
    "playtime": 0,
    "codeLanguage": "javascript"
  },
  {
    "_id": "5317530cc269d400000543c7",
    "submitted": false,
    "code": {
      "muul": {
        "chooseAction": "..."
      },
      "nazgareth": {
        "chooseAction": "// Shamans are spellcasters with a weak magic attack\n// plus two useful spells: 'regen' and 'shrink'.\n\nvar enemy = this.getNearestEnemy();\nif (!enemy)\n    this.move({x: 10, y: 25});\nelse if (!enemy.hasEffect('shrink')) {\n    this.castShrink(enemy);\n    if(this.distance(enemy) <= 30)\n        this.say(\"Shrink, vile \" + enemy.type + \" \" + enemy.id);\n}\nelse {\n    this.attack(enemy);\n}"
      },
      "ironjaw": {
        "chooseAction": "var enemies = this.getEnemies();\nvar enemy = this.getNearest(enemies);\nif (enemy) {\n    if(!this.getCooldown('jump')) {\n        this.jumpTo(enemy.pos);\n        this.say(\"Hi \" + enemy.type + \" \" + enemy.id);\n    }\n    else {\n        this.attack(enemy);\n    }\n}\nelse {\n    this.move({x: 10, y: 30});\n}"
      },
      "programmable-shaman": {
        "hear": "// When the shaman hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.",
        "chooseAction": "// This code is shared across all your Shamans.\n// Shamans are expensive spellcasters with a weak magic attack\n// plus two crippling spells: 'slow' and 'shrink'.\n\nvar enemy = this.getNearestEnemy();\nif (!enemy)\n    this.move({x: 10, y: 10});\nelse if (!enemy.hasEffect('shrink')) {\n    this.castShrink(enemy);\n    if(this.distance(enemy) <= 30)\n        this.say(\"Shrink, vile \" + enemy.type + \" \" + enemy.id);\n}\nelse {\n    this.attack(enemy);\n}"
      },
      "programmable-thrower": {
        "hear": "// When the thrower hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.",
        "chooseAction": "// This code is shared across all your Throwers.\n// You can use this.buildIndex to have Throwers do different things.\n// Throwers are vulnerable but deadly ranged units.\n\nvar enemy = this.getNearestEnemy();\nif (enemy) {\n    this.attack(enemy);\n}\nelse {\n    this.move({x: 10, y: 10});\n}"
      },
      "programmable-munchkin": {
        "hear": "// When the munchkin hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.",
        "chooseAction": "// This code is shared across all your Munchkins.\n// You can use this.buildIndex to have Munchkins do different things.\n// Munchkins are weak but cheap, fast melee units.\n\nvar enemy = this.getNearestEnemy();\nif (enemy && enemy.type !== 'burl') {\n    this.attack(enemy);\n}\nelse {\n    this.move({x: 10, y: 10});\n}"
      },
      "ogre-base": {
        "hear": "// When the base hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.",
        "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// Destroy the enemy base within 90 seconds!\n// Check out the Guide at the top for more info.\n\nif(!this.builtHero) {\n    // Choose your hero!\n    // var heroType = 'brawler';\n    var heroType = 'shaman';\n    this.builtHero = this.build(heroType);\n    return;\n}\n\nvar buildOrder = ['munchkin', 'munchkin', 'thrower'];\nvar type = buildOrder[this.built.length % buildOrder.length];\n//this.say('Unit #' + this.built.length + ' will be a ' + type);\nthis.build(type);"
      },
      "poult": {
        "chooseAction": "// Shamans are spellcasters with a weak magic attack\n// plus two useful spells: 'regen' and 'shrink'.\n\nvar enemy = this.getNearestEnemy();\nif (!enemy)\n    this.move({x: 10, y: 25});\nelse if (!enemy.hasEffect('shrink')) {\n    this.castShrink(enemy);\n    if(this.distance(enemy) <= 30)\n        this.say(\"Shrink, vile \" + enemy.type + \" \" + enemy.id);\n}\nelse {\n    this.attack(enemy);\n}"
      },
      "aoliantak": {
        "chooseAction": "..."
      },
      "programmable-brawler": {
        "chooseAction": "var enemies = this.getEnemies();\nvar enemy = this.getNearest(enemies);\nif (enemy) {\n    if(!this.getCooldown('jump')) {\n        this.jumpTo(enemy.pos);\n        this.say(\"Hi \" + enemy.type + \" \" + enemy.id);\n    }\n    else {\n        this.attack(enemy);\n    }\n}\nelse {\n    this.move({x: 10, y: 30});\n}"
      }
    },
    "levelID": "dungeon-arena",
    "levelName": "Dungeon Arena",
    "submittedCodeLanguage": "javascript",
    "playtime": 0,
    "codeLanguage": "javascript"
  },
  {
    "_id": "5358429413f1278605f03ab8",
    "team": "ogres",
    "levelID": "greed",
    "levelName": "Greed",
    "code": {
      "ogre-base": {
        "chooseAction": "// This code runs once per frame. Build units and command peons!\n// Destroy the human base within 180 seconds.\n// Run over 4000 statements per call and chooseAction will run less often.\n// Check out the green Guide button at the top for more info.\n\nvar base = this;\n\n/////// 1. Command peons to grab coins and gems. ///////\n// You can only command peons, not fighting units.\n// You win by gathering gold more efficiently to make a larger army.\n// Click on a unit to see its API.\nvar items = base.getItems();\nvar peons = base.getByType('peon');\nfor (var peonIndex = 0; peonIndex < peons.length; peonIndex++) {\n    var peon = peons[peonIndex];\n    var item = peon.getNearest(items);\n    if (item)\n        base.command(peon, 'move', item.pos);\n}\n\n\n/////// 2. Decide which unit to build this frame. ///////\n// Peons can gather gold; other units auto-attack the enemy base.\n// You can only build one unit per frame, if you have enough gold.\nvar type;\nif (base.built.length === 0)\n    type = 'peon';\nelse\n    type = 'ogre';\nif (base.gold >= base.buildables[type].goldCost)\n    base.build(type);\n\n\n// 'peon': Peons gather gold and do not fight.\n// 'munchkin': Light melee unit.\n// 'ogre': Heavy melee unit.\n// 'shaman': Support spellcaster.\n// 'fangrider': High damage ranged attacker.\n// 'brawler': Mythically expensive super melee unit.\n// See the buildables documentation below for costs and the guide for more info."
      },
      "well": {
        "chooseAction": "if(!this.inventorySystem) this.inventorySystem = this.world.getSystem('Inventory');\n// Cap at 120 coins for rendering performance reasons.\n// As many as ~420 by stalemate with default code, but one greedy collector -> ~70 tops.\nif(this.inventorySystem.collectables.length < 120) {\n    var x = Math.random();\n    var type = 'silver';\n    if (x < 0.05) type = 'gem';\n    else if (x < 0.15) type = 'gold';\n    else if (x < 0.35) type = 'copper';\n    this.build(type);\n}\n\nif(!this.causeFall) this.causeFall = function causeFall(target) {\n    target.addEffect({name: 'fall', duration: 1.5, reverts: false, factor: 0.1, targetProperty: 'scaleFactor'}, this);\n    target.maxAcceleration = 0;\n    target.addCurrentEvent('fall');\n    target.fellAt = this.now();\n};\n\nfor (var i = 0; i < this.inventorySystem.collectors.length; ++i) {\n    var thang = this.inventorySystem.collectors[i];\n    if ((thang.type == 'peasant' || thang.type == 'peon') &&\n        (thang.pos.x < -3 || thang.pos.x > 88 || thang.pos.y < -5 || thang.pos.y > 80)) {\n        if (thang.maxAcceleration)\n            this.causeFall(thang);\n        else if (thang.fellAt && thang.fellAt + 1.25 < this.now()) {\n            thang.setExists(false);\n            thang.fellAt = null;\n        }\n    }\n}"
      }
    },
    "totalScore": 16.724090931727677,
    "submitted": true,
    "submittedCodeLanguage": "javascript",
    "playtime": 3837,
    "codeLanguage": "javascript"
  },
  {
    "_id": "53177f6da508f6e7b3463fef",
    "team": "humans",
    "levelID": "dungeon-arena",
    "levelName": "Dungeon Arena",
    "submitted": true,
    "totalScore": 11.782554190268042,
    "code": {
      "hushbaum-1": {
        "chooseAction": "..."
      },
      "librarian": {
        "chooseAction": "..."
      },
      "tharin-1": {
        "chooseAction": "var friends = this.getFriends();\nvar nearest = this.getNearest(friends);\nif(this.distance(nearest) > 5) {\n    this.move(nearest.pos);\n}\nelse {\n    this.warcry();\n}"
      },
      "hushbaum": {
        "chooseAction": "var enemy = this.getNearestEnemy();\nif (enemy) {\n    if (!enemy.hasEffect('slow')) {\n        this.say(\"Not so fast, \" + enemy.type + \" \" + enemy.id);\n        this.castSlow(enemy);\n    }\n    else {\n        this.attack(enemy);\n    }\n}\nelse {\n    this.move({x: 70, y: 30});\n}\n"
      },
      "anya": {
        "chooseAction": "var enemy = this.getNearestEnemy();\nif (enemy)\n    this.attack(enemy);"
      },
      "tharin": {
        "chooseAction": "var enemies = this.getEnemies();\nvar enemy = this.getNearest(enemies);\nif (!this.getCooldown('warcry')) {\n    this.warcry();\n}\nelse if (enemy) {\n    this.attack(enemy);\n}\nelse {\n    this.move({x: 10, y: 30});\n}\n"
      },
      "programmable-librarian": {
        "chooseAction": "// The Librarian is a spellcaster with a fireball attack\n// plus three useful spells: 'slow', 'regen', and 'haste'.\n// Slow makes a target move and attack at half speed for 5s.\n// Regen makes a target heal 10 hp/s for 10s.\n// Haste speeds up a target by 4x for 5s, once per match.\n\nvar friends = this.getFriends();\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy = this.getNearest(enemies);\nvar friend = this.getNearest(friends);\n\n// Which one do you do at any given time? Only the last called action happens.\n//if(this.canCast('slow', enemy)) this.castSlow(enemy);\n//if(this.canCast('regen', friend)) this.castRegen(friend);\n//if(this.canCast('haste', friend)) this.castHaste(friend);\n//this.attack(enemy);\n\n// You can also command your troops with this.say():\n//this.say(\"Defend!\", {targetPos: {x: 30, y: 30}}));\n//this.say(\"Attack!\", {target: enemy});\n//this.say(\"Move!\", {targetPos: {x: 50, y: 40});"
      },
      "programmable-tharin": {
        "chooseAction": "// Tharin is a melee fighter with shield, warcry, and terrify skills.\n// this.shield() lets him take one-third damage while defending.\n// this.warcry() gives allies within 10m 30% haste for 5s, every 10s.\n// this.terrify() sends foes within 30m fleeing for 5s, once per match.\n\nvar friends = this.getFriends();\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy = this.getNearest(enemies);\nvar friend = this.getNearest(friends);\n\n// Which one do you do at any given time? Only the last called action happens.\n//if(!this.getCooldown('warcry')) this.warcry();\n//if(!this.getCooldown('terrify')) this.terrify();\n//this.shield();\n//this.attack(enemy);\n\n// You can also command your troops with this.say():\n//this.say(\"Defend!\", {targetPos: {x: 30, y: 30}}));\n//this.say(\"Attack!\", {target: enemy});\n//this.say(\"Move!\", {targetPos: {x: 40, y: 40});\n\n// You can store state on this across frames:\n//this.lastHealth = this.health;"
      },
      "human-base": {
        "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// Destroy the enemy base within 60 seconds!\n// Check out the Guide at the top for more info.\n\n// CHOOSE YOUR HERO! You can only build one hero.\nvar hero;\n//hero = 'tharin';  // A fierce knight with battlecry abilities.\n//hero = 'hushbaum';  // A fiery spellcaster hero.\n\nif(hero && !this.builtHero) {\n    this.builtHero = this.build(hero);\n    return;\n}\n\n// Soldiers are hard-to-kill, low damage melee units with 2s build cooldown.\n// Archers are fragile but deadly ranged units with 2.5s build cooldown.\nvar buildOrder = ['soldier', 'archer', 'soldier', 'soldier', 'archer'];\nvar type = buildOrder[this.built.length % buildOrder.length];\n//this.say('Unit #' + this.built.length + ' will be a ' + type);\nthis.build(type);"
      }
    },
    "submittedCodeLanguage": "javascript",
    "playtime": 1,
    "codeLanguage": "javascript"
  },
  {
    "_id": "5318b6aa7aeef7843bba3357",
    "team": "ogres",
    "levelID": "dungeon-arena",
    "levelName": "Dungeon Arena",
    "submitted": true,
    "totalScore": 34.28623946920249,
    "code": {
      "human-base": {
        "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// Destroy the enemy base within 60 seconds!\n// Check out the Guide at the top for more info.\n\n// CHOOSE YOUR HERO! You can only build one hero.\nvar hero;\nhero = 'tharin';  // A fierce knight with battlecry abilities.\n//hero = 'hushbaum';  // A fiery spellcaster hero.\n\nif(hero && !this.builtHero) {\n    this.builtHero = this.build(hero);\n    return;\n}\n\n// Soldiers are hard-to-kill, low damage melee units with 2s build cooldown.\n// Archers are fragile but deadly ranged units with 2.5s build cooldown.\nvar type;\nif (this.built.length > 50) {\n    type = this.built.length & 1 ? 'archer' : 'soldier';\n} else {\n    type = 'soldier';\n}\n//this.say('Unit #' + this.built.length + ' will be a ' + type);\nthis.build(type);"
      },
      "programmable-tharin": {
        "chooseAction": "var enemies = this.getEnemies();\nvar target = enemies[0];\n\nif (this.now() < 0.2) {\n    this.attack(target);\n    this.say(\"attack\", {target: target});\n    return;\n}\n\nthis.say(\"attack\", {target: target});\nthis.attack(target);\nif (this.pos.x > 40 && !this.getCooldown('terrify')) {\n    this.terrify();\n    return;\n} else if (!this.getCooldown('warcry')) {\n    this.warcry();\n}\nthis.say(\"attack\", {target: target});"
      },
      "programmable-librarian": {
        "chooseAction": "// The Librarian is a spellcaster with a fireball attack\n// plus three useful spells: 'slow', 'regen', and 'haste'.\n// Slow makes a target move and attack at half speed for 5s.\n// Regen makes a target heal 10 hp/s for 10s.\n// Haste speeds up a target by 4x for 5s, once per match.\n\nvar friends = this.getFriends();\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy = this.getNearest(enemies);\nvar friend = this.getNearest(friends);\n\n// Which one do you do at any given time? Only the last called action happens.\n//if(this.canCast('slow', enemy)) this.castSlow(enemy);\n//if(this.canCast('regen', friend)) this.castRegen(friend);\n//if(this.canCast('haste', friend)) this.castHaste(friend);\n//this.attack(enemy);\n\n// You can also command your troops with this.say():\n//this.say(\"Defend!\", {targetPos: {x: 30, y: 30}}));\n//this.say(\"Attack!\", {target: enemy});\n//this.say(\"Move!\", {targetPos: {x: 50, y: 40});"
      },
      "programmable-shaman": {
        "chooseAction": "// Shamans are spellcasters with a weak magic attack\n// and three spells: 'shrink', 'grow', and 'poison-cloud'.\n// Shrink: target has 2/3 health, 1.5x speed for 5s.\n// Grow: target has double health, half speed for 5s.\n// Once per match, she can cast poison cloud, which does\n// 5 poison dps for 10s to enemies in a 10m radius.\n\nvar friends = this.getFriends();\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy = this.getNearest(enemies);\nvar friend = this.getNearest(friends);\n\n// Which one do you do at any given time? Only the last called action happens.\nif(this.canCast('shrink', enemy)) this.castShrink(enemy);\n// if(this.canCast('grow', friend)) this.castGrow(friend);\n//if(this.canCast('poison-cloud', enemy)) this.castPoisonCloud(enemy);\n// this.attack(enemy);\n\n// You can also command your troops with this.say():\n//this.say(\"Defend!\", {targetPos: {x: 60, y: 30}}));\n//this.say(\"Attack!\", {target: enemy});\n//this.say(\"Move!\", {targetPos: {x: 50, y: 40}); "
      },
      "programmable-brawler": {
        "chooseAction": "// The Brawler is a huge melee hero with mighty mass.\n// this.throw() hurls an enemy behind him.\n// this.jumpTo() leaps to a target within 20m every 10s.\n// this.stomp() knocks everyone away, once per match.\n\nvar friends = this.getFriends();\nvar enemies = this.getEnemies();\nif (enemies.length === 0) return;  // Chill if all enemies are dead.\nvar enemy = this.getNearest(enemies);\nvar friend = this.getNearest(friends);\n\n// Which one do you do at any given time? Only the last called action happens.\nif(!this.getCooldown('jump')) this.jumpTo(enemy.pos);\n// if(!this.getCooldown('stomp')) return this.stomp();\n// if(!this.getCooldown('throw')) this.throw(enemy);\n// this.attack(enemy);\n\n// You can also command your troops with this.say():\n//this.say(\"Defend!\", {targetPos: {x: 60, y: 30}}));\n//this.say(\"Attack!\", {target: enemy});\n//this.say(\"Move!\", {targetPos: {x: 50, y: 40});\n\n// You can store state on this across frames:\n//this.lastHealth = this.health;"
      },
      "ironjaw": {
        "chooseAction": "// var enemies = this.getEnemies();\n// var enemy = this.getNearest(enemies);\n// if (enemy) {\n//     if(!this.getCooldown('jump')) {\n//         this.jumpTo(enemy.pos);\n//         this.say(\"Hi \" + enemy.type + \" \" + enemy.id);\n//     }\n//     else {\n//         this.attack(enemy);\n//     }\n// }\n// else {\n//     this.move({x: 10, y: 30});\n// }"
      },
      "nazgareth": {
        "chooseAction": "// // Shamans are spellcasters with a weak magic attack\n// // plus two useful spells: 'regen' and 'shrink'.\n\n// var enemy = this.getNearestEnemy();\n// if (!enemy)\n//     this.move({x: 10, y: 25});\n// else if (!enemy.hasEffect('shrink')) {\n//     this.castShrink(enemy);\n//     if(this.distance(enemy) <= 30)\n//         this.say(\"Shrink, vile \" + enemy.type + \" \" + enemy.id);\n// }\n// else {\n//     this.attack(enemy);\n// }"
      },
      "ogre-base": {
        "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// Destroy the enemy base within 60 seconds!\n// Check out the Guide at the top for more info.\n\n// Choose your hero! You can only build one hero.\nvar hero;\n// hero = 'ironjaw';  // A leaping juggernaut hero, type 'brawler'.\nhero = 'yugargen';  // A devious spellcaster hero, type 'shaman'.\nif(hero && !this.builtHero) {\n    this.builtHero = this.build(hero);\n    return;\n}\n\n// Munchkins are weak melee units with 1.25s build cooldown.\n// Throwers are fragile, deadly ranged units with 2.5s build cooldown.\nvar buildOrder = ['munchkin', 'munchkin', 'munchkin', 'thrower'];\nvar type = buildOrder[this.built.length % buildOrder.length];\n//this.say('Unit #' + this.built.length + ' will be a ' + type);\nthis.build(type);"
      },
      "muul": {
        "chooseAction": "..."
      }
    },
    "submittedCodeLanguage": "javascript",
    "playtime": 0,
    "codeLanguage": "javascript"
  },
  {
    "_id": "52fd11c8e5c2b9000060bd48",
    "team": "ogres",
    "levelID": "brawlwood",
    "levelName": "Brawlwood",
    "submitted": true,
    "totalScore": -10.697956636178176,
    "code": {
      "ogre-base": {
        "hear": "// When the base hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.",
        "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// If you don't have enough gold, this.build() won't build anything.\n// You start with 100 gold and receive 2 gold per second.\n// Kill enemies, especially towers and brawlers, to earn more gold.\n// Destroy the enemy base within 90 seconds!\n// Check out the Guide just up and to the left for more info.\n\n// var type = 'munchkin';\n// if(this.built.length % 5 === 3)\n    type = 'shaman';\n// else if(this.built.length % 3 === 1)\n//     type = 'thrower';\n\n//this.say('Unit #' + this.built.length + ' will be a ' + type);\nthis.build(type);\n"
      },
      "programmable-munchkin": {
        "hear": "// When the munchkin hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.",
        "chooseAction": "// This code is shared across all your Munchkins.\n// You can use this.buildIndex to have Munchkins do different things.\n// Munchkins are weak but cheap, fast melee units.\n\nvar enemy = this.getNearestEnemy();\nif (enemy && enemy.type !== 'burl') {\n    this.attack(enemy);\n}\nelse {\n    this.move({x: 10, y: 10});\n}"
      },
      "programmable-thrower": {
        "hear": "// When the thrower hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.",
        "chooseAction": "// This code is shared across all your Throwers.\n// You can use this.buildIndex to have Throwers do different things.\n// Throwers are vulnerable but deadly ranged units.\n\nvar enemy = this.getNearestEnemy();\nif (enemy) {\n    this.attack(enemy);\n}\nelse {\n    this.move({x: 10, y: 10});\n}"
      },
      "n-beam-tower": {
        "chooseAction": "// This code is shared by both your Beam Towers.\n// Don't let your towers die lest the humans claim 250 gold!\n// You probably don't need to change this basic strategy.\n\nvar enemy = this.getNearestEnemy();\nif (enemy && this.distance(enemy) < this.attackRange) {\n    this.say(\"Die, \" + enemy.id + \"!\");\n    this.attack(enemy);\n}"
      },
      "programmable-shaman": {
        "hear": "// When the shaman hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here.",
        "chooseAction": "// This code is shared across all your Shamans.\n// Shamans are expensive spellcasters with a weak magic attack\n// plus two crippling spells: 'slow' and 'shrink'.\n\nvar enemy = this.getNearestEnemy();\nif (!enemy)\n    this.move({x: 10, y: 10});\nelse if (!enemy.hasEffect('shrink')) {\n    this.castShrink(enemy);\n    if(this.distance(enemy) <= 30)\n        this.say(\"Shrink, vile \" + enemy.type + \" \" + enemy.id);\n}\nelse {\n    this.attack(enemy);\n}"
      }
    },
    "submittedCodeLanguage": "javascript",
    "playtime": 0,
    "codeLanguage": "javascript"
  },
  {
    "_id": "53570b7a1bfa9bba14b5e045",
    "team": "humans",
    "levelID": "greed",
    "levelName": "Greed",
    "code": {
      "well": {
        "chooseAction": "if(!this.inventorySystem) this.inventorySystem = this.world.getSystem('Inventory');\n// Cap at 120 coins for rendering performance reasons.\n// As many as ~420 by stalemate with default code, but one greedy collector -> ~70 tops.\nif(this.inventorySystem.collectables.length < 120) {\n    var x = Math.random();\n    var type = 'silver';\n    if (x < 0.05) type = 'gem';\n    else if (x < 0.15) type = 'gold';\n    else if (x < 0.35) type = 'copper';\n    this.build(type);\n}\n\nif(!this.causeFall) this.causeFall = function causeFall(target) {\n    target.addEffect({name: 'fall', duration: 1.5, reverts: false, factor: 0.1, targetProperty: 'scaleFactor'}, this);\n    target.maxAcceleration = 0;\n    target.addCurrentEvent('fall');\n    target.fellAt = this.now();\n};\n\nfor (var i = 0; i < this.inventorySystem.collectors.length; ++i) {\n    var thang = this.inventorySystem.collectors[i];\n    if ((thang.type == 'peasant' || thang.type == 'peon') &&\n        (thang.pos.x < -3 || thang.pos.x > 88 || thang.pos.y < -5 || thang.pos.y > 80)) {\n        if (thang.maxAcceleration)\n            this.causeFall(thang);\n        else if (thang.fellAt && thang.fellAt + 1.25 < this.now()) {\n            thang.setExists(false);\n            thang.fellAt = null;\n        }\n    }\n}"
      },
      "human-base": {
        "chooseAction": "// This code runs once per frame. Build units and command peons!\n// Destroy the human base within 180 seconds.\n// Run over 4000 statements per call and chooseAction will run less often.\n// Check out the green Guide button at the top for more info.\n\nvar base = this;\n\n/////// 1. Command peons to grab coins and gems. ///////\n// You can only command peons, not fighting units.\n// You win by gathering gold more efficiently to make a larger army.\n// Click on a unit to see its API.\nvar items = base.getItems();\nvar peons = base.getByType('peasant');\nfor (var peonIndex = 0; peonIndex < peons.length; peonIndex++) {\n    var peon = peons[peonIndex];\n    var item = peon.getNearest(items);\n    if (item)\n        base.command(peon, 'move', item.pos);\n}\n\n\n/////// 2. Decide which unit to build this frame. ///////\n// Peons can gather gold; other units auto-attack the enemy base.\n// You can only build one unit per frame, if you have enough gold.\nvar type;\nif (base.built.length === 0)\n    type = 'peasant';\nelse\n    type = 'soldier';\nif (base.gold >= base.buildables[type].goldCost)\n    base.build(type);\n\n\n// 'peon': Peons gather gold and do not fight.\n// 'munchkin': Light melee unit.\n// 'ogre': Heavy melee unit.\n// 'shaman': Support spellcaster.\n// 'fangrider': High damage ranged attacker.\n// 'brawler': Mythically expensive super melee unit.\n// See the buildables documentation below for costs and the guide for more info."
      }
    },
    "submitted": true,
    "totalScore": 29.46867296924995,
    "submittedCodeLanguage": "javascript",
    "playtime": 6295,
    "codeLanguage": "javascript"
  },
  {
    "_id": "52fd11adae7dc8000099b788",
    "team": "humans",
    "levelID": "brawlwood",
    "levelName": "Brawlwood",
    "submitted": true,
    "totalScore": 14.50139221733582,
    "code": {
      "programmable-artillery": {
        "chooseAction": "// This code is shared across all your Artillery.\n// Artillery are expensive, slow, and deadly, with high\n// area-of-effect damage that hurts foes and friends alike.\n\nvar targetEnemy, enemy;\nvar enemies = this.getEnemies();\nfor(var i = 0; i < enemies.length; ++i) {\n    enemy = enemies[i];\n    if(enemy.type === 'munchkin') {\n        targetEnemy = enemy;\n        break;\n    }\n}\n\nif(!targetEnemy)\n    targetEnemy = this.getNearestEnemy();\nif(targetEnemy)\n    this.attackXY(targetEnemy.pos.x, targetEnemy.pos.y);\nelse\n    this.move({x: 70, y: 70});",
        "hear": "// When the artillery hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
      },
      "programmable-soldier": {
        "chooseAction": "// This code is shared across all your Soldiers.\n// Soldiers are basic, fast melee units.\n\nvar enemy = this.getNearestEnemy();\nif(enemy && enemy.type != 'burl')\n    this.attack(enemy);\nelse {\n    var targetPos = {x: 70, y: 70};\n    if(this.now() < 10)\n        targetPos = {x: 40, y: 40};\n    this.move(targetPos);\n}",
        "hear": "// When the soldier hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
      },
      "programmable-archer": {
        "chooseAction": "// This code is shared across all your Archers.\n// Archers are vulnerable but deadly ranged units.\n\nif(this.lastEnemy && !this.lastEnemy.dead) {\n    this.attack(this.lastEnemy);\n    return;\n}\n\nvar enemy = this.getNearestEnemy();\nif(enemy) {\n    this.attack(enemy);\n    if(this.distance(enemy) < this.attackRange) {\n        this.lastEnemy = enemy;\n    }\n}\nelse\n    this.move({x: 70, y: 70});",
        "hear": "// When the archer hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
      },
      "human-base": {
        "chooseAction": "// This is the code for your base. Decide which unit to build each frame.\n// Units you build will go into the this.built array.\n// If you don't have enough gold, this.build() won't build anything.\n// You start with 100 gold and receive 2 gold per second.\n// Kill enemies, especially towers and brawlers, to earn more gold.\n// Destroy the enemy base within 90 seconds!\n\nvar type = 'soldier';\nif(this.built.length === 4)\n    type = 'artillery';\nelse if(this.built.length % 3 === 1)\n    type = 'archer';\n\n\nif(this.gold >= this.buildables[type].goldCost) {\n    //this.say('Unit #' + this.built.length + ' will be a ' + type);\n    this.build(type);\n}",
        "hear": "// When the base hears a say() message, this hear() method will be called.\nif(speaker.team !== this.team) return;\n\n// You can add code to respond to the message here."
      },
      "s-arrow-tower": {
        "chooseAction": "// This code is shared by both your Arrow Towers.\n// Don't let your towers die lest the ogres claim 250 gold!\n\nvar enemy = this.getNearestEnemy();\nif(enemy && this.distance(enemy) < this.attackRange) {\n    this.say(\"Die, \" + enemy.id + \".\");\n    this.attack(enemy);\n}"
      }
    },
    "submittedCodeLanguage": "javascript",
    "playtime": 0,
    "codeLanguage": "javascript"
  }
]

module.exports = ->
  me.isAdmin = -> false
  me.set('permissions', ['employer'])
  v = new ProfileView({}, 'joe')
  jasmine.Ajax.requests.mostRecent()
  for url, responseBody of responses
    requests = jasmine.Ajax.requests.filter(url)
    if not requests.length
      console.error "could not find response for <#{url}>", responses
      continue
    request = requests[0]
    request.response({status: 200, responseText: JSON.stringify(responseBody)})
#  v.$el = v.$el.find('.main-content-area')
  v
