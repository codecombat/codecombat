module.exports = {
  achievements: [
    {
      "_id": "541a23431ccc8eaae19f3bf6",
      "slug": "gems-in-the-deep-completed",
      "related": "54173c90844506ae0195a0b4",
      "userField": "creator",
      "description": "You completed Gems in the Deep.",
      "collection": "level.sessions",
      "query": {
        "state.complete": true,
        "level.original": "54173c90844506ae0195a0b4"
      },
      "name": "Gems in the Deep Completed",
      "__v": 32,
      "rewards": {
        "levels": [
          "54174347844506ae0195a0b8"
        ],
        "gems": 18
#        "items":[
#          "53e4108204c00d4607a89f78"
#        ]
      },
      "worth": 11,
      "i18n": {},
      "i18nCoverage": [],
      "patches": []
    },
    {
      "_id": "5452e14006a59e000067e501",
      "slug": "gems-in-the-deep-clean-code",
      "i18nCoverage": [],
      "i18n": {},
      "related": "54173c90844506ae0195a0b4",
      "userField": "creator",
      "description": "Clean code: no code errors or warnings.",
      "collection": "level.sessions",
      "query": {
        "level.original": "54173c90844506ae0195a0b4",
        "state.goalStates.clean-code.status": "success",
        "state.complete": true
      },
      "name": "Gems in the Deep Clean Code",
      "__v": 29,
      "rewards": {
        "gems": 9
      },
      "worth": 5,
      "patches": []
    }
  ]
  
  
  campaign: {
    "_id": "55b29efd1cd6abe8ce07db0d",
    "slug": "intro",
    "name": "Intro",
    "watchers": [
      "512ef4805a67a8c507000001"
    ],
    "__v": 30,
    "adjacentCampaigns": {
      "549f0801e21e041139ef28c8": {
        "name": "Forest",
        "slug": "forest",
        "position": {
          "x": 94.5,
          "y": 7
        },
        "rotation": -35,
        "color": "purple",
        "showIfUnlocked": "541b67f71ccc8eaae19f3c62",
        "i18n": {}
      }
    },
    "ambientSound": {
      "mp3": "db/campaign/549f07f7e21e041139ef28c7/ambient-dungeon.mp3",
      "ogg": "db/campaign/549f07f7e21e041139ef28c7/ambient-dungeon.ogg"
    },
    "backgroundColor": "rgba(68, 54, 45, 1)",
    "backgroundColorTransparent": "rgba(68, 54, 45, 0)",
    "backgroundImage": [
      {
        "image": "db/campaign/549f07f7e21e041139ef28c7/map_dungeon_1920.jpg",
        "width": 1920
      },
      {
        "image": "db/campaign/549f07f7e21e041139ef28c7/map_dungeon_1366.jpg",
        "width": 1366
      }
    ],
    "description": "1 hour: syntax, methods, parameters, strings, loops, variables",
    "fullName": "Introduction to Computer Science",
    "i18n": {},
    "i18nCoverage": [],
    "levels": {
      "5411cb3769152f1707be029c": {
        "campaignIndex": 0,
        "rewards": [
          {
            "achievement": "541a198a1ccc8eaae19f3be4",
            "level": "54173c90844506ae0195a0b4"
          },
          {
            "achievement": "541a198a1ccc8eaae19f3be4",
            "level": "55525bcaaf92058705a94c02"
          }
        ],
        "name": "Dungeons of Kithgard",
        "description": "Grab the gem, but touch nothing else. In this level you'll learn basic movement for your hero.",
        "i18n": {},
        "type": "hero",
        "slug": "dungeons-of-kithgard",
        "original": "5411cb3769152f1707be029c",
        "disableSpaces": 3,
        "hidesSubmitUntilRun": true,
        "hidesPlayButton": true,
        "hidesRunShortcut": true,
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "lockDefaultCode": false,
        "autocompleteFontSizePx": 20,
        "requiredCode": [
          "moveRight"
        ],
        "requiredGear": {},
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07"
          ]
        },
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "basic_syntax"
        ],
        "position": {
          "x": 19.209888199437682,
          "y": 12.51725346209055
        }
      },
      "54173c90844506ae0195a0b4": {
        "position": {
          "y": 12.117739757859558,
          "x": 28.059445721561577
        },
        "concepts": [
          "basic_syntax"
        ],
        "tasks": [],
        "campaign": "dungeon",
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07"
          ]
        },
        "requiredGear": {},
        "autocompleteFontSizePx": 20,
        "lockDefaultCode": false,
        "backspaceThrottle": true,
        "hidesRealTimePlayback": true,
        "hidesCodeToolbar": true,
        "hidesSay": true,
        "hidesHUD": true,
        "hidesRunShortcut": true,
        "hidesPlayButton": true,
        "hidesSubmitUntilRun": true,
        "disableSpaces": 4,
        "original": "54173c90844506ae0195a0b4",
        "slug": "gems-in-the-deep",
        "type": "hero",
        "i18n": {},
        "description": "Quickly collect the gems; you will need them.",
        "name": "Gems in the Deep",
        "rewards": [
          {
            "achievement": "541a23431ccc8eaae19f3bf6",
            "level": "54174347844506ae0195a0b8"
          }
        ],
        "campaignIndex": 1
      },
      "54174347844506ae0195a0b8": {
        "campaignIndex": 2,
        "rewards": [
          {
            "achievement": "54253cfb5d84cd00002e7f62",
            "level": "544a98f62d002f0000fe331a"
          },
          {
            "achievement": "54253cfb5d84cd00002e7f62",
            "level": "54cfc6e2d06e8152051eb8a4"
          }
        ],
        "name": "Shadow Guard",
        "description": "Evade the ogre.",
        "i18n": {},
        "type": "hero",
        "slug": "shadow-guard",
        "original": "54174347844506ae0195a0b8",
        "disableSpaces": 4,
        "hidesSubmitUntilRun": true,
        "hidesPlayButton": true,
        "hidesRunShortcut": true,
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "lockDefaultCode": false,
        "autocompleteFontSizePx": 20,
        "requiredGear": {},
        "restrictedGear": {
          "right-hand": [
            "53e218d853457600003e3ebe"
          ],
          "feet": [
            "53e2384453457600003e3f07"
          ]
        },
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "basic_syntax"
        ],
        "position": {
          "x": 33.762835987432396,
          "y": 11.364727709666788
        }
      },
      "54ca592de4983255055a5478": {
        "concepts": [
          "basic_syntax",
          "arguments"
        ],
        "tasks": [],
        "campaign": "dungeon",
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07",
            "546d4d259df4a17d0d449ac5",
            "546d4d589df4a17d0d449ac9"
          ],
          "right-hand": [
            "53e218d853457600003e3ebe",
            "544d7d918494308424f564a7",
            "544d7deb8494308424f564ab",
            "544d7ffd8494308424f564c3",
            "544d80598494308424f564c7",
            "544d80928494308424f564cb",
            "544d87188494308424f564f1",
            "544d874f8494308424f564f5",
            "544d877d8494308424f564f9"
          ],
          "programming-book": [
            "53e4108204c00d4607a89f78"
          ]
        },
        "requiredGear": {},
        "autocompleteFontSizePx": 20,
        "lockDefaultCode": false,
        "backspaceThrottle": true,
        "hidesRealTimePlayback": true,
        "hidesCodeToolbar": true,
        "hidesSay": true,
        "hidesHUD": true,
        "hidesRunShortcut": true,
        "hidesPlayButton": true,
        "adminOnly": false,
        "practice": true,
        "adventurer": false,
        "original": "54ca592de4983255055a5478",
        "slug": "enemy-mine",
        "type": "hero",
        "requiresSubscription": true,
        "i18n": {},
        "description": "Tread carefully, danger is afoot!",
        "name": "Enemy Mine",
        "rewards": [
          {
            "achievement": "54caa165fcf7f1540532890b",
            "level": "54caa542e1bd9a4f054648b0"
          }
        ],
        "campaignIndex": 3,
        "position": {
          "x": 40.39966204407879,
          "y": 11.364727709666788
        }
      },
      "541875da4c16460000ab990f": {
        "campaignIndex": 4,
        "rewards": [
          {
            "achievement": "541b15561ccc8eaae19f3c07",
            "level": "5418aec24c16460000ab9aa6"
          },
          {
            "achievement": "541b15561ccc8eaae19f3c07",
            "level": "54527a6257e83800009730c7"
          },
          {
            "achievement": "541b15561ccc8eaae19f3c07",
            "level": "5452972f57e83800009730de"
          }
        ],
        "name": "True Names",
        "description": "Learn an enemy's true name to defeat it.",
        "i18n": {},
        "type": "hero",
        "slug": "true-names",
        "original": "541875da4c16460000ab990f",
        "disableSpaces": 6,
        "hidesPlayButton": true,
        "hidesRunShortcut": true,
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "lockDefaultCode": false,
        "autocompleteFontSizePx": 20,
        "requiredCode": [
          "Brak"
        ],
        "requiredGear": {},
        "restrictedGear": {
          "programming-book": [
            "53e4108204c00d4607a89f78"
          ],
          "feet": [
            "53e2384453457600003e3f07"
          ]
        },
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "basic_syntax",
          "strings"
        ],
        "position": {
          "x": 47.92144985442785,
          "y": 10.462675898908136
        }
      },
      "55ca293b9bc1892c835b0136": {
        "position": {
          "x": 53.50629543094496,
          "y": 11.712539745627982
        },
        "concepts": [
          "basic_syntax",
          "while_loops"
        ],
        "tasks": [],
        "campaign": "dungeon",
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07",
            "546d4d8e9df4a17d0d449acd",
            "546d4d589df4a17d0d449ac9",
            "546d4d259df4a17d0d449ac5"
          ]
        },
        "requiredGear": {},
        "autocompleteFontSizePx": 20,
        "moveRightLoopSnippet": true,
        "lockDefaultCode": false,
        "backspaceThrottle": true,
        "hidesRealTimePlayback": true,
        "hidesCodeToolbar": true,
        "hidesSay": true,
        "hidesHUD": true,
        "hidesRunShortcut": true,
        "original": "55ca293b9bc1892c835b0136",
        "slug": "fire-dancing",
        "type": "hero",
        "i18n": {},
        "description": "Save typing (and your hero) with loops!",
        "name": "Fire Dancing",
        "rewards": [
          {
            "achievement": "55ca43609bc1892c835b0144",
            "level": "565ce2291b940587057366dd"
          }
        ],
        "campaignIndex": 5,
        "suspectCode": [
          {
            "name": "double-while",
            "pattern": "while(.|\\n|\\r)*while"
          }
        ]
      },
      "565ce2291b940587057366dd": {
        "campaignIndex": 6,
        "rewards": [
          {
            "achievement": "565f86219a120c86055496b3",
            "level": "545a5914d820eb0000f6dc0a"
          }
        ],
        "name": "Loop Da Loop",
        "description": "Loops are a life saver!",
        "i18n": {},
        "type": "hero",
        "slug": "loop-da-loop",
        "original": "565ce2291b940587057366dd",
        "adventurer": true,
        "hidesRunShortcut": true,
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "autocompleteFontSizePx": 20,
        "requiredGear": {},
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "basic_syntax",
          "while_loops"
        ],
        "position": {
          "x": 60.674649532710276,
          "y": 11.953497615262322
        }
      },
      "545a5914d820eb0000f6dc0a": {
        "campaignIndex": 7,
        "rewards": [
          {
            "achievement": "545a6d67d820eb0000f6dc21",
            "level": "5452a84d57e83800009730e4"
          },
          {
            "achievement": "545a6d67d820eb0000f6dc21",
            "level": "5418cf256bae62f707c7e1c3"
          }
        ],
        "name": "Haunted Kithmaze",
        "description": "A maze constructed to confuse travelers.",
        "i18n": {},
        "type": "hero",
        "slug": "haunted-kithmaze",
        "original": "545a5914d820eb0000f6dc0a",
        "hidesRunShortcut": true,
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "lockDefaultCode": false,
        "moveRightLoopSnippet": true,
        "autocompleteFontSizePx": 20,
        "requiredCode": [
          "loop"
        ],
        "requiredGear": {},
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07"
          ]
        },
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "basic_syntax",
          "while_loops"
        ],
        "position": {
          "x": 66.94834061194076,
          "y": 11.215687947100905
        }
      },
      "5418cf256bae62f707c7e1c3": {
        "concepts": [
          "basic_syntax",
          "while_loops"
        ],
        "tasks": [],
        "campaign": "dungeon",
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07"
          ]
        },
        "requiredGear": {},
        "autocompleteFontSizePx": 20,
        "moveRightLoopSnippet": true,
        "lockDefaultCode": false,
        "backspaceThrottle": true,
        "hidesRealTimePlayback": true,
        "hidesCodeToolbar": true,
        "hidesSay": true,
        "hidesHUD": true,
        "original": "5418cf256bae62f707c7e1c3",
        "slug": "the-second-kithmaze",
        "type": "hero",
        "i18n": {},
        "description": "Many have tried, few have found their way through this maze.",
        "name": "The Second Kithmaze",
        "rewards": [
          {
            "achievement": "54253d5c5d84cd00002e7f63",
            "level": "5418d40f4c16460000ab9ac2"
          },
          {
            "achievement": "54253d5c5d84cd00002e7f63",
            "item": "5441c2be4e9aeb727cc97105"
          }
        ],
        "campaignIndex": 8,
        "position": {
          "x": 80.63272271770526,
          "y": 12.770871081984192
        }
      },
      "5418d40f4c16460000ab9ac2": {
        "campaignIndex": 9,
        "rewards": [
          {
            "achievement": "541b22b21ccc8eaae19f3c19",
            "level": "5452adea57e83800009730ee"
          },
          {
            "achievement": "541b22b21ccc8eaae19f3c19",
            "level": "54e0cdefe308cb510555a7f5"
          }
        ],
        "name": "Dread Door",
        "description": "Behind a dread door lies a chest full of riches.",
        "i18n": {},
        "type": "hero",
        "slug": "dread-door",
        "original": "5418d40f4c16460000ab9ac2",
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "lockDefaultCode": 9,
        "autocompleteFontSizePx": 20,
        "requiredGear": {},
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07"
          ],
          "right-hand": [
            "53f4e6e3d822c23505b74f42",
            "54694ba3a2b1f53ce794444d"
          ]
        },
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "basic_syntax",
          "while_loops",
          "strings"
        ],
        "position": {
          "x": 88.25112251874386,
          "y": 19.244678910956324
        }
      },
      "54e0cdefe308cb510555a7f5": {
        "position": {
          "y": 26.728260086243417,
          "x": 81.15679685579524
        },
        "campaignIndex": 10,
        "rewards": [
          {
            "achievement": "54e2ab6e0f6efa5005600737",
            "level": "54e8e4047578d754057f852b"
          }
        ],
        "name": "Cupboards of Kithgard",
        "description": "Who knows what horrors lurk in the Cupboards of Kithgard?",
        "i18n": {},
        "requiresSubscription": true,
        "type": "hero",
        "slug": "cupboards-of-kithgard",
        "original": "54e0cdefe308cb510555a7f5",
        "adventurer": false,
        "adminOnly": false,
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "lockDefaultCode": false,
        "autocompleteFontSizePx": 20,
        "requiredGear": {},
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07",
            "546d4d8e9df4a17d0d449acd",
            "546d4d589df4a17d0d449ac9",
            "546d4d259df4a17d0d449ac5"
          ]
        },
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "basic_syntax",
          "while_loops",
          "strings"
        ]
      },
      "54f0e074a375e47f055d619c": {
        "position": {
          "y": 30.34167921686747,
          "x": 73.73231720900935
        },
        "concepts": [
          "basic_syntax",
          "while_loops",
          "strings"
        ],
        "tasks": [],
        "campaign": "dungeon",
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07",
            "546d4d8e9df4a17d0d449acd",
            "546d4d589df4a17d0d449ac9",
            "546d4d259df4a17d0d449ac5"
          ]
        },
        "requiredGear": {},
        "autocompleteFontSizePx": 20,
        "lockDefaultCode": false,
        "backspaceThrottle": true,
        "hidesRealTimePlayback": true,
        "hidesCodeToolbar": true,
        "hidesSay": true,
        "hidesHUD": true,
        "adminOnly": false,
        "adventurer": false,
        "original": "54f0e074a375e47f055d619c",
        "slug": "breakout",
        "type": "hero",
        "requiresSubscription": true,
        "i18n": {},
        "description": "Munchkins are chasing you, and the way ahead is blocked!",
        "name": "Breakout",
        "rewards": [],
        "campaignIndex": 11
      },
      "5452adea57e83800009730ee": {
        "campaignIndex": 12,
        "rewards": [
          {
            "achievement": "5452bb6757e83800009730f4",
            "item": "53e238df53457600003e3f0b"
          },
          {
            "achievement": "5452bb6757e83800009730f4",
            "level": "5452c3ce57e83800009730f7"
          }
        ],
        "name": "Known Enemy",
        "description": "Using your first variable to achieve victory.",
        "i18n": {},
        "type": "hero",
        "slug": "known-enemy",
        "original": "5452adea57e83800009730ee",
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "lockDefaultCode": false,
        "autocompleteFontSizePx": 20,
        "suspectCode": [
          {
            "name": "enemy-in-quotes",
            "pattern": "['\"]enemy"
          }
        ],
        "requiredGear": {},
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07"
          ]
        },
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "variables",
          "basic_syntax",
          "strings"
        ],
        "position": {
          "x": 69.65270816049042,
          "y": 25.67195662532944
        }
      },
      "5452c3ce57e83800009730f7": {
        "position": {
          "y": 26.387842017483997,
          "x": 56.47568004086775
        },
        "concepts": [
          "basic_syntax",
          "variables"
        ],
        "tasks": [],
        "campaign": "dungeon",
        "restrictedGear": {
          "feet": [
            "53e2384453457600003e3f07"
          ]
        },
        "requiredGear": {},
        "suspectCode": [
          {
            "name": "lone-find-nearest-enemy",
            "pattern": "^[ ]*(self|this|@)?[:.]?findNearestEnemy()"
          }
        ],
        "requiredCode": [
          "findNearestEnemy"
        ],
        "autocompleteFontSizePx": 20,
        "lockDefaultCode": false,
        "backspaceThrottle": true,
        "hidesRealTimePlayback": true,
        "hidesCodeToolbar": true,
        "hidesSay": true,
        "hidesHUD": true,
        "original": "5452c3ce57e83800009730f7",
        "slug": "master-of-names",
        "type": "hero",
        "i18n": {},
        "description": "Use your new coding powers to target nameless enemies.",
        "name": "Master of Names",
        "rewards": [
          {
            "achievement": "5452e88a06a59e000067e50e",
            "level": "541b24511ccc8eaae19f3c1f"
          }
        ],
        "campaignIndex": 13
      },
      "55ca29439bc1892c835b0137": {
        "campaignIndex": 14,
        "rewards": [
          {
            "achievement": "55ca45629bc1892c835b014c",
            "level": "541b434e1ccc8eaae19f3c33"
          }
        ],
        "name": "A Mayhem of Munchkins",
        "description": "Survive a neverending stream of ogres with mentorship from two experienced heroes!",
        "i18n": {},
        "type": "hero",
        "slug": "a-mayhem-of-munchkins",
        "original": "55ca29439bc1892c835b0137",
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "lockDefaultCode": false,
        "autocompleteFontSizePx": 20,
        "suspectCode": [
          {
            "name": "lone-find-nearest-enemy",
            "pattern": "^[ ]*(self|this|@)?[:.]?findNearestEnemy()"
          }
        ],
        "requiredGear": {},
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "basic_syntax",
          "variables",
          "arguments",
          "while_loops"
        ],
        "position": {
          "x": 61.29479872441925,
          "y": 34.55907063311842
        }
      },
      "5452d8b906a59e000067e4fa": {
        "position": {
          "y": 40.53034954760448,
          "x": 68.66942399136555
        },
        "concepts": [
          "basic_syntax",
          "variables",
          "while_loops"
        ],
        "tasks": [],
        "campaign": "dungeon",
        "restrictedGear": {
          "right-hand": [
            "53f4e6e3d822c23505b74f42"
          ],
          "feet": [
            "53e2384453457600003e3f07"
          ]
        },
        "requiredGear": {},
        "suspectCode": [
          {
            "name": "lone-find-nearest-enemy",
            "pattern": "^[ ]*(self|this|@)?[:.]?findNearestEnemy()"
          }
        ],
        "autocompleteFontSizePx": 20,
        "lockDefaultCode": false,
        "backspaceThrottle": true,
        "hidesRealTimePlayback": true,
        "hidesCodeToolbar": true,
        "hidesSay": true,
        "hidesHUD": true,
        "practice": true,
        "original": "5452d8b906a59e000067e4fa",
        "slug": "the-gauntlet",
        "type": "hero",
        "requiresSubscription": true,
        "i18n": {},
        "description": "Use all of your skills to survive the gauntlet.",
        "name": "The Gauntlet",
        "rewards": [
          {
            "achievement": "5452db0106a59e000067e4fc",
            "level": "54d24c49bf87255405a8f834"
          }
        ],
        "campaignIndex": 15
      },
      "541b434e1ccc8eaae19f3c33": {
        "campaignIndex": 16,
        "rewards": [
          {
            "achievement": "54253e065d84cd00002e7f65",
            "level": "541c9a30c6362edfb0f34479"
          },
          {
            "achievement": "54253e065d84cd00002e7f65",
            "level": "5452d8b906a59e000067e4fa"
          },
          {
            "achievement": "54253e065d84cd00002e7f65",
            "item": "53f4e6e3d822c23505b74f42"
          }
        ],
        "name": "The Final Kithmaze",
        "description": "To escape you must find your way through an elder Kithman's maze.",
        "i18n": {},
        "type": "hero",
        "slug": "the-final-kithmaze",
        "original": "541b434e1ccc8eaae19f3c33",
        "hidesHUD": true,
        "hidesSay": true,
        "hidesCodeToolbar": true,
        "hidesRealTimePlayback": true,
        "backspaceThrottle": true,
        "lockDefaultCode": false,
        "autocompleteFontSizePx": 20,
        "suspectCode": [
          {
            "name": "lone-find-nearest-enemy",
            "pattern": "^[ ]*(self|this|@)?[:.]?findNearestEnemy()"
          }
        ],
        "requiredGear": {},
        "campaign": "dungeon",
        "tasks": [],
        "concepts": [
          "basic_syntax",
          "while_loops",
          "variables"
        ],
        "position": {
          "x": 74.56912900611479,
          "y": 46.45561310182135
        }
      },
      "541c9a30c6362edfb0f34479": {
        "position": {
          "y": 54.939545780779376,
          "x": 80.71431897968904
        },
        "concepts": [
          "basic_syntax",
          "arguments",
          "strings"
        ],
        "tasks": [],
        "campaign": "dungeon",
        "restrictedGear": {},
        "requiredGear": {},
        "autocompleteFontSizePx": 20,
        "lockDefaultCode": false,
        "backspaceThrottle": true,
        "hidesRealTimePlayback": true,
        "hidesCodeToolbar": true,
        "hidesSay": true,
        "original": "541c9a30c6362edfb0f34479",
        "slug": "kithgard-gates",
        "type": "hero",
        "i18n": {},
        "description": "Escape the Kithgard dungeons, and don't let the guardians get you.",
        "name": "Kithgard Gates",
        "rewards": [
          {
            "achievement": "541c9cf0c6362edfb0f3447a",
            "level": "541b67f71ccc8eaae19f3c62"
          },
          {
            "achievement": "541c9cf0c6362edfb0f3447a",
            "level": "5578843e5cda3d8905654190"
          }
        ],
        "campaignIndex": 17
      },
      "5630eab0c0fcbd86057cc2f8": {
        "hidesRealTimePlayback": true,
        "rewards": [],
        "name": "Wakka Maul",
        "description": "![Nov17 wakka maul](/file/db/level/5630eab0c0fcbd86057cc2f8/NOV17-Wakka Maul.png)\n\nBattle your classmates while gobbling up gems! Use your programming skills and creative thinking to gain an edge over your friends.",
        "i18n": {},
        "type": "course-ladder",
        "slug": "wakka-maul",
        "original": "5630eab0c0fcbd86057cc2f8",
        "hidesCodeToolbar": true,
        "backspaceThrottle": true,
        "autocompleteFontSizePx": 20,
        "campaign": "intro",
        "tasks": [],
        "concepts": [
          "basic_syntax",
          "algorithms",
          "arguments",
          "strings",
          "while_loops"
        ],
        "position": {
          "x": 17.481313926042485,
          "y": 78.3938778580024
        },
        "campaignIndex": 18,
        "requiredGear": {}
      }
    },
    "patches": [],
    "type": "course"
  }  
  
  course: {
    "_id": "560f1a9f22961295f9427742",
    "name": "Introduction to Computer Science",
    "slug": "introduction-to-computer-science",
    "campaignID": "55b29efd1cd6abe8ce07db0d",
    "concepts": [
      "basic_syntax",
      "arguments",
      "strings",
      "while_loops",
      "variables"
    ],
    "description": "Learn basic syntax, while loops, and the CodeCombat environment.",
    "duration": 1,
    "pricePerSeat": 0,
    "free": true,
    "screenshot": "/images/pages/courses/101_info.png"
  }
  
  
  courseInstanceSessions: [
    {
      "_id": "542c78d49ba93600003ee6d3",
      "changed": "2016-01-11T18:45:07.927Z",
      "level": {
        "original": "5411cb3769152f1707be029c"
      },
      "state": {
        "complete": true
      },
      "playtime": 1609
    },
    {
      "_id": "54380da36e7af40021bf5155",
      "changed": "2016-01-11T23:33:09.763Z",
      "level": {
        "original": "54173c90844506ae0195a0b4"
      },
      "state": {
        "complete": true
      },
      "playtime": 724
    },
    {
      "_id": "542ef2c480d9aa104e81272f",
      "changed": "2016-01-11T18:48:40.722Z",
      "level": {
        "original": "54174347844506ae0195a0b8"
      },
      "state": {
        "complete": true
      },
      "playtime": 409
    },
    {
      "_id": "542edae22d8c150000019128",
      "changed": "2016-01-11T18:31:36.932Z",
      "level": {
        "original": "541875da4c16460000ab990f"
      },
      "state": {
        "complete": true
      },
      "playtime": 1659
    },
    {
      "_id": "543c3dd43eb2580000d33045",
      "changed": "2015-11-19T17:56:04.522Z",
      "level": {
        "original": "5418cf256bae62f707c7e1c3"
      },
      "state": {
        "complete": true
      },
      "playtime": 93
    },
    {
      "_id": "542ecadc2d8c150000019125",
      "changed": "2015-11-29T19:23:11.133Z",
      "level": {
        "original": "5418d40f4c16460000ab9ac2"
      },
      "state": {
        "complete": true
      },
      "playtime": 117
    },
    {
      "_id": "5463e15d6f4cc40000b14f3a",
      "changed": "2015-11-29T19:28:33.799Z",
      "level": {
        "original": "541b434e1ccc8eaae19f3c33"
      },
      "state": {
        "complete": true
      },
      "playtime": 59
    },
    {
      "_id": "547e0c62e19f8e58056bf872",
      "changed": "2015-11-29T19:29:18.715Z",
      "level": {
        "original": "541c9a30c6362edfb0f34479"
      },
      "state": {
        "complete": true
      },
      "playtime": 42
    },
    {
      "_id": "545ae2504425d30000ee7db6",
      "changed": "2015-11-29T19:25:47.361Z",
      "level": {
        "original": "5452adea57e83800009730ee"
      },
      "state": {
        "complete": true
      },
      "playtime": 1259
    },
    {
      "_id": "565b513dd458ab9219b9527b",
      "changed": "2015-11-29T19:26:19.521Z",
      "level": {
        "original": "5452c3ce57e83800009730f7"
      },
      "state": {
        "complete": true
      },
      "playtime": 29
    },
    {
      "_id": "565b5188d458ab9219b9528a",
      "changed": "2015-12-27T23:34:21.144Z",
      "level": {
        "original": "5452d8b906a59e000067e4fa"
      },
      "state": {
        "complete": true
      },
      "playtime": 26
    },
    {
      "_id": "546badf73470fc1104015f50",
      "changed": "2015-11-29T19:48:44.660Z",
      "level": {
        "original": "545a5914d820eb0000f6dc0a"
      },
      "state": {
        "complete": true
      },
      "playtime": 57
    },
    {
      "_id": "55dfd5d592e9cfb607cabc2c",
      "changed": "2015-12-03T20:06:32.309Z",
      "level": {
        "original": "54ca592de4983255055a5478"
      },
      "state": {
        "complete": true
      },
      "playtime": 42
    },
    {
      "_id": "565b50a4d458ab9219b95260",
      "changed": "2015-11-29T19:23:52.221Z",
      "level": {
        "original": "54e0cdefe308cb510555a7f5"
      },
      "state": {
        "complete": true
      },
      "playtime": 34
    },
    {
      "_id": "565b50cad458ab9219b9526c",
      "changed": "2015-11-29T19:25:23.814Z",
      "level": {
        "original": "54f0e074a375e47f055d619c"
      },
      "state": {
        "complete": true
      },
      "playtime": 88
    },
    {
      "_id": "55f4570530825985054b0260",
      "changed": "2015-11-29T19:48:39.224Z",
      "level": {
        "original": "55ca293b9bc1892c835b0136"
      },
      "state": {
        "complete": true
      },
      "playtime": 207
    },
    {
      "_id": "565b515dd458ab9219b95282",
      "changed": "2015-12-27T23:38:34.709Z",
      "level": {
        "original": "55ca29439bc1892c835b0137"
      },
      "state": {
        "complete": true
      },
      "playtime": 113
    }
  ]
  
  
  earnedAchievements: [
    {
      "collection": "level.sessions",
      "triggeredBy": "54380da36e7af40021bf5155",
      "achievement": "541a23431ccc8eaae19f3bf6",
      "_id": "543c21473eb2580000d3303c",
      "user": "5162fab9c92b4c751e000274",
      "achievementName": "Gems in the Deep Completed",
      "earnedRewarsd": {
        "gems": 5,
        "levels": [
          "54174347844506ae0195a0b8"
        ]
      },
      "earnedPoints": 11,
      "changed": "2015-04-02T21:18:27.994Z",
      "created": "2014-10-13T19:00:23.833Z",
      "__v": 0,
      "earnedRewards": {
        "gems": 18,
        "levels": [
          "54174347844506ae0195a0b8"
        ]
        "items":[
          "53e4108204c00d4607a89f78"
        ]
      },
      "notified": true
    },
    {
      "collection": "level.sessions",
      "triggeredBy": "54380da36e7af40021bf5155",
      "achievement": "5452e14006a59e000067e501",
      "_id": "5453164e60cfd0188a82a52d",
      "user": "5162fab9c92b4c751e000274",
      "earnedRewards": {
        "gems": 9
      },
      "earnedPoints": 5,
      "achievementName": "Gems in the Deep Clean Code",
      "changed": "2015-04-02T21:18:38.200Z",
      "notified": true
    }
  ]

  
  level: {
    "_id": "568d3143b38ab75c00c2a4e5",
    "slug": "gems-in-the-deep",
    "name": "Gems in the Deep",
    "creator": "568d15a28d909b2500464181",
    "original": "54173c90844506ae0195a0b4",
    "watchers": [
    ],
    "__v": 0,
    "thangs": [],
    "systems": [],
    "goals": [],
    "commitMessage": "",
    "parent": "56898f85450ac83600d8c945",
    "scripts": [],
    "type": "hero",
    "description": "Quickly collect the gems; you will need them.",
    "victory": {
      "body": "You will find a use for these gems soon.",
      "i18n": []
    },
    "nextLevel": {
      "original": "54174347844506ae0195a0b8",
      "majorVersion": 0
    },
    "terrain": "Dungeon",
    "patches": [],
    "i18n": [],
    "documentation": []
    "i18nCoverage": [],
    "index": true,
    "buildTime": 14891,
    "concepts": [
      "basic_syntax"
    ],
    "campaignIndex": 1,
    "created": "2016-01-06T15:22:43.033Z",
    "version": {
      "isLatestMinor": true,
      "isLatestMajor": true,
      "minor": 123,
      "major": 0
    },
    "permissions": [
      {
        "access": "owner",
        "target": "51538fdb812dd9af02000001"
      },
      {
        "access": "read",
        "target": "public"
      }
    ]
  }
  
  
  nextLevel: {
    "_id": "568127b67e81751f00de45f7",
    "slug": "shadow-guard",
    "name": "Shadow Guard",
    "creator": "53b54cda7e17883a0575767a",
    "original": "54174347844506ae0195a0b8",
    "watchers": [],
    "__v": 0,
    "scripts": [],
    "thangs": [],
    "systems": [],
    "commitMessage": "i18n patch",
    "parent": "566fc0cb66f91c2500c38f0a",
    "type": "hero",
    "description": "Evade the ogre.",
    "victory": {},
    "nextLevel": {
      "original": "54ca592de4983255055a5478",
      "majorVersion": 0
    },
    "terrain": "Dungeon",
    "goals": [],
    "patches": [],
    "i18n": {},
    "i18nCoverage": [],
    "loadingTip": "We automatically save your code every few seconds.",
    "documentation": {},
    "requiredGear": {},
    "restrictedGear": {},
    "helpVideos": [],
    "campaign": "dungeon",
    "tasks": [],
    "buildTime": 1923,
    "scoreTypes": ["time"],
    "index": true,
    "concepts": ["basic_syntax"],
    "campaignIndex": 2,
    "created": "2015-12-28T12:14:46.362Z",
    "version": {
      "isLatestMinor": true,
      "isLatestMajor": true,
      "minor": 123,
      "major": 0
    },
    "permissions": [
      {
        "access": "owner",
        "target": "51538fdb812dd9af02000001"
      },
      {
        "access": "read",
        "target": "public"
      }
    ]
  }
  
  
  session: {
    "_id": "54380da36e7af40021bf5155",
    "changed": "2016-01-08T19:01:18.508Z",
    "level": {
      "original": "54173c90844506ae0195a0b4",
      "majorVersion": 0
    },
    "creator": "5162fab9c92b4c751e000274",
    "state": {
      "topScores": [
        {
          "type": "time",
          "date": "2015-10-26T17:46:17.508Z",
          "score": -13.600000000000001
        }
      ],
      "playing": true,
      "selected": "Hero Placeholder",
      "complete": true,
      "scripts": {
        "ended": {
          "Real-Time Submission": 6,
          "Debugging Victory": 5,
          "First Code Run": 4,
          "First Code Preload": 3,
          "First Code Edit": 2,
          "Introduction": 1,
          "Taking Too Long": 7
        },
        "currentScriptOffset": 0,
        "currentScript": null
      },
      "goalStates": {
        "humans-survive": {
          "status": "success",
          "keyFrame": "end",
          "killed": {
            "Hero Placeholder": false
          }
        },
        "collect-gems": {
          "collected": {
            "Gem 4": true,
            "Gem 3": true,
            "Gem 2": true,
            "Gem 1": true,
            "Gem": true
          },
          "keyFrame": 118,
          "status": "success"
        },
        "clean-code": {
          "problems": {
            "Hero Placeholder": false
          },
          "optional": false,
          "keyFrame": "end",
          "status": "success"
        }
      },
      "frame": 0,
      "flagHistory": []
    },
    "codeLanguage": "python",
    "__v": 1,
    "heroConfig": {
      "inventory": {
        "programming-book": "53e4108204c00d4607a89f78",
        "feet": "53e237bf53457600003e3f05",
        "waist": "5437002a7beba4a82024a97d",
        "right-hand": "53e218d853457600003e3ebe",
        "gloves": "5469425ca2b1f53ce7944421",
        "torso": "53e22eac53457600003e3efc",
        "eyes": "53e238df53457600003e3f0b",
        "head": "5441c2be4e9aeb727cc97105"
      },
      "thangType": "529ffbf1cf1818f2be000001"
    },
    "code": {
      "hero-placeholder": {
        "plan": "# Grab all the gems using your movement commands.\n\nself.moveRight()\nself.moveUp()\nself.moveRight()\nself.moveDown()\nself.moveLeft()\nself.moveDown()\nself.moveUp()\n\n"
      }
    },
    "playtime": 698,
    "teamSpells": {
      "humans": [
        "hero-placeholder/plan"
      ]
    },
    "creatorName": "Scott",
    "levelID": "gems-in-the-deep",
    "levelName": "Gems in the Deep",
    "multiplayer": false,
    "browser": {
      "version": "47.0.2526.106",
      "platform": "mac",
      "name": "chrome",
      "desktop": true
    },
    "permissions": [
      {
        "target": "5162fab9c92b4c751e000274",
        "access": "owner"
      }
    ],
    "created": "2014-10-10T16:47:31.077Z"
  }
  

  thangType: {
    "_id": "568fe842cc51432f0036beb6",
    "slug": "programmaticon-i",
    "name": "Programmaticon I",
    "original": "53e4108204c00d4607a89f78",
    "components": [
      {
        "original": "524b4150ff92f1f4f8000024",
        "majorVersion": 0
      },
      {
        "original": "53e12043b82921000051cdf9",
        "majorVersion": 0,
        "config": {
          "slots": [
            "programming-book"
          ]
        }
      },
      {
        "original": "524c81cab8bb087aaf000069",
        "majorVersion": 0,
        "config": {
          "programmableSnippets": [
            "loop"
          ]
        }
      }
    ],
    "description": "Grants access to loops.",
    "version": {
      "isLatestMinor": true,
      "isLatestMajor": true,
      "minor": 56,
      "major": 0
    }
  }
}