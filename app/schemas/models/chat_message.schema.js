const c = require('./../schemas')
const _ = require('lodash')

const ChatMessageSchema = c.object({
  title: 'ChatMessage',
  description: 'A chat message sent by a player, teacher, or AI chatbot to help the player during a level',
  required: ['product', 'kind'], // TOOD: more required fields
  default: {
    product: 'both',
    kind: 'level-chat',
    releasePhase: 'beta'
  }
})

const SenderSchema = c.object({ title: 'Sender', description: 'Who/what sent this message (bot, player, teacher)' }, {
  id: c.objectId({
    links: [{ rel: 'db', href: '/db/user/{($)}' }],
    title: 'User ID',
    description: 'The user ID of the sender'
  }),
  name: {
    type: 'string',
    title: 'Name',
    description: 'Which bot/user sent this message'
  },
  kind: {
    type: 'string',
    enum: ['player', 'teacher', 'bot'],
    title: 'Kind',
    description: 'which kind of sender this is'
  },
  i18n: {
    additionalProperties: true,
    type: 'object',
    format: 'i18n',
    props: ['name'],
    description: 'Translations for the sender name'
  }
})

const ResponseSchema = c.object({ title: 'Message', description: 'A message from the player or the bot' }, {
  text: { type: 'string', title: 'Text', format: 'markdown' },
  sender: SenderSchema,
  startDate: c.date({ title: 'Start Date', description: 'The time the message started being sent' }),
  endDate: c.date({ title: 'End Date', description: 'The time the message finished being sent' }),
  messageId: c.objectId({ title: 'Message ID', description: 'The ID of the message' }),
  textComponents: c.object({ title: 'Text Components', description: 'Structured message components' }, {
    // Structured message fields
    // - normal conversational response (“Hello! Need any help?“, “Sorry, I can’t answer that”)
    // - line-marked code issue summary (“Line 6: change `hero.moveright[)` to `hero.moveRight()`.“)
    // - simple code issue explanation (“You use parentheses `()` to call methods, not brackets `[]`.“)
    // - action button (<button>Fix It</button>, <button>Reformat</button>)
    // - full code that goes along with the response/action button
    // - links/popovers with more info on specific coding concepts
    // - other stuff I haven’t thought of yet
    freeText: { type: 'string', title: 'Free Text', format: 'markdown' },
    codeIssue: c.object({ title: 'Code Issue', description: 'Text describing current code line' }, {
      line: { type: 'integer', title: 'Line' },
      text: { type: 'string', title: 'Text', format: 'markdown' }
    }),
    codeIssueExplanation: c.object({ title: 'Code Issue Explanation', description: 'Text explaining the code issue' }, {
      text: { type: 'string', title: 'Text', format: 'markdown' }
    }),
    actionButtons: c.array({ title: 'Action Buttons', description: 'Buttons that can be clicked to perform an action' }, {
      type: 'object',
      properties: {
        text: { type: 'string', title: 'Text' },
        action: { type: 'string', title: 'Action' }
      }
    }),
    code: { type: 'string', title: 'Code', format: 'code' },
    links: c.array({ title: 'Links', description: 'Links to more information' }, {
      type: 'object',
      properties: {
        // TODO: should this be popover info or article references instead of just links?
        text: { type: 'string', title: 'Text' },
        url: { type: 'string', title: 'URL' },
        i18n: {
          additionalProperties: true,
          type: 'object',
          format: 'i18n',
          props: ['text', 'url'],
          description: 'Translations for the link text and URL'
        }
      }
    })
  }),
  i18n: {
    additionalProperties: true,
    type: 'object',
    format: 'i18n',
    props: ['text'],
    description: 'Translations for the message text'
  }
})

