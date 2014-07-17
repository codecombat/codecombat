View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/problem_alert'
{me} = require 'lib/auth'

module.exports = class ProblemAlertView extends View
  className: 'problem-alert'
  template: template

  subscriptions: {}

  events:
    'click .close': 'onRemoveClicked'

  constructor: (options) ->
    super options
    @problem = options.problem

  getRenderData: (context={}) ->
    context = super context
    format = (s) -> s?.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\n/g, '<br>')
    message = @problem.aetherProblem.message
    age = @problem.aetherProblem.userInfo?.age
    if age?
      if /^Line \d+:/.test message
        message = message.replace /^(Line \d+)/, "$1, time #{age.toFixed(1)}"
      else
        message = "Time #{age.toFixed(1)}: #{message}"
    context.message = format message
    context.hint = format @problem.aetherProblem.hint
    context

  afterRender: ->
    super()
    @$el.addClass('alert').addClass("alert-#{@problem.aetherProblem.level}").hide().fadeIn('slow')
    Backbone.Mediator.publish 'play-sound', trigger: 'error_appear', volume: 1.0

  onRemoveClicked: ->
    @$el.remove()
    @destroy()
    #@problem.destroy()  # let's try leaving the annotations / marker ranges alone
