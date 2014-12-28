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

  getRenderData: (context={}) ->
    context = super context
    shift = $.i18n.t 'keyboard_shortcuts.shift'
    enter = $.i18n.t 'keyboard_shortcuts.enter'
    castShortcutVerbose = "#{shift}+#{enter}"
    castRealTimeShortcutVerbose = (if @isMac() then 'Cmd' else 'Ctrl') + '+' + castShortcutVerbose
    context.castVerbose = castShortcutVerbose + ': ' + $.i18n.t('keyboard_shortcuts.run_code')
    context.castRealTimeVerbose = castRealTimeShortcutVerbose + ': ' + $.i18n.t('keyboard_shortcuts.run_real_time')
    context

  afterRender: ->
    super()
    @castButton = $('.cast-button', @$el)
    @castOptions = $('.autocast-delays', @$el)
    #delay = me.get('autocastDelay')  # No more autocast
    delay = 90019001
    @setAutocastDelay delay
    if @options.level.get('hidesSubmitUntilRun') or @options.level.get('hidesRealTimePlayback')
      @$el.find('.submit-button').hide()  # Hide Submit for the first few until they run it once.
    if @options.session.get('state')?.complete and @options.level.get 'hidesRealTimePlayback'
      @$el.find('.done-button').show()
    if @options.level.get('slug') is 'thornbush-farm'# and not @options.session.get('state')?.complete
      @$el.find('.submit-button').hide()  # Hide submit until first win so that script can explain it.

  attachTo: (spellView) ->
    @$el.detach().prependTo(spellView.toolbarView.$el).show()

  onCastButtonClick: (e) ->
    Backbone.Mediator.publish 'tome:manual-cast', {}

  onCastRealTimeButtonClick: (e) ->
    if @inRealTimeMultiplayerSession
      Backbone.Mediator.publish 'real-time-multiplayer:manual-cast', {}
    else
      Backbone.Mediator.publish 'tome:manual-cast', {realTime: true}

  onDoneButtonClick: (e) ->
    Backbone.Mediator.publish 'level:show-victory', showModal: true

  onSpellChanged: (e) ->
    @updateCastButton()

  onCastSpells: (e) ->
    return if e.preload
    @casting = true
    if @hasStartedCastingOnce  # Don't play this sound the first time
      Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'cast', volume: 0.5
    @hasStartedCastingOnce = true
    @updateCastButton()

  onNewWorld: (e) ->
    @casting = false
    if @hasCastOnce  # Don't play this sound the first time
      Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'cast-end', volume: 0.5
    @hasCastOnce = true
    @updateCastButton()

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

  setAutocastDelay: (delay) ->
    #console.log 'Set autocast delay to', delay
    return unless delay
    delay = 90019001  # No more autocast
    @autocastDelay = delay = parseInt delay
    me.set('autocastDelay', delay)
    me.patch()
    spell.view?.setAutocastDelay delay for spellKey, spell of @spells
    @castOptions.find('a').each ->
      $(@).toggleClass('selected', parseInt($(@).attr('data-delay')) is delay)

  onJoinedRealTimeMultiplayerGame: (e) ->
    @inRealTimeMultiplayerSession = true

  onLeftRealTimeMultiplayerGame: (e) ->
    @inRealTimeMultiplayerSession = false
