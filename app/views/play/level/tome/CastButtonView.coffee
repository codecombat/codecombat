CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/tome/cast_button'
{me} = require 'core/auth'

module.exports = class CastButtonView extends CocoView
  id: 'cast-button-view'
  template: template

  events:
    'click .cast-button': 'onCastButtonClick'
    'click .submit-button': 'onCastRealTimeButtonClick'
    'click .done-button': 'onDoneButtonClick'

  subscriptions:
    'tome:spell-changed': 'onSpellChanged'
    'tome:cast-spells': 'onCastSpells'
    'tome:manual-cast-denied': 'onManualCastDenied'
    'god:new-world-created': 'onNewWorld'
    'real-time-multiplayer:created-game': 'onJoinedRealTimeMultiplayerGame'
    'real-time-multiplayer:joined-game': 'onJoinedRealTimeMultiplayerGame'
    'real-time-multiplayer:left-game': 'onLeftRealTimeMultiplayerGame'
    'goal-manager:new-goal-states': 'onNewGoalStates'
    'god:goals-calculated': 'onGoalsCalculated'

  constructor: (options) ->
    super options
    @spells = options.spells
    @castShortcut = '⇧↵'
    @updateReplayabilityInterval = setInterval @updateReplayability, 1000
    @observing = options.session.get('creator') isnt me.id

  destroy: ->
    clearInterval @updateReplayabilityInterval
    super()

  getRenderData: (context={}) ->
    context = super context
    shift = $.i18n.t 'keyboard_shortcuts.shift'
    enter = $.i18n.t 'keyboard_shortcuts.enter'
    castShortcutVerbose = "#{shift}+#{enter}"
    castRealTimeShortcutVerbose = (if @isMac() then 'Cmd' else 'Ctrl') + '+' + castShortcutVerbose
    context.castVerbose = castShortcutVerbose + ': ' + $.i18n.t('keyboard_shortcuts.run_code')
    context.castRealTimeVerbose = castRealTimeShortcutVerbose + ': ' + $.i18n.t('keyboard_shortcuts.run_real_time')
    context.observing = @observing
    context

  afterRender: ->
    super()
    @castButton = $('.cast-button', @$el)
    spell.view?.createOnCodeChangeHandlers() for spellKey, spell of @spells
    if @options.level.get('hidesSubmitUntilRun') or @options.level.get('hidesRealTimePlayback')
      @$el.find('.submit-button').hide()  # Hide Submit for the first few until they run it once.
    if @options.session.get('state')?.complete and @options.level.get 'hidesRealTimePlayback'
      @$el.find('.done-button').show()
    if @options.level.get('slug') is 'thornbush-farm'# and not @options.session.get('state')?.complete
      @$el.find('.submit-button').hide()  # Hide submit until first win so that script can explain it.
    @updateReplayability()

  attachTo: (spellView) ->
    @$el.detach().prependTo(spellView.toolbarView.$el).show()

  onCastButtonClick: (e) ->
    Backbone.Mediator.publish 'tome:manual-cast', {}

  onCastRealTimeButtonClick: (e) ->
    if @inRealTimeMultiplayerSession
      Backbone.Mediator.publish 'real-time-multiplayer:manual-cast', {}
    else if @options.level.get('replayable') and (timeUntilResubmit = @options.session.timeUntilResubmit()) > 0
      Backbone.Mediator.publish 'tome:manual-cast-denied', timeUntilResubmit: timeUntilResubmit
    else
      Backbone.Mediator.publish 'tome:manual-cast', {realTime: true}
    @updateReplayability()

  onDoneButtonClick: (e) ->
    @options.session.recordScores @world.scores, @options.level
    Backbone.Mediator.publish 'level:show-victory', showModal: true

  onSpellChanged: (e) ->
    @updateCastButton()

  onCastSpells: (e) ->
    return if e.preload
    @casting = true
    if @hasStartedCastingOnce  # Don't play this sound the first time
      @playSound 'cast', 0.5
    @hasStartedCastingOnce = true
    @updateCastButton()

  onManualCastDenied: (e) ->
    wait = moment().add(e.timeUntilResubmit, 'ms').fromNow()
    #@playSound 'manual-cast-denied', 1.0   # find some sound for this?
    noty text: "You can try again #{wait}.", layout: 'center', type: 'warning', killer: false, timeout: 6000

  onNewWorld: (e) ->
    @casting = false
    if @hasCastOnce  # Don't play this sound the first time
      @playSound 'cast-end', 0.5
    @hasCastOnce = true
    @updateCastButton()
    @world = e.world

  onNewGoalStates: (e) ->
    winnable = e.overallStatus is 'success'
    return if @winnable is winnable
    @winnable = winnable
    @$el.toggleClass 'winnable', @winnable
    Backbone.Mediator.publish 'tome:winnability-updated', winnable: @winnable
    if @options.level.get 'hidesRealTimePlayback'
      @$el.find('.done-button').toggle @winnable
    else if @winnable and @options.level.get('slug') is 'thornbush-farm'
      @$el.find('.submit-button').show()  # Hide submit until first win so that script can explain it.

  onGoalsCalculated: (e) ->
    # When preloading, with real-time playback enabled, we highlight the submit button when we think they'll win.
    return unless e.preload
    return if @options.level.get 'hidesRealTimePlayback'
    return if @options.level.get('slug') is 'thornbush-farm'  # Don't show it until they actually win for this first one.
    @onNewGoalStates e

  updateCastButton: ->
    return if _.some @spells, (spell) => not spell.loaded

    async.some _.values(@spells), (spell, callback) =>
      spell.hasChangedSignificantly spell.getSource(), null, callback
    , (castable) =>
      Backbone.Mediator.publish 'tome:spell-has-changed-significantly-calculation', hasChangedSignificantly: castable
      @castButton.toggleClass('castable', castable).toggleClass('casting', @casting)
      if @casting
        castText = $.i18n.t('play_level.tome_cast_button_running')
      else if castable or true
        castText = $.i18n.t('play_level.tome_cast_button_run')
        unless @options.level.get 'hidesRunShortcut'  # Hide for first few.
          castText += ' ' + @castShortcut
      else
        castText = $.i18n.t('play_level.tome_cast_button_ran')
      @castButton.text castText
      #@castButton.prop 'disabled', not castable

  updateReplayability: =>
    return if @destroyed
    return unless @options.level.get 'replayable'
    timeUntilResubmit = @options.session.timeUntilResubmit()
    disabled = timeUntilResubmit > 0
    submitButton = @$el.find('.submit-button').toggleClass('disabled', disabled)
    submitAgainLabel = submitButton.find('.submit-again-time').toggleClass('secret', not disabled)
    if disabled
      waitTime = moment().add(timeUntilResubmit, 'ms').fromNow()
      submitAgainLabel.text waitTime

  onJoinedRealTimeMultiplayerGame: (e) ->
    @inRealTimeMultiplayerSession = true

  onLeftRealTimeMultiplayerGame: (e) ->
    @inRealTimeMultiplayerSession = false
