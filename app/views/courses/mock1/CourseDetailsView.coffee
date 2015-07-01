app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/courses/mock1/course-details'

module.exports = class CourseDetailsView extends RootView
  id: 'course-details-view'
  template: template

  events:
    'click .edit-class-name-btn': 'onClickEditClassName'
    'click .edit-description-btn': 'onClickEditClassDescription'
    'change .select-session': 'onChangeSession'

  constructor: (options, @courseID) ->
    super options
    @initData()

  getRenderData: ->
    context = super()
    context.course = @course ? {}
    context.instance = @instances?[@currentInstanceIndex] ? {}
    context.instances = @instances ? []
    context

  initData: ->
    mockData = require 'views/courses/mock1/CoursesMockData'
    @course = mockData.courses[@courseID]
    # @instance = mockData.instances[_.random(0, mockData.instances.length - 1)]
    @currentInstanceIndex = 0
    @instances = mockData.instances

  onChangeSession: (e) ->
    newSessionValue = $(e.target).val()
    for val, index in @instances when val.name is newSessionValue
      @currentInstanceIndex = index
    @render?()

  onClickEditClassName: (e) ->
    alert 'TODO: Popup for editing name for this course session'

  onClickEditClassDescription: (e) ->
    alert 'TODO: Popup for editing description for this course session'
