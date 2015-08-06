app = require 'core/application'
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
    'hidden.bs.modal #continueModal': 'onHideContinueModal'

  constructor: (options) ->
    super options
    @initData()

  getRenderData: ->
    context = super()
    context.courses = @courses ? []
    context.instances = @instances ? []
    context.praise = @praise
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
    $('#continueModal').modal('hide')
    courseID = $(e.target).data('course-id') ? 0
    viewClass = require 'views/courses/mock1/CourseEnrollView'
    viewArgs = [{}, courseID]
    navigationEvent = route: "/courses/mock1/enroll", viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickContinue: (e) ->
    courseID = $(e.target).data('course-id')
    courseTitle = $(e.target).data('course-title')
    $('#continueModal').find('.modal-title').text(courseTitle)
    $('#continueModal').find('.btn-buy').data('course-id', courseID)
    $('#continueModal').find('.btn-enroll').data('course-id', courseID)
    $('#continueModal').find('.btn-enter').data('course-id', courseID)
    $('#continueModal .row-pick-class').show() if @courses[courseID]?.unlocked

  onClickEnroll: (e) ->
    $('#continueModal').modal('hide')
    courseID = $(e.target).data('course-id')
    instanceID = _.random(0, @instances.length - 1)
    viewClass = require 'views/courses/mock1/CourseDetailsView'
    viewArgs = [{}, courseID, instanceID]
    navigationEvent = route: "/courses/mock1/#{courseID}", viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickEnter: (e) ->
    $('#continueModal').modal('hide')
    courseID = $(e.target).data('course-id')
    instanceName = $('.select-session').val()
    instanceID = index for val, index in @instances when val.name is instanceName
    viewClass = require 'views/courses/mock1/CourseDetailsView'
    viewArgs = [{}, courseID, instanceID]
    navigationEvent = route: "/courses/mock1/#{courseID}", viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onHideContinueModal: (e) ->
    $('#continueModal .row-pick-class').hide()
