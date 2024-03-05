require('app/styles/play/level/tome/problem_alert.sass')
CocoView = require 'views/core/CocoView'
GameMenuModal = require 'views/play/menu/GameMenuModal'
template = require 'app/templates/play/level/tome/problem_alert'
{me} = require 'core/auth'
userUtils = require 'app/lib/user-utils'

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
    '/images/pages/play/duck_amara.png'
    '/images/pages/play/duck_arryn.png'
    '/images/pages/play/duck_hattori.png'
    '/images/pages/play/duck_hushbaum.png'
    '/images/pages/play/duck_illia.png'
    '/images/pages/play/duck_nalfar.png'
    '/images/pages/play/duck_naria.png'
    '/images/pages/play/duck_omarn.png'
    '/images/pages/play/duck_pender.png'
    '/images/pages/play/duck_ritic.png'
    '/images/pages/play/duck_senick.png'
    '/images/pages/play/duck_usara.png'
    '/images/pages/play/duck_zana.png'
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
    'click .ai-help-button': 'onAIHelpClicked'

  constructor: (options) ->
    @supermodel = options.supermodel # Has to go before super so events are hooked up
    super options
    @level = options.level
    @session = options.session
    @aceConfig = options.aceConfig || {}
    if options.problem?
      @problem = options.problem
      @onWindowResize()
    else
      @$el.hide()
    @duckImg = _.sample(@duckImages)
    $(window).on 'resize', @onWindowResize
    @creditMessage = ''
    @showAiBotHelp = false
    if @aceConfig.levelChat != 'none'
      if me.isHomeUser() && me.getLevelChatExperimentValue() == 'beta'
        @showAiBotHelp = true
      else if not me.isHomeUser()
        @showAiBotHelp = true

  destroy: ->
    $(window).off 'resize', @onWindowResize
    super()

  afterRender: ->
    @$('[data-toggle="popover"]').popover()
    unless @creditMessage
      @handleUserCreditsMessage()

    super()
    if @problem?
      @$el.addClass('alert').addClass("alert-#{@problem.level}").hide().fadeIn('slow')
      @$el.addClass('no-hint') unless @problem.hint
      @playSound 'error_appear'

  setProblemMessage: ->
    return unless @problem
    format = (s) -> marked(s) if s?
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

  onAIHelpClicked: (e) ->
    rand = _.random(1, 13)
    message = $.i18n.t('ai.prompt_level_chat_' + rand)
    Backbone.Mediator.publish 'level:add-user-chat', { message }
    _.delay (=> @handleUserCreditsMessage()), 5000

  onWindowResize: (e) =>
    return unless @problem
    tomeLocation = if $('#code-area').offset().top > 100 then 'bottom' else 'right'
    tomeWidth = $('#code-area').outerWidth()
    right = if tomeLocation is 'bottom' then 'auto' else tomeWidth + 40
    left = if tomeLocation is 'bottom' then 40 else 'auto'
    maxWidth = $('#game-area').innerWidth() - $('#goals-view').outerWidth(true) - 2 * 20  # 20px padding
    @$el.css { left, right, maxWidth }
    codeAreaTop = $('#code-area .ace').offset().top
    if tomeLocation is 'bottom'
      top = codeAreaTop - @$el.outerHeight() - 80
    else
      top = codeAreaTop + @lineOffsetPx - @$el.height() / 2
    @$el.css top: Math.max(60, top)
    null

  handleUserCreditsMessage: ->
    userUtils.levelChatCreditsString().then (res) =>
      if @creditMessage != res
        @creditMessage = res
        @render()
