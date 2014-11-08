CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/problem_alert'
{me} = require 'lib/auth'

module.exports = class ProblemAlertView extends CocoView
  id: 'problem-alert-view'
  className: 'problem-alert'
  template: template

  subscriptions:
    'tome:show-problem-alert': 'onShowProblemAlert'
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
      format = (s) -> s?.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\n/g, '<br>')
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
    return if @problem? and data.problem.aetherProblem.message is @problem.aetherProblem.message and data.problem.aetherProblem.hint is @problem.aetherProblem.hint
    return unless $('#code-area').is(":visible")
    @problem = data.problem
    @lineOffsetPx = data.lineOffsetPx or 0
    @$el.show()
    @onWindowResize()
    @render()
    @onJiggleProblemAlert()

  onJiggleProblemAlert: ->
    if @$el.is(":visible")
      @$el.css('animation-play-state', 'running')
      @$el.css('-moz-animation-play-state', 'running')
      @$el.css('-webkit-animation-play-state', 'running')
      pauseJiggle = =>
        @$el.css('animation-play-state', 'paused')
        @$el.css('-moz-animation-play-state', 'paused')
        @$el.css('-webkit-animation-play-state', 'paused')
      _.delay pauseJiggle, 2000

  onHideProblemAlert: ->
    @onRemoveClicked()

  onRemoveClicked: ->
    @$el.hide()
    @problem = null

  onWindowResize: (e) => 
    # TODO: This all seems a little hacky
    if @problem?
      @$el.css('left', $('#goals-view').outerWidth(true) + 'px')
      @$el.css('right', $('#code-area').outerWidth(true) + 'px')

      # 45px from top roughly aligns top of alert with top of first code line
      # TODO: calculate this in a more dynamic, less sketchy way
      @$el.css('top', (45 + @lineOffsetPx) + 'px')
