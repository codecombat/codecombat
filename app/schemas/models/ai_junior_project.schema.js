const _ = require('lodash')
const c = require('./../schemas')

const AIJuniorProjectSchema = c.object({
  title: 'AI Junior Project',
  description: 'A generative AI project for AI HackStack Junior',
  required: ['user', 'scenario'],
})

_.extend(AIJuniorProjectSchema.properties, {
  user: {
    title: 'User',
    type: ['object', 'string'],
    description: 'The user ID of the project owner',
    links: [{ rel: 'db', href: '/db/user/{($)}' }],
  },
  scenario: {
    title: 'Scenario',
    type: ['object', 'string'],
    description: 'The scenario ID of the project',
    links: [{ rel: 'db', href: '/db/ai_junior_scenario/{($)}' }],
  },
  classroom: {
    title: 'Classroom',
    type: ['object', 'string'],
    description: 'The classroom ID of the classroom, if any',
    links: [{ rel: 'db', href: '/db/classroom/{{$}}' }],
  },
  inputValues: {
    title: 'Input Values',
    description: 'The images, choices, text, etc. the user has made, by input field id',
    type: 'object',
    additionalProperties: {
      oneOf: [
        { title: 'Value', type: 'string', maxLength: 30 },
        { title: 'Choices', type: 'array', items: { type: 'string' } },
        { title: 'Image', type: 'string', format: 'image-file', minLength: 31 },
      ]
    }
  },
  promptsResponses: c.array({
    title: 'Prompt Responses',
    description: 'The text and file responses received from the AI models',
  }, c.object({}, {
    promptId: c.shortString(),
    text: { type: 'string' },
    image: { type: 'string', format: 'image-file' },
    startDate: c.date({ title: 'Start Date', description: 'The time the message started being sent' }),
    endDate: c.date({ title: 'End Date', description: 'The time the message finished being sent' }),
  })),
  spokenLanguage: {
    type: 'string',
    title: 'Spoken Language',
    description: 'The spoken language of the player, when this project was made'
  },
})

c.extendBasicProperties(AIJuniorProjectSchema, 'ai_junior_project')
c.extendPermissionsProperties(AIJuniorProjectSchema, 'ai_junior_project')

module.exports = AIJuniorProjectSchema
