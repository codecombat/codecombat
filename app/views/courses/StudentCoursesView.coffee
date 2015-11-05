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
    
    if (@classCode = utils.getQueryVariable('_cc', false)) and not me.isAnonymous()
      @joinClass()

  onClickJoinClassButton: (e) ->
    return @openModalView new AuthModal() if me.isAnonymous()
    @classCode = @$('#classroom-code-input').val()
    @joinClass()

  joinClass: () ->
    @state = 'enrolling'
    @renderSelectors '#join-classroom-form'
    $.ajax({
      method: 'POST'
      url: '/db/classroom/-/members'
      data: code: @classCode
      context: @
      success: @onJoinClassroomSuccess
      error: (jqxhr, textStatus, errorThrown) ->
        application.tracker?.trackEvent 'Failed to join classroom with code', status: textStatus
        @state = 'unknown_error'
        if jqxhr.status is 422
          @stateMessage = 'Please enter a code.'
        else if jqxhr.status is 404
          @stateMessage = 'Code not found.'
        else
          @stateMessage = "#{jqxhr.responseText}"
        @renderSelectors '#join-classroom-form'
    })

  onJoinClassroomSuccess: (data, textStatus, jqxhr) ->
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

