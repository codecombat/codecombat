const _ = require('lodash')
const schemas = require('../schemas/schemas')
const levelSchema = require('../schemas/models/level')
const terrainGeneration = require('./terrain-generation')
const Vector = require('./world/vector')

module.exports = {
  generateLevel,
}

async function generateLevel (parameters) {
  parameters.terrain = parameters.terrain || 'Junior'
  extractPracticeLevelParameters(parameters)
  parameters = fillRandomParameters(parameters)

  const level = {
    parameters,
    parametersKey: generateKeyForParameters(parameters),
  }

  for (const generationFunction of generationFunctions) {
    await generationFunction(level, parameters)
  }

  return level
}

// ---- Input Parameters ----

const juniorSizes = ['junior3x2', 'junior4x3', 'junior5x4', 'junior6x5', 'junior7x6', 'junior8x7', 'junior9x7', 'junior9x8']
const ParametersSchema = schemas.object({ required: ['difficulty', 'kind'] }, {
  terrain: schemas.terrainString,
  kind: schemas.shortString({ title: 'Kind', description: 'Similar to type, but just for our organization.', enum: ['demo', 'usage', 'mastery', 'advanced', 'practice', 'challenge'] }),
  difficulty: { type: 'integer', minimum: 1, maximum: 5 },
  combat: { type: 'boolean' },
  size: schemas.shortString({ title: 'Size', description: 'How big the level is', enum: juniorSizes }),
  skillReading: { type: 'number', minimum: 0, maximum: 1 },
  skillTyping: { type: 'number', minimum: 0, maximum: 1 },
  skillEditing: { type: 'number', minimum: 0, maximum: 1 },
  skillGo: { type: 'number', minimum: 0, maximum: 1 },
  skillStringArgumnets: { type: 'number', minimum: 0, maximum: 1 },
  skillNumericArgumnets: { type: 'number', minimum: 0, maximum: 1 },
  skillHit: { type: 'number', minimum: 0, maximum: 1 },
  skillZap: { type: 'number', minimum: 0, maximum: 1 },
  skillSpin: { type: 'number', minimum: 0, maximum: 1 },
  skillLook: { type: 'number', minimum: 0, maximum: 1 },
  skillForLoops: { type: 'number', minimum: 0, maximum: 1 },
})

function extractPracticeLevelParameters (parameters) {
  if (!parameters.sourceLevel) { return }
  // Find the size of the existing level, and pick one a similar size or maybe one bigger
  // let rows, cols
  // const floorThangType = '66340645d79810f8365343e1' // Junior Beach Floor
  // for (let col = 8; col >= 0; --col) {
  //   if (_.find(parameters.sourceLevel.get('thangs'), (t) =>
  //     t.thangType === floorThangType &&
  //       t.components[1].config?.pos.x === 6 + 8 * col
  //   )) {
  //     cols = col + 1
  //     break
  //   }
  // }
  // for (let row = 8; row >= 0; --row) {
  //   if (_.find(parameters.sourceLevel.get('thangs'), (t) =>
  //     t.thangType === floorThangType &&
  //       t.components[1].config?.pos.y === 6 + 8 * row
  //   )) {
  //     rows = row + 1
  //     break
  //   }
  // }
  // const sourceSize = `junior${cols}x${rows}`
  // const sourceSizeIndex = juniorSizes.indexOf(sourceSize)
  // if (sourceSizeIndex !== -1) {
  //   parameters.size = _.sample(juniorSizes.slice(sourceSizeIndex, sourceSizeIndex + 2))
  // }
  // Actually, just always make a big one; we will cut it down later, in adjustTerrain
  parameters.size = juniorSizes[juniorSizes.length - 1]
}

function fillRandomParameters (parameters) {
  parameters = parameters || {}

  // Iterate the ParametersSchema, choosing a random enum value if it's an enum type or a numeric value between minimum and maximum if it's a number type
  for (const [key, value] of Object.entries(ParametersSchema.properties)) {
    if (parameters[key] !== undefined) {
      continue
    }

    if (value.type === 'boolean') {
      parameters[key] = !(Math.random() < 0.5)
    } else if (value.enum) {
      parameters[key] = value.enum[Math.floor(Math.random() * value.enum.length)]
    } else if (value.type === 'integer') {
      parameters[key] = Math.floor(Math.random() * (value.maximum - value.minimum + 1)) + value.minimum
    } else if (value.type === 'number') {
      parameters[key] = Math.floor(Math.random() * 10) / 10 * (value.maximum - value.minimum) + value.minimum
    }
  }

  return parameters
}

function generateKeyForParameters (parameters) {
  // Generate a key string to identify these parameter values, preserving the order of parameters defined in ParameterSchema
  const result = []
  for (const key of Object.keys(ParametersSchema.properties)) {
    result.push(parameters[key])
  }
  return result.join('_')
}

// ---- Output Properties ----

const generationFunctions = []
function generateProperty (property, fn) {
  const generationFunction = async function (level, parameters) {
    const result = await fn(level, parameters)
    if (property && result !== undefined) {
      const { errors } = tv4.validateMultiple(result, levelSchema.properties[property])
      if (errors?.length) {
        console.error(`Couldn't validate assignment of ${property}:`, result, `Validation error: ${errors}`)
        return
      }
      level[property] = result
    }
  }
  generationFunctions.push(generationFunction)
}

// name: c.shortString()
generateProperty('name', function (level, parameters) {
  if (!parameters.sourceLevel) { return undefined }
  // Add parameters.sourceLevel.get('name') with ' A', ' B', ' C', etc., stripping existing suffix if needed
  // TODO: this will need to take into account the multiple other extant levels, not just the source level
  const sourceName = parameters.sourceLevel.get('name')
  const existingLetter = name.replace(/^.*? ([A-Z])$/, '$1')
  const newLetter = existingLetter ? String.fromCharCode(existingLetter.charCodeAt(0) + 1) : 'A'
  return sourceName.replace(/ [A-Z]$/, '') + ' ' + newLetter
})

// // displayName: c.shortString({title: 'Display Name', inEditor: 'ozaria'}),
// generateProperty('displayName', function (level, parameters) {
//   return `Autolevel ${parameters.terrain} ${parameters.kind} ${parameters.difficulty}`
// })

// description: {title: 'Description', description: 'A short explanation of what this level is about.', type: 'string', maxLength: 65536, format: 'markdown', inEditor: true},
generateProperty('description', function (level, parameters) {
  if (!parameters.sourceLevel) { return undefined }
  return `Extra practice for level ${parameters.sourceLevel.get('name')}`
})

// // loadingTip: { type: 'string', title: 'Loading Tip', description: 'What to show for this level while it\'s loading.', inEditor: 'codecombat' },
// generateProperty('loadingTip', function (level, parameters) {
//   return `This is a ${parameters.terrain} ${parameters.kind} level with difficulty ${parameters.difficulty} / 5`
// })

