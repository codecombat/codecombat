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
    @studentMode = Backbone.history.getFragment()?.indexOf('courses/students') >= 0
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
    @supermodel.loadCollection(@courseInstances, 'course_instances')
    if prepaidCode = utils.getQueryVariable('_ppc', false)
      if me.isAnonymous()
        @state = 'ppc_logged_out'
      else
        @courseEnroll(prepaidCode)

  getRenderData: ->
    context = super()
    context.courses = @courses.models ? []
    context.enrolledCourses = @enrolledCourses ? {}
    context.instances = @courseInstances.models ? []
    context.praise = @praise
    context.state = @state
    context.stateMessage = @stateMessage
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
    prepaidCode = ($(".code-input[data-course-id=#{courseID}]").val() ? '').trim()
    @courseEnroll(prepaidCode)

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
    route = "/courses/students"
    viewClass = require 'views/courses/CoursesView'
    navigationEvent = route: route, viewClass: viewClass, viewArgs: []
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickTeacher: (e) ->
    route = "/courses/teachers"
    viewClass = require 'views/courses/CoursesView'
    navigationEvent = route: route, viewClass: viewClass, viewArgs: []
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  courseEnroll: (prepaidCode) ->
    @state = 'enrolling'
    @render?()
    data = prepaidCode: prepaidCode
    jqxhr = $.post('/db/course_instance/-/redeem_prepaid', data)
    jqxhr.done (data, textStatus, jqXHR) =>
      application.tracker?.trackEvent 'Redeemed course prepaid code', {prepaidCode: prepaidCode}
      # TODO: handle fetch errors
      me.fetch(cache: false).always =>
        if data?.length > 0 && data[0].courseID && data[0]._id
          courseID = data[0].courseID
          courseInstanceID = data[0]._id
          route = "/courses/#{courseID}/#{courseInstanceID}"
          viewArgs = [{}, courseID, courseInstanceID]
          Backbone.Mediator.publish 'router:navigate',
            route: route
            viewClass: 'views/courses/CourseDetailsView'
            viewArgs: viewArgs
        else
          @state = 'unknown_error'
          @stateMessage = "Database error."
          @render?()
    jqxhr.fail (xhr, textStatus, errorThrown) =>
      console.error 'Got an error redeeming a course prepaid code:', textStatus, errorThrown
      application.tracker?.trackEvent 'Failed to redeem course prepaid code', status: textStatus
      @state = 'unknown_error'
      @stateMessage = "#{xhr.status}: #{xhr.responseText}"
      @render?()
