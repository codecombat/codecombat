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
          transactionDate: c.date()
        }
      )
    )
  }
})

UserCreditSchema.required = ['userId']

module.exports = UserCreditSchema
