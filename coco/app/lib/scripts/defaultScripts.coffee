module.exports = [
  {
    "id": "Add Default Goals",
    "channel": "god:new-world-created",
    "noteChain": [
      {
        "goals": {
          "add": [
            {
              "name": "Humans Survive",
              "id": "humans-survive",
              "saveThangs": [
                "humans"
              ],
              "worldEndsAfter": 3,
              "howMany": 1,
              "hiddenGoal": true
            },
            {
              "name": "Ogres Die",
              "id": "ogres-die",
              "killThangs": [
                "ogres"
              ],
              "worldEndsAfter": 3,
              "hiddenGoal": true
            }
          ]
        }
      }
    ]
  }
]


# Could add other default scripts, like not having to redo Victory Playback sequence from scratch every time.
