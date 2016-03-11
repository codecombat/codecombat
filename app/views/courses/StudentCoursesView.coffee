app = require 'core/application'
CreateAccountModal = require 'views/core/CreateAccountModal'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
User = require 'models/User'
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
    @courseInstances.comparator = (ci) -> return ci.get('classroomID') + ci.get('courseID')
    @supermodel.loadCollection(@courseInstances, 'course_instances')
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @supermodel.loadCollection(@classrooms, 'classrooms', { data: {memberID: me.id} })
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')

  onLoaded: ->
    if (@classCode = utils.getQueryVariable('_cc', false)) and not me.isAnonymous()
      @joinClass()
    super()

  onClickJoinClassButton: (e) ->
    return @openModalView new CreateAccountModal() if me.isAnonymous()
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
    classroom = new Classroom(data)
    application.tracker?.trackEvent 'Joined classroom', {
      classroomID: classroom.id,
      classroomName: classroom.get('name')
      ownerID: classroom.get('ownerID')
    }
    @classrooms.add(classroom)
    @render()

    classroomCourseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance })
    classroomCourseInstances.fetch({ data: {classroomID: classroom.id} })
    @listenToOnce classroomCourseInstances, 'sync', ->

      # join any course instances in the classroom which are free to join
      jqxhrs = []
      for courseInstance in classroomCourseInstances.models
        course = @courses.get(courseInstance.get('courseID'))
        if course.get('free')
          jqxhrs.push $.ajax({
            method: 'POST'
            url: _.result(courseInstance, 'url') + '/members'
            data: { userID: me.id }
            context: @
            success: (data) ->
              @courseInstances.add(data)
              @courseInstances.get(data._id).justJoined = true
          })
      $.when(jqxhrs...).done =>
        @state = ''
        @render()
