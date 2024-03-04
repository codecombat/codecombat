const c = require('./../schemas')

const BackgroundJobSchema = c.object({
  title: 'Background Job',
  description: 'A background job to be run by the server',
  properties: {
    type: {
      type: 'string',
      enum: ['outcome-report'],
      description: 'The type of the job'
    },
    status: {
      type: 'string',
      enum: ['created', 'processing', 'completed', 'failed'],
      description: 'The current status of the job'
    },
    input: { type: 'string', description: 'The data for the job' },
    createdAt: { type: c.date(), description: 'The time the job was created' },
    updatedAt: { type: c.date(), description: 'The time the job last updated' },
    output: { type: 'string', description: 'The final output of the job' },
    userId: c.objectId({
      links:
        [
          {
            rel: 'extra',
            href: '/db/user/{($)}'
          }
        ]
    })
  }
})

BackgroundJobSchema.required = ['type', 'status', 'input', 'userId']

module.exports = BackgroundJobSchema
