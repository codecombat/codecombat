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
    history: c.array(
      {
        title: 'History of transactions'
      },
      c.object(
        {
          title: 'transaction'
        }, {
          action: c.shortString(),
          transactionDate: c.date(),
          uid: c.shortString()
        }
      )
    ),
    extras: c.array(
      {
        title: 'Extra credits'
      },
      c.object(
        {
          title: 'Extra credits'
        }, {
          credits: c.int(),
          endDate: c.date(),
          operation: c.shortString(),
        }
      )
    )
  }
})

UserCreditSchema.required = ['userId']

module.exports = UserCreditSchema
