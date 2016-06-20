RootView = require 'views/core/RootView'
template = require 'templates/editor/achievement/edit'
Achievement = require 'models/Achievement'
AchievementPopup = require 'views/core/AchievementPopup'
ConfirmModal = require 'views/editor/modal/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'
app = require 'core/application'
nodes = require 'views/editor/level/treema_nodes'

module.exports = class AchievementEditView extends RootView
  id: 'editor-achievement-edit-view'
  template: template

  events:
    'click #save-button': 'saveAchievement'
    'click #recalculate-button': 'confirmRecalculation'
    'click #recalculate-all-button': 'confirmAllRecalculation'
    'click #delete-button': 'confirmDeletion'

  constructor: (options, @achievementID) ->
    super options
    @achievement = new Achievement(_id: @achievementID)
    @achievement.saveBackups = true
    @supermodel.loadModel @achievement
    @pushChangesToPreview = _.throttle(@pushChangesToPreview, 500)

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @achievement, 'change', =>
      @achievement.updateI18NCoverage()
      @treema.set('/', @achievement.attributes)

  buildTreema: ->
    return if @treema? or (not @achievement.loaded)
    data = $.extend(true, {}, @achievement.attributes)
    options =
      data: data
      filePath: "db/achievement/#{@achievement.get('_id')}"
      schema: Achievement.schema
      readOnly: me.get('anonymous')
      callbacks:
        change: @pushChangesToPreview
      nodeClasses:
        'thang-type': nodes.ThangTypeNode
        'item-thang-type': nodes.ItemThangTypeNode
      supermodel: @supermodel
    @treema = @$el.find('#achievement-treema').treema(options)
    @treema.build()
    @treema.childrenTreemas.rewards?.open(3)
    @pushChangesToPreview()

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @showReadOnly() if me.get('anonymous')
    @pushChangesToPreview()
    @patchesView = @insertSubView(new PatchesView(@achievement), @$el.find('.patches-view'))
    @patchesView.load()

  pushChangesToPreview: =>
    return unless @treema
    @$el.find('#achievement-view').empty()
    for key, value of @treema.data
      @achievement.set key, value
    earned = get: (key) => {earnedPoints: @achievement.get('worth'), previouslyAchievedAmount: 0}[key]
    popup = new AchievementPopup achievement: @achievement, earnedAchievement: earned, popup: false, container: $('#achievement-view')

  openSaveModal: ->
    'Maybe later' # TODO patch patch patch

  saveAchievement: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @achievement.set(key, value)

    res = @achievement.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/achievement/#{@achievement.get('slug') or @achievement.id}"
      document.location.href = url

  confirmRecalculation: (e, all=false) ->
    renderData =
      title: 'Are you really sure?'
      body: "This will trigger recalculation of #{if all then 'all achievements' else 'the achievement'} for all users. Are you really sure you want to go down this path?"
      decline: 'Not really'
      confirm: 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @recalculateAchievement
    @recalculatingAll = all
    @openModalView confirmModal

  confirmAllRecalculation: (e) ->
    @confirmRecalculation e, true

  confirmDeletion: ->
    renderData =
      title: 'Are you really sure?'
      body: 'This will completely delete the achievement, potentially breaking a lot of stuff you don\'t want breaking. Are you entirely sure?'
      decline: 'Not really'
      confirm: 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @deleteAchievement
    @openModalView confirmModal

  recalculateAchievement: =>
    data = if @recalculatingAll then {} else {achievements: [@achievement.get('slug') or @achievement.get('_id')]}
    $.ajax
      data: JSON.stringify data
      success: (data, status, jqXHR) ->
        noty
          timeout: 5000
          text: 'Recalculation process started'
          type: 'success'
          layout: 'topCenter'
      error: (jqXHR, status, error) ->
        console.error jqXHR
        noty
          timeout: 5000
          text: "Starting recalculation process failed with error code #{jqXHR.status}"
          type: 'error'
          layout: 'topCenter'
      url: '/admin/earned.achievement/recalculate'
      type: 'POST'
      contentType: 'application/json'

  deleteAchievement: =>
    console.debug 'deleting'
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 5000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
        _.delay ->
          app.router.navigate '/editor/achievement', trigger: true
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting achievement failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/achievement/#{@achievement.id}"
