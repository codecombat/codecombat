const Language = require('./languages')

// schema helper methods

const me = module.exports

const combine = function (base, ext) {
  if (ext == null) { return base }
  return _.extend(base, ext)
}

const urlPattern = '^(ht|f)tp(s?)\:\/\/[0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*(:(0-9)*)*(\/?)([a-zA-Z0-9\-\.\?\,\'\/\\\+&%\$#_=]*)?$' // eslint-disable-line no-useless-escape
const pathPattern = '^\/([a-zA-Z0-9\-\.\?\,\'\/\\\+&%\$#_=]*)?$' // eslint-disable-line no-useless-escape

// Common schema properties
me.object = (ext, props) => combine({ type: 'object', additionalProperties: false, properties: props || {} }, ext)
me.array = (ext, items) => combine({ type: 'array', items: items || {} }, ext)
me.shortString = ext => combine({ type: 'string', maxLength: 100 }, ext)
me.pct = ext => combine({ type: 'number', maximum: 1.0, minimum: 0.0 }, ext)
me.passwordString = {
  allOf: [
    { type: 'string', maxLength: 64, minLength: 4, title: 'Password' },
    { not: { pattern: '([\\s\\S])\\1\\1' } }
  ]
}

// Dates should usually be strings, ObjectIds should be strings: https://github.com/codecombat/codecombat/issues/1384
me.date = ext => combine({ type: ['object', 'string'], format: 'date-time' }, ext) // old
me.stringDate = ext => combine({ type: ['string'], format: 'date-time' }, ext) // new
me.objectId = ext => combine({ type: ['object', 'string'] }, ext) // old
me.stringID = ext => combine({ type: 'string', minLength: 24, maxLength: 24 }, ext) // use for anything new

me.url = ext => combine({ type: 'string', format: 'url', pattern: urlPattern }, ext)
me.path = ext => combine({ type: 'string', pattern: pathPattern }, ext)
me.int = ext => combine({ type: 'integer' }, ext)
me.float = ext => combine({ type: 'number' }, ext)

const PointSchema = me.object({ title: 'Point', description: 'An {x, y} coordinate point.', format: 'point2d', required: ['x', 'y'] }, {
  x: { title: 'x', description: 'The x coordinate.', type: 'number', default: 15 },
  y: { title: 'y', description: 'The y coordinate.', type: 'number', default: 20 }
})

me.point2d = ext => combine(_.cloneDeep(PointSchema), ext)

const SoundSchema = me.object({ format: 'sound' }, {
  mp3: { type: 'string', format: 'sound-file' },
  ogg: { type: 'string', format: 'sound-file' }
})

me.sound = function (props) {
  const obj = _.cloneDeep(SoundSchema)
  for (const prop in props) { obj.properties[prop] = props[prop] }
  return obj
}

me.file = ext => combine({ type: 'string', format: 'file' }, ext)

const ColorConfigSchema = me.object({ format: 'color-sound' }, {
  hue: { format: 'range', type: 'number', minimum: 0, maximum: 1 },
  saturation: { format: 'range', type: 'number', minimum: 0, maximum: 1 },
  lightness: { format: 'range', type: 'number', minimum: 0, maximum: 1 }
})

me.colorConfig = function (props) {
  const obj = _.cloneDeep(ColorConfigSchema)
  for (const prop in props) { obj.properties[prop] = props[prop] }
  return obj
}

// BASICS

const basicProps = linkFragment => ({
  _id: me.objectId({ links: [{ rel: 'self', href: `/db/${linkFragment}/{($)}` }], format: 'hidden' }),
  __v: { title: 'Mongoose Version', format: 'hidden' }
})

me.extendBasicProperties = function (schema, linkFragment) {
  if (schema.properties == null) { schema.properties = {} }
  return _.extend(schema.properties, basicProps(linkFragment))
}

// PATCHABLE

const patchableProps = () => ({
  patches: me.array({ title: 'Patches' }, {
    _id: me.objectId({ links: [{ rel: 'db', href: '/db/patch/{($)}' }], title: 'Patch ID', description: 'A reference to the patch.' }),
    status: { enum: ['pending', 'accepted', 'rejected', 'cancelled'] }
  }),

  allowPatches: { type: 'boolean' },

  watchers: me.array({ title: 'Watchers' },
    me.objectId({ links: [{ rel: 'extra', href: '/db/user/{($)}' }] }))
})

me.extendPatchableProperties = function (schema) {
  if (schema.properties == null) { schema.properties = {} }
  return _.extend(schema.properties, patchableProps())
}

