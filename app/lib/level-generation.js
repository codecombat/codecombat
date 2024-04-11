const _ = require('lodash')
const schemas = require('../schemas/schemas')
const levelSchema = require('../schemas/models/level')
const terrainGeneration = require('./terrain-generation')

module.exports = {
  generateLevel,
}

async function generateLevel (parameters) {
  parameters.terrain = parameters.terrain || 'Junior'
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

const ParametersSchema = schemas.object({ required: ['difficulty', 'kind'] }, {
  terrain: schemas.terrainString,
  kind: schemas.shortString({ title: 'Kind', description: 'Similar to type, but just for our organization.', enum: ['demo', 'usage', 'mastery', 'advanced', 'practice', 'challenge'] }),
  difficulty: { type: 'integer', minimum: 1, maximum: 5 },
  combat: { type: 'boolean' },
  size: schemas.shortString({ title: 'Size', description: 'How big the level is', enum: ['junior3x2', 'junior4x3', 'junior5x4', 'junior6x5', 'junior7x6', 'junior8x7', 'junior9x7', 'junior9x8'] }),
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

// // name: c.shortString()
// generateProperty('name', function (level, parameters) {
//   return `autolevel-${generateKeyForParameters(parameters)}`
// })

// // displayName: c.shortString({title: 'Display Name', inEditor: 'ozaria'}),
// generateProperty('displayName', function (level, parameters) {
//   return `Autolevel ${parameters.terrain} ${parameters.kind} ${parameters.difficulty}`
// })

// // description: {title: 'Description', description: 'A short explanation of what this level is about.', type: 'string', maxLength: 65536, format: 'markdown', inEditor: true},
// generateProperty('description', function (level, parameters) {
//   return `${parameters.terrain} ${parameters.kind} level with difficulty ${parameters.difficulty} / 5`
// })

// // loadingTip: { type: 'string', title: 'Loading Tip', description: 'What to show for this level while it\'s loading.', inEditor: 'codecombat' },
// generateProperty('loadingTip', function (level, parameters) {
//   return `This is a ${parameters.terrain} ${parameters.kind} level with difficulty ${parameters.difficulty} / 5`
// })

// goals: c.array({title: 'Goals', description: 'An array of goals which are visible to the player and can trigger scripts.', inEditor: true}, GoalSchema),
generateProperty('goals', function (level, parameters) {
  const exampleGoals = {
    heroSurvives: {
      hiddenGoal: false,
      worldEndsAfter: 1,
      howMany: 1,
      saveThangs: ['humans'],
      name: 'Your hero must survive.',
      id: 'hero-survives'
    },

    avoidSpikes: {
      saveThangs: ['humans'],
      hiddenGoal: false,
      howMany: 1,
      worldEndsAfter: 3,
      id: 'humans-survive',
      name: 'Avoid the spikes.'
    },

    // TODO: can you just do saveThangs: ["humans"] with no count and have it work?
    saveFriends: {
      name: 'Friends must survive.',
      id: 'humans-survive',
      saveThangs: [
        'Giselle',
        'Brandy',
        'Gwendolin',
        'Yorik',
        'Durfkor',
        'Charles'
      ],
      worldEndsAfter: 5,
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
        targets: ['Goal Junior'], // Placeholder
        who: ['Hero Placeholder']
      },
      id: 'touch-goal',
      name: 'Go to the X.'
    },

    defeatEnemies: {
      killThangs: ['ogres'],
      id: 'ogres-die',
      name: 'Defeat the enemies.'
    },

    defeatDoor: {
      name: 'Break the door.',
      id: 'break-door',
      killThangs: ['Weak Door'],
      howMany: 1,
    },

    collectGems: {
      // worldEndsAfter: 2, // TODO: make this happen after all positive goals are achieved, not just one
      collectThangs: {
        targets: ['Gem Junior'], // Placeholder
        who: ['humans']
      },
      id: 'collect-gems',
      name: 'Collect the gems.'
    },
  }

  const goals = [exampleGoals.heroSurvives, exampleGoals.cleanCode]
  if (!parameters.combat && Math.random() < 0.75) {
    goals.push(exampleGoals.defeatEnemies)
  }
  if (Math.random() < 0.5) {
    goals.push(exampleGoals.collectGems)
  }
  if (Math.random() < 0.5 || goals.length === 2) {
    goals.push(exampleGoals.moveToTarget)
  }

  return _.cloneDeep(goals)
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
                x: 0,
                y: 0
              },
              {
                x: 4 + 8 * rows,
                y: (4 + 8 * rows) * 17 / 20 // Maintain aspect ratio
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
const loadedThangTypes = new Map()
async function loadThangTypes (terrainThangs) {
  // Need at least one promise in loadingPromises to prevent empty array Promise bug.
  const loadingPromises = [Promise.resolve()]
  const uniqueTerrainThangs = _.uniq(terrainThangs, 'id')
  for (const terrainThang of uniqueTerrainThangs) {
    const spriteName = terrainThang.id
    const thangType = loadedThangTypes[spriteName]
    if (!thangType) {
      const slug = _.string.slugify(spriteName)
      const fetchOptions = {
        headers: { 'content-type': 'application/json' },
        credentials: 'same-origin'
      }
      const origin = window?.location?.origin || 'https://codecombat.com'
      const thangTypePromise = fetch(`${origin}/db/thang.type/${slug}?project=original,components`, fetchOptions).then(async function (response) {
        loadedThangTypes[spriteName] = await response.json()
      })
      loadingPromises.push(thangTypePromise)
    }
  }
  await Promise.all(loadingPromises)
  return loadedThangTypes
}

// thangs: c.array({title: 'Thangs', description: 'An array of Thangs that make up the level.' }, LevelThangSchema),
generateProperty('thangs', async function (level, parameters) {
  const terrainThangs = terrainGeneration.generateThangs({ presetName: parameters.terrain, presetSize: parameters.size, goals: level.goals })
  const thangTypes = await loadThangTypes(terrainThangs)

  const resultThangs = []
  const resultThangsByNameCount = {}
  for (const terrainThang of terrainThangs) {
    const spriteName = terrainThang.id
    const isHero = spriteName === 'Hero Placeholder'
    const numExistingThangsForSpriteName = resultThangsByNameCount[spriteName] || 0
    // Match existing level editor naming logic: Gem, Gem 1, Gem 2, etc.
    const thangID = numExistingThangsForSpriteName > 0 ? `${spriteName} ${numExistingThangsForSpriteName}` : spriteName
    const thangType = thangTypes[spriteName]
    const components = createEssentialComponents(thangType.components, terrainThang.pos, isHero)
    const thang = { thangType: thangType.original, id: thangID, components }
    resultThangs.push(thang)
    resultThangsByNameCount[spriteName] = (resultThangsByNameCount[spriteName] || 0) + 1
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
  return parameters.kind
})

// terrain: c.terrainString,
generateProperty('terrain', function (level, parameters) {
  return parameters.terrain
})

// requiresSubscription: {title: 'Requires Subscription', description: 'Whether this level is available to subscribers only.', type: 'boolean', inEditor: 'codecombat'},
generateProperty('requiresSubscription', function (level, parameters) {
  return false
})

// tasks: c.array({title: 'Tasks', description: 'Tasks to be completed for this level.'}, c.task),
generateProperty('tasks', function (level, parameters) {
  return []
})

// // practice: { type: 'boolean', inEditor: 'codecombat' },
// generateProperty('practice', function (level, parameters) {
//   return false
// })

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
  return []
})

// primaryConcepts: c.array({title: 'Primary Concepts', description: 'The main 1-3 concepts this level focuses on.', uniqueItems: true, inEditor: true}, c.concept),
generateProperty('primaryConcepts', function (level, parameters) {
  return []
})

// codePoints: c.int({title: 'CodePoints', minimum: 0, description: 'CodePoints that can be earned for completing this level'}),
generateProperty('codePoints', function (level, parameters) {
  return 0
})

// difficulty: { type: 'integer', title: 'Difficulty', description: 'Difficulty of this level - used to show difficulty in star-rating of 1 to 5', minimum: 1, maximum: 5, inEditor: 'codecombat' }
generateProperty('difficulty', function (level, parameters) {
  return parameters.difficulty
})

generateProperty('permissions', function (level, parameters) {
  return [{ access: 'owner', target: '512ef4805a67a8c507000001' }] // Nick's id
})

generateProperty('product', function (level, parameters) {
  return 'codecombat-junior'
})

// ---- Refining Outputs ----

generateProperty(null, function (level, parameters) {
  // Come up with starter and solution code
  const apis = []
  if (Math.random() > parameters.skillGo) {
    apis.push('go')
  } else {
    apis.push('go')
  }
  if (_.find(level.goals, (goal) => goal.killThangs)) {
    apis.push('hit')
  }
  if (Math.random() > parameters.skillForLoops && parameters.difficulty > 2) {
    apis.push('for-loop')
  }
  let indent = 0
  const solutionCodeLines = []
  const directions = ['up', 'down', 'left', 'right']
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
      solutionCodeLines.push(prefix + `${api}('${_.sample(directions)}', ${Math.ceil(Math.random() * 4)})`)
    } else if (['hit', 'zap'].includes(api)) {
      solutionCodeLines.push(prefix + `${api}('${_.sample(directions)}')`)
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

  const juniorPlayer = _.find(hero.components, (component) => component.original === defaultHeroComponentIDs.JuniorPlayer)
  juniorPlayer.config = {
    programmableSnippets: [],
    requiredThangTypes: ['5467beaf69d1ba0000fb91fb']
  }

  const physical = _.find(hero.components, (component) => component.original === PhysicalID)
  physical.config = {
    pos: { x: 6, y: 14, z: 0.5 }
  }
})
