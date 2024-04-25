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
        type: 'string',
        enum: ['English', 'espanol']
      }
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
        type: 'object',
        properties: {
          language: {
            type: 'string',
            enum: ['python', 'javascript', 'html', 'css', 'lua', 'java', 'cpp', 'coffeescript']
          },
          level: {
            type: 'array',
            items: {
              type: 'number',
              description: '0 for beginners, 1 for intermediate, 2 for advanced'
            }
          }
        }
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
          time: {
            type: 'array',
            items: {
              type: 'number',
              description: 'Time in 24 hour format, from 0 to 23, PDT timezone'
            }
          },
        }
      }
    }
  }
)

schema.extendBasicProperties(OnlineTeacherSchema, 'online.teacher')
module.exports = OnlineTeacherSchema