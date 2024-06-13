require('app/styles/play/level/tome/spell-top-bar-view.sass')
template = require 'app/templates/play/level/tome/spell-top-bar-view'
ReloadLevelModal = require 'views/play/level/modal/ReloadLevelModal'
CocoView = require 'views/core/CocoView'
ImageGalleryModal = require 'views/play/level/modal/ImageGalleryModal'
utils = require 'core/utils'
CourseVideosModal = require 'views/play/level/modal/CourseVideosModal'
AskAIHelpView = require('views/play/level/AskAIHelpView').default
store = require 'core/store'
globalVar = require 'core/globalVar'

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
    'tome:game-menu-opened': 'onGameMenuOpened'
    'websocket:user-online': 'onUserOnlineChanged'

  events:
    'click .reload-code': 'onCodeReload'
    'click .beautify-code': 'onBeautifyClick'
    'click .fullscreen-code': 'onToggleMaximize'
    'click .hints-button': 'onClickHintsButton'
    'click .image-gallery-button': 'onClickImageGalleryButton'
    'click .videos-button': 'onClickVideosButton'
    'click #fill-solution': 'onFillSolution'
    'click #toggle-solution': 'onToggleSolution'
    'click #switch-team': 'onSwitchTeam'
    'click .toggle-blocks': 'onToggleBlocks'
    'click #ask-teacher-for-help': 'onClickHelpButton'
    'click .spell-chatbot-hint': 'onClickHintButton'

  constructor: (options) ->
    @hintsState = options.hintsState
    @spell = options.spell
    @courseInstanceID = options.courseInstanceID
    @courseID = options.courseID
    @blocks = options.blocks
    @blocksHidden = options.blocksHidden
    @teacherID = options.teacherID
    @teaching = utils.getQueryVariable 'teaching'
    @showLevelHelp = true
    if me.isStudent()
      @showLevelHelp = options.showLevelHelp and options.showLevelHelp != 'none'

    @wsBus = globalVar.application.wsBus
    super(options)

  getRenderData: (context={}) ->
    context = super context
    ctrl = if @isMac() then 'Cmd' else 'Ctrl'
    shift = $.i18n.t 'keyboard_shortcuts.shift'
    context.beautifyShortcutVerbose = "#{ctrl}+#{shift}+B: #{$.i18n.t 'keyboard_shortcuts.beautify'}"
    context.maximizeShortcutVerbose = "#{ctrl}+#{shift}+M: #{$.i18n.t 'keyboard_shortcuts.maximize_editor'}"
    context.codeLanguage = @options.codeLanguage
    context.showAmazonLogo = application.getHocCampaign() is 'game-dev-hoc'
    context.askingTeacher = if me.isStudent() and @teacherOnline() then $.i18n.t('play_level.ask_teacher_for_help') else $.i18n.t('play_level.ask_teacher_for_help_offline')
    context

  afterRender: ->
    super()
    @$('[data-toggle="popover"]').popover()

  showVideosButton: () ->
    me.isStudent() and @courseID == utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE

  teacherOnline: () ->
    console.log("what online?", @wsBus?.wsInfos?.friends?[@teacherID], @teacherID)
    @wsBus?.wsInfos?.friends?[@teacherID]?.online

  onDisableControls: (e) -> @toggleControls e, false
  onEnableControls: (e) -> @toggleControls e, true

  onClickImageGalleryButton: (e) ->
    @openModalView new ImageGalleryModal()

  onGameMenuOpened: ->
    hintState = @hintsState.get('hidden')
    unless hintState
      @hintsState.set('hidden', not hintState)

  onClickHintsButton: ->
    return unless @hintsState?
    Backbone.Mediator.publish 'level:hints-button', {state: @hintsState.get('hidden')}
    @hintsState.set('hidden', not @hintsState.get('hidden'))
    window.tracker?.trackEvent 'Hints Clicked', category: 'Students', levelSlug: @options.level.get('slug'), hintCount: @hintsState.get('hints')?.length ? 0

  onClickVideosButton: ->
    @openModalView new CourseVideosModal({courseInstanceID: @courseInstanceID, courseID: @courseID})

  onFillSolution: ->
    return unless me.canAutoFillCode()
    store.dispatch('game/autoFillSolution', @options.codeLanguage)

  onToggleSolution: ->
    console.log('click toggle solution')
    Backbone.Mediator.publish 'level:toggle-solution', {}

  onCodeReload: (e) ->
    if key.shift
      Backbone.Mediator.publish 'level:restart', {}
    else
      @openModalView new ReloadLevelModal()

  onBeautifyClick: (e) ->
    return unless @controlsEnabled
    Backbone.Mediator.publish 'tome:spell-beautify', spell: @spell

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

  onUserOnlineChanged: (e) ->
    console.log('user online changed', e)
    if e.user.toString() == @teacherID?.toString()
      @renderSelectors('#ask-teacher-for-help')

  toggleControls: (e, enabled) ->
    return if e.controls and not ('editor' in e.controls)
    return if enabled is @controlsEnabled
    @controlsEnabled = enabled
    @$el.toggleClass 'read-only', not enabled

  otherTeam: =>
    teams = _.without ['humans', 'ogres'], @options.spell.team
    teams[0]

  onSwitchTeam: =>
    protocol = window.location.protocol + "//"
    host = window.location.host
    pathname = window.location.pathname
    query = window.location.search
    query = query.replace(/team=[^&]*&?/, '')
    if query
      if query.endsWith('?') or query.endsWith('&')
        query += 'team='
      else
        query += '&team='
    else
      query = '?team='
    window.location.href = protocol+host+pathname+query + @otherTeam()

  onToggleBlocks: ->
    @blocks = not @blocks
    Backbone.Mediator.publish 'tome:toggle-blocks', { blocks: @blocks }

  onClickHelpButton: ->
    Backbone.Mediator.publish('websocket:asking-help', {
      msg:
        to: @teacherID.toString(),
        type: 'msg',
        info:
          text: $.i18n.t('teacher.student_ask_for_help', {name: me.broadName()})
          url: window.location.pathname
    })

  destroy: ->
    super()

  onClickHintButton: ->
    this.openModalView(new AskAIHelpView({}))
