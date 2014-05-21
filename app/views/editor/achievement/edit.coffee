View = require 'views/kinds/RootView'
ErrorView = require '../../error_view'
template = require 'templates/editor/achievement/edit'
Achievement = require 'models/Achievement'

module.exports = class AchievementEditView extends View
  id: "editor-achievement-edit-view"
  template: template
  startsLoading: true

  events:
    'click #save-button': 'openSaveModal'

  subscriptions:
    'save-achievement': 'saveAchievement'

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
      #filePath: "db/thang.type/#{@article.get('original')}"
      schema: Achievement.schema
      readOnly: me.get('anonymous')
      callbacks:
        change: @pushChangesToPreview
    @treema = @$el.find('#achievement-treema').treema(options)

    @treema.build()

  pushChangesToPreview: =>
    'TODO'

  getRenderData: (context={}) ->
    context = super(context)
    context.achievement = @achievement
    context.authorized = me.isAdmin()
    context

  openSaveModal: ->
    'TODO'

  saveAchievement: (e) ->
    'TODO'