require('app/styles/play/level/tome/spell-top-bar-view.sass')
template = require 'templates/play/level/tome/spell-top-bar-view'
ReloadLevelModal = require 'views/play/level/modal/ReloadLevelModal'
CocoView = require 'views/core/CocoView'
ImageGalleryModal = require 'views/play/level/modal/ImageGalleryModal'
utils = require 'core/utils'
CourseVideosModal = require 'views/play/level/modal/CourseVideosModal'

module.exports = class SpellTopBarView extends CocoView
  template: template
  id: 'spell-top-bar-view'
  controlsEnabled: true

  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'tome:spell-loaded': 'onSpellLoaded'
    'tome:spell-changed': 'onSpellChanged'
    'tome:spell-changed-language': 'onSpellChangedLanguage'
    'tome:toggle-maximize': 'onToggleMaximize'

  events:
    'click .reload-code': 'onCodeReload'
    'click .beautify-code': 'onBeautifyClick'
    'click .fullscreen-code': 'onToggleMaximize'
    'click .hints-button': 'onClickHintsButton'
    'click .image-gallery-button': 'onClickImageGalleryButton'
    'click .videos-button': 'onClickVideosButton'

  constructor: (options) ->
    @hintsState = options.hintsState
    @spell = options.spell
    @courseInstanceID = options.courseInstanceID
    @courseID = options.courseID
    super(options)

  getRenderData: (context={}) ->
    context = super context
    ctrl = if @isMac() then 'Cmd' else 'Ctrl'
    shift = $.i18n.t 'keyboard_shortcuts.shift'
    context.beautifyShortcutVerbose = "#{ctrl}+#{shift}+B: #{$.i18n.t 'keyboard_shortcuts.beautify'}"
    context.maximizeShortcutVerbose = "#{ctrl}+#{shift}+M: #{$.i18n.t 'keyboard_shortcuts.maximize_editor'}"
    context.codeLanguage = @options.codeLanguage
    context.showAmazonLogo = application.getHocCampaign() is 'game-dev-hoc'
    context

  afterRender: ->
    super()
    @attachTransitionEventListener()
    @$('[data-toggle="popover"]').popover()

  showVideosButton: () ->
    me.isStudent() and @courseID == utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true

  onClickImageGalleryButton: (e) ->
    @openModalView new ImageGalleryModal()

  onClickHintsButton: ->
    return unless @hintsState?
    @hintsState.set('hidden', not @hintsState.get('hidden'))
    window.tracker?.trackEvent 'Hints Clicked', category: 'Students', levelSlug: @options.level.get('slug'), hintCount: @hintsState.get('hints')?.length ? 0, []

  onClickVideosButton: ->
    @openModalView new CourseVideosModal({courseInstanceID: @courseInstanceID, courseID: @courseID})

  onCodeReload: (e) ->
    if key.shift
      Backbone.Mediator.publish 'level:restart', {}
    else
      @openModalView new ReloadLevelModal()

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
    @render()
    @updateReloadButton()

  toggleControls: (e, enabled) ->
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
    super()