// goals: c.array({title: 'Goals', description: 'An array of goals which are visible to the player and can trigger scripts.', inEditor: true}, GoalSchema),
generateProperty('goals', function (level, parameters) {
  if (parameters.sourceLevel) {
    return _.cloneDeep(parameters.sourceLevel.get('goals'))
  }

  const exampleGoals = {
    heroSurvives: {
      hiddenGoal: true,
      worldEndsAfter: 1,
      howMany: 1,
      saveThangs: ['humans'],
      name: 'Your hero must survive.',
      id: 'hero-survives'
    },

    saveFriends: {
      name: 'Friends must survive.',
      id: 'humans-survive',
      saveThangs: ['Chicken Junior'], // Placeholder
      worldEndsAfter: 1,
    },

    cleanCode: {
      hiddenGoal: true,
      codeProblems: ['humans'],
      optional: false,
      id: 'clean-code',
      name: 'No code problems.'
    },

    shortCode: {
      optional: false,
      linesOfCode: { humans: 5 },
      id: 'short-code',
      name: 'Under 6 statements.'
    },

    moveToTarget: {
      worldEndsAfter: 1,
      getToLocations: {
        targets: ['Goal Junior'],
        who: ['Hero Placeholder']
      },
      id: 'touch-goal',
      name: 'Go to the raft.' // TODO: update generation to put it on water
    },

    defeatEnemies: {
      killThangs: ['ogres'],
      id: 'ogres-die',
      name: 'Defeat the enemies.'
    },

    defeatDoor: {
      name: 'Break the door.',
      id: 'break-door',
      killThangs: ['Crates Junior'],
      howMany: 1,
    },

    collectGems: {
      collectThangs: {
        targets: ['Gem Junior'], // Placeholder
        who: ['humans']
      },
      id: 'collect-gems',
      name: 'Collect the gems.'
    },
  }

  const goals = []
  function addGoal (goal, config) {
    goal = _.cloneDeep(goal)
    for (const key in config || {}) {
      goal[key] = config[key]
    }
    goals.push(goal)
  }

  addGoal(exampleGoals.heroSurvives)
  addGoal(exampleGoals.cleanCode)
  if (parameters.combat && Math.random() < 0.75) {
    addGoal(exampleGoals.defeatEnemies)
    _.find(goals, { id: 'hero-survives' }).hiddenGoal = false

    if (Math.random() < 0.25) {
      addGoal(exampleGoals.saveFriends)
    }
  }
  // TODO: break doors goal
  if (Math.random() < 0.5) {
    addGoal(exampleGoals.collectGems)
  }
  if (Math.random() < 0.5 || goals.length === 2) {
    addGoal(exampleGoals.moveToTarget)
  } else {
    const lastGoal = _.find(goals, { id: 'collect-gems' }) || _.find(goals, { id: 'ogres-die' }) || _.find(goals, { id: 'break-door' }) || {}
    lastGoal.worldEndsAfter = 1
  }

  return goals
})

// documentation: c.object({title: 'Documentation', description: 'Documentation articles relating to this level.', 'default': {specificArticles: [], generalArticles: []}, inEditor: true}, {
generateProperty('documentation', function (level, parameters) {
  return {
    specificArticles: [],
    generalArticles: [],
  }
})

// scripts: c.array({title: 'Scripts', description: 'An array of scripts that trigger based on what the player does and affect things outside of the core level simulation.'}, ScriptSchema),
generateProperty('scripts', function (level, parameters) {
  const rows = parseInt(parameters.size.replace(/junior(.+?)x.+/, '$1'), 10)
  // const cols = parseInt(parameters.size.replace(/junior.+?x(.+)/, '$1'), 10)
  return [{
    id: 'Introduction',
    channel: 'god:new-world-created',
    noteChain: [
      {
        name: 'Set camera, start music.',
        surface: {
          focus: {
            bounds: [
              {
                x: -4,
                y: -4 * 17 / 20
              },
              {
                x: 4 + 8 * rows + 4,
                y: (4 + 8 * rows + 4) * 17 / 20 // Maintain aspect ratio
              }
            ],
            target: 'Hero Placeholder',
            zoom: 0.5
          }
        },
        sound: {
          music: {
            file: `/music/music_level_${parameters.difficulty}`,
            play: true
          }
        },
        script: {
          duration: 1
        },
        playback: {
          playing: false
        }
      }
    ]
  }]
})

// Can't import these from LevelComponent when sourced from a script for some reason
// const LevelComponent = require('../models/LevelComponent')
const PhysicalID = '524b75ad7fc0f6d519000001' // LevelComponent.ExistsID
const ExistsID = '524b4150ff92f1f4f8000024' // LevelComponent.PhysicalID
const SelectableID = '524b7bb67fc0f6d519000018' // LevelComponent.SelectableID

const defaultHeroComponentIDs = {
  Programmable: '524b7b5a7fc0f6d51900000e',
  JuniorPlayer: '65b29e528f43392e778c9433',
  Collides: '524b7b857fc0f6d519000012',
  Attackable: '524b7bab7fc0f6d519000017',
  HasEvents: '524b3e3fff92f1f4f800000d',
  Spawns: '524cbdc03ea855e0ab0000bb',
  Says: '524b7b9f7fc0f6d519000015',
  Moves: '524b7b8c7fc0f6d519000013',
  MovesSimply: '524b7b427fc0f6d51900000b',
  HasAPI: '52e816058c875f0000000001',
  Targets: '524b7b7c7fc0f6d519000011',
  Collects: '524b7bbe7fc0f6d519000019',
}

const defaultHeroComponentConfig = {
  Attackable: { maxHealth: 3 },
  JuniorPlayer: {
    programmableSnippets: [],
    requiredThangTypes: ['5467beaf69d1ba0000fb91fb']
  },
  Moves: { maxSpeed: 8 },
  MovesSimply: { simpleMoveDistance: 8 },
  Plans: { worldEndsAfter: 2 },
}

function createEssentialComponents (defaultComponents, pos, isHero) {
  const physicalConfig = { pos }
  const physicalComponent = _.find(defaultComponents || [], { original: PhysicalID })
  if (physicalComponent && physicalComponent.config) {
    physicalConfig.pos.z = physicalComponent.config.pos.z // Get the z right
  }
  if (isHero) {
    physicalConfig.pos.x = 6
    physicalConfig.pos.y = 14
  }

  const components = [
    { original: ExistsID, majorVersion: 0, config: {} },
    { original: PhysicalID, majorVersion: 0, config: physicalConfig }
  ]
  if (isHero) {
    for (const [name, id] of Object.entries(defaultHeroComponentIDs)) {
      const component = { original: id, majorVersion: 0 }
      const config = defaultHeroComponentConfig[name]
      if (config) {
        component.config = config
      }
      components.push(component)
    }
  }
  return components
}

