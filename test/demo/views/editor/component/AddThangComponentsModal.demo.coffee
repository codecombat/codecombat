AddThangComponentsModal = require('views/editor/component/AddThangComponentsModal')

response =
  [
    {
      "_id": "53c46b06bd135abdb79a4f32",
      "name": "InventorySomething",
      "original": "53c46ae2bd135abdb79a4f2f",
      "official": false,
      "configSchema": {
        "additionalProperties": false,
        "type": "object"
      },
      "propertyDocumentation": [],
      "dependencies": [],
      "code": "class AttacksSelf extends Component\n  @className: 'AttacksSelf'\n  chooseAction: ->\n    @attack @",
      "description": "This Component makes the Thang attack itself.",
      "system": "inventory",
      "version": {
        "minor": 2,
        "major": 0,
        "isLatestMajor": true,
        "isLatestMinor": true
      }
    },
    {
      "_id": "538755f3cb18e70000712278",
      "name": "Jitters",
      "original": "530d8a70286ddc0000cc5d9d",
      "official": false,
      "configSchema": {
        "additionalProperties": false,
        "type": "object"
      },
      "propertyDocumentation": [],
      "dependencies": [],
      "code": "class AttacksSelf extends Component\n  @className: 'AttacksSelf'\n  chooseAction: ->\n    @attack @",
      "description": "This Component makes the Thang jitter. Or, it would, if it did anything yet. (Test Component.)",
      "system": "movement",
      "version": {
        "minor": 3,
        "major": 0,
        "isLatestMajor": true,
        "isLatestMinor": true
      }
    },
    {
      "_id": "538755f3cb18e70000712279",
      "name": "DelaysExistence",
      "original": "524cbbea3ea855e0ab00003d",
      "official": false,
      "configSchema": {
        "additionalProperties": false,
        "type": "object"
      },
      "propertyDocumentation": [],
      "dependencies": [],
      "code": "class AttacksSelf extends Component\n  @className: 'AttacksSelf'\n  chooseAction: ->\n    @attack @",
      "description": "This Thang doesn't show up right away.",
      "system": "existence",
      "version": {
        "minor": 25,
        "major": 0,
        "isLatestMajor": true,
        "isLatestMinor": true
      }
    },
    {
      "_id": "538755f3cb18e7000071227a",
      "name": "RunsInCircles",
      "original": "52438245ef76c3dcf5000004",
      "official": false,
      "configSchema": {
        "additionalProperties": false,
        "type": "object"
      },
      "propertyDocumentation": [],
      "dependencies": [],
      "code": "class AttacksSelf extends Component\n  @className: 'AttacksSelf'\n  chooseAction: ->\n    @attack @",
      "description": "This Thang runs in circles.",
      "system": "ai",
      "version": {
        "minor": 39,
        "major": 0,
        "isLatestMajor": true,
        "isLatestMinor": true
      }
    },
    {
      "_id": "538755f3cb18e7000071227b",
      "name": "AttacksSelf",
      "original": "52437b061d9e25b8dc000004",
      "official": false,
      "configSchema": {
        "additionalProperties": false,
        "type": "object"
      },
      "propertyDocumentation": [],
      "dependencies": [],
      "code": "class AttacksSelf extends Component\n  @className: 'AttacksSelf'\n  chooseAction: ->\n    @attack @",
      "description": "This Component makes the Thang attack itself.",
      "system": "ai",
      "version": {
        "minor": 41,
        "major": 0,
        "isLatestMajor": true,
        "isLatestMinor": true
      }
    },
    {
      "_id": "538755f3cb18e7000071227d",
      "name": "FollowsNearestFriend",
      "original": "52437e31ef76c3dcf5000002",
      "official": false,
      "configSchema": {
        "additionalProperties": false,
        "type": "object"
      },
      "propertyDocumentation": [],
      "dependencies": [],
      "code": "class AttacksSelf extends Component\n  @className: 'AttacksSelf'\n  chooseAction: ->\n    @attack @",
      "description": "This Thang follows the nearest friend.",
      "system": "ai",
      "version": {
        "minor": 39,
        "major": 0,
        "isLatestMajor": true,
        "isLatestMinor": true
      }
    },
    {
      "_id": "538755f4cb18e7000071227e",
      "name": "FollowsNearest",
      "original": "52437c851d9e25b8dc000008",
      "official": false,
      "configSchema": {
        "additionalProperties": false,
        "type": "object"
      },
      "propertyDocumentation": [],
      "dependencies": [],
      "code": "class AttacksSelf extends Component\n  @className: 'AttacksSelf'\n  chooseAction: ->\n    @attack @",
      "description": "This Thang follows the nearest other Thang.",
      "system": "ai",
      "version": {
        "minor": 39,
        "major": 0,
        "isLatestMajor": true,
        "isLatestMinor": true
      }
    }
  ]


module.exports = ->
  view = new AddThangComponentsModal({skipOriginals:['52437c851d9e25b8dc000008']}) # FollowsNearest original
  console.log jasmine.Ajax.requests.all()
  jasmine.Ajax.requests.mostRecent().respondWith({status: 200, responseText: JSON.stringify(response)})
  view.render()
  return view