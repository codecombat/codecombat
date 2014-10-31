CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/cast_button'
{me} = require 'lib/auth'

module.exports = class CastButtonView extends CocoView
  id: 'cast-button-view'
  template: template

  events:
    'click .cast-button': 'onCastButtonClick'
    'click .submit-button': 'onCastRealTimeButtonClick'

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
    @levelID = options.levelID
    @castShortcut = '⇧↵'

  getRenderData: (context={}) ->
    context = super context
    shift = $.i18n.t 'keyboard_shortcuts.shift'
    enter = $.i18n.t 'keyboard_shortcuts.enter'
    castShortcutVerbose = "#{shift}+#{enter}"
    castRealTimeShortcutVerbose = (if @isMac() then 'Cmd' else 'Ctrl') + '+' + castShortcutVerbose
    context.castVerbose = castShortcutVerbose + ': ' + $.i18n.t('keyboard_shortcuts.cast_spell')
    context.castRealTimeVerbose = castRealTimeShortcutVerbose + ': ' + $.i18n.t('keyboard_shortcuts.run_real_time')
    context

  afterRender: ->
    super()
    @castButton = $('.cast-button', @$el)
    @castOptions = $('.autocast-delays', @$el)
    #delay = me.get('autocastDelay')  # No more autocast
    delay = 90019001
    @setAutocastDelay delay
    @$el.find('.submit-button').hide() if @options.levelID in ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'true-names']

  attachTo: (spellView) ->
    @$el.detach().prependTo(spellView.toolbarView.$el).show()

  onCastButtonClick: (e) ->
    Backbone.Mediator.publish 'tome:manual-cast', {}

  onCastRealTimeButtonClick: (e) ->
    if @multiplayerSession
      Backbone.Mediator.publish 'real-time-multiplayer:manual-cast', {}
      # Wait for multiplayer session to be up and running
      @multiplayerSession.on 'change', (e) =>
        if @multiplayerSession.get('state') is 'running'
          # Real-time multiplayer session is ready to go, so resume normal cast
          @multiplayerSession.off 'change'
          Backbone.Mediator.publish 'tome:manual-cast', {realTime: true}
    else
      Backbone.Mediator.publish 'tome:manual-cast', {realTime: true}

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
    @winnable = e.overallStatus is 'success'
    @$el.toggleClass 'winnable', @winnable
    if @winnable or (@hasCastOnce and @options.levelID isnt 'dungeons-of-kithgard')  # Show once 1) we think they will win or 2) they have hit “run” once. (Only #1 on the fist level.)
      @$el.find('.submit-button').show()  # In case we hid it, like on the first level.

  onGoalsCalculated: (e) ->
    return unless e.preload
    @onNewGoalStates e

  updateCastButton: ->
    return if _.some @spells, (spell) => not spell.loaded

    async.some _.values(@spells), (spell, callback) =>
      spell.hasChangedSignificantly spell.getSource(), null, callback
    , (castable) =>
      Backbone.Mediator.publish 'tome:spell-has-changed-significantly-calculation', hasChangedSignificantly: castable
      @castButton.toggleClass('castable', castable).toggleClass('casting', @casting)
      if @casting
        s = $.i18n.t('play_level.tome_cast_button_running')
        s = $.i18n.t('play_level.tome_cast_button_casting') if s is 'Running' and me.get('preferredLanguage', true).split('-')[0] isnt 'en'  # Temporary, if tome_cast_button_running isn't translated.
      else if castable
        s = $.i18n.t('play_level.tome_cast_button_run')
        s = $.i18n.t('play_level.tome_cast_button_casting') if s is 'Run' and me.get('preferredLanguage').split('-')[0] isnt 'en'  # Temporary, if tome_cast_button_running isn't translated.
        unless @options.levelID in ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'true-names', 'the-raised-sword', 'the-first-kithmaze']  # Hide for first few.
          s += ' ' + @castShortcut
      else
        s = $.i18n.t('play_level.tome_cast_button_ran')
        s = $.i18n.t('play_level.tome_cast_button_casting') if s is 'Ran' and me.get('preferredLanguage').split('-')[0] isnt 'en'  # Temporary, if tome_cast_button_running isn't translated.
      @castButton.text s
      @castButton.prop 'disabled', not castable

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
    @multiplayerSession = e.session

  onLeftRealTimeMultiplayerGame: (e) ->
    if @multiplayerSession
      @multiplayerSession.off 'change'
      @multiplayerSession = null
