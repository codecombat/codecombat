View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/problem_alert'
{me} = require 'lib/auth'

module.exports = class ProblemAlertView extends View
  className: 'problem-alert'
  template: template

  subscriptions: {}

  events:
    "click .close": "onRemoveClicked"

  constructor: (options) ->
    super options
    @problem = options.problem

  getRenderData: (context={}) ->
    context = super context
    context.message = @problem.aetherProblem.message.replace("\n", "<br>")
    context.hint = @problem.aetherProblem.hint?.replace("\n", "<br>")
    context

  afterRender: ->
    super()
    @$el.addClass('alert').addClass("alert-#{@problem.aetherProblem.level}")

  onRemoveClicked: ->
    @$el.remove()
    @destroy()
    #@problem.destroy()  # let's try leaving the annotations / marker ranges alone
