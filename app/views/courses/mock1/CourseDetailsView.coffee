app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/courses/mock1/course-details'

# TODO: show invite tab and no students tab if no students

module.exports = class CourseDetailsView extends RootView
  id: 'course-details-view'
  template: template

  constructor: (options, @courseID) ->
    super options
    @initData()

  getRenderData: ->
    context = super()
    context.course = @course ? {}
    context.instance = @instance ? {}
    context

  initData: ->
    mockData = require 'views/courses/mock1/CoursesMockData'
    @course = mockData.courses[@courseID]
    @instance = mockData.instances[_.random(0, mockData.instances.length - 1)]
