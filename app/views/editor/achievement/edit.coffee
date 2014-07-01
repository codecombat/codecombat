View = require 'views/kinds/RootView'
template = require 'templates/editor/achievement/edit'
Achievement = require 'models/Achievement'
ConfirmModal = require 'views/modal/confirm'

module.exports = class AchievementEditView extends View
  id: 'editor-achievement-edit-view'
  template: template
  startsLoading: true

  events:
    'click #save-button': 'saveAchievement'
    'click #recalculate-button': 'confirmRecalculation'

  subscriptions:
    'save-new': 'saveAchievement'

  constructor: (options, @achievementID) ->
    super options
    @achievement = new Achievement(_id: @achievementID)
    @achievement.saveBackups = true

    @listenToOnce(@achievement, 'error',
      () =>
        @hideLoading()
        $(@$el).find('.main-content-area').children('*').not('#error-view').remove()

        @insertSubView(new ErrorView())
    )

    @achievement.fetch()
    @listenToOnce(@achievement, 'sync', @buildTreema)
    @pushChangesToPreview = _.throttle(@pushChangesToPreview, 500)

  buildTreema: ->
    return if @treema? or (not @achievement.loaded)

    @startsLoading = false
    @render()
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

  pushChangesToPreview: =>
    'TODO' # TODO might want some intrinsic preview thing

  getRenderData: (context={}) ->
    context = super(context)
    context.achievement = @achievement
    context.authorized = me.isAdmin()
    context

  openSaveModal: ->
    'Maybe later' # TODO

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

  confirmRecalculation: (e) ->
    renderData =
      'confirmTitle': 'Are you really sure?'
      'confirmBody': 'This will trigger recalculation of the achievement for all users. Are you really sure you want to go down this path?'
      'confirmDecline': 'Not really'
      'confirmConfirm': 'Definitely'

    confirmModal = new ConfirmModal(renderData)
    confirmModal.onConfirm @recalculateAchievement
    @openModalView confirmModal

  recalculateAchievement: =>
    $.ajax
      data: JSON.stringify(achievements: [@achievement.get('slug') or @achievement.get('_id')])
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
