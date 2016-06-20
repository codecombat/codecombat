RootView = require 'views/core/RootView'
template = require 'templates/editor/level/edit'
Level = require 'models/Level'
LevelSystem = require 'models/LevelSystem'
World = require 'lib/world/world'
DocumentFiles = require 'collections/DocumentFiles'
LevelLoader = require 'lib/LevelLoader'

# in the template, but need to require them to load them
require 'views/modal/RevertModal'
require 'views/editor/level/modals/GenerateTerrainModal'

ThangsTabView = require './thangs/ThangsTabView'
SettingsTabView = require './settings/SettingsTabView'
ScriptsTabView = require './scripts/ScriptsTabView'
ComponentsTabView = require './components/ComponentsTabView'
SystemsTabView = require './systems/SystemsTabView'
TasksTabView = require './tasks/TasksTabView'
SaveLevelModal = require './modals/SaveLevelModal'
ArtisanGuideModal = require './modals/ArtisanGuideModal'
ForkModal = require 'views/editor/ForkModal'
SaveVersionModal = require 'views/editor/modal/SaveVersionModal'
PatchesView = require 'views/editor/PatchesView'
RelatedAchievementsView = require 'views/editor/level/RelatedAchievementsView'
VersionHistoryView = require './modals/LevelVersionsModal'
ComponentsDocumentationView = require 'views/editor/docs/ComponentsDocumentationView'
SystemsDocumentationView = require 'views/editor/docs/SystemsDocumentationView'
LevelFeedbackView = require 'views/editor/level/LevelFeedbackView'
storage = require 'core/storage'

require 'vendor/coffeescript' # this is tenuous, since the LevelSession and LevelComponent models are what compile the code
require 'vendor/treema'

# Make sure that all of our Aethers are loaded, so that if we try to preview the level, it will work.
require 'vendor/aether-javascript'
require 'vendor/aether-python'
require 'vendor/aether-coffeescript'
require 'vendor/aether-lua'
require 'vendor/aether-java'