_.extend(ChatMessageSchema.properties, {
  product: {
    type: 'string',
    enum: ['ozaria', 'codecombat', 'both'],
    title: 'Product',
    description: 'Which product(s) this message is for'
  },
  kind: {
    type: 'string',
    enum: ['level-chat'],
    title: 'Kind',
    description: '`level-chat`: for in-level chatbot messages. More kinds to be added in the future.'
  },
  example: {
    type: 'boolean',
    title: 'Example',
    description: 'Whether this is an example message or not. Example messages are not shown to users, but used in training.'
  },
  releasePhase: {
    type: 'string',
    enum: ['beta', 'released'],
    title: 'Release Phase',
    description: 'Example messages start off in beta, then are released when they are completed'
  },
  message: ResponseSchema,
  context: c.object({ title: 'Context', description: 'Contextual state when this message triggered' }, {
    codeLanguage: {
      type: 'string',
      title: 'Code Language',
      description: 'The programming language of the player'
    },
    spokenLanguage: {
      type: 'string',
      title: 'Spoken Language',
      description: 'The spoken language of the player'
    },
    player: c.objectId({
      links: [{ rel: 'db', href: '/db/user/{($)}' }],
      title: 'Player',
      description: 'The user ID of the player'
    }),
    playerName: {
      type: 'string',
      title: 'Player Name',
      description: 'The broad name of the player, by which the bot knows them'
    },
    levelOriginal: c.objectId({
      links: [{ rel: 'db', href: '/db/level/{($)}/version' }],
      format: 'latest-version-original-reference',
      title: 'Level',
      description: 'The level original ID of the level the player is on'
    }),
    levelName: {
      type: 'string',
      title: 'Level Name',
      description: 'The name of the level the player is on'
    },
    apiProperties: {
      type: 'array',
      title: 'API Properties',
      description: 'The APIs the player has access to in this level',
      items: c.PropertyDocumentationSchema
    },
    i18n: {
      additionalProperties: true,
      type: 'object',
      format: 'i18n',
      props: ['levelName'],
      description: 'Translations for the context fields, like `levelName`'
    },
    code: c.object({ title: 'Code', description: 'Start, solution, and current code' }, {
      start: {
        format: 'code-languages-object',
        type: 'object',
        title: 'Start Code by Language',
        description: 'The start code for the level, by programming language',
        additionalProperties: {
          type: 'string',
          format: 'code',
          description: 'Start code for this programming language'
        }
      },
      solution: {
        format: 'code-languages-object',
        type: 'object',
        title: 'Solution Code by Language',
        description: 'The solution code for the level, by programming language',
        additionalProperties: {
          type: 'string',
          format: 'code',
          description: 'Solution code for this programming language'
        }
      },
      current: {
        format: 'code-languages-object',
        type: 'object',
        title: 'Current Code by Language',
        description: 'The current code for the player, by programming language',
        additionalProperties: {
          type: 'string',
          format: 'code',
          description: 'Current code for this programming language'
        }
      },
      fixed: {
        format: 'code-languages-object',
        type: 'object',
        title: 'Fixed Code by Language',
        description: 'The fixed code for the player after the suggested single change, by programming language',
        additionalProperties: {
          type: 'string',
          format: 'code',
          description: 'Fixed code for this programming language after the suggested single change'
        }
      }
    }),
    codeComments: c.object({ title: 'Code Comments', description: 'Code comment translation strings' }, {
      context: {
        additionalProperties: {
          type: 'string'
        },
        type: 'object',
        title: 'Code Comments Context'
      },
      i18n: {
        additionalProperties: true,
        type: 'object',
        format: 'i18n',
        props: ['context'],
        description: 'Translations for the start code comments'
      }
    }),
    error: c.object({ title: 'Error', description: 'Current error player is experiencing' }, {
      codeSnippet: { type: 'string', title: 'Code Snippet', description: 'The code snippet that caused the error' },
      hint: { type: 'string', title: 'Error Hint' },
      id: { type: 'string', title: 'Error ID' },
      errorCode: { type: 'string', title: 'Error Code' },
      level: { type: 'string', title: 'Error Level' },
      message: { type: 'string', title: 'Error Message' },
      messageNoLineInfo: { type: 'string', title: 'Error Message No Line Info' },
      range: { type: 'array', title: 'Error Range', items: { type: 'object' } },
      type: { type: 'string', title: 'Error Type' },
      i18nParams: {
        additionalProperties: true,
        type: 'object',
        title: 'Error Translation Parameters',
        description: 'Parameters to be used in translating the error message (passed from Esper.js)'
      }
    }),
    goalStates: {
      type: 'object',
      title: 'Goal States',
      description: 'The current state of the goals for the level',
      additionalProperties: c.object({ title: 'Goal State', description: 'The current state for a goal in the level' }, {
        name: { type: 'string', title: 'Name' },
        status: { type: 'string', title: 'Status', enum: ['success', 'incomplete', 'failure'] },
        i18n: {
          additionalProperties: true,
          type: 'object',
          format: 'i18n',
          props: ['name'],
          description: 'Translations for the goal name'
        }
      })
    },
    previousMessages: {
      type: 'array',
      title: 'Previous Messages',
      description: 'The messages that been sent so far in this session',
      items: ResponseSchema
    }
  })
})

ChatMessageSchema.definitions = {}
c.extendBasicProperties(ChatMessageSchema, 'chat_message')
c.extendPermissionsProperties(ChatMessageSchema, 'chat_message')
c.extendTranslationCoverageProperties(ChatMessageSchema)

module.exports = ChatMessageSchema