// Stores thangType with spriteName as the key
const spriteNamesToThangTypes = {}
const thangTypesToSpriteNames = {}
async function loadThangTypes (spriteNames) {
  // Need at least one promise in loadingPromises to prevent empty array Promise bug.
  const loadingPromises = [Promise.resolve()]
  const uniqueSpriteNames = _.uniq(spriteNames)
  for (const spriteName of uniqueSpriteNames) {
    let thangType = spriteNamesToThangTypes[spriteName]
    if (!thangType) {
      const slug = _.string.slugify(spriteName)
      const fetchOptions = {
        headers: { 'content-type': 'application/json' },
        credentials: 'same-origin'
      }
      const origin = window?.location?.origin || 'https://codecombat.com'
      const thangTypePromise = fetch(`${origin}/db/thang.type/${slug}?project=original,components`, fetchOptions).then(async function (response) {
        try {
          thangType = await response.json()
          spriteNamesToThangTypes[spriteName] = thangType
          thangTypesToSpriteNames[thangType.original] = spriteName
        } catch (err) {}
      })
      loadingPromises.push(thangTypePromise)
    }
  }
  await Promise.all(loadingPromises)
}

// thangs: c.array({title: 'Thangs', description: 'An array of Thangs that make up the level.' }, LevelThangSchema),
generateProperty('thangs', async function (level, parameters) {
  const terrainGenerationOptions = { presetName: parameters.terrain, presetSize: parameters.size }
  let spriteNamesToLoad = significantSpriteNames.slice()
  if (!parameters.sourceLevel) {
    // If we have a source level, we'll just use its goals and related thangs.
    // If not, we will want to make sure the levels' goals have corresponding thangs, like gems for collect goals.
    terrainGenerationOptions.goals = level.goals
  }
  const terrainThangs = terrainGeneration.generateThangs(terrainGenerationOptions)
  spriteNamesToLoad = spriteNamesToLoad.concat(terrainThangs.map((t) => t.id))
  await loadThangTypes(spriteNamesToLoad)

  const resultThangs = []
  const resultThangsByNameCount = {}
  for (const terrainThang of terrainThangs) {
    const spriteName = terrainThang.id
    if (parameters.sourceLevel && significantSpriteNames.includes(spriteName)) {
      continue // Don't use any new randomly generated non-terrain thangs; we'll be using the ones already existing in the source level
    }
    const isHero = spriteName === 'Hero Placeholder'
    const numExistingThangsForSpriteName = resultThangsByNameCount[spriteName] || 0
    // Match existing level editor naming logic: Gem, Gem 1, Gem 2, etc.
    const thangID = numExistingThangsForSpriteName > 0 ? `${spriteName} ${numExistingThangsForSpriteName}` : spriteName
    const thangType = spriteNamesToThangTypes[spriteName]
    const components = createEssentialComponents(thangType.components, terrainThang.pos, isHero)
    const thang = { thangType: thangType.original, id: thangID, components }
    resultThangs.push(thang)
    resultThangsByNameCount[spriteName] = (resultThangsByNameCount[spriteName] || 0) + 1
  }

  if (parameters.sourceLevel) {
    for (const thang of parameters.sourceLevel.get('thangs')) {
      const spriteName = thangTypesToSpriteNames[thang.thangType]
      if (significantSpriteNames.includes(spriteName)) {
        resultThangs.push(_.cloneDeep(thang))
      }
    }
  }

  return resultThangs
})

// systems: c.array({title: 'Systems', description: 'Levels are configured by changing the Systems attached to them.', uniqueItems: true }, LevelSystemSchema),  // TODO: uniqueness should be based on 'original', not whole thing
generateProperty('systems', function (level, parameters) {
  const pathfindingAndLineOfSight = ['Dungeon', 'Indoor', 'Mountain', 'Glacier', 'Volcano', 'Junior'].includes(parameters.terrain)
  const systems = [
    // Copied from default systems list in SystemsTabView
    { original: '528112c00268d018e3000008', majorVersion: 0 }, // Event
    { original: '5280f83b8ae1581b66000001', majorVersion: 0, config: { randomSeed: 'zero' } }, // Existence
    { original: '5281146f0268d018e3000014', majorVersion: 0 }, // Programming
    { original: '528110f30268d018e3000001', majorVersion: 0, config: { findsPaths: pathfindingAndLineOfSight } }, // AI
    { original: '52810ffa33e01a6e86000012', majorVersion: 0 }, // Action
    { original: '528114b20268d018e3000017', majorVersion: 0 }, // Targeting
    { original: '528105f833e01a6e86000007', majorVersion: 0 }, // Collision
    { original: '528113240268d018e300000c', majorVersion: 0, config: { simpleMoveDistance: 8 } }, // Movement
    { original: '528112530268d018e3000007', majorVersion: 0 }, // Combat
    { original: '52810f4933e01a6e8600000c', majorVersion: 0 }, // Hearing
    { original: '528115040268d018e300001b', majorVersion: 0, config: { checksLineOfSight: pathfindingAndLineOfSight } }, // Vision
    { original: '5280dc4d251616c907000001', majorVersion: 0 }, // Inventory
    { original: '528111b30268d018e3000004', majorVersion: 0 }, // Alliance
    { original: '528114e60268d018e300001a', majorVersion: 0, config: { showCoordinates: false } }, // UI
    { original: '528114040268d018e3000011', majorVersion: 0 }, // Physics
    { original: '52ae4f02a4dcd4415200000b', majorVersion: 0 }, // Display
    { original: '52e953e81b2028d102000004', majorVersion: 0 }, // Effect
    { original: '52f1354370fb890000000005', majorVersion: 0 }, // Magic
    { original: '65b26a9e720a3caed74828bc', majorVersion: 0 }, // Junior
  ]
  return systems
})

// i18n: {type: 'object', format: 'i18n', props: ['name', 'description', 'loadingTip', 'studentPlayInstructions', 'displayName'], description: 'Help translate this level', inEditor: true},
generateProperty('i18n', function (level, parameters) {
  return {}
})

// // banner: {type: 'string', format: 'image-file', title: 'Banner', inEditor: 'codecombat'},
// generateProperty('banner', function (level, parameters) {
//   return undefined
// })

// type: c.shortString({title: 'Type', description: 'What type of level this is.', 'enum': ['campaign', 'ladder', 'ladder-tutorial', 'hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev', 'intro'], inEditor: true}),
generateProperty('type', function (level, parameters) {
  return 'hero'
})

// kind: c.shortString({title: 'Kind', description: 'Similar to type, but just for our organization.', enum: ['demo', 'usage', 'mastery', 'advanced', 'practice', 'challenge'], inEditor: 'codecombat'}),
generateProperty('kind', function (level, parameters) {
  return parameters.sourceLevel?.get('kind') || parameters.kind
})

// terrain: c.terrainString,
generateProperty('terrain', function (level, parameters) {
  return parameters.sourceLevel?.get('terrain') || parameters.terrain
})

// requiresSubscription: {title: 'Requires Subscription', description: 'Whether this level is available to subscribers only.', type: 'boolean', inEditor: 'codecombat'},
generateProperty('requiresSubscription', function (level, parameters) {
  return parameters.sourceLevel?.get('requiresSubscription') || false
})

// tasks: c.array({title: 'Tasks', description: 'Tasks to be completed for this level.'}, c.task),
generateProperty('tasks', function (level, parameters) {
  return []
})

