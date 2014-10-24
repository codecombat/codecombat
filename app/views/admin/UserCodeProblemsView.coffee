RootView = require 'views/kinds/RootView'
template = require 'templates/admin/user-code-problems'
UserCodeProblem = require 'models/UserCodeProblem'

module.exports = class UserCodeProblemsView extends RootView
  # TODO: Pagination, choosing filters on the page itself.

  id: 'admin-user-code-problems-view'
  template: template

  constructor: (options) ->
    super options
    @getUserCodeProblems()

  getUserCodeProblems: ->
    # can have this page show arbitrary conditions, see mongoose queries
    # http://mongoosejs.com/docs/queries.html
    # Each list in conditions is a function call.
    # The first arg is the function name
    # The rest are the args for the function

    conditions = [
      ['limit', 1000]
      ['sort', '-created']
    ]
    conditions = $.param({conditions:JSON.stringify(conditions)})
    UserCodeProblemCollection = Backbone.Collection.extend({
      model: UserCodeProblem
      url: '/db/user.code.problem?' + conditions
    })
    @userCodeProblems = new UserCodeProblemCollection()
    @userCodeProblems.fetch()
    @listenTo(@userCodeProblems, 'all', @render)

  getRenderData: ->
    c = super()
    c.userCodeProblems = (problem.attributes for problem in @userCodeProblems.models)
    c
