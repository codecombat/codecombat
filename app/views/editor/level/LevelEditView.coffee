RootView = require 'views/kinds/RootView'
template = require 'templates/editor/level/edit'
Level = require 'models/Level'
LevelSystem = require 'models/LevelSystem'
World = require 'lib/world/world'
DocumentFiles = require 'collections/DocumentFiles'
LevelLoader = require 'lib/LevelLoader'

ThangsTabView = require './thangs/ThangsTabView'
SettingsTabView = require './settings/SettingsTabView'
ScriptsTabView = require './scripts/ScriptsTabView'
ComponentsTabView = require './components/ComponentsTabView'
SystemsTabView = require './systems/SystemsTabView'
SaveLevelModal = require './modals/SaveLevelModal'
ForkModal = require 'views/editor/ForkModal'
SaveVersionModal = require 'views/modal/SaveVersionModal'
PatchesView = require 'views/editor/PatchesView'
RelatedAchievementsView = require 'views/editor/level/RelatedAchievementsView'
VersionHistoryView = require './modals/LevelVersionsModal'
ComponentDocsView = require 'views/docs/ComponentDocumentationView'

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
    'click #fork-start-button': 'startForking'
    'click #level-history-button': 'showVersionHistory'
    'click #undo-button': 'onUndo'
    'mouseenter #undo-button': 'showUndoDescription'
    'click #redo-button': 'onRedo'
    'mouseenter #redo-button': 'showRedoDescription'
    'click #patches-tab': -> @patchesView.load()
    'click #components-tab': -> @subviews.editor_level_components_tab_view.refreshLevelThangsTreema @level.get('thangs')
    'click #level-patch-button': 'startPatchingLevel'
    'click #level-watch-button': 'toggleWatchLevel'
    'click #pop-level-i18n-button': -> @level.populateI18N()
    'mouseup .nav-tabs > li a': 'toggleTab'

  constructor: (options, @levelID) ->
    super options
    @supermodel.shouldSaveBackups = (model) ->
      model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, headless: true
    @level = @levelLoader.level
    @files = new DocumentFiles(@levelLoader.level)
    @supermodel.loadCollection(@files, 'file_names')

  showLoading: ($el) ->
    $el ?= @$el.find('.outer-content')
    super($el)

  onLoaded: ->
    _.defer =>
      @world = @levelLoader.world
      @render()

  getRenderData: (context={}) ->
    context = super(context)
    context.level = @level
    context.authorized = me.isAdmin() or @level.hasWriteAccess(me)
    context.anonymous = me.get('anonymous')
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @$el.find('a[data-toggle="tab"]').on 'shown.bs.tab', (e) =>
      Backbone.Mediator.publish 'level:view-switched', e
    @insertSubView new ThangsTabView world: @world, supermodel: @supermodel, level: @level
    @insertSubView new SettingsTabView supermodel: @supermodel
    @insertSubView new ScriptsTabView world: @world, supermodel: @supermodel, files: @files
    @insertSubView new ComponentsTabView supermodel: @supermodel
    @insertSubView new SystemsTabView supermodel: @supermodel
    @insertSubView new RelatedAchievementsView supermodel: @supermodel, level: @level
    @insertSubView new ComponentDocsView  # Don't give it the supermodel, it'll pollute it!

    Backbone.Mediator.publish 'level-loaded', level: @level
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
    sendLevel = =>
      @childWindow.Backbone.Mediator.publish 'level-reload-from-data', level: @level, supermodel: @supermodel
    if @childWindow and not @childWindow.closed
      # Reset the LevelView's world, but leave the rest of the state alone
      sendLevel()
    else
      # Create a new Window with a blank LevelView
      scratchLevelID = @level.get('slug') + '?dev=true'
      scratchLevelID += "&team=#{team}" if team
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
    @$el.find('#undo-button').attr('title', 'Undo ' + undoDescription + ' (Ctrl+Z)')

  showRedoDescription: ->
    redoDescription = TreemaNode.getLastTreemaWithFocus().getRedoDescription()
    @$el.find('#redo-button').attr('title', 'Redo ' + redoDescription + ' (Ctrl+Shift+Z)')

  getCurrentView: ->
    tabText = _.string.underscored $('li.active')[0]?.textContent
    currentView = @subviews["editor_level_#{tabText}_tab_view"]
    if tabText is 'patches' then currentView = @patchesView
    if tabText is 'documentation' then currentView = @subviews.docs_components_view
    currentView

  startPatchingLevel: (e) ->
    @openModalView new SaveVersionModal({model: @level})
    Backbone.Mediator.publish 'level:view-switched', e

  startCommittingLevel: (e) ->
    @openModalView new SaveLevelModal level: @level, supermodel: @supermodel
    Backbone.Mediator.publish 'level:view-switched', e

  startForking: (e) ->
    @openModalView new ForkModal model: @level, editorPath: 'level'
    Backbone.Mediator.publish 'level:view-switched', e

  showVersionHistory: (e) ->
    versionHistoryView = new VersionHistoryView level: @level, @levelID
    @openModalView versionHistoryView
    Backbone.Mediator.publish 'level:view-switched', e

  toggleWatchLevel: ->
    button = @$el.find('#level-watch-button')
    @level.watch(button.find('.watch').is(':visible'))
    button.find('> span').toggleClass('secret')

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
