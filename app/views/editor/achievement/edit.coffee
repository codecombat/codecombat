View = require 'views/kinds/RootView'
template = require 'templates/editor/achievement/edit'
Achievement = require 'models/Achievement'

module.exports = class AchievementEditView extends View
  id: "editor-achievement-edit-view"
  template: template
  startsLoading: true

  events:
    'click #save-button': 'saveAchievement'

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
