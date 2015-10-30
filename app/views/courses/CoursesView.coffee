app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses'
utils = require 'core/utils'

# TODO: Hour of Code (HoC) integration is a mess

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click .btn-buy': 'onClickBuy'
    'click .btn-enroll': 'onClickEnroll'
    'click .btn-enter': 'onClickEnter'
    'click .btn-hoc-student-continue': 'onClickHOCStudentContinue'
    'click .btn-student': 'onClickStudent'
    'click .btn-teacher': 'onClickTeacher'

  constructor: (options) ->
    super(options)
    @setUpHourOfCode()
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
        @studentMode = true
        @courseEnrollByURL(prepaidCode)

  setUpHourOfCode: ->
    # If we are coming in at /hoc, then we show the landing page.
    # If we have ?hoc=true (for the step after the landing page), then we show any HoC-specific instructions.
    # If we haven't tracked this player as an hourOfCode player yet, and it's a new account, we do that now.
    @hocLandingPage = Backbone.history.getFragment()?.indexOf('hoc') >= 0
    @hocMode = utils.getQueryVariable('hoc', false)
    elapsed = new Date() - new Date(me.get('dateCreated'))
    if not me.get('hourOfCode') and (@hocLandingPage or @hocMode) and elapsed < 5 * 60 * 1000
      me.set('hourOfCode', true)
      me.patch()
      $('body').append($('<img src="https://code.org/api/hour/begin_codecombat.png" style="visibility: hidden;">'))
      application.tracker?.trackEvent 'Hour of Code Begin'
    if me.get('hourOfCode') and elapsed < 24 * 60 * 60 * 1000
      @hocMode = true  # If they really just arrived, make sure we're still in hocMode even if they lost ?hoc=true.

  getRenderData: ->
    context = super()
    context.courses = @courses.models ? []
    context.enrolledCourses = @enrolledCourses ? {}
    context.hocLandingPage = @hocLandingPage
    context.hocMode = @hocMode
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
    return @openModalView new AuthModal() if me.isAnonymous()
    courseID = $(e.target).data('course-id')
    prepaidCode = ($(".code-input[data-course-id=#{courseID}]").val() ? '').trim()
    @courseEnrollByModal(prepaidCode)

  onClickEnter: (e) ->
    $('.continue-dialog').modal('hide')
    courseID = $(e.target).data('course-id')
    courseInstanceID = $(".select-session[data-course-id=#{courseID}]").val()
    route = "/courses/#{courseID}/#{courseInstanceID}"
    viewClass = require 'views/courses/CourseDetailsView'
    viewArgs = [{}, courseID, courseInstanceID]
    navigationEvent = route: route, viewClass: viewClass, viewArgs: viewArgs
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickHOCStudentContinue: (e) ->
    $('.continue-dialog').modal('hide')
    if e
      courseID = $(e.target).data('course-id')
    else
      courseID = '560f1a9f22961295f9427742'

    @state = 'enrolling'
    @stateMessage = undefined
    @render?()

    # TODO: Copied from CourseEnrollView

    data =
      name: 'Single Player'
      seats: 9999
      courseID: courseID
      hourOfCode: true
    jqxhr = $.post('/db/course_instance/-/create', data)
    jqxhr.done (data, textStatus, jqXHR) =>
      application.tracker?.trackEvent 'Finished HoC student course creation', {courseID: courseID}
      # TODO: handle fetch errors
      me.fetch(cache: false).always =>
        courseID = courseID
        route = "/courses/#{courseID}"
        viewArgs = [{}, courseID]
        if data?.length > 0
          courseInstanceID = data[0]._id
          route += "/#{courseInstanceID}"
          viewArgs[0].courseInstanceID = courseInstanceID
        Backbone.Mediator.publish 'router:navigate',
          route: route
          viewClass: 'views/courses/CourseDetailsView'
          viewArgs: viewArgs
    jqxhr.fail (xhr, textStatus, errorThrown) =>
      console.error 'Got an error purchasing a course:', textStatus, errorThrown
      application.tracker?.trackEvent 'Failed HoC student course creation', status: textStatus
      if xhr.status is 402
        @state = 'declined'
        @stateMessage = arguments[2]
      else
        @state = 'unknown_error'
        @stateMessage = "#{xhr.status}: #{xhr.responseText}"
      @render?()

  onClickStudent: (e) ->
    if @supermodel.finished() and @hocLandingPage
      # Automatically enroll in first course
      @onClickHOCStudentContinue()
      return
    route = "/courses/students"
    route += "?hoc=true" if @hocLandingPage or @hocMode
    viewClass = require 'views/courses/CoursesView'
    navigationEvent = route: route, viewClass: viewClass, viewArgs: []
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  onClickTeacher: (e) ->
    route = "/courses/teachers"
    route += "?hoc=true" if @hocLandingPage or @hocMode
    viewClass = require 'views/courses/CoursesView'
    navigationEvent = route: route, viewClass: viewClass, viewArgs: []
    Backbone.Mediator.publish 'router:navigate', navigationEvent

  courseEnrollByURL: (prepaidCode) ->
    @state = 'enrolling'
    @render?()
    $.ajax({
      method: 'POST'
      url: '/db/course_instance/-/redeem_prepaid'
      data: prepaidCode: prepaidCode
      context: @
      success: @onRedeemPrepaidSuccess
      error: (xhr, textStatus, errorThrown) ->
        console.error 'Got an error redeeming a course prepaid code:', textStatus, errorThrown
        application.tracker?.trackEvent 'Failed to redeem course prepaid code by url', status: textStatus
        @state = 'unknown_error'
        @stateMessage = "Failed to redeem code: #{xhr.responseText}"
        @render?()
    })
      
  courseEnrollByModal: (prepaidCode) ->
    @state = 'enrolling-by-modal'
    @renderSelectors '.student-dialog-state-row'
    $.ajax({
      method: 'POST'
      url: '/db/course_instance/-/redeem_prepaid'
      data: prepaidCode: prepaidCode
      context: @
      success: ->
        $('.continue-dialog').modal('hide')
        @onRedeemPrepaidSuccess(arguments...)
      error: (jqxhr, textStatus, errorThrown) ->
        application.tracker?.trackEvent 'Failed to redeem course prepaid code by modal', status: textStatus
        @state = 'unknown_error'
        if jqxhr.status is 422
          @stateMessage = 'Please enter a code.'
        else if jqxhr.status is 404
          @stateMessage = 'Code not found.'
        else
          @stateMessage = "#{jqxhr.responseText}"
        @renderSelectors '.student-dialog-state-row'
    })
    
  onRedeemPrepaidSuccess: (data, textStatus, jqxhr) ->
    prepaidID = data[0]?.prepaidID
    application.tracker?.trackEvent 'Redeemed course prepaid code', {prepaidCode: prepaidID}
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