// NAMED

const namedProps = () => ({
  name: me.shortString({ title: 'Name' }),
  slug: me.shortString({ title: 'Slug', format: 'hidden' })
})

me.extendNamedProperties = function (schema) {
  if (schema.properties == null) { schema.properties = {} }
  return _.extend(schema.properties, namedProps())
}

// VERSIONED

const versionedProps = linkFragment => ({
  version: {
    default: { minor: 0, major: 0, isLatestMajor: true, isLatestMinor: true },
    format: 'version',
    title: 'Version',
    type: 'object',
    readOnly: true,
    additionalProperties: false,
    properties: {
      major: { type: 'number', minimum: 0 },
      minor: { type: 'number', minimum: 0 },
      isLatestMajor: { type: 'boolean' },
      isLatestMinor: { type: 'boolean' }
    }
  },

  // TODO: figure out useful 'rel' values here
  original: me.objectId({ links: [{ rel: 'extra', href: `/db/${linkFragment}/{($)}` }], format: 'hidden' }),

  parent: me.objectId({ links: [{ rel: 'extra', href: `/db/${linkFragment}/{($)}` }], format: 'hidden' }),
  creator: me.objectId({ links: [{ rel: 'extra', href: '/db/user/{($)}' }], format: 'hidden' }),
  created: me.date({ title: 'Created', readOnly: true }),
  commitMessage: { type: 'string', maxLength: 500, title: 'Commit Message', readOnly: true }
})

me.extendVersionedProperties = function (schema, linkFragment) {
  if (schema.properties == null) { schema.properties = {} }
  return _.extend(schema.properties, versionedProps(linkFragment))
}

// SEARCHABLE

const searchableProps = () => ({
  // CodeCombat / original
  index: { format: 'hidden' },

  // Ozaria / new
  _algoliaObjectID: { type: 'string', format: 'hidden' }
})

me.extendSearchableProperties = function (schema) {
  if (schema.properties == null) { schema.properties = {} }
  return _.extend(schema.properties, searchableProps())
}

// PERMISSIONED

const permissionsProps = () => ({
  permissions: {
    type: 'array',
    items: {
      type: 'object',
      additionalProperties: false,
      properties: {
        target: {},
        access: { type: 'string', enum: ['read', 'write', 'owner'] }
      }
    },
    format: 'hidden'
  }
})

me.extendPermissionsProperties = function (schema) {
  if (schema.properties == null) { schema.properties = {} }
  return _.extend(schema.properties, permissionsProps())
}

// TRANSLATABLE

me.generateLanguageCodeArrayRegex = () => '^(' + Language.languageCodes.join('|') + ')$'

me.getLanguageCodeArray = () => Language.languageCodes

me.getLanguagesObject = () => Language

me.extendTranslationCoverageProperties = function (schema) {
  if (schema.properties == null) { schema.properties = {} }
  schema.properties.i18nCoverage = { title: 'i18n Coverage', type: 'array', items: { type: 'string' } }
  return schema.properties.i18nCoverage
}

// OTHER

me.classNamePattern = '^[A-Z][A-Za-z0-9]*$' // starts with capital letter; just letters and numbers
me.identifierPattern = '^[a-z][A-Za-z0-9]*$' // starts with lowercase letter; just letters and numbers
me.constantPattern = '^[A-Z0-9_]+$' // just uppercase letters, underscores, and numbers
me.identifierOrConstantPattern = '^([a-z][A-Za-z0-9]*|[A-Z0-9_]+)$'

me.FunctionArgumentSchema = me.object({
  title: 'Function Argument',
  description: 'Documentation entry for a function argument.',
  default: {
    name: 'target',
    type: 'object',
    optional: false,
    example: 'this.getNearestEnemy()',
    description: 'The target of this function.'
  },
  required: ['name', 'type', 'example', 'description']
}, {
  name: { type: 'string', pattern: me.identifierPattern, title: 'Name', description: 'Name of the function argument.' },
  i18n: { type: 'object', format: 'i18n', props: ['description'], description: 'Help translate this argument' },
  // not actual JS types, just whatever they describe...
  type: me.shortString({ title: 'Type', description: 'Intended type of the argument.' }),
  optional: { title: 'Optional', description: 'Whether an argument may be omitted when calling the function', type: 'boolean' },
  example: {
    oneOf: [
      {
        type: 'object',
        title: 'Language Examples',
        description: 'Examples by code language.',
        additionalProperties: me.shortString({ description: 'Example value for the argument.' }),
        format: 'code-languages-object',
        default: { javascript: '', python: '' }
      },
      me.shortString({ title: 'Example', description: 'Example value for the argument.' })
    ]
  },
  description: {
    oneOf: [
      {
        type: 'object',
        title: 'Language Descriptions',
        description: 'Example argument descriptions by code language.',
        additionalProperties: { type: 'string', description: 'Description of the argument.', maxLength: 1000 },
        format: 'code-languages-object',
        default: { javascript: '', python: '' }
      },
      { title: 'Description', type: 'string', description: 'Description of the argument.', maxLength: 1000 }
    ]
  },
  default: {
    title: 'Default',
    description: 'Default value of the argument. (Your code should set this.)',
    default: null
  }
}
)

