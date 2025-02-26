const _ = require('lodash')
const schemas = require('../schemas/schemas')
const levelSchema = require('../schemas/models/level')
const terrainGeneration = require('./terrain-generation')
const Vector = require('./world/vector')
const VerifierTest = require('views/editor/verifier/VerifierTest')
const SuperModel = require('models/SuperModel')

module.exports = {
  generateLevel,
}

async function generateLevel ({ parameters, supermodel }) {
  parameters.terrain = parameters.terrain || 'Junior'
  if (parameters.sourceLevel) {
    parameters.size = juniorSizes[juniorSizes.length - 1]
  }
  parameters = fillRandomParameters(parameters)
  parameters.supermodel = supermodel

  const level = {
    parameters,
    parametersKey: generateKeyForParameters(parameters),
  }

  for (const generationFunction of generationFunctions) {
    await generationFunction(level, parameters)
  }

  if (level.invalid) {
    return null
  }

  return level
}

// ---- Input Parameters ----

const maxCols = 18
const maxRows = 16
const juniorSizes = ['junior3x2', 'junior4x3', 'junior5x4', 'junior6x5', 'junior7x6', 'junior8x7', 'junior9x7', 'junior9x8', `junior${maxCols}x${maxRows}`]
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
      const enumLength = key === 'size' ? value.enum.length - 1 : value.enum.length
      parameters[key] = value.enum[Math.floor(Math.random() * enumLength)]
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
  const sourceName = parameters.sourceLevel.get('name')
  const newLetter = String.fromCharCode('A'.charCodeAt(0) + parameters.levelIndex || 0)
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
      linesOfCode: { humans: 6 },
      id: 'short-code',
      name: 'Only 6 lines of code'
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
const ScalesID = '52a399b98537a70000000003' // LevelComponent.ScalesID

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
  Attackable: { maxHealth: 4 },
  JuniorPlayer: {
    programmableSnippets: [],
    requiredThangTypes: ['66873b397eff730c9e750994', '62050186cb069a0023866b0d'],
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
  if (parameters.sourceLevel) {
    return _.cloneDeep(parameters.sourceLevel.get('systems'))
  }
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

generateProperty('classroomSub', function (level, parameters) {
  return parameters.sourceLevel?.get('classroomSub') || undefined
})

// tasks: c.array({title: 'Tasks', description: 'Tasks to be completed for this level.'}, c.task),
generateProperty('tasks', function (level, parameters) {
  return []
})

// practice: { type: 'boolean', inEditor: 'codecombat' },
generateProperty('practice', function (level, parameters) {
  return Boolean(parameters.sourceLevel)
})

// practiceThresholdMinutes: { type: 'number', description: 'Players with larger playtimes may be directed to a practice level.', inEditor: 'codecombat' },
generateProperty('practiceThresholdMinutes', function (level, parameters) {
  let sourceP50 = parameters.levelStats?.playtime?.p50
  if (!sourceP50 && parameters.sourceLevel) {
    // Experimental data very roughly suggests 10s + 5s/line p50 completion time. We can come up with a better fit if important.
    const hero = _.find(parameters.sourceLevel.get('thangs') || level.thangs, { id: 'Hero Placeholder' })
    const programmableConfig = _.find(hero.components, { original: defaultHeroComponentIDs.Programmable }).config
    const solutionLines = _.find(programmableConfig.programmableMethods.plan.solutions, { succeeds: true }).source.trim().split('\n').length
    const startLines = programmableConfig.programmableMethods.plan.source.trim().split('\n').length
    sourceP50 = 10 + 5 * (solutionLines - startLines)
  }
  if (!sourceP50) {
    sourceP50 = 2 * 60 // Randomly assume 2 minutes per level for new levels with no data
  }
  const levelIndex = parameters.levelIndex || 0
  // Increase by 10% + 10s with each level, so that slow players eventually move on
  // console.log('Setting practice threshold to', Math.round(Math.max(60, sourceP50 * (1 + 0.1 * levelIndex) + 10 * levelIndex)) + 's for level index', levelIndex, 'with source level p50', sourceP50)
  return Math.round(Math.max(60, sourceP50 * (1 + 0.1 * levelIndex) + 10 * levelIndex)) / 60
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
  return [
    { access: 'owner', target: '512ef4805a67a8c507000001' }, // Nick's id
    { access: 'read', target: 'public' },
  ]
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
  if (sourceLevel) {
    juniorPlayer.config = _.find(heroSource.components, (component) => component.original === defaultHeroComponentIDs.JuniorPlayer).config
  } else {
    juniorPlayer.config = {
      programmableSnippets: ['for-loop', 'if', '==', 'while-loop', '<', '>', 'variable'],
      requiredThangTypes: ['66873b397eff730c9e750994', '62050186cb069a0023866b0d'],
    }
  }

  const physical = _.find(hero.components, (component) => component.original === PhysicalID)
  if (sourceLevel) {
    physical.config = _.cloneDeep(_.find(heroSource.components, (component) => component.original === PhysicalID).config)
  } else {
    physical.config = { pos: { x: 6, y: 14, z: 0.5 } }
  }

  const heroSurvives = _.find(level.goals, { id: 'hero-survives' })
  if (heroSurvives && !heroSurvives.hiddenGoal) {
    // Show health bar if we might be attacked, by adding Selectable component
    const selectable = { original: SelectableID, majorVersion: 0 }
    hero.components.push(selectable)
  }
})

const permutationTriesPerMove = 150
const permutationTriesOverall = 500

generateProperty(null, async function (level, parameters) {
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
    apis = ['go', 'hit', 'spin', 'zap', 'look', 'heal', 'health', 'dist']
  }

  let solutionCode, starterCode
  if (!sourceLevel) {
    ({ solutionCode, starterCode } = generateRandomCodeForApis(apis))
    updateProgrammableConfig({ thangs: level.thangs, solutionCode, starterCode, apis })
    return
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

  const solutionCodeSource = _.find(programmableSource.config.programmableMethods.plan.solutions, (solution) => solution.succeeds).source
  const starterCodeSource = programmableSource.config.programmableMethods.plan.source
  const actions = parseActions(solutionCodeSource)
  let tries = 0
  let actionsNew, thangsNew, valid, offset, size, visitedPositions
  do {
    valid = true
    const checkDistanceTraveled = tries < 0.4 * permutationTriesOverall // If it's not working, we can relax this constraint
    const checkZapTurns = tries < 0.5 * permutationTriesOverall // If it's not working, we can relax this constraint
    const checkHitTurns = tries < 0.6 * permutationTriesOverall // If it's not working, we can relax this constraint
    ;({ actions: actionsNew, thangs: thangsNew, visitedPositions } = permuteActions({ actions, thangs: level.thangs, checkDistanceTraveled, checkZapTurns, checkHitTurns }))
    solutionCode = compileActions(actionsNew)
    const starterCodeLinesSrc = starterCodeSource.trim().split('\n')
    const numStarterCodeLines = starterCodeSource.length > 0 ? starterCodeLinesSrc.length : 0
    const starterCodeLinesNew = solutionCode.split('\n').slice(0, numStarterCodeLines)
    if (_.last(solutionCode.split('\n')) === '}' && numStarterCodeLines) {
      // Simple way to close loop. TODO: make this general to various loop closures, not just the most basic case.
      starterCodeLinesNew[starterCodeLinesNew.length - 1] = '}'
    }
    // Adjust any loop counts, in case the difference in starter code was in changing those. Also preserve empty loop lines.
    for (let lineIndex = 0; lineIndex < numStarterCodeLines; ++lineIndex) {
      const lineSrc = starterCodeLinesSrc[lineIndex]
      const lineNew = starterCodeLinesNew[lineIndex]
      if (/^for \(/.test(lineNew) || !lineSrc.trim()) {
        starterCodeLinesNew[lineIndex] = lineSrc
      }
    }
    starterCode = starterCodeLinesNew.join('\n')
    if (_.find(actionsNew, (a) => a.invalid)) {
      valid = false
      // console.log('Repeating because an action was invalid')
      // console.log(solutionCodeSource)
      // console.log(solutionCode)
    }
    if (valid && solutionCode.trim() === solutionCodeSource.trim()) {
      valid = false
      console.log('Repeating because code was same')
      console.log(solutionCodeSource)
      console.log(solutionCode)
    }
    if (valid && starterCode.trim() === solutionCode.trim()) {
      valid = false
      console.log('Repeating because starter code and solution code were the same')
      console.log(solutionCode)
    }
    if (valid) {
      for (const pos of visitedPositions) {
        // Not sure why floating point instability is getting in here, but fix it
        pos.x = Math.round(pos.x)
        pos.y = Math.round(pos.y)
      }
      repositionFriendsAndExplosives({ thangsSrc: level.thangs, thangsNew, visitedPositions })
      ;({ offset, size } = shiftLayout({ thangs: thangsNew, visitedPositions }))
      if (size.cols > maxCols || size.rows > maxRows) {
        valid = false
        console.log(`Level would be too big at ${size.cols}x${size.rows}`)
        // console.log(solutionCodeSource)
        // console.log(solutionCode)
      }
    }
    if (valid) {
      for (const otherLevel of (parameters.existingPracticeLevels || []).concat(parameters.newPracticeLevels || [])) {
        const otherThangs = otherLevel.thangs || otherLevel.get('thangs')
        const otherHero = _.find(otherThangs, { id: 'Hero Placeholder' })
        const otherProgrammable = _.find(otherHero.components, { original: defaultHeroComponentIDs.Programmable })
        const otherSolution = _.find(otherProgrammable.config.programmableMethods.plan.solutions, { succeeds: true })
        if (solutionCode.trim() === otherSolution.source.trim()) {
          valid = false
          console.log('Repeating because solution code was same as in', otherLevel.name || otherLevel.get('name'))
          console.log(solutionCode)
          break
        }
        if (valid && layoutsAreEquivalent(otherLevel.thangs || otherLevel.get('thangs'), thangsNew)) {
          valid = false
          console.log('Repeating because layout was same as in', otherLevel.name || otherLevel.get('name'))
          break
        }
      }
    }
    if (valid && layoutsAreEquivalent(level.thangs, thangsNew)) {
      valid = false
      console.log('Repeating because layout was same as source level')
    }
    if (valid) {
      const oldThangsOffset = _.cloneDeep(parameters.originalThangs) // May not be right because of visitedPositions, but will catch some cases
      shiftLayout({ thangs: oldThangsOffset, visitedPositions: [] })
      if (layoutsAreEquivalent(oldThangsOffset, thangsNew)) {
        valid = false
        console.log('Repeating because layout was same as source level after shifting')
      }
    }
    if (valid) {
      updateProgrammableConfig({ thangs: thangsNew, solutionCode, starterCode, apis })
      if (!(await verifyLevel({ sourceLevel, thangs: thangsNew, solutionCode, starterCode, supermodel: parameters.supermodel }))) {
        valid = false
        console.log('Repeating because level did not verify')
        console.log(solutionCodeSource)
        console.log(solutionCode)
      }
    }
    // TODO: check to see if this matches any other previously generated practice levels
    // TODO: load up the verifier and do all our checks
    ++tries
  } while (!valid && tries < permutationTriesOverall)
  if (!valid) {
    console.log('Could not find valid overall permutation', { actionsNew, thangsNew, solutionCode, starterCode, solutionCodeSource, starterCodeSource })
    level.invalid = true
  } else {
    console.log('Generated new level', { actionsNew, thangsNew, solutionCode, starterCode, solutionCodeSource, starterCodeSource })
    console.log(solutionCodeSource)
    console.log(solutionCode)
    level.thangs = thangsNew
    adjustTerrain({ offset, size, level, visitedPositions })
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

function updateProgrammableConfig ({ thangs, solutionCode, starterCode, apis }) {
  const hero = _.find(thangs, (thang) => thang.id === 'Hero Placeholder')
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
}

function simplifyPos (pos) {
  // Go from { x: 6, y: 6 } as middle of lower left square to { x: 0, y: 0 }
  // Round it in case some of the existing source level positions are slightly off
  return new Vector(Math.round((pos.x - 6) / 8), Math.round((pos.y - 6) / 8))
}

function complexifyPos (pos) {
  // Go from { x: 0, y: 0 } as middle of lower left square to { x: 6, y: 6 }
  return new Vector(Math.round(pos.x * 8 + 6), Math.round(pos.y * 8 + 6))
}

function manhattanDistance (a, b) {
  return Math.abs(a.x - b.x) + Math.abs(a.y - b.y)
}

function parseActions (code) {
  const actions = code.trim().split('\n').map(codeToAction)
  return actions
}

function compileActions (actions) {
  const lines = []
  let indent = ''
  for (const action of actions) {
    let line = actionToCode(action)
    if (action.type === '}') {
      indent = indent.replace(/ {4}$/, '')
    }
    line = indent + line
    if (action.type === 'for') {
      indent += '    '
    }
    lines.push(line)
  }
  return lines.join('\n')
}

function codeToAction (line) {
  const type = line.trim().split('(')[0].trim()
  const directionStr = line.match(/'(up|down|left|right)'/)?.[1]
  const direction = directionStr ? new Direction(directionStr) : undefined
  const distanceStr = line.match(/(\d+)/)?.[1]
  const distance = distanceStr ? parseInt(distanceStr, 10) : undefined
  const forLoop = line.match(/for \(let (.+?) = 0; .+? < (\d+); \+?\+?.+?\+?\+?\) {/)
  const loopVariable = forLoop?.[1]
  const loopCountStr = forLoop?.[2]
  const loopCount = loopCountStr ? parseInt(loopCountStr, 10) : undefined
  return new Action({ type, direction, distance, loopVariable, loopCount })
}

function actionToCode (action) {
  // This could be a method of Action class
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
  } else if (action.type === 'for') {
    line = `for (let ${action.loopVariable} = 0; ${action.loopVariable} < ${action.loopCount}; ++${action.loopVariable}) {`
  } else if (action.type === '}') {
    line = '}'
  }
  if (action.invalid) {
    line += ' // invalid'
  }
  return line
}

const significantSpriteNames = ['Chicken Junior', 'Crab Monster Junior', 'Crates Junior', 'Gelatinous Cube Junior', 'Explosive Junior', 'Dragonfly Monster Junior', 'Gem Junior', 'Goal Junior']
const hittableSpriteNames = _.without(significantSpriteNames, 'Gem Junior', 'Goal Junior') // Is chicken hittable or zappable?
const floorSpriteNames = ['Junior Beach Floor', 'Junior Wall']
function findThangAt (simplePos, thangs, relevantSpriteNames) {
  // Return what thang is at the given position, or a floor that's there, or undefined if nothing is there
  const complexPos = complexifyPos(simplePos)
  let floorThang, foundThang
  for (const thang of thangs) {
    const spriteName = thangTypesToSpriteNames[thang.thangType]
    const isFloor = floorSpriteNames.includes(spriteName)
    relevantSpriteNames = relevantSpriteNames || significantSpriteNames
    if (relevantSpriteNames.includes(spriteName) || isFloor) {
      const thangComplexPos = _.find(thang.components || [], { original: PhysicalID })?.config?.pos
      if (thangComplexPos && Math.abs(thangComplexPos.x - complexPos.x) < 0.1 && Math.abs(thangComplexPos.y - complexPos.y) < 0.1) {
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
  // Move a new thang we found at the given position in the source thangs list to the new position
  // If there's already something significant there, return false
  const targetThangSrc = findThangAt(at, thangsSrc)
  const spriteName = thangTypesToSpriteNames[targetThangSrc?.thangType]
  if (!targetThangSrc || floorSpriteNames.includes(spriteName)) {
    // console.log('There was nothing at', at)
    return false
  }
  const toComplex = complexifyPos(to)
  const targetThangNew = _.find(thangsNew, { id: targetThangSrc.id })
  const existingThangNew = findThangAt(to, thangsNew, significantSpriteNames.concat(['Hero Placeholder']))
  const existingSpriteName = thangTypesToSpriteNames[existingThangNew?.thangType]
  if (existingSpriteName && !floorSpriteNames.includes(existingSpriteName) && targetThangNew.id !== existingThangNew.id) {
    // console.log('Already had', existingThangNew, existingSpriteName, 'at', to, toComplex)
    return false
  }
  // console.log('Moving', spriteName, targetThangNew, existingThangNew, 'from', at, 'to', to, toComplex, 'where there was', existingThangNew, 'of', _.cloneDeep(thangsNew))
  const targetThangNewPhysical = _.find(targetThangNew.components, (component) => component.original === PhysicalID)
  targetThangNewPhysical.config.pos.x = toComplex.x
  targetThangNewPhysical.config.pos.y = toComplex.y
  return true
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
      const randomDirection = new Direction(_.sample(directionNames))
      this.name = randomDirection.name
      this.vector = randomDirection.vector
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
  constructor ({ type, direction, distance, loopVariable, loopCount }) {
    this.type = type // 'move', 'hit', 'zap', 'spin', 'look', 'for'
    this.direction = direction // A Direction like 'up', 'down', 'left', 'right', or undefined for spin/for
    this.distance = distance
    this.loopVariable = loopVariable
    this.loopCount = loopCount
  }

  clone () {
    return new Action({ type: this.type, direction: this.direction, distance: this.distance, loopVariable: this.loopVariable, loopCount: this.loopCount })
  }
}

// Change actions while maintaining some invariances:;
// - Manhattan distance of hero from start to current should always be same after each move
// - Should turn when hero turns, go forward when it goes forward, goes backwards when it goes backwards
// - Should follow similar patterns for hit and zap
function permuteActions ({ actions, thangs, checkDistanceTraveled, checkZapTurns, checkHitTurns }) {
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
  setPositionPlaceholders(thangsNew)
  const visitedPositions = [startPos.copy()]
  let hasSeenZap = false
  let lastAction
  const loopStack = []
  let actionIndex = 0
  while (actionIndex < actionsSrc.length) {
    const inRepeatedLoop = _.find(loopStack, (loop) => loop.currentIteration > 0)
    const actionSrc = actionsSrc[actionIndex]
    const actionNew = inRepeatedLoop ? actionsNew[actionIndex] : actionSrc.clone()
    const lastDirectionSrc = lastDirectionsPerActionSrc[actionSrc.type]

    if (actionSrc.type === 'for') {
      loopStack.push({ startIndex: actionIndex, iterations: actionSrc.loopCount, currentIteration: 0 })
      if (!inRepeatedLoop) {
        actionsNew.push(actionNew)
      }
      ++actionIndex
      continue
    }

    if (actionSrc.type === '}') {
      if (loopStack.length > 0) {
        const currentLoop = loopStack[loopStack.length - 1]
        if (++currentLoop.currentIteration < currentLoop.iterations) {
          actionIndex = currentLoop.startIndex
        } else {
          loopStack.pop()
        }
      }
      if (!inRepeatedLoop) {
        actionsNew.push(actionNew)
      }
      actionIndex++
      continue
    }

    const lastDirectionNew = lastDirectionsPerActionNew[actionNew.type]
    const currentDirectionRelationshipSrc = lastDirectionSrc ? actionSrc.direction.getRelationship(lastDirectionSrc) : undefined
    if (actionSrc.type === 'go') {
      const targetCurrentPosSrc = currentPosSrc.copy().add(actionSrc.direction.vector.copy().multiply(actionSrc.distance || 1))
      const targetDistanceFromStart = manhattanDistance(startPos, targetCurrentPosSrc)
      let targetCurrentPosNew, valid
      let tries = 0
      do {
        valid = true
        if (inRepeatedLoop) continue
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
      } while (!valid && tries < permutationTriesPerMove)
      if (!valid) {
        console.log('Could not find valid permutation for go', { actionSrc, actionNew, lastDirectionSrc, lastDirectionNew, currentDirectionRelationshipSrc })
        actionNew.invalid = true
      }
      for (let distance = 1; distance <= (actionNew.distance || 1); ++distance) {
        // Put any gems or rafts we crossed in the right places
        currentPosSrc.add(actionSrc.direction.vector)
        currentPosNew.add(actionNew.direction.vector)
        const thang = findThangAt(currentPosSrc, thangsSrc)
        const spriteName = thangTypesToSpriteNames[thang?.thangType]
        if (['Gem Junior', 'Goal Junior'].includes(spriteName)) {
          // console.log('Moving', thang.id, spriteName, 'from', currentPosSrc, complexifyPos(currentPosSrc), 'to', currentPosNew, complexifyPos(currentPosNew))
          if (!moveThang({ at: currentPosSrc, to: currentPosNew, thangsSrc, thangsNew })) {
            actionNew.invalid = true
          }
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
        const lastGoDirectionSrc = lastDirectionsPerActionSrc.go
        const lastGoDirectionNew = lastDirectionsPerActionNew.go
        const lastGoDirectionRelationship = lastGoDirectionNew?.getRelationship(lastGoDirectionSrc)
        const directionNew = new Direction(directionName)
        // console.log({ lastGoDirectionSrc, lastGoDirectionNew, lastGoDirectionRelationship })
        if (!lastGoDirectionRelationship || lastGoDirectionRelationship === 'forward') {
          // No change needed
        } else if (lastGoDirectionRelationship === 'backward') {
          directionNew.vector.multiply(-1)
        } else {
          // How to tell which way to rotate?
          // directionNew.vector.rotate(Math.PI / 2)
          // Claude thinks this
          directionNew.vector.rotate(Math.PI / 2 * (lastGoDirectionNew.vector.x * lastGoDirectionSrc.vector.y - lastGoDirectionNew.vector.y * lastGoDirectionSrc.vector.x > 0 ? 1 : -1))
        }
        const targetPosNew = currentPosNew.copy().add(directionNew.vector)
        const thang = findThangAt(targetPosSrc, thangsSrc)
        const spriteName = thangTypesToSpriteNames[thang?.thangType]
        if (thang && hittableSpriteNames.includes(spriteName)) {
          if (!moveThang({ at: targetPosSrc, to: targetPosNew, thangsSrc, thangsNew })) {
            actionNew.invalid = true
          }
        }
      }
    } else if (actionSrc.type === 'hit') {
      const targetPosSrc = currentPosSrc.copy().add(actionSrc.direction.vector)
      const targetDistanceFromStart = manhattanDistance(startPos, targetPosSrc)
      let targetPosNew, valid
      let tries = 0
      do {
        valid = true
        if (inRepeatedLoop) {
          targetPosNew = currentPosNew.copy().add(actionNew.direction.vector)
          continue
        }
        if (lastAction && lastAction.type === 'zap') {
          // Hit the same way we were just zapping (some monster has probably run up to us)
          actionNew.direction = lastDirectionsPerActionNew.zap
        } else {
          actionNew.direction = new Direction()
        }
        const currentDirectionRelationshipNew = lastDirectionNew ? actionNew.direction.getRelationship(lastDirectionNew) : undefined
        if (currentDirectionRelationshipNew !== currentDirectionRelationshipSrc && (checkHitTurns || currentDirectionRelationshipSrc === 'forward')) {
          // console.log('  ', 'Not valid because relationship is different', { lastDirectionSrc, lastDirectionNew, currentDirectionRelationshipSrc, currentDirectionRelationshipNew })
          valid = false // Don't hit in a different sort of way than we previously did
        }
        targetPosNew = currentPosNew.copy().add(actionNew.direction.vector)
        if (valid && checkDistanceTraveled && manhattanDistance(startPos, targetPosNew) !== targetDistanceFromStart) {
          // console.log('  ', 'Not valid because distance from start is different', { targetDistanceFromStart, newDistance: manhattanDistance(startPos, targetPosNew), startPos, targetPosNew, currentPosSrc, actionSrc, actionNew: _.cloneDeep(actionNew) })
          valid = false // Don't end up hitting a target at a different distance from the start position
        }
        ++tries
      } while (!valid && tries < permutationTriesPerMove)
      if (!valid) {
        console.log('Could not find valid permutation for hit', { actionSrc, actionNew, lastDirectionSrc, lastDirectionNew, currentDirectionRelationshipSrc })
        actionNew.invalid = true
      }

      // Find the target that it would hit and put it in the right place
      const thang = findThangAt(targetPosSrc, thangsSrc)
      const spriteName = thangTypesToSpriteNames[thang?.thangType]
      if (thang && hittableSpriteNames.includes(spriteName)) {
        if (!moveThang({ at: targetPosSrc, to: targetPosNew, thangsSrc, thangsNew })) {
          actionNew.invalid = true
        }
      } else if (!hasSeenZap) {
        // If we haven't zapped (which might have aggro'd a monster and brought it to us), then our hits should be hitting something next to us
        console.log('Only found', spriteName, thang, 'at', currentPosSrc, 'but expected to find a hittable sprite')
        actionNew.invalid = true
      }
    } else if (actionSrc.type === 'zap') {
      hasSeenZap = true
      const targetPosSrc = currentPosSrc.copy().add(actionSrc.direction.vector)
      const targetDistanceFromStart = manhattanDistance(startPos, targetPosSrc)
      let targetPosNew, valid
      let tries = 0
      do {
        valid = true
        if (inRepeatedLoop) {
          targetPosNew = currentPosNew.copy().add(actionNew.direction.vector)
          continue
        }
        actionNew.direction = new Direction()
        const currentDirectionRelationshipNew = lastDirectionNew ? actionNew.direction.getRelationship(lastDirectionNew) : undefined
        if (currentDirectionRelationshipNew !== currentDirectionRelationshipSrc && (checkZapTurns || currentDirectionRelationshipSrc === 'forward')) {
          valid = false // Don't zap in a different sort of way than we previously did
        }
        targetPosNew = currentPosNew.copy().add(actionNew.direction.vector)
        if (valid && checkDistanceTraveled && manhattanDistance(startPos, targetPosNew) !== targetDistanceFromStart) {
          valid = false // Don't end up zapping a target at a different distance from the start position
        }
        ++tries
      } while (!valid && tries < permutationTriesPerMove)
      if (!valid) {
        console.log('Could not find valid permutation for zap', { actionSrc, actionNew, lastDirectionSrc, lastDirectionNew, currentDirectionRelationshipSrc })
        actionNew.invalid = true
      }

      // Find the targets that it would hit and put them in the right places
      const processedPositions = new Set()
      const maxZapDistance = 8
      const zapVisitedPositions = []
      for (let distance = 1; distance < maxZapDistance; ++distance) {
        const zapTargetPosSrc = currentPosSrc.copy().add(actionSrc.direction.vector.copy().multiply(distance))
        const zapTargetPosNew = currentPosNew.copy().add(actionNew.direction.vector.copy().multiply(distance))
        const zappableThangSrc = findThangAt(zapTargetPosSrc, thangsSrc)
        const zappableSpriteName = thangTypesToSpriteNames[zappableThangSrc?.thangType]
        zapVisitedPositions.push(zapTargetPosNew.copy())
        if (zappableThangSrc && hittableSpriteNames.includes(zappableSpriteName)) {
          if (!moveThang({ at: zapTargetPosSrc, to: zapTargetPosNew, thangsSrc, thangsNew })) {
            actionNew.invalid = true
          }
          for (const visitedPosition of zapVisitedPositions) {
            // Whenever we hit something, we know that all visited positions up to that point are important to be able to zap over
            visitedPositions.push(visitedPosition)
          }

          // If it's TNT, also move any hittables next to it (recursively for other TNT)
          if (zappableSpriteName === 'Explosive Junior') {
            processExplosiveChain({ zapTargetPosSrc, zapTargetPosNew, thangsSrc, thangsNew, processedPositions, visitedPositions, actionSrc, actionNew })
          }

          // Move all the Thangs in this line, in case some would be killed out of the way in between start of level and when the zap would happen.
          // This could result in slightly wrong behavior, because perhaps we are counting on the zap only hitting the first one?
          // We randomly break or not here, so that we can test it both ways and eventually get a valid layout in either scenario.
          let chanceZapStopsOnHit = 0.05
          if (zappableSpriteName === 'Explosive Junior') {
            chanceZapStopsOnHit = 0.5 // Don't often need to shoot one of these out of the way
          }
          if (Math.random() < chanceZapStopsOnHit) {
            break
          }
        }
      }
    } else if (actionSrc.type === 'look') {
      // TODO: update lots of things for look to work, when look is fully implemented with levels that use it
      // TODO: probably add positions in between currentPosNew and any targets to visitedPositions
    } else if (actionSrc.type === '') {
      // Don't need to do anything for newlines
    }

    if (actionSrc.type === 'go') {
      // Reset the other actions' directions. TODO: is this right?
      lastDirectionsPerActionSrc = { go: actionSrc.direction }
      lastDirectionsPerActionNew = { go: actionNew.direction }
      // console.log('Setting lastDirectionsPerAction to source', _.cloneDeep(lastDirectionsPerActionSrc), 'and new', _.cloneDeep(lastDirectionsPerActionNew))
    } else {
      lastDirectionsPerActionSrc[actionSrc.type] = actionSrc.direction
      lastDirectionsPerActionNew[actionNew.type] = actionNew.direction
      // console.log('Setting lastDirection for', actionSrc.type, 'to source', _.cloneDeep(actionSrc.direction), 'and new', _.cloneDeep(actionNew.direction))
    }

    if (!inRepeatedLoop) {
      actionsNew.push(actionNew)
    }
    lastAction = actionNew
    ++actionIndex
  }

  return { actions: actionsNew, thangs: thangsNew, visitedPositions }
}

function layoutsAreEquivalent (thangsA, thangsB) {
  for (let col = 0; col < maxCols; ++col) {
    for (let row = 0; row < maxRows; ++row) {
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

function processExplosiveChain ({ zapTargetPosSrc, zapTargetPosNew, thangsSrc, thangsNew, processedPositions, visitedPositions, actionSrc, actionNew }) {
  const directions = [
    new Direction('up'),
    new Direction('right'),
    new Direction('down'),
    new Direction('left'),
    { name: 'upleft', vector: new Vector(-1, 1) },
    { name: 'upright', vector: new Vector(1, 1) },
    { name: 'downleft', vector: new Vector(-1, -1) },
    { name: 'downright', vector: new Vector(1, -1) }
  ]

  for (const direction of directions) {
    const nearbyPosSrc = zapTargetPosSrc.copy().add(direction.vector)
    const posKey = `${nearbyPosSrc.x},${nearbyPosSrc.y}`

    if (processedPositions.has(posKey)) continue
    processedPositions.add(posKey)

    const nearbyThangSrc = findThangAt(nearbyPosSrc, thangsSrc)
    const nearbySpriteName = thangTypesToSpriteNames[nearbyThangSrc?.thangType]

    if (nearbyThangSrc && hittableSpriteNames.includes(nearbySpriteName)) {
      const zapDirectionRelationship = actionNew.direction.getRelationship(actionSrc.direction)
      const directionNew = new Vector(direction.vector.x, direction.vector.y)

      if (zapDirectionRelationship === 'backward') {
        directionNew.multiply(-1)
      } else if (zapDirectionRelationship === 'turn') {
        const rotationFactor = actionNew.direction.vector.x * actionSrc.direction.vector.y - actionNew.direction.vector.y * actionSrc.direction.vector.x > 0 ? 1 : -1
        directionNew.rotate(Math.PI / 2 * rotationFactor)
      }

      const nearbyPosNew = zapTargetPosNew.copy().add(directionNew)
      visitedPositions.push(nearbyPosNew.copy())

      if (!moveThang({ at: nearbyPosSrc, to: nearbyPosNew, thangsSrc, thangsNew })) {
        actionNew.invalid = true
      }

      if (nearbySpriteName === 'Explosive Junior') {
        // console.log('Processing explosive chain', nearbyThangSrc, posKey)
        processExplosiveChain({ zapTargetPosSrc: nearbyPosSrc, zapTargetPosNew: nearbyPosNew, thangsSrc, thangsNew, processedPositions, visitedPositions, actionSrc, actionNew })
      }
    }
  }
}

function repositionFriendsAndExplosives ({ thangsSrc, thangsNew, visitedPositions }) {
  // Find any TNT or chickens that weren't moved into position (x == y == placeholderPosition), and try to put them where they might go
  // Perhaps there is an accurate way to do this, but we can also try semi-randomly until it works:
  // - For each leftover explosive:
  //   - Place explosive same manhattan distance from hero start point as in the source
  //     - Pick a random rotation and use that, maybe bias towards the one we used first in this sequence
  //   - For each nearby chicken (also explosives but let me just not make to-avoid chain reactions)
  //     - Use the same rotation and distance to preserve offset
  // Technically, we would want to move standalone friends, too, but I don't think I've used those (only friends next to TNT)

  const heroSrc = _.find(thangsSrc, { id: 'Hero Placeholder' })
  const heroNew = _.find(thangsNew, { id: 'Hero Placeholder' })
  const heroStartPosSrc = simplifyPos(_.find(heroSrc.components, (component) => component.original === PhysicalID).config.pos)
  const heroStartPosNew = simplifyPos(_.find(heroNew.components, (component) => component.original === PhysicalID).config.pos)

  const explosives = thangsNew.filter(thang => {
    const spriteName = thangTypesToSpriteNames[thang.thangType]
    if (spriteName !== 'Explosive Junior') return false
    const pos = simplifyPos(_.find(thang.components, (component) => component.original === PhysicalID).config.pos)
    return pos.x >= placeholderPositionSimple || pos.y >= placeholderPositionSimple
  })
  // console.log('Found unplaced explosives', explosives)

  const processedFriendsAndExplosives = []
  for (const explosiveThang of explosives) {
    const explosiveThangSrc = _.find(thangsSrc, { id: explosiveThang.id })
    const explosivePosSrc = simplifyPos(_.find(explosiveThangSrc.components, (component) => component.original === PhysicalID).config.pos)

    const directions = [
      new Direction('up'),
      new Direction('right'),
      new Direction('down'),
      new Direction('left'),
      { name: 'upleft', vector: new Vector(-1, 1) },
      { name: 'upright', vector: new Vector(1, 1) },
      { name: 'downleft', vector: new Vector(-1, -1) },
      { name: 'downright', vector: new Vector(1, -1) }
    ]

    const adjacentFriendsAndExplosives = [{ thang: explosiveThang, offset: new Vector(0, 0) }]
    for (const direction of directions) {
      const nearbyPosSrc = explosivePosSrc.copy().add(direction.vector)
      const nearbyThang = findThangAt(nearbyPosSrc, thangsSrc, ['Explosive Junior', 'Chicken Junior'])
      if (nearbyThang && !floorSpriteNames.includes(thangTypesToSpriteNames[nearbyThang.thangType]) && processedFriendsAndExplosives.indexOf(nearbyThang) === -1) {
        adjacentFriendsAndExplosives.push({ thang: nearbyThang, offset: direction.vector })
        processedFriendsAndExplosives.push(nearbyThang)
      }
    }

    let allPlaced = false
    let tries = 0
    while (!allPlaced && tries < 50) {
      const permutationVector = new Vector(Math.random() < 0.5 ? -1 : 1, Math.random() < 0.5 ? -1 : 1)
      let placed = true
      for (const { offset } of adjacentFriendsAndExplosives) {
        const posSrc = explosivePosSrc.copy().add(offset)
        const heroToThangVectorSrc = posSrc.copy().subtract(heroStartPosSrc)
        const heroToThangVectorNew = heroToThangVectorSrc.copy()
        heroToThangVectorNew.x *= permutationVector.x
        heroToThangVectorNew.y *= permutationVector.y
        const posNew = heroStartPosNew.copy().add(heroToThangVectorNew)
        if (!moveThang({ at: posSrc, to: posNew, thangsSrc, thangsNew })) {
          placed = false
          break
        }
        placed = true
      }
      if (placed) {
        allPlaced = true
      }
      tries++
    }
    if (!allPlaced) {
      console.warn(`Could not place ${adjacentFriendsAndExplosives.map((t) => t.id).join(', ')} after 50 tries`)
    }
  }
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
    // if (simplePos.x >= placeholderPositionSimple || simplePos.y >= placeholderPositionSimple) {
    //   console.log('Found unmoved', spriteName, thang.id, 'at', simplePos.x, simplePos.y)
    // }
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
  for (let col = -1; col <= maxCols; ++col) {
    for (let row = -1; row <= maxRows; ++row) {
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

  // Adjust ocean background scale if it's a really big one
  const ocean = _.find(level.thangs, (thang) => thang.id === 'Junior Ocean Background')
  let scales = _.find(ocean.components, (component) => component.original === ScalesID)
  if (!scales) {
    scales = { original: ScalesID, majorVersion: 0 }
    ocean.components.push(scales)
  }
  const colsAt1X = 9
  const rowsAt1X = 8
  scales.config = { scaleFactor: Math.max(1, size.cols / colsAt1X, size.rows / rowsAt1X) }
  // Move it to center it, if needed. (Don't adjust from default center of 40, 34 otherwise.)
  const oceanPhysicalConfig = _.find(ocean.components, (component) => component.original === PhysicalID).config
  oceanPhysicalConfig.pos.x = Math.max(40, (6 + 8 * size.cols) / 2)
  oceanPhysicalConfig.pos.y = Math.max(34, (6 + 8 * size.rows) / 2)
}

const placeholderPositionSimple = 50
const placeholderPosition = 6 + placeholderPositionSimple * 8
function setPositionPlaceholders (thangs) {
  // Move all signifiant Thangs out of the way, so any Thangs in the actual level layout will have to have been moved there deliberately
  for (const thang of thangs) {
    const spriteName = thangTypesToSpriteNames[thang.thangType]
    if (significantSpriteNames.includes(spriteName)) {
      const physicalConfig = _.find(thang.components, (component) => component.original === PhysicalID).config
      physicalConfig.pos.x = placeholderPosition
      physicalConfig.pos.y = placeholderPosition
    }
  }
}

async function verifyLevel ({ sourceLevel, thangs, solutionCode, starterCode, supermodel }) {
  // console.log('Should verify', { sourceLevel, thangs, solutionCode, starterCode })
  const solutions = constructSolutions({ solutionCode, starterCode })
  const testContext = { running: 0, problems: 0, failed: 0, passedExceptFrames: 0, passed: 0, waiting: solutions.length, completed: 0, total: solutions.length }

  return new Promise((resolve) => {
    const onVerifierTestUpdate = createVerifierTestListener(testContext, () => {
      if (testContext.completed === solutions.length || testContext.aborted) {
        resolve(testContext.passed + testContext.passedExceptFrames === solutions.length)
      }
    })

    solutions.map(solution => {
      const childSupermodel = new SuperModel()
      childSupermodel.models = _.clone(supermodel.models)
      childSupermodel.collections = _.clone(supermodel.collections)
      return new VerifierTest(sourceLevel.get('slug'), onVerifierTestUpdate, childSupermodel, 'javascript', { devMode: false, solution, thangsOverride: thangs })
    })
  })
}

function constructSolutions ({ solutionCode, starterCode }) {
  const solutions = []
  solutions.push({ source: solutionCode, language: 'javascript', succeeds: true })
  solutions.push({ source: starterCode, language: 'javascript', succeeds: false })
  const solutionCodeLines = solutionCode.split('\n')
  for (let i = 0; i < solutionCodeLines.length; ++i) {
    if (i !== solutionCodeLines.length - 1) {
      // Maybe we don't need to test all the intermediate lines, and just testing starter code plus solution less last line is enough
      continue
    }
    solutions.push({ source: solutionCodeLines.slice(0, i).join('\n'), language: 'javascript', succeeds: false })
  }
  return solutions
}

function createVerifierTestListener (testContext, onAllTestsCompleted) {
  return (e) => {
    if (testContext.aborted) { return }
    if (e.state === 'running') {
      --testContext.waiting
      ++testContext.running
    } else if (['complete', 'error', 'no-solution'].includes(e.state)) {
      --testContext.running
      ++testContext.completed
      if (e.state === 'complete') {
        if (e.test.isSuccessful(true)) {
          ++testContext.passed
        } else if (e.test.isSuccessful(false)) {
          ++testContext.passedExceptFrames
        } else {
          ++testContext.failed
        }
      } else if (e.state === 'no-solution') {
        console.warn('Solution problem for', e.test.language)
        ++testContext.problems
      } else {
        ++testContext.problems
      }
    }

    if (testContext.failed || testContext.problems) {
      // As soon as one test fails, end early and stop paying attention to any others
      testContext.aborted = true
      onAllTestsCompleted()
    }

    if (testContext.completed === testContext.total) {
      onAllTestsCompleted()
    }
  }
}