module.exports = class LevelEditView extends RootView
  id: 'editor-level-view'
  className: 'editor'
  template: template
  cache: false

  events:
    'click #play-button': 'onPlayLevel'
    'click .play-with-team-button': 'onPlayLevel'
    'click .play-with-team-parent': 'onPlayLevelTeamSelect'
    'click #commit-level-start-button': 'startCommittingLevel'
    'click li:not(.disabled) > #fork-start-button': 'startForking'
    'click #level-history-button': 'showVersionHistory'
    'click #undo-button': 'onUndo'
    'mouseenter #undo-button': 'showUndoDescription'
    'click #redo-button': 'onRedo'
    'mouseenter #redo-button': 'showRedoDescription'
    'click #patches-tab': -> @patchesView.load()
    'click #components-tab': -> @subviews.editor_level_components_tab_view.refreshLevelThangsTreema @level.get('thangs')
    'click #artisan-guide-button': 'showArtisanGuide'
    'click #level-patch-button': 'startPatchingLevel'
    'click #level-watch-button': 'toggleWatchLevel'
    'click li:not(.disabled) > #pop-level-i18n-button': 'onPopulateI18N'
    'click a[href="#editor-level-documentation"]': 'onClickDocumentationTab'
    'mouseup .nav-tabs > li a': 'toggleTab'

  constructor: (options, @levelID) ->
    super options
    @supermodel.shouldSaveBackups = (model) ->
      model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, headless: true, sessionless: true
    @level = @levelLoader.level
    @files = new DocumentFiles(@levelLoader.level)
    @supermodel.loadCollection(@files, 'file_names')

  destroy: ->
    clearInterval @timerIntervalID
    super()

  showLoading: ($el) ->
    $el ?= @$el.find('.outer-content')
    super($el)

  getTitle: -> "LevelEditor - " + (@level.get('name') or '...')

  onLoaded: ->
    _.defer =>
      @world = @levelLoader.world
      @render()
      @timerIntervalID = setInterval @incrementBuildTime, 1000

  getRenderData: (context={}) ->
    context = super(context)
    context.level = @level
    context.authorized = me.isAdmin() or @level.hasWriteAccess(me)
    context.anonymous = me.get('anonymous')
    context.recentlyPlayedOpponents = storage.load('recently-played-matches')?[@levelID] ? []
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @$el.find('a[data-toggle="tab"]').on 'shown.bs.tab', (e) =>
      Backbone.Mediator.publish 'editor:view-switched', {targetURL: $(e.target).attr('href')}
    @insertSubView new ThangsTabView world: @world, supermodel: @supermodel, level: @level
    @insertSubView new SettingsTabView supermodel: @supermodel
    @insertSubView new ScriptsTabView world: @world, supermodel: @supermodel, files: @files
    @insertSubView new ComponentsTabView supermodel: @supermodel
    @insertSubView new SystemsTabView supermodel: @supermodel, world: @world
    @insertSubView new TasksTabView world: @world, supermodel: @supermodel, level: @level
    @insertSubView new RelatedAchievementsView supermodel: @supermodel, level: @level
    @insertSubView new ComponentsDocumentationView lazy: true  # Don't give it the supermodel, it'll pollute it!
    @insertSubView new SystemsDocumentationView lazy: true  # Don't give it the supermodel, it'll pollute it!
    @insertSubView new LevelFeedbackView level: @level


    Backbone.Mediator.publish 'editor:level-loaded', level: @level
    @showReadOnly() if me.get('anonymous')
    @patchesView = @insertSubView(new PatchesView(@level), @$el.find('.patches-view'))
    @listenTo @patchesView, 'accepted-patch', -> location.reload()
    @$el.find('#level-watch-button').find('> span').toggleClass('secret') if @level.watching()

  onPlayLevelTeamSelect: (e) ->
    if @childWindow and not @childWindow.closed
      # We already have a child window open, so we don't need to ask for a team; we'll use its existing team.
      e.stopImmediatePropagation()
      @onPlayLevel e

  onPlayLevel: (e) ->
    team = $(e.target).data('team')
    opponentSessionID = $(e.target).data('opponent')
    sendLevel = =>
      @childWindow.Backbone.Mediator.publish 'level:reload-from-data', level: @level, supermodel: @supermodel
    if @childWindow and not @childWindow.closed
      # Reset the LevelView's world, but leave the rest of the state alone
      sendLevel()
    else
      # Create a new Window with a blank LevelView
      scratchLevelID = @level.get('slug') + '?dev=true'
      scratchLevelID += "&team=#{team}" if team
      scratchLevelID += "&opponent=#{opponentSessionID}" if opponentSessionID
      if me.get('name') is 'Nick'
        @childWindow = window.open("/play/level/#{scratchLevelID}", 'child_window', 'width=2560,height=1080,left=0,top=-1600,location=1,menubar=1,scrollbars=1,status=0,titlebar=1,toolbar=1', true)
      else
        @childWindow = window.open("/play/level/#{scratchLevelID}", 'child_window', 'width=1024,height=560,left=10,top=10,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0', true)
      @childWindow.onPlayLevelViewLoaded = (e) => sendLevel()  # still a hack
    @childWindow.focus()

  onUndo: ->
    TreemaNode.getLastTreemaWithFocus()?.undo()

  onRedo: ->
    TreemaNode.getLastTreemaWithFocus()?.redo()

  showUndoDescription: ->
    undoDescription = TreemaNode.getLastTreemaWithFocus().getUndoDescription()
    @$el.find('#undo-button').attr('title', $.i18n.t("general.undo_prefix") + " " + undoDescription + " " + $.i18n.t("general.undo_shortcut"))

  showRedoDescription: ->
    redoDescription = TreemaNode.getLastTreemaWithFocus().getRedoDescription()
    @$el.find('#redo-button').attr('title', $.i18n.t("general.redo_prefix") + " " + redoDescription + " " + $.i18n.t("general.redo_shortcut"))

  getCurrentView: ->
    currentViewID = @$el.find('.tab-pane.active').attr('id')
    return @patchesView if currentViewID is 'editor-level-patches'
    currentViewID = 'components-documentation-view' if currentViewID is 'editor-level-documentation'
    return @subviews[_.string.underscored(currentViewID)]

  startPatchingLevel: (e) ->
    @openModalView new SaveVersionModal({model: @level})
    Backbone.Mediator.publish 'editor:view-switched', {}

  startCommittingLevel: (e) ->
    @openModalView new SaveLevelModal level: @level, supermodel: @supermodel, buildTime: @levelBuildTime
    Backbone.Mediator.publish 'editor:view-switched', {}

  showArtisanGuide: (e) ->
    @openModalView new ArtisanGuideModal level: @level
    Backbone.Mediator.publish 'editor:view-switched', {}

  startForking: (e) ->
    @openModalView new ForkModal model: @level, editorPath: 'level'
    Backbone.Mediator.publish 'editor:view-switched', {}

  showVersionHistory: (e) ->
    versionHistoryView = new VersionHistoryView level: @level, @levelID
    @openModalView versionHistoryView
    Backbone.Mediator.publish 'editor:view-switched', {}

  toggleWatchLevel: ->
    button = @$el.find('#level-watch-button')
    @level.watch(button.find('.watch').is(':visible'))
    button.find('> span').toggleClass('secret')

  onPopulateI18N: ->
    @level.populateI18N()
    f = -> document.location.reload()
    setTimeout(f, 2000)

  toggleTab: (e) ->
    @renderScrollbar()
    return unless $(document).width() <= 800
    li = $(e.target).closest('li')
    if li.hasClass('active')
      li.parent().find('li').show()
    else
      li.parent().find('li').hide()
      li.show()
    console.log li.hasClass('active')

  onClickDocumentationTab: (e) ->
    # It's either too late at night or something is going on with Bootstrap nested tabs, so we do the click instead of using .active.
    return if @initializedDocs
    @initializedDocs = true
    @$el.find('a[href="#components-documentation-view"]').click()

  incrementBuildTime: =>
    return if application.userIsIdle
    @levelBuildTime ?= @level.get('buildTime') ? 0
    ++@levelBuildTime

  getTaskCompletionRatio: ->
    if not @level.get('tasks')?
      return '0/0'
    else
      return _.filter(@level.get('tasks'), (_elem) -> return _elem.complete).length + '/' + @level.get('tasks').length
