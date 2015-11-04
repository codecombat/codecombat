app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/student-courses-view'
utils = require 'core/utils'

# TODO: Implement join class
# TODO: Implement course instance links

module.exports = class StudentCoursesView extends RootView
  id: 'student-courses-view'
  template: template

  events:
    'click #join-class-btn': 'onClickJoinClassButton'

  constructor: (options) ->
    super(options)
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @supermodel.loadCollection(@courseInstances, 'course_instances')
    
#    if classCode = utils.getQueryVariable('_cc', false) and not me.isAnonymous()
#      @joinClass(classCode)
#
#  onClickJoinClassButton: (e) ->
#    return @openModalView new AuthModal() if me.isAnonymous()
#    courseID = $(e.target).data('course-id')
#    classCode = ($(".code-input[data-course-id=#{courseID}]").val() ? '').trim()
#    @courseEnrollByModal(prepaidCode)
#
#  joinClass: (prepaidCode) ->
#    @state = 'enrolling-by-modal'
#    @renderSelectors '.student-dialog-state-row'
#    $.ajax({
#      method: 'POST'
#      url: '/db/course_instance/-/redeem_prepaid'
#      data: prepaidCode: prepaidCode
#      context: @
#      success: ->
#        $('.continue-dialog').modal('hide')
#        @onRedeemPrepaidSuccess(arguments...)
#      error: (jqxhr, textStatus, errorThrown) ->
#        application.tracker?.trackEvent 'Failed to redeem course prepaid code by modal', status: textStatus
#        @state = 'unknown_error'
#        if jqxhr.status is 422
#          @stateMessage = 'Please enter a code.'
#        else if jqxhr.status is 404
#          @stateMessage = 'Code not found.'
#        else
#          @stateMessage = "#{jqxhr.responseText}"
#        @renderSelectors '.student-dialog-state-row'
#    })
#    
#  onRedeemPrepaidSuccess: (data, textStatus, jqxhr) ->
#    prepaidID = data[0]?.prepaidID
#    application.tracker?.trackEvent 'Redeemed course prepaid code', {prepaidCode: prepaidID}
#    me.fetch(cache: false).always =>
#      if data?.length > 0 && data[0].courseID && data[0]._id
#        courseID = data[0].courseID
#        courseInstanceID = data[0]._id
#        route = "/courses/#{courseID}/#{courseInstanceID}"
#        viewArgs = [{}, courseID, courseInstanceID]
#        Backbone.Mediator.publish 'router:navigate',
#          route: route
#          viewClass: 'views/courses/CourseDetailsView'
#          viewArgs: viewArgs
#      else
#        @state = 'unknown_error'
#        @stateMessage = "Database error."
#        @render?()

