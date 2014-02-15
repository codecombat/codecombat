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
    format = (s) -> s?.replace("\n", "<br>").replace('<', '&lt;').replace('>', '&gt;')
    context.message = format @problem.aetherProblem.message
    context.hint = format @problem.aetherProblem.hint
    context

  afterRender: ->
    super()
    @$el.addClass('alert').addClass("alert-#{@problem.aetherProblem.level}")

  onRemoveClicked: ->
    @$el.remove()
    @destroy()
    #@problem.destroy()  # let's try leaving the annotations / marker ranges alone
