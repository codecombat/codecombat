const c = require('./../schemas')

const ExamSchema = c.object({
  title: 'Exam',
  description: 'CodeCombat exam with limited levels and complete time',
})

_.extend(ExamSchema.properties, {
  title: {
    type: 'string',
    description: 'Title of the exam',
  },
  description: {
    type: 'string',
    description: 'Description of the exam',
  },
  clan: c.objectId({ links: [{ rel: 'db', href: '/db/clan/{($)}' }], description: 'Classroom auto clan, since students need a classroom to play the level, but clan is easy for permission checking' }),
  startDate: c.stringDate(),
  endDate: c.stringDate(),
  duration: {
    type: 'number',
    description: 'Duration of the exam in minutes',
  },
  problems: {
    type: 'array',
    description: 'Problems that are included in the exam',
    items: {
      type: 'object',
      title: 'ExamProblemCourse',
      description: 'by course, includes instanceId and level slugs',
      properties: {
        courseId: {
          type: 'string',
          description: 'ID of the course',
        },
        instanceId: {
          type: 'string',
          description: 'ID of the course instance',
        },
        levels: {
          type: 'array',
          description: 'Levels that are included in the exam',
          items: c.object({
            title: 'ExamProblemLevel',
            description: 'Level that is included in the exam',
            slug: {
              type: 'string',
              description: 'Slug of the level',
            },
            point: {
              type: 'number',
              description: 'If set, the point of the level',
            },
          }),
        },
      },
    },
  },
})

c.extendBasicProperties(ExamSchema, 'exam')
module.exports = ExamSchema