module.exports = [
  {
    "channel": "surface:sprite-selected",
    "noteChain": [
      {
        "sprites": [
          {
            "id": "Captain Anya",
            "say": {
              "text": "What do you need help with, boss?",
              "responses": [
                {
                  "text": "What do I do next?",
                  "channel": "help-next"
                },
                {
                  "text": "I'm lost",
                  "channel": "help-overview"
                },
                {
                  "text": "Never mind.",
                  "channel": "end-current-script"
                }
              ]
            }
          }
        ]
      }
    ],
    "eventPrereqs": [
      {
        "eventProps": [
          "sprite",
          "thang",
          "id"
        ],
        "equalTo": "Captain Anya"
      }
    ],
    "id": "Anya Clicked Guide"
    "repeats": true
  },
  {
    "channel": "help-next",
    "noteChain": [
      {
        "sprites": [
          {
            "id": "Captain Anya",
            "say": {
              "text": "Look for a list of objectives on the upper left. They tell you what to focus on."
            }
          }
        ],
        "dom": {
          "highlight": {
            "target": "#primary-goals-list"
          }
        }
      }
    ],
    "id": "Clicked Help Next"
  },
  {
    "channel": "help-overview",
    "noteChain": [
      {
        "sprites": [
          {
            "id": "Captain Anya",
            "say": {
              "text": "Click the 'Guide' button on the upper right for an overview of the level and some hints."
            }
          }
        ],
        "dom": {
          "highlight": {
            "target": "#docs-button"
          }
        }
      }
    ],
    "id": "Clicked I'm Lost"
  }
]
