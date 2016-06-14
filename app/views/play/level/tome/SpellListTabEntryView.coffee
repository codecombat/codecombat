SpellListEntryView = require './SpellListEntryView'
ThangAvatarView = require 'views/play/level/ThangAvatarView'
template = require 'templates/play/level/tome/spell_list_tab_entry'
LevelComponent = require 'models/LevelComponent'
DocFormatter = require './DocFormatter'
ReloadLevelModal = require 'views/play/level/modal/ReloadLevelModal'

module.exports = class SpellListTabEntryView extends SpellListEntryView
  template: template
  id: 'spell-list-tab-entry-view'

  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'tome:spell-loaded': 'onSpellLoaded'
    'tome:spell-changed': 'onSpellChanged'
    'god:new-world-created': 'onNewWorld'
    'tome:spell-changed-language': 'onSpellChangedLanguage'
    'tome:toggle-maximize': 'onToggleMaximize'

  events:
    'click .spell-list-button': 'onDropdownClick'
    'click .reload-code': 'onCodeReload'
    'click .beautify-code': 'onBeautifyClick'
    'click .fullscreen-code': 'onToggleMaximize'
    'click .hints-button': 'onClickHintsButton'

  constructor: (options) ->
    @hintsState = options.hintsState
    super(options)

  getRenderData: (context={}) ->
    context = super context
    ctrl = if @isMac() then 'Cmd' else 'Ctrl'
    shift = $.i18n.t 'keyboard_shortcuts.shift'
    context.beautifyShortcutVerbose = "#{ctrl}+#{shift}+B: #{$.i18n.t 'keyboard_shortcuts.beautify'}"
    context.maximizeShortcutVerbose = "#{ctrl}+#{shift}+M: #{$.i18n.t 'keyboard_shortcuts.maximize_editor'}"
    context.includeSpellList = @options.level.get('slug') in ['break-the-prison', 'zone-of-danger', 'k-means-cluster-wars', 'brawlwood', 'dungeon-arena', 'sky-span', 'minimax-tic-tac-toe']
    context.codeLanguage = @options.codeLanguage
    context.levelType = @options.level.get 'type', true
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
    return if @spell.name is 'plan'  # Too confusing for beginners
    @docsBuilt = true
    lcs = @supermodel.getModels LevelComponent
    found = false
    for lc in lcs when not found
      for doc in lc.get('propertyDocumentation') ? []
        if doc.name is @spell.name
          found = true
          break
    return unless found
    docFormatter = new DocFormatter doc: doc, thang: @thang, language: @options.codeLanguage, selectedMethod: true
    @$el.find('.method-signature').popover(
      animation: true
      html: true
      placement: 'bottom'
      trigger: 'hover'
      content: docFormatter.formatPopover()
      container: @$el.parent()
    ).on 'show.bs.popover', =>
      @playSound 'spell-tab-entry-open', 0.75

  onMouseEnterAvatar: (e) ->  # Don't call super
  onMouseLeaveAvatar: (e) ->  # Don't call super
  onClick: (e) ->  # Don't call super
  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true

  onClickHintsButton: ->
    return unless @hintsState?
    @hintsState.set('hidden', not @hintsState.get('hidden'))
    window.tracker?.trackEvent 'Hints Clicked', category: 'Students', levelSlug: @options.level.get('slug'), hintCount: @hintsState.get('hints')?.length ? 0, ['Mixpanel']

  onDropdownClick: (e) ->
    return unless @controlsEnabled
    Backbone.Mediator.publish 'tome:toggle-spell-list', {}
    @playSound 'spell-list-open'

  onCodeReload: (e) ->
    #return unless @controlsEnabled
    #Backbone.Mediator.publish 'tome:reload-code', spell: @spell  # Old: just reload the current code
    @openModalView new ReloadLevelModal()                # New: prompt them to restart the level

  onBeautifyClick: (e) ->
    return unless @controlsEnabled
    Backbone.Mediator.publish 'tome:spell-beautify', spell: @spell

  onToggleMaximize: (e) ->
    $codearea = $('html')
    $('#code-area').css 'z-index', 20 unless $codearea.hasClass 'fullscreen-editor'
    $('html').toggleClass 'fullscreen-editor'
    $('.fullscreen-code').toggleClass 'maximized'
    Backbone.Mediator.publish 'tome:maximize-toggled', {}

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
    @options.codeLanguage = e.language
    @$el.find('.method-signature').popover 'destroy'
    @render()
    @docsBuilt = false
    @buildDocs() if @thang
    @updateReloadButton()

  toggleControls: (e, enabled) ->
    # Don't call super; do it differently
    return if e.controls and not ('editor' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.toggleClass 'read-only', not enabled

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
      $codearea.css 'z-index', 2 unless $('html').hasClass 'fullscreen-editor'


  destroy: ->
    @avatar?.destroy()
    @$el.find('.method-signature').popover 'destroy'
    super()
