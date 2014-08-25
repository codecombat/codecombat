UserCodeProblem = require './UserCodeProblem'
Handler = require '../commons/Handler'

class UserCodeProblemHandler extends Handler
  modelClass: UserCodeProblem
  jsonSchema: require '../../app/schemas/models/user_code_problem'
  editableProperties: [
    'code'
    'codeSnippet'
    'errHint'
    'errId'
    'errLevel'
    'errMessage'
    'errRange'
    'errType'
    'language'
    'levelID'
  ]

  makeNewInstance: (req) ->
    ucp = super(req)
    ucp.set('creator', req.user._id)
    ucp

module.exports = new UserCodeProblemHandler()
