c = require './../schemas'

UserCodeProblemSchema = c.object {
  title: 'User Code Problem'
  description: 'Data for a problem in user code.'
}

_.extend UserCodeProblemSchema.properties,
  creator: c.objectId(links: [{rel: 'extra', href: '/db/user/{($)}'}])
  created: c.date({title: 'Created', readOnly: true})

  code: {type: 'string'}
  codeSnippet: {type: 'string'}
  errHint: {type: 'string'}
  errId: {type: 'string'}
  errLevel: {type: 'string'}
  errMessage: {type: 'string'}
  errMessageNoLineInfo: {type: 'string'}
  errRange: {type: 'array'}
  errType: {type: 'string'}
  language: {type: 'string'}
  levelID: {type: 'string'}

c.extendBasicProperties UserCodeProblemSchema, 'user.code.problem'

module.exports = UserCodeProblemSchema
