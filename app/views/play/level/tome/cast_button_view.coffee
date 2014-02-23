View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/cast_button'
{me} = require 'lib/auth'

module.exports = class CastButtonView extends View
  id: 'cast-button-view'
  template: template

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
    @castShortcut = "⇧↩"
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
    @castButton.on 'click', @onCastButtonClick
    @castOptions.find('a').on 'click', @onCastOptionsClick
    # TODO: use a User setting instead of localStorage
    delay = localStorage.getItem 'autocastDelay'
    delay ?= 5000
    if @levelID is 'project-dota'
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
    overlay = @castButtonGroup.find '.button-progress-overlay'
    overlay.css 'width', e.progress * @castButton.outerWidth() + 1

  onNewWorld: (e) ->
    @casting = false
    Backbone.Mediator.publish 'play-sound', trigger: 'cast-end', volume: 0.5
    @updateCastButton()

  updateCastButton: ->
    return if _.some @spells, (spell) => not spell.loaded
    castable = _.some @spells, (spell) => spell.hasChangedSignificantly spell.getSource()
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
    localStorage.setItem 'autocastDelay', delay
    spell.view.setAutocastDelay delay for spellKey, spell of @spells
    @castOptions.find('a').each ->
      $(@).toggleClass('selected', parseInt($(@).attr('data-delay')) is delay)

  destroy: ->
    @castButton.off 'click', @onCastButtonClick
    @castOptions.find('a').off 'click', @onCastOptionsClick
    @onCastOptionsClick = null
    super()