// practice: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('practice', function (level, parameters) {
  return Boolean(parameters.sourceLevel)
})

// // assessment: { type: ['boolean', 'string'], enum: [true, false, 'open-ended', 'cumulative'], description: 'Set to true if this is an assessment level.', inEditor: true }, // ozaria has a few, needed?
// generateProperty('assessment', function (level, parameters) {
//   return false
// })

// // adventurer: { type: 'boolean', inEditor: 'codecombat' },
// generateProperty('adventurer', function (level, parameters) {
//   return false
// })

// // adminOnly: { type: 'boolean', inEditor: 'codecombat' },
// generateProperty('adminOnly', function (level, parameters) {
//   return false
// })

// releasePhase: { enum: ['beta', 'internalRelease', 'released'], title: 'Release status', description: "Release status of the level, determining who sees it.", default: 'internalRelease', inEditor: true },
generateProperty('releasePhase', function (level, parameters) {
  return 'released'
})

// // disableSpaces: { type: ['boolean','integer'], inEditor: 'codecombat' },
// generateProperty('disableSpaces', function (level, parameters) {
//   return false
// })

// hidesSubmitUntilRun: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('hidesSubmitUntilRun', function (level, parameters) {
  return false
})

// hidesPlayButton: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('hidesPlayButton', function (level, parameters) {
  return false
})

// hidesRunShortcut: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('hidesRunShortcut', function (level, parameters) {
  return true
})

// hidesHUD: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('hidesHUD', function (level, parameters) {
  return true
})

// hidesSay: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('hidesSay', function (level, parameters) {
  return false
})

// hidesCodeToolbar: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('hidesCodeToolbar', function (level, parameters) {
  return false
})

// hidesRealTimePlayback: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('hidesRealTimePlayback', function (level, parameters) {
  return true
})

// backspaceThrottle: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('backspaceThrottle', function (level, parameters) {
  return true
})

// // lockDefaultCode: { type: ['boolean','integer'], inEditor: 'codecombat' },
// generateProperty('lockDefaultCode', function (level, parameters) {
//   return false
// })

// // moveRightLoopSnippet: { type: 'boolean', inEditor: 'codecombat' },
// generateProperty('moveRightLoopSnippet', function (level, parameters) {
//   return false
// })

// realTimeSpeedFactor: { type: 'number', inEditor: 'codecombat' },
generateProperty('realTimeSpeedFactor', function (level, parameters) {
  return 3
})

// autocompleteFontSizePx: { type: 'number', inEditor: 'codecombat' },
generateProperty('autocompleteFontSizePx', function (level, parameters) {
  return 20
})

// // requiredCode: c.array({ inEditor: true }, {
// generateProperty('requiredCode', function (level, parameters) {
//   return []
// })

// // suspectCode: c.array({ inEditor: true }, {
// generateProperty('suspectCode', function (level, parameters) {
//   return []
// })

// // autocompleteReplacement: c.array({ inEditor: true }, {
// generateProperty('autocompleteReplacement', function (level, parameters) {
//   return []
// })

// // requiredGear: { type: 'object', title: 'Required Gear', description: 'Slots that should require one of a set array of items for that slot', inEditor: 'codecombat', additionalProperties: {
// generateProperty('requiredGear', function (level, parameters) {
//   return {}
// })

// // restrictedGear: { type: 'object', title: 'Restricted Gear', description: 'Slots that should restrict all of a set array of items for that slot', inEditor: 'codecombat', additionalProperties: {
// generateProperty('restrictedGear', function (level, parameters) {
//   return {}
// })

// // requiredProperties: { type: 'array', items: {type: 'string'}, description: 'Names of properties a hero must have equipped to play.', format: 'solution-gear', title: 'Required Properties', inEditor: 'codecombat' },
// generateProperty('requiredProperties', function (level, parameters) {
//   return []
// })

// // restrictedProperties: { type: 'array', items: {type: 'string'}, description: 'Names of properties a hero must not have equipped to play.', title: 'Restricted Properties', inEditor: 'codecombat' },
// generateProperty('restrictedProperties', function (level, parameters) {
//   return []
// })

// // clampedProperties: { type: 'object', title: 'Clamped Properties', description: 'Other non-health properties that should be clamped to a range of values (attackDamage, maxSpeed, etc.). Only applies for classroom players with classroom items enabled.', inEditor: 'codecombat', additionalProperties: {
// generateProperty('clampedProperties', function (level, parameters) {
//   return {}
// })

// // allowedHeroes: { type: 'array', title: 'Allowed Heroes', description: 'Which heroes can play this level. For any hero, leave unset.', inEditor: 'codecombat', items: {
// generateProperty('allowedHeroes', function (level, parameters) {
//   return undefined
// })

// scoreTypes: c.array({title: 'Score Types', description: 'What metric to show leaderboards for. Most important one first, not too many (2 is good).'}, {inEditor: 'codecombat'}, {
generateProperty('scoreTypes', function (level, parameters) {
  // ['time', 'damage-taken', 'damage-dealt', 'gold-collected', 'difficulty', 'code-length', 'survival-time', 'defeated']}
  if (parameters.sourceLevel) { return _.clone(parameters.sourceLevel.get('scoreTypes')) }
  const scoreTypes = []
  if (parameters.combat && _.find(level.goals, (goal) => goal.killThangs)) {
    scoreTypes.push('damage-dealt')
  }
  if (_.find(level.goals, (goal) => goal.killThangs || goal.getToLocations || goal.collectThangs)) {
    scoreTypes.push('time')
  }
  return scoreTypes
})

// concepts: c.array({title: 'Programming Concepts', description: 'Which programming concepts this level covers.', uniqueItems: true, format: 'concepts-list', inEditor: true}, c.concept),
generateProperty('concepts', function (level, parameters) {
  if (parameters.sourceLevel) { return _.clone(parameters.sourceLevel.get('concepts')) }
  return []
})

// primaryConcepts: c.array({title: 'Primary Concepts', description: 'The main 1-3 concepts this level focuses on.', uniqueItems: true, inEditor: true}, c.concept),
generateProperty('primaryConcepts', function (level, parameters) {
  if (parameters.sourceLevel) { return _.clone(parameters.sourceLevel.get('primaryConcepts')) }
  return []
})

// codePoints: c.int({title: 'CodePoints', minimum: 0, description: 'CodePoints that can be earned for completing this level'}),
generateProperty('codePoints', function (level, parameters) {
  return 0
})

// // difficulty: { type: 'integer', title: 'Difficulty', description: 'Difficulty of this level - used to show difficulty in star-rating of 1 to 5', minimum: 1, maximum: 5, inEditor: 'codecombat' }
// generateProperty('difficulty', function (level, parameters) {
//   return parameters.sourceLevel?.get('difficulty') || parameters.difficulty
// })

generateProperty('permissions', function (level, parameters) {
  return [{ access: 'owner', target: '512ef4805a67a8c507000001' }] // Nick's id
})

generateProperty('product', function (level, parameters) {
  return 'codecombat-junior'
})

// ---- Refining Outputs ----

