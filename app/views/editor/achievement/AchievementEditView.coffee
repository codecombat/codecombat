RootView = require 'views/kinds/RootView'
template = require 'templates/editor/achievement/edit'
Achievement = require 'models/Achievement'
AchievementPopup = require 'views/achievements/AchievementPopup'
ConfirmModal = require 'views/modal/ConfirmModal'
errors = require 'lib/errors'
app = require 'application'

module.exports = class AchievementEditView extends RootView
  id: 'editor-achievement-edit-view'
  template: template

  events:
    'click #save-button': 'saveAchievement'
    'click #recalculate-button': 'confirmRecalculation'
    'click #delete-button': 'confirmDeletion'

  subscriptions:
    'save-new': 'saveAchievement'

  constructor: (options, @achievementID) ->
    super options
    @achievement = new Achievement(_id: @achievementID)
    @achievement.saveBackups = true
    @supermodel.loadModel @achievement, 'achievement'
    @pushChangesToPreview = _.throttle(@pushChangesToPreview, 500)

  onLoaded: ->
    super()
    @buildTreema()

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
    @treema = @$el.find('#achievement-treema').treema(options)
    @treema.build()

  getRenderData: (context={}) ->
    context = super(context)
    context.achievement = @achievement
    context.authorized = me.isAdmin()
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @pushChangesToPreview()

  pushChangesToPreview: =>
    @$el.find('#achievement-view').empty()
    for key, value of @treema.data
      @achievement.set key, value
    earned = earnedPoints: @achievement.get 'worth'
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

  confirmRecalculation: ->
    renderData =
      'confirmTitle': 'Are you really sure?'
      'confirmBody': 'This will trigger recalculation of the achievement for all users. Are you really sure you want to go down this path?'
      'confirmDecline': 'Not really'
      'confirmConfirm': 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @recalculateAchievement
    @openModalView confirmModal

  confirmDeletion: ->
    renderData =
      'confirmTitle': 'Are you really sure?'
      'confirmBody': 'This will completely delete the achievement, potentially breaking a lot of stuff you don\'t want breaking. Are you entirely sure?'
      'confirmDecline': 'Not really'
      'confirmConfirm': 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @deleteAchievement
    @openModalView confirmModal

  recalculateAchievement: =>
    $.ajax
      data: JSON.stringify(earnedAchievements: [@achievement.get('slug') or @achievement.get('_id')])
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
