require('app/styles/editor/course/edit.sass')
RootView = require 'views/core/RootView'
template = require 'templates/editor/course/edit'
Course = require 'models/Course'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'

require 'lib/game-libraries'

module.exports = class CourseEditView extends RootView
  id: 'editor-course-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'

  constructor: (options, @courseID) ->
    super options
    @course = new Course(_id: @courseID)
    @course.saveBackups = true
    @supermodel.loadModel @course

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @course, 'change', =>
      @course.updateI18NCoverage()
      @treema.set('/', @course.attributes)

  buildTreema: ->
    return if @treema? or (not @course.loaded)
    data = $.extend(true, {}, @course.attributes)
    options =
      data: data
      filePath: "db/course/#{@course.get('_id')}"
      schema: Course.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
    @treema = @$el.find('#course-treema').treema(options)
    @treema.build()
    @treema.childrenTreemas.rewards?.open(3)

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @showReadOnly() if me.get('anonymous')
    @patchesView = @insertSubView(new PatchesView(@course), @$el.find('.patches-view'))
    @patchesView.load()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @course.set(key, value)
    @course.updateI18NCoverage()

    res = @course.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/course/#{@course.get('slug') or @course.id}"
      document.location.href = url
