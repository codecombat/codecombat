CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/cast_button'
{me} = require 'lib/auth'
LevelOptions = require 'lib/LevelOptions'

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
    @levelID = options.levelID
    @castShortcut = '⇧↵'
    @levelOptions = LevelOptions[@options.levelID] ? {}
    @initButtonTextABTest() unless @levelOptions.hidesRealTimePlayback

  getRenderData: (context={}) ->
    context = super context
    shift = $.i18n.t 'keyboard_shortcuts.shift'
    enter = $.i18n.t 'keyboard_shortcuts.enter'
    castShortcutVerbose = "#{shift}+#{enter}"
    castRealTimeShortcutVerbose = (if @isMac() then 'Cmd' else 'Ctrl') + '+' + castShortcutVerbose
    context.castVerbose = castShortcutVerbose + ': ' + $.i18n.t('keyboard_shortcuts.run_code')
    context.castRealTimeVerbose = castRealTimeShortcutVerbose + ': ' + $.i18n.t('keyboard_shortcuts.run_real_time')
    # A/B test submit button text
    context.testSubmitText = @testButtonsText.submit if @testGroup? and @testGroup isnt 0
    context

  afterRender: ->
    super()
    @castButton = $('.cast-button', @$el)
    @castOptions = $('.autocast-delays', @$el)
    #delay = me.get('autocastDelay')  # No more autocast
    delay = 90019001
    @setAutocastDelay delay
    if @levelOptions.hidesSubmitUntilRun or @levelOptions.hidesRealTimePlayback
      @$el.find('.submit-button').hide()  # Hide Submit for the first few until they run it once.
    if @options.session.get('state')?.complete and @levelOptions.hidesRealTimePlayback
      @$el.find('.done-button').show()
    if @options.levelID is 'thornbush-farm'# and not @options.session.get('state')?.complete
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
    if @levelOptions.hidesRealTimePlayback
      @$el.find('.done-button').toggle @winnable
    else if @winnable and @options.levelID is 'thornbush-farm'
      @$el.find('.submit-button').show()  # Hide submit until first win so that script can explain it.

  onGoalsCalculated: (e) ->
    # When preloading, with real-time playback enabled, we highlight the submit button when we think they'll win.
    return unless e.preload
    return if @levelOptions.hidesRealTimePlayback
    return if @options.levelID is 'thornbush-farm'  # Don't show it until they actually win for this first one.
    @onNewGoalStates e

  updateCastButton: ->
    return if _.some @spells, (spell) => not spell.loaded

    async.some _.values(@spells), (spell, callback) =>
      spell.hasChangedSignificantly spell.getSource(), null, callback
    , (castable) =>
      Backbone.Mediator.publish 'tome:spell-has-changed-significantly-calculation', hasChangedSignificantly: castable
      @castButton.toggleClass('castable', castable).toggleClass('casting', @casting)

      # A/B testing cast button text for en-US
      unless @testGroup? and @testGroup isnt 0
        if @casting
          castText = $.i18n.t('play_level.tome_cast_button_running')
        else if castable or true
          castText = $.i18n.t('play_level.tome_cast_button_run')
          unless @levelOptions.hidesRunShortcut  # Hide for first few.
            castText += ' ' + @castShortcut
        else
          castText = $.i18n.t('play_level.tome_cast_button_ran')
      else
        castText = @testButtonsText.run
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

  # https://mixpanel.com/report/227350/segmentation/#action:segment,arb_event:'Saw%20Victory',bool_op:or,chart_type:bar,from_date:-9,segfilter:!((filter:(operand:!('Ogre%20Encampment'),operator:%3D%3D),property:level,selected_property_type:string,type:string),(property:castButtonTextGroup,selected_property_type:number,type:number)),segment_type:number,to_date:0,type:unique,unit:day
  initButtonTextABTest: ->
    return if me.isAdmin()
    return unless $.i18n.lng() is 'en-US'
    # A/B test buttons text
    # Only testing 'en-US' for simplicity and it accounts for a significant % of users
    # Test group 0 is existing behavior
    # Intentionally leaving out cast shortcut for test groups for simplicity
    @testGroup = me.getCastButtonTextGroup()
    @testButtonsText = switch @testGroup
      when 0 then run: 'Run/Running', submit: 'Submit'
      when 1 then run: 'Run', submit: 'Submit'
      when 2 then run: 'Test', submit: 'Submit'
      when 3 then run: 'Run', submit: 'Continue'
      when 4 then run: 'Test', submit: 'Continue'
      when 5 then run: 'Run', submit: 'Finish'
      when 6 then run: 'Test', submit: 'Finish'
    application.tracker?.trackEvent 'Cast Button',
      levelID: @levelID
      castButtonText: @testButtonsText.run + ' ' + @testButtonsText.submit
      castButtonTextGroup: @testGroup
