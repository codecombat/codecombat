app = require 'core/application'
utils = require 'core/utils'
RootView = require 'views/core/RootView'
template = require 'templates/courses/mock1/courses'

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click .btn-buy': 'onClickBuy'
    'click .btn-continue': 'onClickContinue'
    'click .btn-enroll': 'onClickEnroll'
    'click .btn-enter': 'onClickEnter'
    'click .btn-student': 'onClickStudent'
    'hidden.bs.modal #continueModal': 'onHideContinueModal'

  constructor: (options) ->
    super options
    @studentMode = utils.getQueryVariable('student', false) or options.studentMode
    @initData()

  getRenderData: ->
    context = super()
    context.courses = @courses ? []
    context.instances = @instances ? []
    context.praise = @praise
    context.studentMode = @studentMode
    context

  initData: ->
    mockData = require 'views/courses/mock1/CoursesMockData'
    @courses = mockData.courses
    for course, i in @courses
      if _.random(0, 2) > 0
        course.unlocked = true
      else
        break
    @instances = mockData.instances
    @praise = mockData.praise[_.random(0, mockData.praise.length - 1)]

  onClickBuy: (e) ->
    courseID = $(e.target).data('course-id') ? 0
    app.router.navigate("/courses/mock1/enroll/#{courseID}")
    window.location.reload()

  onClickContinue: (e) ->
    courseID = $(e.target).data('course-id')
    courseTitle = $(e.target).data('course-title')
    $('#continueModal').find('.modal-title').text(courseTitle)
    $('#continueModal').find('.btn-buy').data('course-id', courseID)
    $('#continueModal').find('.btn-enroll').data('course-id', courseID)
    $('#continueModal').find('.btn-enter').data('course-id', courseID)
    $('#continueModal .row-pick-class').show() if @courses[courseID]?.unlocked
    if @courses[courseID]?.unlocked
      $('#continueModal .btn-buy').prop('innerText', 'Start new class')
    else if courseTitle is 'Introduction to Computer Science'
      $('#continueModal .btn-buy').prop('innerText', 'Get this FREE course!')
    else
      $('#continueModal .btn-buy').prop('innerText', 'Buy this course')

  onClickEnroll: (e) ->
    $('#continueModal').modal('hide')
    courseID = $(e.target).data('course-id')
    instanceID = _.random(0, @instances.length - 1)
    viewClass = require 'views/courses/mock1/CourseDetailsView'
    viewArgs = [{studentMode: @studentMode}, courseID, instanceID]
    navigationEvent = route: "/courses/mock1/#{courseID}", viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickEnter: (e) ->
    $('#continueModal').modal('hide')
    courseID = $(e.target).data('course-id')
    instanceName = $('.select-session').val()
    for val, index in @instances when val.name is instanceName
      instanceID = index
    viewClass = require 'views/courses/mock1/CourseDetailsView'
    viewArgs = [{}, courseID, instanceID]
    navigationEvent = route: "/courses/mock1/#{courseID}", viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickStudent: (e) ->
    route = "/courses/mock1?student=true"
    viewClass = require 'views/courses/mock1/CoursesView'
    viewArgs = [studentMode: true]
    navigationEvent = route: route, viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onHideContinueModal: (e) ->
    $('#continueModal .row-pick-class').hide()