generateProperty(null, function (level, parameters) {
  // Configure hero's position and a couple other things
  const hero = _.find(level.thangs, (thang) => thang.id === 'Hero Placeholder')
  const sourceLevel = parameters.sourceLevel
  let heroSource
  if (sourceLevel) {
    heroSource = _.find(sourceLevel.get('thangs'), (thang) => thang.id === 'Hero Placeholder')
  }

  const juniorPlayer = _.find(hero.components, (component) => component.original === defaultHeroComponentIDs.JuniorPlayer)
  juniorPlayer.config = {
    programmableSnippets: [],
    requiredThangTypes: ['5467beaf69d1ba0000fb91fb']
  }

  const physical = _.find(hero.components, (component) => component.original === PhysicalID)
  if (parameters.sourceLevel) {
    physical.config = _.cloneDeep(_.find(heroSource.components, (component) => component.original === PhysicalID).config)
  } else {
    physical.config = {
      pos: { x: 6, y: 14, z: 0.5 }
    }
  }

  const heroSurvives = _.find(level.goals, { id: 'hero-survives' })
  if (heroSurvives && !heroSurvives.hiddenGoal) {
    // Show health bar if we might be attacked, by adding Selectable component
    const selectable = { original: SelectableID, majorVersion: 0 }
    hero.components.push(selectable)
  }
})

generateProperty(null, function (level, parameters) {
  // Configure hero's APIs and starter/solution code
  // Also permute the level's layout based on source level, if given
  const sourceLevel = parameters.sourceLevel
  let heroSource, programmableSource
  if (sourceLevel) {
    heroSource = _.find(sourceLevel.get('thangs'), (thang) => thang.id === 'Hero Placeholder')
    programmableSource = _.find(heroSource.components, (component) => component.original === defaultHeroComponentIDs.Programmable)
  }

  // Come up with starter and solution code
  let apis = []
  if (sourceLevel) {
    apis = programmableSource.config.programmableProperties
  } else {
    apis.push('go')
    if (_.find(level.goals, (goal) => goal.killThangs)) {
      apis.push('hit')
    }
    if (Math.random() > parameters.skillForLoops && parameters.difficulty > 2) {
      apis.push('for-loop')
    }
  }

  // Find existing movement pattern
  // From the beginning, permute it:
  // - Manhattan distance of hero from start should be the same at each step
  // - Manhattan distance of something a hero hits/zaps should be the same at each step
  // - When a hit is performed, find the Thang that would have been hit, and put it there
  // - Same for Thangs affected by a zap or spin
  // - If there is a TNT, find the Thangs around it and put them same Manhattan distance from TNT and also from hero
  // - Put gems and rafts same number of movements along hero's path
  // Check to make sure all interactive Thangs are placed
  // Swap floor into wall every empty square that the hero doesn't walk or zap through
  // Each iterative solution, from starter code to penultimate line of solution code, should fail
  // Solution code should succeed
  // Source level's solution code should fail

  let solutionCode, starterCode
  if (sourceLevel) {
    const solutionCodeSource = _.find(programmableSource.config.programmableMethods.plan.solutions, (solution) => solution.succeeds).source
    const starterCodeSource = programmableSource.config.programmableMethods.plan.source
    const actions = parseActions(solutionCodeSource)
    let tries = 0
    let actionsNew, thangsNew, valid, offset, size, visitedPositions
    do {
      valid = true
      const checkDistanceTraveled = tries < 50 // If it's not working, we can relax this constraint
      ;({ actions: actionsNew, thangs: thangsNew, visitedPositions } = permuteActions({ actions, thangs: level.thangs, checkDistanceTraveled }))
      solutionCode = compileActions(actionsNew)
      const numStarterCodeLines = starterCodeSource.length > 0 ? starterCodeSource.trim().split('\n').length : 0
      starterCode = solutionCode.split('\n').slice(0, numStarterCodeLines).join('\n')
      if (solutionCode.trim() === solutionCodeSource.trim()) {
        valid = false
        console.log('Repeating because code was same')
        console.log(solutionCodeSource)
        console.log(solutionCode)
      }
      if (valid && layoutsAreEquivalent(level.thangs, thangsNew)) {
        valid = false
        console.log('Repeating because layout was same', level.thangs, thangsNew, tries)
      }
      if (valid) {
        ({ offset, size } = shiftLayout({ thangs: thangsNew, visitedPositions }))
        if (size.cols > 9 || size.rows > 8) {
          valid = false
          console.log(`Level would be too big at ${size.cols}x${size.rows}`)
        }
      }
      // TODO: check to see if this matches any other previously generated practice levels
      // TODO: load up the verifier and do all our checks
      ++tries
    } while (!valid && tries < 100)
    if (!valid) {
      console.log('Could not find valid permutation', { actionsNew, thangsNew, solutionCode, starterCode, solutionCodeSource, starterCodeSource })
    } else {
      console.log('Generated new level', { actionsNew, thangsNew, solutionCode, starterCode, solutionCodeSource, starterCodeSource })
      console.log(solutionCodeSource)
      console.log(solutionCode)
      level.thangs = thangsNew
      adjustTerrain({ offset, size, level, visitedPositions })
    }
  } else {
    ({ solutionCode, starterCode } = generateRandomCodeForApis(apis))
  }

  const hero = _.find(level.thangs, (thang) => thang.id === 'Hero Placeholder')
  const programmable = _.find(hero.components, (component) => component.original === defaultHeroComponentIDs.Programmable)

  programmable.config = {
    programmableMethods: {
      plan: {
        name: 'plan',
        source: starterCode,
        languages: {},
        solutions: [
          {
            source: solutionCode,
            language: 'javascript',
            succeeds: true,
            // goals: ...
          },
          {
            source: starterCode,
            language: 'javascript',
            succeeds: false,
            // goals: ...
          },
        ]
      }
    },
    programmableProperties: apis,
  }
})

function generateRandomCodeForApis (apis) {
  let indent = 0
  const solutionCodeLines = []
  while (solutionCodeLines.length < 3 + Math.random() * 10) {
    const api = _.sample(apis)
    let prefix = ''
    for (let i = 0; i < indent * 4; ++i) {
      prefix += ' '
    }
    if (api === 'for-loop') {
      solutionCodeLines.push(prefix + `for (let i = 0; i < ${Math.ceil(Math.random() * 5)}; ++i {`)
      ++indent
    } else if (api === 'go') {
      solutionCodeLines.push(prefix + `${api}('${_.sample(directionNames)}', ${Math.ceil(Math.random() * 4)})`)
    } else if (['hit', 'zap'].includes(api)) {
      solutionCodeLines.push(prefix + `${api}('${_.sample(directionNames)}')`)
    } else if (['spin'].includes(api)) {
      solutionCodeLines.push(prefix + `${api}()`)
    // } else if (['look'].includes(api)) {
    //   solutionCodeLines.push(prefix + `${api}()`)
    } else {
      solutionCodeLines.push(prefix + `${api}()`)
    }
  }
  while (indent > 0) {
    let prefix = ''
    for (let i = 0; i < indent * 4; ++i) {
      prefix += ' '
    }
    solutionCodeLines.push(prefix + '}')
    --indent
  }
  const solutionCode = solutionCodeLines.join('\n')
  const starterCode = solutionCodeLines.slice(0, 1 + Math.floor(Math.random() * 3)).join('\n')
  return { solutionCode, starterCode }
}

