app = require 'core/application'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses'
utils = require 'core/utils'

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click .btn-buy': 'onClickBuy'
    'click .btn-enroll': 'onClickEnroll'
    'click .btn-enter': 'onClickEnter'
    'click .btn-student': 'onClickStudent'
    'click .btn-teacher': 'onClickTeacher'

  constructor: (options) ->
    super(options)
    @praise = utils.getCoursePraise()
    @studentMode = utils.getQueryVariable('student', false) or options.studentMode
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
    @supermodel.loadCollection(@courseInstances, 'course_instances')

  getRenderData: ->
    context = super()
    context.courses = @courses.models ? []
    context.enrolledCourses = @enrolledCourses ? {}
    context.instances = @courseInstances.models ? []
    context.praise = @praise
    context.studentMode = @studentMode
    context

  afterRender: ->
    super()
    @setupCoursesFAQPopover()

  onCourseInstancesLoaded: ->
    @enrolledCourses = {}
    @enrolledCourses[courseInstance.get('courseID')] = true for courseInstance in @courseInstances.models

  setupCoursesFAQPopover: ->
    popoverTitle = "<h3>Courses FAQ<button type='button' class='close' onclick='$(&#39;.courses-faq&#39;).popover(&#39;hide&#39;);'>&times;</button></h3>"
    popoverContent = "<p><strong>Q:</strong> What's the difference between these courses and the single player game?</p>"
    popoverContent += "<p><strong>A:</strong> The single player game is designed for individuals, while the courses are designed for classes.</p>"
    popoverContent += "<p>The single player game has items, gems, hero selection, leveling up, and in-app purchases.  Courses have classroom management features and streamlined student-focused level pacing.</p>"
    @$el.find('.courses-faq').popover(
      animation: true
      html: true
      placement: 'top'
      trigger: 'click'
      title: popoverTitle
      content: popoverContent
      container: @$el
    ).on 'shown.bs.popover', =>
      application.tracker?.trackEvent 'Subscription payment methods hover'

  onClickBuy: (e) ->
    courseID = $(e.target).data('course-id')
    route = "/courses/enroll/#{courseID}"
    viewClass = require 'views/courses/CourseEnrollView'
    viewArgs = [{}, courseID]
    navigationEvent = route: route, viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickEnroll: (e) ->
    alert('TODO: redeem course prepaid and navigate to correct course instance')

  onClickEnter: (e) ->
    $('.continue-dialog').modal('hide')
    courseID = $(e.target).data('course-id')
    courseInstanceID = $('.select-session').val()
    viewClass = require 'views/courses/CourseDetailsView'
    viewArgs = [{courseInstanceID:courseInstanceID}, courseID]
    navigationEvent = route: "/courses/#{courseID}", viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickStudent: (e) ->
    route = "/courses?student=true"
    viewClass = require 'views/courses/CoursesView'
    viewArgs = [studentMode: true]
    navigationEvent = route: route, viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickTeacher: (e) ->
    route = "/courses?student=false"
    viewClass = require 'views/courses/CoursesView'
    viewArgs = [studentMode: false]
    navigationEvent = route: route, viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent
