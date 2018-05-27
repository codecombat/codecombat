require('app/styles/play/level/tome/problem_alert.sass')
CocoView = require 'views/core/CocoView'
GameMenuModal = require 'views/play/menu/GameMenuModal'
template = require 'templates/play/level/tome/problem_alert'
{me} = require 'core/auth'

module.exports = class ProblemAlertView extends CocoView
  id: 'problem-alert-view'
  className: 'problem-alert'
  template: template
  duckImages: [
    '/images/pages/play/duck_alejandro.png'
    '/images/pages/play/duck_anya2.png'
    '/images/pages/play/duck_ida.png'
    '/images/pages/play/duck_okar.png'
    '/images/pages/play/duck_tharin2.png'
  ]

  subscriptions:
    'tome:show-problem-alert': 'onShowProblemAlert'
    'tome:hide-problem-alert': 'onHideProblemAlert'
    'level:restart': 'onHideProblemAlert'
    'tome:jiggle-problem-alert': 'onJiggleProblemAlert'
    'tome:manual-cast': 'onHideProblemAlert'

  events:
    'click .close': 'onRemoveClicked'
    'click': -> Backbone.Mediator.publish 'tome:focus-editor', {}

  constructor: (options) ->
    @supermodel = options.supermodel # Has to go before super so events are hooked up
    super options
    @level = options.level
    @session = options.session
    if options.problem?
      @problem = options.problem
      @onWindowResize()
    else
      @$el.hide()
    @duckImg = _.sample(@duckImages)
    $(window).on 'resize', @onWindowResize

  destroy: ->
    $(window).off 'resize', @onWindowResize
    super()

  afterRender: ->
    super()
    if @problem?
      @$el.addClass('alert').addClass("alert-#{@problem.level}").hide().fadeIn('slow')
      @$el.addClass('no-hint') unless @problem.hint
      @playSound 'error_appear'

  setProblemMessage: ->
    if @problem?
      format = (s) -> marked(s.replace(/</g, '&lt;').replace(/>/g, '&gt;')) if s?
      message = @problem.message
      # Add time to problem message if hint is for a missing null check
      # NOTE: This may need to be updated with Aether error hint changes
      if @problem.hint? and /(?:null|undefined)/.test @problem.hint
        age = @problem.userInfo?.age
        if age?
          if /^Line \d+:/.test message
            message = message.replace /^(Line \d+)/, "$1, time #{age.toFixed(1)}"
          else
            message = "Time #{age.toFixed(1)}: #{message}"
      @message = format message
      @hint = format @problem.hint

  onShowProblemAlert: (data) ->
    return unless $('#code-area').is(":visible") or @level.isType('game-dev')
    if @problem?
      if @$el.hasClass "alert-#{@problem.level}"
        @$el.removeClass "alert-#{@problem.level}"
      if @$el.hasClass "no-hint"
        @$el.removeClass "no-hint"
    @problem = data.problem
    @lineOffsetPx = data.lineOffsetPx or 0
    @$el.show()
    @onWindowResize()
    @setProblemMessage()
    @render()
    @onJiggleProblemAlert()
    application.tracker?.trackEvent 'Show problem alert', {levelID: @level.get('slug'), ls: @session?.get('_id')}

  onJiggleProblemAlert: ->
    return unless @problem?
    @$el.show() unless @$el.is(":visible")
    @$el.addClass 'jiggling'
    @playSound 'error_appear'
    pauseJiggle = =>
      @$el?.removeClass 'jiggling'
    _.delay pauseJiggle, 1000

  onHideProblemAlert: ->
    return unless @$el.is(':visible')
    @onRemoveClicked()

  onRemoveClicked: ->
    @playSound 'menu-button-click'
    @$el.hide()
    Backbone.Mediator.publish 'tome:focus-editor', {}

  onWindowResize: (e) =>
    # TODO: This all seems a little hacky
    if @problem?
      levelContentWidth = $('.level-content').outerWidth(true)
      goalsViewWidth = $('#goals-view').outerWidth(true)
      codeAreaWidth = $('#code-area').outerWidth(true)
      # problem alert view has 20px padding
      @$el.css('max-width', levelContentWidth - codeAreaWidth - goalsViewWidth + 40 + 'px')
      @$el.css('right', codeAreaWidth + 'px')

      # 110px from top roughly aligns top of alert with top of first code line
      # TODO: calculate this in a more dynamic, less sketchy way
      @$el.css('top', (110 + @lineOffsetPx) + 'px')