me.codeSnippet = me.object({ description: 'A language-specific code snippet' }, {
  code: { type: 'string', format: 'code', title: 'Snippet', default: '', description: 'Code snippet. Use ${1:defaultValue} syntax to add flexible arguments' }, // eslint-disable-line no-template-curly-in-string
  tab: { type: 'string', title: 'Tab Trigger', description: 'Tab completion text. Will be expanded to the snippet if typed and hit tab.' }
})

me.PropertyDocumentationSchema = me.object({
  title: 'Property Documentation',
  description: 'Documentation entry for a property this Component will add to its Thang which other Components might want to also use.',
  default: {
    name: 'foo',
    type: 'object',
    description: 'The `foo` property can satisfy all the #{spriteName}\'s foobar needs. Use it wisely.'
  },
  required: ['name', 'type', 'description']
}, {
  name: { type: 'string', title: 'Name', description: 'Name of the property.' },
  i18n: { type: 'object', format: 'i18n', props: ['name', 'shortDescription', 'description', 'context'], description: 'Help translate this property' },
  context: {
    type: 'object',
    title: 'Example template context',
    additionalProperties: { type: 'string' }
  },
  codeLanguages: me.array({ title: 'Specific Code Languages', description: 'If present, then only the languages specified will show this documentation. Leave unset for language-independent documentation.', format: 'code-languages-array' }, me.shortString({ title: 'Code Language', description: 'A specific code language to show this documentation for.', format: 'code-language' })),
  // not actual JS types, just whatever they describe...
  type: me.shortString({ title: 'Type', description: 'Intended type of the property.' }),
  shortDescription: {
    oneOf: [
      { title: 'Short Description', type: 'string', description: 'Short Description of the property.', maxLength: 1000, format: 'markdown' },
      {
        type: 'object',
        title: 'Language Descriptions (short)',
        description: 'Property short-descriptions by code language.',
        additionalProperties: { type: 'string', description: 'Short Description of the property.', maxLength: 1000, format: 'markdown' },
        format: 'code-languages-object',
        default: { javascript: '' }
      }
    ]
  },
  description: {
    oneOf: [
      { title: 'Description', type: 'string', description: 'Description of the property.', maxLength: 1000, format: 'markdown' },
      {
        type: 'object',
        title: 'Language Descriptions',
        description: 'Property descriptions by code language.',
        additionalProperties: { type: 'string', description: 'Description of the property.', maxLength: 1000, format: 'markdown' },
        format: 'code-languages-object',
        default: { javascript: '' }
      }
    ]
  },
  args: me.array({ title: 'Arguments', description: 'If this property has type "function", then provide documentation for any function arguments.' }, me.FunctionArgumentSchema),
  owner: { title: 'Owner', type: 'string', description: 'Owner of the property, like "this" or "Math".' },
  example: {
    oneOf: [
      {
        type: 'object',
        title: 'Language Examples',
        description: 'Examples by code language.',
        additionalProperties: { type: 'string', description: 'An example code block.', format: 'code' },
        format: 'code-languages-object',
        default: { javascript: '' }
      },
      { title: 'Example', type: 'string', description: 'An optional example code block.', format: 'javascript' }
    ]
  },
  snippets: { type: 'object', title: 'Snippets', description: 'List of snippets for the respective programming languages', additionalProperties: me.codeSnippet, format: 'code-languages-object' },
  returns: me.object({
    title: 'Return Value',
    description: 'Optional documentation of any return value.',
    required: ['type'],
    default: { type: 'null' }
  }, {
    type: me.shortString({ title: 'Type', description: 'Type of the return value' }),
    example: {
      oneOf: [
        {
          type: 'object',
          title: 'Language Examples',
          description: 'Example return values by code language.',
          additionalProperties: me.shortString({ description: 'Example return value.', format: 'code' }),
          format: 'code-languages-object',
          default: { javascript: '' }
        },
        me.shortString({ title: 'Example', description: 'Example return value' })
      ]
    },
    description: {
      oneOf: [
        {
          type: 'object',
          title: 'Language Descriptions',
          description: 'Example return values by code language.',
          additionalProperties: { type: 'string', description: 'Description of the return value.', maxLength: 1000 },
          format: 'code-languages-object',
          default: { javascript: '' }
        },
        { title: 'Description', type: 'string', description: 'Description of the return value.', maxLength: 1000 }
      ]
    },
    i18n: { type: 'object', format: 'i18n', props: ['description'], description: 'Help translate this return value' }
  }),
  autoCompletePriority: {
    type: 'number',
    title: 'Autocomplete Priority',
    description: 'How important this property is to autocomplete.',
    minimum: 0,
    default: 1.0
  },
  userShouldCaptureReturn: {
    type: 'object',
    title: 'User Should Capture Return',
    properties: {
      variableName: {
        type: 'string',
        title: 'Variable Name',
        description: 'Variable name this property is autocompleted into.',
        default: 'result'
      },
      type: {
        type: 'object',
        title: 'Variable Type',
        description: 'Variable return types by code language. Can usually leave blank. Fill in if it is a primitive type and not auto in C++.',
        additionalProperties: { type: 'string', description: 'Description of the return value.', maxLength: 1000 },
        format: 'code-languages-object',
        default: { cpp: 'auto' }
      }
    }
  }
})

