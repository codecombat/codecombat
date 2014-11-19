CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/problem_alert'
{me} = require 'lib/auth'

module.exports = class ProblemAlertView extends CocoView
  id: 'problem-alert-view'
  className: 'problem-alert'
  template: template

  subscriptions:
    'tome:show-problem-alert': 'onShowProblemAlert'
    'tome:hide-problem-alert': 'onHideProblemAlert'
    'level:restart': 'onHideProblemAlert'
    'tome:jiggle-problem-alert': 'onJiggleProblemAlert'
    'tome:manual-cast': 'onHideProblemAlert'
    'real-time-multiplayer:manual-cast': 'onHideProblemAlert'

  events:
    'click .close': 'onRemoveClicked'

  constructor: (options) ->
    super options
    if options.problem?
      @problem = options.problem
      @onWindowResize()
    else
      @$el.hide()
    $(window).on 'resize', @onWindowResize

  destroy: ->
    $(window).off 'resize', @onWindowResize
    super()

  getRenderData: (context={}) ->
    context = super context
    if @problem?
      format = (s) -> marked(s.replace(/</g, '&lt;').replace(/>/g, '&gt;')) if s?
      context.message = format @problem.aetherProblem.message
      context.hint = format @problem.aetherProblem.hint
    context

  afterRender: ->
    super()
    if @problem?
      @$el.addClass('alert').addClass("alert-#{@problem.aetherProblem.level}").hide().fadeIn('slow')
      @$el.addClass('no-hint') unless @problem.aetherProblem.hint
      Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'error_appear', volume: 1.0

  onShowProblemAlert: (data) ->
    return unless $('#code-area').is(":visible")
    if @problem?
      if @$el.hasClass "alert-#{@problem.aetherProblem.level}"
        @$el.removeClass "alert-#{@problem.aetherProblem.level}"
      if @$el.hasClass "no-hint"
        @$el.removeClass "no-hint"
    @problem = data.problem
    @lineOffsetPx = data.lineOffsetPx or 0
    @$el.show()
    @onWindowResize()
    @render()
    @onJiggleProblemAlert()

  onJiggleProblemAlert: ->
    return unless @problem?
    @$el.show() unless @$el.is(":visible")
    @$el.addClass 'jiggling'
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'error_appear', volume: 1.0
    pauseJiggle = =>
      @$el?.removeClass 'jiggling'
    _.delay pauseJiggle, 2000

  onHideProblemAlert: ->
    @onRemoveClicked()

  onRemoveClicked: ->
    @$el.hide()

  onWindowResize: (e) =>
    # TODO: This all seems a little hacky
    if @problem?
      @$el.css('left', $('#goals-view').outerWidth(true) + 'px')
      @$el.css('right', $('#code-area').outerWidth(true) + 'px')

      # 110px from top roughly aligns top of alert with top of first code line
      # TODO: calculate this in a more dynamic, less sketchy way
      @$el.css('top', (110 + @lineOffsetPx) + 'px')