function simplifyPos (pos) {
  // Go from { x: 6, y: 6 } as middle of lower left square to { x: 0, y: 0 }
  return new Vector((pos.x - 6) / 8, (pos.y - 6) / 8)
}

function complexifyPos (pos) {
  // Go from { x: 0, y: 0 } as middle of lower left square to { x: 6, y: 6 }
  return new Vector(pos.x * 8 + 6, pos.y * 8 + 6)
}

function manhattanDistance (a, b) {
  return Math.abs(a.x - b.x) + Math.abs(a.y - b.y)
}

function parseActions (code) {
  // TODO: handle wrapper, like while-loop or if-statement
  const actions = code.trim().split('\n').map(codeToAction)
  return actions
}

function compileActions (actions) {
  // TODO: handle wrapper, like while-loop or if-statement
  const code = actions.map(actionToCode).join('\n')
  return code
}

function codeToAction (line) {
  const type = line.trim().split('(')[0]
  const directionStr = line.match(/'(up|down|left|right)'/)?.[1]
  const direction = directionStr ? new Direction(directionStr) : undefined
  const distanceStr = line.match(/(\d+)/)?.[1]
  const distance = distanceStr ? parseInt(distanceStr, 10) : undefined
  return new Action({ type, direction, distance })
}

function actionToCode (action) {
  let line
  if (action.type === 'go' && action.distance) {
    line = `${action.type}('${action.direction.name}', ${action.distance})`
  } else if (action.type === 'go') {
    line = `${action.type}('${action.direction.name}')`
  } else if (action.type === 'look') {
    // TODO: returns value
    line = `${action.type}('${action.direction.name}', ${action.distance})`
  } else if (action.type === 'hit') {
    line = `${action.type}('${action.direction.name}')`
  } else if (action.type === 'zap') {
    line = `${action.type}('${action.direction.name}')`
  } else if (action.type === 'spin') {
    line = `${action.type}()`
  }
  return line
}

const significantSpriteNames = ['Chicken Junior', 'Crab Monster Junior', 'Crates Junior', 'Cube Monster Junior', 'Explosive Junior', 'Dragonfly Junior', 'Gem Junior', 'Goal Junior']
const floorSpriteNames = ['Junior Beach Floor', 'Junior Wall']
function findThangAt (simplePos, thangs) {
  // Return what thang is at the given position, or a floor that's there, or undefined if nothing is there
  const complexPos = complexifyPos(simplePos)
  let floorThang, foundThang
  for (const thang of thangs) {
    const spriteName = thangTypesToSpriteNames[thang.thangType]
    const isFloor = floorSpriteNames.includes(spriteName)
    if (significantSpriteNames.includes(spriteName) || isFloor) {
      const physicalComponent = _.find(thang.components || [], { original: PhysicalID })
      if (physicalComponent && physicalComponent.config && physicalComponent.config.pos.x === complexPos.x && physicalComponent.config.pos.y === complexPos.y) {
        if (isFloor) {
          floorThang = thang
        } else {
          foundThang = thang
        }
      }
    }
  }
  return foundThang || floorThang
}

function moveThang ({ at, to, thangsSrc, thangsNew }) {
  const targetThangSrc = findThangAt(at, thangsSrc)
  if (!targetThangSrc || floorSpriteNames.includes(thangTypesToSpriteNames[targetThangSrc.thangType])) return
  const targetThangNew = _.find(thangsNew, { id: targetThangSrc.id })
  const targetThangNewPhysical = _.find(targetThangNew.components, (component) => component.original === PhysicalID)
  const toComplex = complexifyPos(to)
  targetThangNewPhysical.config.pos.x = toComplex.x
  targetThangNewPhysical.config.pos.y = toComplex.y
}

const directionNames = ['up', 'down', 'left', 'right']

class Direction {
  constructor (name) {
    this.name = name // 'up', 'down', 'left', 'right'
    if (this.name === 'up') {
      this.vector = new Vector(0, 1)
    } else if (this.name === 'down') {
      this.vector = new Vector(0, -1)
    } else if (this.name === 'left') {
      this.vector = new Vector(-1, 0)
    } else if (this.name === 'right') {
      this.vector = new Vector(1, 0)
    } else {
      return new Direction(_.sample(directionNames))
    }
  }

  is (direction) {
    return this.name === direction.name
  }

  isOpposite (direction) {
    return this.vector.x === direction.vector.x * -1 && this.vector.y === direction.vector.y * -1
  }

  isOrthogonal (direction) {
    return Math.abs(this.vector.x - direction.vector.x) === 1 && Math.abs(this.vector.y - direction.vector.y) === 1
  }

  getRelationship (direction) {
    if (!direction) return undefined
    if (this.is(direction)) return 'forward'
    if (this.isOpposite(direction)) return 'backward'
    if (this.isOrthogonal(direction)) return 'turn'
  }
}

class Action {
  constructor ({ type, direction, distance }) {
    this.type = type // 'move', 'hit', 'zap', 'spin', 'look'
    this.direction = direction // A Direction like 'up', 'down', 'left', 'right', or undefined for spin
    this.distance = distance
  }

  clone () {
    return new Action({ type: this.type, direction: this.direction, distance: this.distance })
  }
}