me.activity = me.object({ description: 'Stats on an activity' }, {
  first: me.date(),
  last: me.date(),
  count: { type: 'integer', minimum: 0 }
})

me.terrainString = me.shortString({ enum: ['Grass', 'Dungeon', 'Indoor', 'Desert', 'Mountain', 'Glacier', 'Volcano'], title: 'Terrain', description: 'Which terrain type this is.', inEditor: 'codecombat' })

me.HeroConfigSchema = me.object({ description: 'Which hero the player is using, equipped with what inventory.' }, {
  inventory: {
    type: 'object',
    description: 'The inventory of the hero: slots to item ThangTypes.',
    additionalProperties: me.objectId({ description: 'An item ThangType.' })
  },
  thangType: me.objectId({ links: [{ rel: 'db', href: '/db/thang.type/{($)}/version' }], title: 'Thang Type', description: 'The ThangType of the hero.', format: 'thang-type' })
}
)

me.RewardSchema = function (descriptionFragment) {
  if (descriptionFragment == null) { descriptionFragment = 'earned by achievements' }
  return {
    type: 'object',
    additionalProperties: false,
    description: `Rewards ${descriptionFragment}.`,
    properties: {
      heroes: me.array({ uniqueItems: true, description: `Heroes ${descriptionFragment}.` },
        me.stringID({ links: [{ rel: 'db', href: '/db/thang.type/{($)}/version' }], title: 'Hero ThangType', description: 'A reference to the earned hero ThangType.', format: 'thang-type' })),
      items: me.array({ uniqueItems: true, description: `Items ${descriptionFragment}.` },
        me.stringID({ links: [{ rel: 'db', href: '/db/thang.type/{($)}/version' }], title: 'Item ThangType', description: 'A reference to the earned item ThangType.', format: 'thang-type' })),
      levels: me.array({ uniqueItems: true, description: `Levels ${descriptionFragment}.` },
        me.stringID({ links: [{ rel: 'db', href: '/db/level/{($)}/version' }], title: 'Level', description: 'A reference to the earned Level.', format: 'latest-version-original-reference' })),
      gems: me.float({ description: `Gems ${descriptionFragment}.` })
    }
  }
}

me.task = me.object({ title: 'Task', description: 'A task to be completed', format: 'task', default: { name: 'TODO', complete: false } }, {
  name: { title: 'Name', description: 'What must be done?', type: 'string' },
  complete: { title: 'Complete', description: 'Whether this task is done.', type: 'boolean', format: 'checkbox' }
})

me.concept = { type: 'string', format: 'concept' }

me.scoreType = me.shortString({ title: 'Score Type', enum: ['time', 'damage-taken', 'damage-dealt', 'gold-collected', 'difficulty', 'code-length', 'survival-time', 'defeated'] }) // TODO: total gear value.

// Valid Teacher Dashboard resource icons
me.resourceIcons = ['PDF', 'Spreadsheet', 'Doc', 'FAQ', 'Slides', 'Solutions', 'Video', 'Audio']

