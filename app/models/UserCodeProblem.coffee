CocoModel = require './CocoModel'

module.exports = class UserCodeProblem extends CocoModel
  @className: 'UserCodeProblem'
  @schema: require 'schemas/models/user_code_problem'
  urlRoot: '/db/user.code.problem'
