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
    archived: { type: 'boolean', title: 'Archived', description: 'Whether the exam has been archived' },
    extraDuration: { type: 'number', title: 'Extra Duration', description: 'Add extra time for the user in minutes' },
    duration: { type: 'number', title: 'Duration', description: 'Limited duration of the exam in minutes, optional' },
    classroomId: c.objectId({ title: 'Classroom Id' }),
  },
})

c.extendBasicProperties(UserExamSchema, 'user.exam')
module.exports = UserExamSchema
