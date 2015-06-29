app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/courses/mock1/courses'

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click .btn-enter': 'onClickEnter'
    'click .btn-have-code': 'onClickHaveCode'
    'click .btn-more-info': 'onClickMoreInfo'

  constructor: (options) ->
    super options
    @initData()

  getRenderData: ->
    context = super()
    context.courses = @courses ? []
    context

  initData: ->
    mockData = require 'views/courses/mock1/CoursesMockData'
    @courses = mockData.courses
    for course, i in @courses
      if i is 0 or _.random(0, 2) is 0
        course.unlocked = true
      else
        break

  onClickEnter: (e) ->
    courseID = $(e.target).data('course-id')
    app.router.navigate "/courses/mock1/#{courseID}"
    window.location.reload()

  onClickHaveCode: (e) ->
    courseID = $(e.target).data('course-id')
    alert 'TODO: Popup for entering prepaid code to unlock this course'

    # TODO: would just navigate instead of rendering unlock here in practice
    @courses[courseID].unlocked = true
    @render?()
    # app.router.navigate "/courses/mock1/#{courseID}"
    # window.location.reload()

  onClickMoreInfo: (e) ->
    courseID = $(e.target).data('course-id')
    app.router.navigate "/courses/mock1/#{courseID}/info"
    window.location.reload()
