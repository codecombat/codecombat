const c = require('./../schemas')

const ClassroomStatsSchema = c.object({
  title: 'ClassroomStats',
  description: 'The stats of a classroom which uses in outcome-reports.',
})

_.extend(ClassroomStatsSchema.properties, {
  classroom: c.objectId(),
  course: c.array({
    title: 'Course',
    description: 'The course set of the classroom.',
    items: c.objectId()
  }),
  date: c.stringDate({ description: 'the daily date of the stats' }),
  membersWithCode: c.array({
    title: 'Members with code',
    description: 'The members set who have submitted code.',
    items: c.objectId()
  }),
  programs: {
    type: 'number',
    description: 'the number of programs(level.sessions) submitted on this day for a course'
  },
  playtime: {
    type: 'number',
    description: 'The total play time on this day for a course'
  },
  projects: {
    type: 'number',
    description: 'The project number on this day for a course'
  },
  linesOfCode: {
    type: 'number',
    description: 'The lines of code on this day for a course'
  },
  language: {
    type: 'string',
    enum: ['cpp', 'python', 'javascript', 'java']
  }
})

c.extendBasicProperties(ClassroomStatsSchema, 'classroom.stats')
module.exports = ClassroomStatsSchema
