LevelSessionCodeView = require 'views/common/LevelSessionCodeView'
LevelSession = require 'models/LevelSession'

levelSessionData = {
  "_id": "5334901f0a0f9b286f57382c",
  "level": {
    "original": "533353722a61b7ca6832840c",
    "majorVersion": 0
  },
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
  "teamSpells": {
    "common": [
      "coin-generator-9000/chooseAction"
    ],
    "humans": [
      "tharin/chooseAction"
    ],
    "ogres": [
      "mak-fod/chooseAction"
    ]
  },
  "levelID": "gold-rush",
  "levelName": "Gold Rush",
  "totalScore": 39.23691444835561,
  "submitted": true,
  "submittedCodeLanguage": "javascript",
  "playtime": 1158,
  "codeLanguage": "javascript"
}

levelData = {
  "_id": "53c71962587cd615bf404919",
  "name": "Dungeon Arena",
  "icon": "db/level/53173f76c269d400000543c2/11_dungeon.png",
  "description": "This level is indescribably flarmy!",
  "employerDescription": "A DotA-like level where players:\n* Take control of a hero with special abilities\n* Choose which sorts of troops to build.\n* Have limited control over their troops."
  "version": {
    "minor": 0,
    "major": 0,
    "isLatestMajor": true,
    "isLatestMinor": true
  }
}

module.exports = ->
  session = new LevelSession(levelSessionData)
  v = new LevelSessionCodeView({session:session})
  request = jasmine.Ajax.requests.mostRecent()
  request.response({status: 200, responseText: JSON.stringify(levelData)})
  console.log 'okay should be fine'
  v
