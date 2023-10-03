const c = require('./../schemas')

const UserCreditSchema = c.object({
  title: 'User Credits',
  description: 'User credits to use prompts, level chat etc features',
  properties: {
    userId: c.objectId({
      links:
        [
          {
            rel: 'extra',
            href: '/db/user/{($)}'
          }
        ]
    }),
    credits: c.array({
      title: 'Credit by different types like hackstack, level_chat' // making it an array of objects so that we can field like endDate in future if needed
    }, c.object({
      title: 'Single credit type with its value'
    }, {
      key: c.shortString({
        title: 'Credit type: level_chat, hackstack'
      }),
      value: c.int({
        title: 'Number of credits available to use'
      })
    })),
    history: c.array(
      {
        title: 'History of credit transactions'
      },
      c.object(
        {
          title: 'Credit transaction'
        }, {
          operation: c.shortString({
            enum: ['add', 'sub']
          }),
          credit: c.object({
            title: 'Type and value of credit'
          }, {
            type: c.shortString(),
            value: c.int()
          }),
          transactionDate: c.date(),
          source: c.object({
            title: 'source of transaction'
          }, {
            info: c.shortString({
              enum: ['webhook', 'admin']
            }),
            id: c.shortString({
              title: 'objectid in case of webhook or any unique string to stop double credits'
            })
          })
        }
      )
    )
  }
})

UserCreditSchema.required = ['userId', 'credits']

module.exports = UserCreditSchema