// Change actions while maintaining some invariances:;
// - Manhattan distance of hero from start to current should always be same after each move
// - Should turn when hero turns, go forward when it goes forward, goes backwards when it goes backwards
// - Should follow similar patterns for hit and zap
function permuteActions ({ actions, thangs, checkDistanceTraveled }) {
  const hero = _.find(thangs, { id: 'Hero Placeholder' })
  const heroPhysical = _.find(hero.components, (component) => component.original === PhysicalID)
  const startPos = simplifyPos(heroPhysical.config.pos)
  const currentPosSrc = startPos.copy()
  const currentPosNew = startPos.copy()
  let lastDirectionsPerActionSrc = {}
  let lastDirectionsPerActionNew = {}
  const actionsSrc = actions
  const actionsNew = []
  const thangsSrc = thangs
  const thangsNew = _.cloneDeep(thangs)
  const visitedPositions = [startPos.copy()]
  for (const actionSrc of actionsSrc) {
    const actionNew = actionSrc.clone()
    const lastDirectionSrc = lastDirectionsPerActionSrc[actionSrc.type]
    const lastDirectionNew = lastDirectionsPerActionNew[actionNew.type]
    const currentDirectionRelationshipSrc = lastDirectionSrc ? actionSrc.direction.getRelationship(lastDirectionSrc) : undefined
    if (actionSrc.type === 'go') {
      const targetCurrentPosSrc = currentPosSrc.copy().add(actionSrc.direction.vector.copy().multiply(actionSrc.distance || 1))
      const targetDistanceFromStart = manhattanDistance(startPos, targetCurrentPosSrc)
      let targetCurrentPosNew, valid
      let tries = 0
      do {
        valid = true
        actionNew.direction = new Direction()
        const currentDirectionRelationshipNew = lastDirectionNew ? actionNew.direction.getRelationship(lastDirectionNew) : undefined
        // console.log(' Checking', { lastDirectionSrc, lastDirectionNew, currentDirectionRelationshipSrc, currentDirectionRelationshipNew })
        if (currentDirectionRelationshipNew !== currentDirectionRelationshipSrc) {
          // console.log('  ', 'Not valid because relationship is different', { lastDirectionSrc, lastDirectionNew, currentDirectionRelationshipSrc, currentDirectionRelationshipNew })
          valid = false // Don't move in a different sort of way than we previously did
        }
        targetCurrentPosNew = currentPosNew.copy().add(actionNew.direction.vector.copy().multiply(actionNew.distance || 1))
        // if (checkDistanceTraveled) {
        //   console.log(' Checking', { targetDistanceFromStart, newDistance: manhattanDistance(startPos, targetCurrentPosNew), startPos, targetCurrentPosNew, currentPosSrc, actionSrc, actionNew: _.cloneDeep(actionNew) })
        // }
        if (valid && checkDistanceTraveled && manhattanDistance(startPos, targetCurrentPosNew) !== targetDistanceFromStart) {
          // console.log('  ', 'Not valid because distance from start is different', { targetDistanceFromStart, newDistance: manhattanDistance(startPos, targetCurrentPosNew), startPos, targetCurrentPosNew, currentPosSrc, actionSrc, actionNew: _.cloneDeep(actionNew) })
          valid = false // Don't end up moving a different distance from the start position
        }
        ++tries
      } while (!valid && tries < 100)
      if (!valid) {
        console.log('Could not find valid permutation', { actionSrc, actionNew, lastDirectionSrc, lastDirectionNew, currentDirectionRelationshipSrc })
      }
      for (let distance = 1; distance <= (actionNew.distance || 1); ++distance) {
        // Put any gems or rafts we crossed in the right places
        currentPosSrc.add(actionSrc.direction.vector)
        currentPosNew.add(actionNew.direction.vector)
        const thang = findThangAt(currentPosSrc, thangsSrc)
        const spriteName = thangTypesToSpriteNames[thang?.thangType]
        if (['Gem Junior', 'Goal Junior'].includes(spriteName)) {
          // console.log('Moving', thang.id, spriteName, 'from', currentPosSrc, complexifyPos(currentPosSrc), 'to', currentPosNew, complexifyPos(currentPosNew))
          moveThang({ at: currentPosSrc, to: currentPosNew, thangsSrc, thangsNew })
        } else {
          // console.log('Got', spriteName, thang, 'at', currentPosSrc)
        }
        visitedPositions.push(currentPosNew.copy())
      }
      // console.log('Old action direction was', actionSrc.direction, 'and new one is', actionNew.direction)
    } else if (actionSrc.type === 'spin') {
      // Spin has no config, will always be the same
      // Find the targets that it would hit and put them in the right places
      for (const directionName of directionNames) {
        const targetPosSrc = currentPosSrc.copy().add(new Direction(directionName).vector)
        const targetPosNew = currentPosNew.copy().add(new Direction(directionName).vector)
        moveThang({ at: targetPosSrc, to: targetPosNew, thangsSrc, thangsNew })
      }
    } else if (actionSrc.type === 'hit') {
      const targetPosSrc = currentPosSrc.copy().add(actionSrc.direction.vector)
      const targetDistanceFromStart = manhattanDistance(startPos, targetPosSrc)
      let targetPosNew, valid
      let tries = 0
      do {
        valid = true
        actionNew.direction = new Direction()
        const currentDirectionRelationshipNew = lastDirectionNew ? actionNew.direction.getRelationship(lastDirectionNew) : undefined
        if (currentDirectionRelationshipNew !== currentDirectionRelationshipSrc) {
          valid = false // Don't hit in a different sort of way than we previously did
        }
        targetPosNew = currentPosNew.copy().add(actionNew.direction.vector)
        if (valid && checkDistanceTraveled && manhattanDistance(startPos, targetPosNew) !== targetDistanceFromStart) {
          valid = false // Don't end up hitting a target at a different distance from the start position
        }
        ++tries
      } while (!valid && tries < 100)
      if (!valid) {
        console.log('Could not find valid permutation', { actionSrc, actionNew, lastDirectionSrc, lastDirectionNew, currentDirectionRelationshipSrc })
      }

      // Find the target that it would hit and put it in the right place
      moveThang({ at: targetPosSrc, to: targetPosNew, thangsSrc, thangsNew })
    } else if (actionSrc.type === 'zap') {
      const targetPosSrc = currentPosSrc.copy().add(actionSrc.direction.vector)
      const targetDistanceFromStart = manhattanDistance(startPos, targetPosSrc)
      let targetPosNew, valid
      let tries = 0
      do {
        valid = true
        actionNew.direction = new Direction()
        const currentDirectionRelationshipNew = lastDirectionNew ? actionNew.direction.getRelationship(lastDirectionNew) : undefined
        if (currentDirectionRelationshipNew !== currentDirectionRelationshipSrc) {
          valid = false // Don't zap in a different sort of way than we previously did
        }
        targetPosNew = currentPosNew.copy().add(actionNew.direction.vector)
        if (valid && checkDistanceTraveled && manhattanDistance(startPos, targetPosNew) !== targetDistanceFromStart) {
          valid = false // Don't end up zapping a target at a different distance from the start position
        }
        ++tries
      } while (!valid && tries < 100)
      if (!valid) {
        console.log('Could not find valid permutation', { actionSrc, actionNew, lastDirectionSrc, lastDirectionNew, currentDirectionRelationshipSrc })
      }

      // Find the targets that it would hit and put them in the right places
      for (let distance = 1; distance < 9; ++distance) {
        const zapTargetPos = currentPosSrc.copy().add(actionSrc.direction.vector.copy().multiply(distance))
        const newZapTargetPos = currentPosNew.copy().add(actionNew.direction.vector.copy().multiply(distance))
        const zappableThang = findThangAt(zapTargetPos, thangsSrc)
        if (zappableThang && floorSpriteNames.includes(thangTypesToSpriteNames[zappableThang.thangType])) {
          moveThang({ at: zapTargetPos, to: newZapTargetPos, thangsSrc, thangsNew })
          // Move all the Thangs in this line, in case some would be killed out of the way in between start of level and when the zap would happen.
          // This could result in slightly wrong behavior, because perhaps we are counting on the zap only hitting the first one?
          // We randomly break or not here, so that we can test it both ways and eventually get a valid layout in either scenario.
          if (Math.random() < 0.5) {
            break
          }
        }
      }
    } else if (actionSrc.type === 'look') {
      // TODO: update lots of things for look to work, when look is fully implemented with levels that use it
      // TODO: probably add positions in between currentPosNew and any targets to visitedPositions
    }

    if (actionSrc.type === 'go') {
      // Reset the other actions' directions. TODO: is this right?
      lastDirectionsPerActionSrc = { go: actionSrc.direction }
      lastDirectionsPerActionNew = { go: actionNew.direction }
      // console.log('Setting lastDirectionsPerAction to source', _.cloneDeep(lastDirectionsPerActionSrc), 'and new', _.cloneDeep(lastDirectionsPerActionNew))
    } else {
      lastDirectionsPerActionSrc[actionSrc.type] = actionSrc.direction
      lastDirectionsPerActionSrc[actionNew.type] = actionNew.direction
      // console.log('Setting lastDirection for', actionSrc.type, 'to source', _.cloneDeep(actionSrc.direction), 'and new', _.cloneDeep(actionNew.direction))
    }

    actionsNew.push(actionNew)
  }

  return { actions: actionsNew, thangs: thangsNew, visitedPositions }
}

