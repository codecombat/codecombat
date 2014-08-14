c = require './../schemas'

UserCodeProblemSchema = c.object {
  title: 'User Code Problem'
  description: 'Data for a problem in user code.'
}

_.extend UserCodeProblemSchema.properties,
  creator: c.objectId(links: [{rel: 'extra', href: '/db/user/{($)}'}])
  created: c.date({title: 'Created', readOnly: true})

  code: String
  codeSnippet: String
  errHint: String
  errId: String
  errLevel: String
  errMessage: String
  errRange: []
  errType: String
  language: String
  levelID: String

c.extendBasicProperties UserCodeProblemSchema, 'user.code.problem'

module.exports = UserCodeProblemSchema
