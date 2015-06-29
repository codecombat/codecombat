app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/courses/mock1/course-info'

module.exports = class CourseInfoView extends RootView
  id: 'course-info-view'
  template: template

  events:
    'click .btn-enroll': 'onClickEnroll'

  constructor: (options, @courseID) ->
    super options
    @initData()

  getRenderData: ->
    context = super()
    context.course = @course ? {}
    context.courseID = @courseID
    context.praise = @praise
    context

  initData: ->
    mockData = require 'views/courses/mock1/CoursesMockData'
    @course = mockData.courses[@courseID]
    @praise = mockData.praise[_.random(0, mockData.praise.length - 1)]

  onClickEnroll: (e) ->
    courseID = $(e.target).data('course-id')
    app.router.navigate "/courses/mock1/#{courseID}/enroll"
    window.location.reload()
