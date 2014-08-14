SpellListEntryView = require './SpellListEntryView'
ThangAvatarView = require 'views/play/level/ThangAvatarView'
template = require 'templates/play/level/tome/spell_list_tab_entry'
LevelComponent = require 'models/LevelComponent'
DocFormatter = require './DocFormatter'
filters = require 'lib/image_filter'

module.exports = class SpellListTabEntryView extends SpellListEntryView
  template: template
  id: 'spell-list-tab-entry-view'

  subscriptions:
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'
    'tome:spell-loaded': 'onSpellLoaded'
    'tome:spell-changed': 'onSpellChanged'
    'god:new-world-created': 'onNewWorld'
    'tome:spell-changed-language': 'onSpellChangedLanguage'
    'tome:fullscreen-view': 'onFullscreenClick'

  events:
    'click .spell-list-button': 'onDropdownClick'
    'click .reload-code': 'onCodeReload'
    'click .beautify-code': 'onBeautifyClick'
    'click .fullscreen-code': 'onFullscreenClick'

  constructor: (options) ->
    super options

  getRenderData: (context={}) ->
    context = super context
    context

  afterRender: ->
    super()
    @$el.addClass 'spell-tab'
    @attachTransitionEventListener()

  onNewWorld: (e) ->
    @thang = e.world.thangMap[@thang.id] if @thang

  setThang: (thang) ->
    return if thang.id is @thang?.id
    @thang = thang
    @spellThang = @spell.thangs[@thang.id]
    @buildAvatar()
    @buildDocs() unless @docsBuilt

  buildAvatar: ->
    avatar = new ThangAvatarView thang: @thang, includeName: false, supermodel: @supermodel
    if @avatar
      @avatar.$el.replaceWith avatar.$el
      @avatar.destroy()
    else
      @$el.find('.thang-avatar-placeholder').replaceWith avatar.$el
    @avatar = avatar
    @avatar.render()

  buildDocs: ->
    @docsBuilt = true
    lcs = @supermodel.getModels LevelComponent
    found = false
    for lc in lcs when not found
      for doc in lc.get('propertyDocumentation') ? []
        if doc.name is @spell.name
          found = true
          break
    return unless found
    docFormatter = new DocFormatter doc: doc, thang: @thang, language: @options.language, selectedMethod: true
    @$el.find('code').popover(
      animation: true
      html: true
      placement: 'bottom'
      trigger: 'hover'
      content: docFormatter.formatPopover()
      container: @$el.parent()
    )

  onMouseEnterAvatar: (e) ->  # Don't call super
  onMouseLeaveAvatar: (e) ->  # Don't call super
  onClick: (e) ->  # Don't call super
  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true

  onDropdownClick: (e) ->
    return unless @controlsEnabled
    Backbone.Mediator.publish 'tome:toggle-spell-list'

  onCodeReload: ->
    return unless @controlsEnabled
    Backbone.Mediator.publish 'tome:reload-code', spell: @spell

  onBeautifyClick: ->
    return unless @controlsEnabled
    Backbone.Mediator.publish 'spell-beautify', spell: @spell

  onFullscreenClick: ->
    $codearea = $('html')
    $('#code-area').css 'z-index', 20 unless $codearea.hasClass 'fullscreen-editor'
    $('html').toggleClass 'fullscreen-editor'
    $('.fullscreen-code').toggleClass 'maximized'

  updateReloadButton: ->
    changed = @spell.hasChanged null, @spell.getSource()
    @$el.find('.reload-code').css('display', if changed then 'inline-block' else 'none')

  onSpellLoaded: (e) ->
    return unless e.spell is @spell
    @updateReloadButton()

  onSpellChanged: (e) ->
    return unless e.spell is @spell
    @updateReloadButton()

  onSpellChangedLanguage: (e) ->
    return unless e.spell is @spell
    @options.language = e.language
    @$el.find('code').popover 'destroy'
    @render()
    @docsBuilt = false
    @buildDocs() if @thang

  toggleControls: (e, enabled) ->
    # Don't call super; do it differently
    return if e.controls and not ('editor' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.toggleClass 'read-only', not enabled
    @toggleBackground()

  toggleBackground: =>
    # TODO: make the palette background an actual background and do the CSS trick
    # used in spell_list_entry.sass for disabling
    background = @$el.find('img.spell-tab-image-hidden')[0]
    if background.naturalWidth is 0  # not loaded yet
      return _.delay @toggleBackground, 100
    filters.revertImage background, '.spell-list-entry-view.spell-tab' if @controlsEnabled
    filters.darkenImage background, '.spell-list-entry-view.spell-tab', 0.8 unless @controlsEnabled

  attachTransitionEventListener: =>
    transitionListener = ''
    testEl = document.createElement 'fakeelement'
    transitions = 
      'transition':'transitionend'
      'OTransition':'oTransitionEnd'
      'MozTransition':'transitionend'
      'WebkitTransition':'webkitTransitionEnd'
    for transition, transitionEvent of transitions
      unless testEl.style[transition] is undefined
        transitionListener = transitionEvent
        break
    $codearea = $('#code-area')
    $codearea.on transitionListener, =>
      $codearea.css 'z-index', 1 unless $('html').hasClass 'fullscreen-editor'


  destroy: ->
    @avatar?.destroy()
    @$el.find('code').popover 'destroy'
    super()
