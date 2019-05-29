require('app/styles/editor/level/documentation_tab.sass')
RootView = require 'views/core/RootView'
template = require 'templates/editor/level/level-edit-view'
Level = require 'models/Level'
LevelSystem = require 'models/LevelSystem'
LevelComponent = require 'models/LevelComponent'
LevelSystems = require 'collections/LevelSystems'
LevelComponents = require 'collections/LevelComponents'
World = require 'lib/world/world'
DocumentFiles = require 'collections/DocumentFiles'
LevelLoader = require 'lib/LevelLoader'

Campaigns = require 'collections/Campaigns'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'

RevertModal = require 'views/modal/RevertModal'
GenerateTerrainModal = require 'views/editor/level/modals/GenerateTerrainModal'

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
SaveBranchModal = require 'views/editor/level/modals/SaveBranchModal'
LoadBranchModal = require 'views/editor/level/modals/LoadBranchModal'
PatchesView = require 'views/editor/PatchesView'
RelatedAchievementsView = require 'views/editor/level/RelatedAchievementsView'
VersionHistoryView = require './modals/LevelVersionsModal'
ComponentsDocumentationView = require 'views/editor/docs/ComponentsDocumentationView'
SystemsDocumentationView = require 'views/editor/docs/SystemsDocumentationView'
LevelFeedbackView = require 'views/editor/level/LevelFeedbackView'
storage = require 'core/storage'
utils = require 'core/utils'
loadAetherLanguage = require("lib/loadAetherLanguage");

require 'vendor/scripts/coffeescript' # this is tenuous, since the LevelSession and LevelComponent models are what compile the code
require 'lib/setupTreema'

# Make sure that all of our languages are loaded, so that if we try to preview the level, it will work.
require 'bower_components/aether/build/html'
Promise.all(
  ["javascript", "python", "coffeescript", "lua"].map(
    loadAetherLanguage
  )
)
require 'lib/game-libraries'

