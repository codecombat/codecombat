View = require 'views/kinds/RootView'
template = require 'templates/editor/level/edit'
Level = require 'models/Level'
LevelSystem = require 'models/LevelSystem'
World = require 'lib/world/world'
DocumentFiles = require 'collections/DocumentFiles'

ThangsTabView = require './thangs_tab_view'
SettingsTabView = require './settings_tab_view'
ScriptsTabView = require './scripts_tab_view'
ComponentsTabView = require './components_tab_view'
SystemsTabView = require './systems_tab_view'
LevelSaveView = require './save_view'
LevelForkView = require './fork_view'
SaveVersionModal = require 'views/modal/save_version_modal'
PatchesView = require 'views/editor/patches_view'
VersionHistoryView = require './versions_view'
ErrorView = require '../../error_view'

module.exports = class EditorLevelView extends View
  id: "editor-level-view"
  template: template
  startsLoading: true
  cache: false

  events:
    'click #play-button': 'onPlayLevel'
    'click #commit-level-start-button': 'startCommittingLevel'
    'click #fork-level-start-button': 'startForkingLevel'
    'click #level-history-button': 'showVersionHistory'
    'click #patches-tab': -> @patchesView.load()
    'click #level-patch-button': 'startPatchingLevel'
    'click #level-watch-button': 'toggleWatchLevel'
    
  subscriptions:
    'refresh-level-editor': 'rerenderAllViews'

  rerenderAllViews: ->
    for view in [@thangsTab, @settingsTab, @scriptsTab, @componentsTab, @systemsTab, @patchesView]
      view.render()
    
  constructor: (options, @levelID) ->
    super options
    @listenToOnce(@supermodel, 'loaded-all', @onAllLoaded)

    # load only the level itself and the one it points to, but no others
    # TODO: this is duplicated in views/play/level_view.coffee; need cleaner method
    @supermodel.shouldPopulate = (model) ->
      @levelsLoaded ?= 0
      @levelsLoaded += 1 if model.constructor.className is "Level"
      return false if @levelsLoaded > 1
      return true

    @supermodel.shouldSaveBackups = (model) ->
      model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem']

    @level = new Level _id: @levelID
    @listenToOnce(@level, 'sync', @onLevelLoaded)

    @listenToOnce(@supermodel, 'error',
      () =>
        @hideLoading()
        @insertSubView(new ErrorView())
    )
    @supermodel.populateModel @level

  showLoading: ($el) ->
    $el ?= @$el.find('.tab-content')
    super($el)

  onLevelLoaded: ->
    @files = new DocumentFiles(@level)
    @files.fetch()

  onAllLoaded: ->
    @level.unset('nextLevel') if _.isString(@level.get('nextLevel'))
    @initWorld()
    @startsLoading = false
    @render()  # do it again but without the loading screen

  initWorld: ->
    @world = new World @level.name

  getRenderData: (context={}) ->
    context = super(context)
    context.level = @level
    context.authorized = me.isAdmin() or @level.hasWriteAccess(me)
    context.anonymous = me.get('anonymous')
    context

  afterRender: ->
    return if @startsLoading
    super()
    @$el.find('a[data-toggle="tab"]').on 'shown.bs.tab', (e) =>
      Backbone.Mediator.publish 'level:view-switched', e
    @thangsTab = @insertSubView new ThangsTabView world: @world, supermodel: @supermodel
    @settingsTab = @insertSubView new SettingsTabView world: @world, supermodel: @supermodel
    @scriptsTab = @insertSubView new ScriptsTabView world: @world, supermodel: @supermodel, files: @files
    @componentsTab = @insertSubView new ComponentsTabView supermodel: @supermodel
    @systemsTab = @insertSubView new SystemsTabView supermodel: @supermodel
    Backbone.Mediator.publish 'level-loaded', level: @level
    @showReadOnly() if me.get('anonymous')
    @patchesView = @insertSubView(new PatchesView(@level), @$el.find('.patches-view'))
    @listenTo @patchesView, 'accepted-patch', -> setTimeout "location.reload()", 400
    @$el.find('#level-watch-button').find('> span').toggleClass('secret') if @level.watching()

  onPlayLevel: (e) ->
    sendLevel = =>
      @childWindow.Backbone.Mediator.publish 'level-reload-from-data', level: @level, supermodel: @supermodel
    if @childWindow and not @childWindow.closed
      # Reset the LevelView's world, but leave the rest of the state alone
      sendLevel()
    else
      # Create a new Window with a blank LevelView
      scratchLevelID = @level.get('slug') + "?dev=true"
      @childWindow = window.open("/play/level/#{scratchLevelID}", 'child_window', 'width=1024,height=560,left=10,top=10,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0', true)
      @childWindow.onPlayLevelViewLoaded = (e) => sendLevel()  # still a hack
    @childWindow.focus()

  startPatchingLevel: (e) ->
    @openModalView new SaveVersionModal({model:@level})
    Backbone.Mediator.publish 'level:view-switched', e
    
  startCommittingLevel: (e) ->
    @openModalView new LevelSaveView level: @level, supermodel: @supermodel
    Backbone.Mediator.publish 'level:view-switched', e

  startForkingLevel: (e) ->
    levelForkView = new LevelForkView level: @level
    @openModalView levelForkView
    Backbone.Mediator.publish 'level:view-switched', e

  showVersionHistory: (e) ->
    versionHistoryView = new VersionHistoryView level:@level, @levelID
    @openModalView versionHistoryView
    Backbone.Mediator.publish 'level:view-switched', e

  toggleWatchLevel: ->
    button = @$el.find('#level-watch-button')
    @level.watch(button.find('.watch').is(':visible'))
    button.find('> span').toggleClass('secret')