me.voiceOver = {
  oneOf: [
    me.sound(),
    me.object({
      title: 'Hero VO',
      description: 'This voice over is spoken by the hero',
      required: ['female', 'male']
    }, {
      female: me.sound(),
      male: me.sound()
    })
  ]
}

me.product = { type: 'string', title: 'Product', description: 'Which product this document is for (codecombat, ozaria, or both)', enum: ['codecombat', 'ozaria', 'both'], default: 'both' } // Older version; for differentiating between codecombat.com and ozaria.com and separate databases (like a ResourceHubResource)
me.singleProduct = { type: 'string', title: 'Product', description: 'Which product this document is for (codecombat, ozaria, or codecombat-junior)', enum: ['codecombat', 'ozaria', 'codecombat-junior'], default: 'codecombat' } // Newer version: for when this document is specific to a single product (like a Level)

me.InlineInteractionSchema = me.object({ description: 'An inline interaction', definitions: {}, required: ['type', 'actor'], additionalProperties: true }, {
  type: { type: 'string', enum: ['model-response', 'prompt-quiz', 'free-chat', 'chat-message', 'load-document'] },
  actor: { type: 'string', enum: ['user', 'model', 'teacher', 'system'], description: 'Who is performing this interaction' },
  teacherDialogue: { $ref: '#/definitions/teacherDialogue' },
  repeat: { oneOf: [{ type: 'boolean' }, { type: 'integer', minimum: 1 }] }, // Could also do like script system: enum: [true, false, 'session']
  condition: { type: 'object', description: 'TODO' }
}) // TODO: Think about pulling logic from ScriptSchema eventPrereqs, scriptPrereqs, notAfter
// delay, duration, etc. could be brought in, too

me.InlineInteractionSchema.definitions.teacherDialogue = me.object({ required: ['text'] }, {
  text: { type: 'string', format: 'markdown' },
  actions: me.array({},
    me.shortString({}))
})

const ModelResponseInteractionSchema = me.object(({ title: 'Model Response', required: [], default: { type: 'model-response', actor: 'model' } }), {
  type: { type: 'string', const: 'model-response' },
  actor: { type: 'string', const: 'model' },
  interaction: me.objectId({ links: [{ rel: 'db', href: '/db/ai_interaction/{($)}' }] })
})

const PromptQuizInteractionSchema = me.object({ title: 'Prompt Quiz', required: ['content'], default: { type: 'prompt-quiz', actor: 'user', content: {} } }, {
  type: { type: 'string', const: 'prompt-quiz' },
  actor: { type: 'string', const: 'user' },
  content: me.object({ required: ['choices'], default: { choices: [] } }, {
    choices: me.array({},
      me.object({ required: ['text'] }, {
        text: { type: 'string' },
        isCorrect: { type: 'boolean' },
        teacherDialogue: { $ref: '#/definitions/teacherDialogue' },
        resultingInteraction: me.objectId({ links: [{ rel: 'db', href: '/db/ai_interaction/{($)}' }] })
      }))
  })
})

const FreeChatInteractionSchema = me.object({ title: 'Free Chat', default: { type: 'free-chat', actor: 'user', content: { text: '' } } }, {
  type: { type: 'string', const: 'free-chat' },
  actor: { type: 'string', const: 'user' },
  content: me.object({},
    { text: { type: 'string', format: 'markdown' } })
})

const ChatMessageInteractionSchema = me.object({ title: 'Chat Message', default: { type: 'chat-message', actor: 'model', content: { text: '' } } }, {
  type: { type: 'string', const: 'chat-message' },
  content: me.object({},
    { text: { type: 'string', format: 'markdown' } })
})

const LoadDocumentInteractionSchema = me.object({ title: 'Load Document', default: { type: 'load-document', actor: 'user', content: {} } }, {
  type: { type: 'string', const: 'load-document' },
  content: me.object({},
    { document: me.objectId({ links: [{ rel: 'db', href: '/db/ai_document/{($)}' }] }) })
}
)

me.InlineInteractionSchema.oneOf = [
  ModelResponseInteractionSchema,
  PromptQuizInteractionSchema,
  FreeChatInteractionSchema,
  ChatMessageInteractionSchema,
  LoadDocumentInteractionSchema
]

// TODO: Treema doesn't really understand this, maybe worth updating Treema, tweaking things until it's less confusing to Treema, or doing in a less `oneOf` way

me.InteractionArraySchema = description => ({
  type: 'array',
  description,
  items: me.InlineInteractionSchema
})