module.exports = class LevelEditView extends RootView
  id: 'editor-level-view'
  className: 'editor'
  template: template
  cache: false

  events:
    'click #play-button': 'onPlayLevel'
    'click .play-with-team-button': 'onPlayLevel'
    'click .play-with-team-parent': 'onPlayLevelTeamSelect'
    'click .play-classroom-level': 'onPlayLevel'
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
    'click #save-branch': 'onClickSaveBranch'
    'click #load-branch': 'onClickLoadBranch'
    'mouseup .nav-tabs > li a': 'toggleTab'
    'click [data-toggle="coco-modal"][data-target="modal/RevertModal"]': 'openRevertModal'
    'click [data-toggle="coco-modal"][data-target="editor/level/modals/GenerateTerrainModal"]': 'openGenerateTerrainModal'

  constructor: (options, @levelID) ->
    super options
    @supermodel.shouldSaveBackups = (model) ->
      model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, headless: true, sessionless: true, loadArticles: true
    @level = @levelLoader.level
    @files = new DocumentFiles(@levelLoader.level)
    @supermodel.loadCollection(@files, 'file_names')
    @campaigns = new Campaigns()
    @supermodel.trackRequest @campaigns.fetchByType('course', { data: { project: 'levels' } })
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')

  getMeta: ->
    title: 'Level Editor'

  destroy: ->
    clearInterval @timerIntervalID
    super()

  showLoading: ($el) ->
    $el ?= @$el.find('.outer-content')
    super($el)

  onLoaded: ->
    _.defer =>
      @world = @levelLoader.world
      @render()
      @timerIntervalID = setInterval @incrementBuildTime, 1000
    campaignCourseMap = {}
    campaignCourseMap[course.get('campaignID')] = course.id for course in @courses.models
    for campaign in @campaigns.models
      for levelID, level of campaign.get('levels') when levelID is @level.get('original')
        @courseID = campaignCourseMap[campaign.id]
      break if @courseID
    if not @courseID and (me.isAdmin() or me.isArtisan())
      # Give it a fake course ID so we can test it in course mode before it's in a course.
      @courseID = '560f1a9f22961295f9427742'
    @getLevelCompletionRate()

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
    @listenTo @level, 'change:tasks', => @renderSelectors '#tasks-tab'
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
    @listenTo @patchesView, 'accepted-patch', (attrs) ->
      if attrs?.save
        f = => @startCommittingLevel(attrs)
        setTimeout f, 400 # Give some time for closing patch modal
      else
        location.reload() unless key.shift  # Reload to make sure changes propagate, unless secret shift shortcut
    @$el.find('#level-watch-button').find('> span').toggleClass('secret') if @level.watching()

  openRevertModal: (e) ->
    e.stopPropagation()
    @openModalView new RevertModal()

  openGenerateTerrainModal: (e) ->
    e.stopPropagation()
    @openModalView new GenerateTerrainModal()

  onPlayLevelTeamSelect: (e) ->
    if @childWindow and not @childWindow.closed
      # We already have a child window open, so we don't need to ask for a team; we'll use its existing team.
      e.stopImmediatePropagation()
      @onPlayLevel e

  onPlayLevel: (e) ->
    team = $(e.target).data('team')
    opponentSessionID = $(e.target).data('opponent')
    if $(e.target).data('classroom') is 'home'
      newClassMode = @lastNewClassMode = undefined
    else if $(e.target).data('classroom')
      newClassMode = @lastNewClassMode = true
    else
      newClassMode = @lastNewClassMode
    newClassLanguage = @lastNewClassLanguage = ($(e.target).data('code-language') ? @lastNewClassLanguage) or undefined
    sendLevel = =>
      @childWindow.Backbone.Mediator.publish 'level:reload-from-data', level: @level, supermodel: @supermodel
    if @childWindow and not @childWindow.closed and @playClassMode is newClassMode and @playClassLanguage is newClassLanguage
      # Reset the LevelView's world, but leave the rest of the state alone
      sendLevel()
    else
      # Create a new Window with a blank LevelView
      scratchLevelID = @level.get('slug') + '?dev=true'
      scratchLevelID += "&team=#{team}" if team
      scratchLevelID += "&opponent=#{opponentSessionID}" if opponentSessionID
      @playClassMode = newClassMode
      @playClassLanguage = newClassLanguage
      if @playClassMode
        scratchLevelID += "&course=#{@courseID}"
        scratchLevelID += "&codeLanguage=#{@playClassLanguage}"
      if me.get('name') is 'Nick'
        @childWindow = window.open("/play/level/#{scratchLevelID}", 'child_window', 'width=2560,height=1080,left=0,top=-1600,location=1,menubar=1,scrollbars=1,status=0,titlebar=1,toolbar=1', true)
      else
        @childWindow = window.open("/play/level/#{scratchLevelID}", 'child_window', 'width=1280,height=640,left=10,top=10,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0', true)
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
    @openModalView new SaveLevelModal level: @level, supermodel: @supermodel, buildTime: @levelBuildTime, commitMessage: e?.commitMessage
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
    totalChanges = @level.populateI18N()

    levelComponentMap = _(currentView.supermodel.getModels(LevelComponent))
      .map((c) -> [c.get('original'), c])
      .object()
      .value()

    for thang, thangIndex in @level.get('thangs')
      for thangComponent, thangComponentIndex in thang.components
        component = levelComponentMap[thangComponent.original]
        configSchema = component.get('configSchema')
        path = "/thangs/#{thangIndex}/components/#{thangComponentIndex}/config"
        totalChanges += @level.populateI18N(thangComponent.config, configSchema, path)

    if totalChanges
      f = -> document.location.reload()
      setTimeout(f, 500)
    else
      noty timeout: 2000, text: 'No changes.', type: 'information', layout: 'topRight'

  onClickSaveBranch: ->
    components = new LevelComponents(@supermodel.getModels(LevelComponent))
    systems = new LevelSystems(@supermodel.getModels(LevelSystem))
    @openModalView new SaveBranchModal({components, systems})
    Backbone.Mediator.publish 'editor:view-switched', {}

  onClickLoadBranch: ->
    components = new LevelComponents(@supermodel.getModels(LevelComponent))
    systems = new LevelSystems(@supermodel.getModels(LevelSystem))
    @openModalView new LoadBranchModal({components, systems})
    Backbone.Mediator.publish 'editor:view-switched', {}

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

  getLevelCompletionRate: ->
    return unless me.isAdmin()
    startDay = utils.getUTCDay -14
    startDayDashed = "#{startDay[0..3]}-#{startDay[4..5]}-#{startDay[6..7]}"
    endDay = utils.getUTCDay -1
    endDayDashed = "#{endDay[0..3]}-#{endDay[4..5]}-#{endDay[6..7]}"
    success = (data) =>
      return if @destroyed
      started = 0
      finished = 0
      for day in data
        started += day.started ? 0
        finished += day.finished ? 0
      rate = finished / started
      rateDisplay = (rate * 100).toFixed(1) + '%'
      @$('#completion-rate').text rateDisplay
    request = @supermodel.addRequestResource 'level_completions', {
      url: '/db/analytics_perday/-/level_completions'
      data: {startDay: startDay, endDay: endDay, slug: @level.get('slug')}
      method: 'POST'
      success: success
    }, 0
    request.load()
