const schema = require('../schemas')

const OnlineTeacherSchema = schema.object(
  {
    title: 'Info of Online Class Teachers',
    required: ['userId'],
  },
  {
    name: { type: 'string', description: 'Teacher Name' },
    email: { type: 'string', description: 'Teacher Email' },
    userId: schema.objectId({ description: '_id of the teacher' }),
    languages: {
      type: 'array',
      description: 'Languages the teacher can speak',
      items: {
        type: 'string'
      }
    },
    levels: {
      type: 'array',
      description: 'Levels the teacher can teach, 0 for beginners, 1 for intermediate, 2 for advanced',
      items: {
        type: 'number',
      },
    },
    products: {
      type: 'array',
      description: 'Products the teacher can teach',
      items: {
        type: 'string',
        enum: ['CodeCombat', 'Ozaria', 'E-sports', 'Roblox', 'APCSP']
      }
    },
    codeLanguages: {
      type: 'array',
      description: 'Code languages the teacher can teach',
      items: {
        type: 'string',
        enum: ['python', 'javascript', 'html', 'css', 'lua', 'java', 'cpp', 'coffeescript']
      }
    },
    trialsOnly: {
      type: 'boolean',
    },
    schedule: {
      type: 'array',
      description: 'Teacher schedule',
      items: {
        type: 'object',
        properties: {
          day: {
            type: 'string',
            enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
          },
          timeStart: {
            type: 'string',
            description: 'Time in 24 hour format',
            pattern: '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
          },
          timeEnd: {
            type: 'string',
            description: 'Time in 24 hour format',
            pattern: '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
          }
        }
      }
    }
  }
)

module.exports = OnlineTeacherSchema