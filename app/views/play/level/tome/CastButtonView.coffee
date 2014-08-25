CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/cast_button'
{me} = require 'lib/auth'

module.exports = class CastButtonView extends CocoView
  id: 'cast-button-view'
  template: template

  events:
    'click .cast-button': 'onCastButtonClick'
    'click .cast-real-time-button': 'onCastRealTimeButtonClick'

  subscriptions:
    'tome:spell-changed': 'onSpellChanged'
    'tome:cast-spells': 'onCastSpells'
    'god:world-load-progress-changed': 'onWorldLoadProgressChanged'
    'god:new-world-created': 'onNewWorld'

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
    @castButtonGroup = $('.cast-button-group', @$el)
    @castOptions = $('.autocast-delays', @$el)
    delay = me.get('autocastDelay')
    delay ?= 90019001
    @setAutocastDelay delay

  attachTo: (spellView) ->
    @$el.detach().prependTo(spellView.toolbarView.$el).show()

  onCastButtonClick: (e) ->
    Backbone.Mediator.publish 'tome:manual-cast', {}

  onCastRealTimeButtonClick: (e) ->
    Backbone.Mediator.publish 'tome:manual-cast', {realTime: true}

  onCastOptionsClick: (e) =>
    Backbone.Mediator.publish 'tome:focus-editor'
    @castButtonGroup.removeClass 'open'
    @setAutocastDelay $(e.target).attr 'data-delay'
    false

  onSpellChanged: (e) ->
    @updateCastButton()

  onCastSpells: (e) ->
    return if e.preload
    @casting = true
    if @hasStartedCastingOnce  # Don't play this sound the first time
      Backbone.Mediator.publish 'play-sound', trigger: 'cast', volume: 0.5
    @hasStartedCastingOnce = true
    @updateCastButton()
    @onWorldLoadProgressChanged progress: 0

  onWorldLoadProgressChanged: (e) ->
    return # trying out showing progress on the canvas instead
    overlay = @castButtonGroup.find '.button-progress-overlay'
    overlay.css 'width', e.progress * @castButton.outerWidth() + 1

  onNewWorld: (e) ->
    @casting = false
    if @hasCastOnce  # Don't play this sound the first time
      Backbone.Mediator.publish 'play-sound', trigger: 'cast-end', volume: 0.5
    @hasCastOnce = true
    @updateCastButton()

  updateCastButton: ->
    return if _.some @spells, (spell) => not spell.loaded

    async.some _.values(@spells), (spell, callback) =>
      spell.hasChangedSignificantly spell.getSource(), null, callback
    , (castable) =>
      Backbone.Mediator.publish 'tome:spell-has-changed-significantly-calculation', hasChangedSignificantly: castable
      @castButtonGroup.toggleClass('castable', castable).toggleClass('casting', @casting)
      if @casting
        s = $.i18n.t('play_level.tome_cast_button_casting', defaultValue: 'Casting')
      else if castable
        s = $.i18n.t('play_level.tome_cast_button_castable', defaultValue: 'Cast Spell') + ' ' + @castShortcut
      else
        s = $.i18n.t('play_level.tome_cast_button_cast', defaultValue: 'Spell Cast')
      @castButton.text s
      @castButton.prop 'disabled', not castable

  setAutocastDelay: (delay) ->
    #console.log 'Set autocast delay to', delay
    return unless delay
    @autocastDelay = delay = parseInt delay
    me.set('autocastDelay', delay)
    me.patch()
    spell.view?.setAutocastDelay delay for spellKey, spell of @spells
    @castOptions.find('a').each ->
      $(@).toggleClass('selected', parseInt($(@).attr('data-delay')) is delay)
