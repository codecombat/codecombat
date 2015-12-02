Campaign = require 'models/Campaign'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
Classroom = require 'models/Classroom'
LevelSession = require 'models/LevelSession'
RootView = require 'views/core/RootView'
template = require 'templates/courses/classroom-view'
User = require 'models/User'
utils = require 'core/utils'
Prepaid = require 'models/Prepaid'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'
ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
RemoveStudentModal = require 'views/courses/RemoveStudentModal'

module.exports = class ClassroomView extends RootView
  id: 'classroom-view'
  template: template
  
  events:
    'click #edit-class-details-link': 'onClickEditClassDetailsLink'
    'click #activate-licenses-btn': 'onClickActivateLicensesButton'
    'click .activate-single-license-btn': 'onClickActivateSingleLicenseButton'
    'click #add-students-btn': 'onClickAddStudentsButton'
    'click .enable-btn': 'onClickEnableButton'
    'click .remove-student-link': 'onClickRemoveStudentLink'

  initialize: (options, classroomID) ->
    @classroom = new Classroom({_id: classroomID})
    @supermodel.loadModel @classroom, 'classroom'
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @courses.comparator = '_id'
    @supermodel.loadCollection(@courses, 'courses')
    @campaigns = new CocoCollection([], { url: "/db/campaign", model: Campaign })
    @courses.comparator = '_id'
    @supermodel.loadCollection(@campaigns, 'campaigns', { data: { type: 'course' }})
    @courseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance})
    @courseInstances.comparator = 'courseID'
    @supermodel.loadCollection(@courseInstances, 'course_instances', { data: { classroomID: classroomID } })
    @users = new CocoCollection([], { url: "/db/classroom/#{classroomID}/members", model: User })
    @users.comparator = (user) => user.broadName().toLowerCase()
    @supermodel.loadCollection(@users, 'users')
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesSync

  onCourseInstancesSync: ->
    @sessions = new CocoCollection([], { model: LevelSession })
    for courseInstance in @courseInstances.models
      sessions = new CocoCollection([], { url: "/db/course_instance/#{courseInstance.id}/level_sessions", model: LevelSession })
      @supermodel.loadCollection(sessions, 'sessions')
      courseInstance.sessions = sessions
      sessions.courseInstance = courseInstance
      @listenToOnce sessions, 'sync', (sessions) ->
        @sessions.add(sessions.slice())
        sessions.courseInstance.sessionsByUser = sessions.groupBy('creator')
      
  onLoaded: ->
    userSessions = @sessions.groupBy('creator')
    for user in @users.models
      user.sessions = new CocoCollection(userSessions[user.id], { model: LevelSession })
      user.sessions.comparator = 'changed'
      user.sessions.sort()
    for courseInstance in @courseInstances.models
      courseID = courseInstance.get('courseID')
      course = @courses.get(courseID)
      campaignID = course.get('campaignID')
      campaign = @campaigns.get(campaignID)
      courseInstance.sessions.campaign = campaign
    super()

  onClickActivateLicensesButton: ->
    modal = new ActivateLicensesModal({
      classroom: @classroom
      users: @users
    })
    @openModalView(modal)
    modal.once 'redeem-users', -> document.location.reload()

  onClickActivateSingleLicenseButton: (e) ->
    userID = $(e.target).data('user-id')
    user = @users.get(userID)
    modal = new ActivateLicensesModal({
      classroom: @classroom
      users: @users
      user: user
    })
    @openModalView(modal)
    modal.once 'redeem-users', -> document.location.reload()

  onClickEditClassDetailsLink: ->
    modal = new ClassroomSettingsModal({classroom: @classroom})
    @openModalView(modal)
    @listenToOnce modal, 'hidden', @render

  makeLastPlayedString: (user) ->
    session = user.sessions.last()
    return '' if not session
    campaign = session.collection.campaign
    levelOriginal = session.get('level').original
    campaignLevel = campaign.get('levels')[levelOriginal]
    return "#{campaign.get('fullName')}, #{campaignLevel.name}"

  onClickAddStudentsButton: (e) ->
    modal = new InviteToClassroomModal({classroom: @classroom})
    @openModalView(modal)

  onClickEnableButton: (e) ->
    courseInstance = @courseInstances.get($(e.target).data('course-instance-id'))
    userID = $(e.target).data('user-id')
    courseInstance.addMember(userID)
    $(e.target).attr('disabled', true)
    @listenToOnce courseInstance, 'sync', @render

  onClickRemoveStudentLink: (e) ->
    user = @users.get($(e.target).closest('a').data('user-id'))
    modal = new RemoveStudentModal({
      classroom: @classroom
      user: user
      courseInstances: @courseInstances
    })
    @openModalView(modal)
    modal.once 'remove-student', @onStudentRemoved, @
    
  onStudentRemoved: (e) ->
    @users.remove(e.user)
    @render()