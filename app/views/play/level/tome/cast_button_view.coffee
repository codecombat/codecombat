View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/cast_button'
{me} = require 'lib/auth'

module.exports = class CastButtonView extends View
  id: 'cast-button-view'
  template: template

  events:
    'click .cast-button': 'onCastButtonClick'
    'click .autocast-delays a': 'onCastOptionsClick'

  subscriptions:
    'tome:spell-changed': "onSpellChanged"
    'tome:cast-spells': 'onCastSpells'
    'god:world-load-progress-changed': 'onWorldLoadProgressChanged'
    'god:new-world-created': 'onNewWorld'

  constructor: (options) ->
    super options
    @spells = options.spells
    @levelID = options.levelID
    isMac = navigator.platform.toUpperCase().indexOf('MAC') isnt -1
    @castShortcut = "⇧↵"
    @castShortcutVerbose = "Shift+Enter"

  getRenderData: (context={}) ->
    context = super context
    context.castShortcutVerbose = @castShortcutVerbose
    context

  afterRender: ->
    super()
    @castButton = $('.cast-button', @$el)
    @castButtonGroup = $('.cast-button-group', @$el)
    @castOptions = $('.autocast-delays', @$el)
    delay = me.get('autocastDelay')
    delay ?= 5000
    if @levelID in ['brawlwood', 'brawlwood-tutorial', 'dungeon-arena', 'dungeon-arena-tutorial', 'gold-rush', 'greed']
      delay = 90019001
    @setAutocastDelay delay

  attachTo: (spellView) ->
    @$el.detach().prependTo(spellView.toolbarView.$el).show()

  onCastButtonClick: (e) ->
    Backbone.Mediator.publish 'tome:manual-cast', {}

  onCastOptionsClick: (e) =>
    console.log 'cast options click', $(e.target)
    Backbone.Mediator.publish 'focus-editor'
    @castButtonGroup.removeClass 'open'
    @setAutocastDelay $(e.target).attr 'data-delay'
    false

  onSpellChanged: (e) ->
    @updateCastButton()

  onCastSpells: (e) ->
    @casting = true
    Backbone.Mediator.publish 'play-sound', trigger: 'cast', volume: 0.5
    @updateCastButton()
    @onWorldLoadProgressChanged progress: 0

  onWorldLoadProgressChanged: (e) ->
    return # trying out showing progress on the canvas instead
    overlay = @castButtonGroup.find '.button-progress-overlay'
    overlay.css 'width', e.progress * @castButton.outerWidth() + 1

  onNewWorld: (e) ->
    @casting = false
    Backbone.Mediator.publish 'play-sound', trigger: 'cast-end', volume: 0.5
    @updateCastButton()

  updateCastButton: ->
    return if _.some @spells, (spell) => not spell.loaded

    async.some _.values(@spells), (spell, callback) =>
      spell.hasChangedSignificantly spell.getSource(), null, callback
    , (castable) =>

      @castButtonGroup.toggleClass('castable', castable).toggleClass('casting', @casting)
      if @casting
        s = $.i18n.t("play_level.tome_cast_button_casting", defaultValue: "Casting")
      else if castable
        s = $.i18n.t("play_level.tome_cast_button_castable", defaultValue: "Cast Spell") + " " + @castShortcut
      else
        s = $.i18n.t("play_level.tome_cast_button_cast", defaultValue: "Spell Cast")
      @castButton.text s
      @castButton.prop 'disabled', not castable

  setAutocastDelay: (delay) ->
    #console.log "Set autocast delay to", delay
    return unless delay
    @autocastDelay = delay = parseInt delay
    me.set('autocastDelay', delay)
    me.save()
    spell.view.setAutocastDelay delay for spellKey, spell of @spells
    @castOptions.find('a').each ->
      $(@).toggleClass('selected', parseInt($(@).attr('data-delay')) is delay)
