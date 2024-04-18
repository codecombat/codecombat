const schema = require('../schemas')

const OnlineTeacherSchema = schema.object(
  {
    title: 'Online Class Teachers',
    required: ['userId'],
  },
  {
    name: { type: 'string', description: 'Teacher Name' },
    email: { type: 'string', description: 'Teacher Email' },
    userId: schema.objectId({ description: '_id of the teacher' }),
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
    }
  }
)

module.exports = OnlineTeacherSchema