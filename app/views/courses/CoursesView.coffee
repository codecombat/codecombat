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
    popoverTitle = "<h3>" + $.i18n.t('courses.faq') + "<button type='button' class='close' onclick='$(&#39;.courses-faq&#39;).popover(&#39;hide&#39;);'>&times;</button></h3>"
    popoverContent = "<p><strong>" + $.i18n.t('courses.question') + "</strong> " + $.i18n.t('courses.question1') + "</p>"
    popoverContent += "<p><strong>" + $.i18n.t('courses.answer') + "</strong> " + $.i18n.t('courses.answer1') + "</p>"
    popoverContent += "<p>" + $.i18n.t('courses.answer2') + "</p>"
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
    $('.continue-dialog').modal('hide')
    courseID = $(e.target).data('course-id')
    route = "/courses/enroll/#{courseID}"
    viewClass = require 'views/courses/CourseEnrollView'
    viewArgs = [{}, courseID]
    navigationEvent = route: route, viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickEnroll: (e) ->
    $('.continue-dialog').modal('hide')
    courseID = $(e.target).data('course-id')
    prepaidCode = $(".code-input[data-course-id=#{courseID}]").val()
    data = prepaidCode: prepaidCode
    jqxhr = $.post('/db/course_instance/-/redeem_prepaid', data)
    jqxhr.done (data, textStatus, jqXHR) =>
      application.tracker?.trackEvent 'Redeemed course prepaid code', {courseID: courseID, prepaidCode: prepaidCode}
      # TODO: handle fetch errors
      me.fetch(cache: false).always =>
        route = "/courses/#{courseID}"
        viewArgs = [{}, courseID]
        Backbone.Mediator.publish 'router:navigate',
          route: route
          viewClass: 'views/courses/CourseDetailsView'
          viewArgs: viewArgs
    jqxhr.fail (xhr, textStatus, errorThrown) =>
      console.error 'Got an error redeeming a course prepaid code:', textStatus, errorThrown
      application.tracker?.trackEvent 'Failed to redeem course prepaid code', status: textStatus
      @state = 'unknown_error'
      @stateMessage = "#{xhr.status}: #{xhr.responseText}"
      @render?()

  onClickEnter: (e) ->
    $('.continue-dialog').modal('hide')
    courseID = $(e.target).data('course-id')
    courseInstanceID = $(".select-session[data-course-id=#{courseID}]").val()
    route = "/courses/#{courseID}/#{courseInstanceID}"
    viewClass = require 'views/courses/CourseDetailsView'
    viewArgs = [{}, courseID, courseInstanceID]
    navigationEvent = route: route, viewClass: viewClass, viewArgs: viewArgs
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
