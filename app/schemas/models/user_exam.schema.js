const c = require('./../schemas')

const UserExamSchema = c.object({
  title: 'UserExam',
  description: 'Relationship between users and exams, one to many',
  properties: {
    userId: c.objectId({ title: 'User Id' }),
    examId: c.objectId({ title: 'Exam Id' }),
    codeLanguage: {
      type: 'string',
      enum: ['python', 'javascript'],
    },
    startDate: c.stringDate(),
    endDate: c.stringDate(),
    submitted: { type: 'boolean', title: 'Submitted', description: 'Whether the user has submitted/completed the exam' },
  },
})

c.extendBasicProperties(UserExamSchema, 'user.exam')
module.exports = UserExamSchema
