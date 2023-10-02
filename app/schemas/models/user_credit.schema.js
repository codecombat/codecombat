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
    credits: c.int(),
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
          credit: c.int(),
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