function layoutsAreEquivalent (thangsA, thangsB) {
  for (let col = 0; col < 9; ++col) {
    for (let row = 0; row < 8; ++row) {
      const pos = { x: col, y: row }
      let thangA = findThangAt(pos, thangsA)
      let thangB = findThangAt(pos, thangsB)
      if (thangA && floorSpriteNames.includes(thangTypesToSpriteNames[thangA.thangType])) {
        thangA = null
      }
      if (thangB && floorSpriteNames.includes(thangTypesToSpriteNames[thangB.thangType])) {
        thangB = null
      }
      if (!thangA && !thangB) {
        continue
      }
      if (!thangA || !thangB) {
        return false
      }
      if (thangA.thangType !== thangB.thangType) {
        return false
      }
    }
  }
  return true
}

function shiftLayout ({ thangs, visitedPositions }) {
  // Keep track of the min/max position of all significant Thangs plus places the hero visits
  // Once we know the needed bounds and offset of the level, we can shift everything to start from row 0, col 0
  // We maintain standard level viewport aspect ratio, so we may center the level along the major axis
  let [minCol, minRow, maxCol, maxRow] = [9001, 9001, -9001, -9001]

  for (const pos of visitedPositions) {
    minCol = Math.min(minCol, pos.x)
    minRow = Math.min(minRow, pos.y)
    maxCol = Math.max(maxCol, pos.x)
    maxRow = Math.max(maxRow, pos.y)
  }

  for (const thang of thangs) {
    const spriteName = thangTypesToSpriteNames[thang.thangType]
    if (!significantSpriteNames.concat(['Hero Placeholder']).includes(spriteName)) {
      continue
    }
    const complexPos = _.find(thang.components, (component) => component.original === PhysicalID).config.pos
    const simplePos = simplifyPos(complexPos)
    minCol = Math.min(minCol, simplePos.x)
    minRow = Math.min(minRow, simplePos.y)
    maxCol = Math.max(maxCol, simplePos.x)
    maxRow = Math.max(maxRow, simplePos.y)
  }

  const size = { cols: maxCol - minCol + 1, rows: maxRow - minRow + 1 }
  size.cols = Math.max(size.cols, 3)
  size.rows = Math.max(size.rows, 2)

  const targetAspectRatio = 20 / 17
  const currentAspectRatio = size.cols / size.rows

  let offsetX = 0
  let offsetY = 0

  if (currentAspectRatio > targetAspectRatio) {
    // Width is the major dimension, adjust height
    const targetRows = Math.round(size.cols / targetAspectRatio)
    offsetY = Math.floor((targetRows - size.rows) / 2)
    size.rows = targetRows
  } else {
    // Height is the major dimension, adjust width
    const targetCols = Math.round(size.rows * targetAspectRatio)
    offsetX = Math.floor((targetCols - size.cols) / 2)
    size.cols = targetCols
  }

  const offset = { x: -minCol + offsetX, y: -minRow + offsetY }

  for (const thang of thangs) {
    const spriteName = thangTypesToSpriteNames[thang.thangType]
    if (!significantSpriteNames.concat(['Hero Placeholder']).includes(spriteName)) {
      continue
    }
    const physicalConfig = _.find(thang.components, (component) => component.original === PhysicalID).config
    physicalConfig.pos.x += 8 * offset.x
    physicalConfig.pos.y += 8 * offset.y
  }

  // console.log('Shifted everything by', offset, 'with size', size)
  return { offset, size }
}

function adjustTerrain ({ offset, size, level, visitedPositions }) {
  // Turn every unused square to water (Junior Wall)
  // Cut off unnecessary squares on top & right
  // Adjust camera to match the new size
  // console.log('Need to adjust terrain', offset, size, level, visitedPositions)
  const visitedPositionsOffset = {}
  for (const pos of visitedPositions) {
    const offsetPos = pos.copy().add(offset)
    visitedPositionsOffset[offsetPos.x] = visitedPositionsOffset[offsetPos.x] || {}
    visitedPositionsOffset[offsetPos.x][offsetPos.y] = true
  }

  // Turn any unused floors (walkable beach sand) into walls (unwalkable ocean)
  // Include one row past the right/top as the natural border
  for (let col = 0; col <= size.cols; ++col) {
    for (let row = 0; row <= size.rows; ++row) {
      const pos = { x: col, y: row }
      let thang = findThangAt(pos, level.thangs)
      if (thang) {
        const spriteName = thangTypesToSpriteNames[thang.thangType]
        if (spriteName === 'Goal Junior') {
          const floor = findThangAt(pos, _.without(level.thangs, thang))
          thang = floor // Turn the floor under the raft into a wall (since raft goes on the ocean)
          // TODO: turn the raft facing the ocean
        } else if (visitedPositionsOffset[col]?.[row]) {
          continue
        } else if (significantSpriteNames.concat(['Hero Placeholder']).includes(spriteName)) {
          continue
        }
        // We have a floor here and we never use it, so turn it into a wall
        thang.thangType = spriteNamesToThangTypes['Junior Wall'].original
        thang.id = thang.id.replace(/Floor/, 'Wall')
        const physicalConfig = _.find(thang.components, (component) => component.original === PhysicalID).config
        physicalConfig.pos.z = 0.5
      }
    }
  }

  // Cut off unnecessary squares on top & right
  for (let col = -1; col <= 9; ++col) {
    for (let row = -1; row <= 8; ++row) {
      if (col <= size.cols && row <= size.rows) { continue }
      const pos = { x: col, y: row }
      const thang = findThangAt(pos, level.thangs)
      _.pull(level.thangs, thang)
    }
  }

  // Adjust camera to match the new size
  const bounds = level.scripts[0].noteChain[0].surface.focus.bounds
  const largest = size.cols > size.rows * 20 / 17 ? size.cols : size.rows
  if (largest === size.cols) {
    bounds[1].x = 4 + 8 * largest + 4
    bounds[1].y = (4 + 8 * largest + 4) * 17 / 20
  } else {
    bounds[1].x = (4 + 8 * largest + 4) * 20 / 17
    bounds[1].y = 4 + 8 * largest + 4
  }
}
