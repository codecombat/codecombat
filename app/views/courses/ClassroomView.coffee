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


module.exports = class ClassroomView extends RootView
  id: 'classroom-view'
  template: template
  
  events:
    'click #edit-class-details-link': 'onClickEditClassDetailsLink'

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
    @users.comparator = (user) =>
      @makeDisplayName(user).toLowerCase()
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

  onClickEditClassDetailsLink: ->
    modal = new ClassroomSettingsModal({classroom: @classroom})
    @openModalView(modal)
    @listenToOnce modal, 'hidden', @render

  makeDisplayName: (user) ->
    name = user.get('name')
    return name if name
    name = _.filter([user.get('firstName'), user.get('lastName')]).join('')
    return name if name
    email = user.get('email')
    return email if email
    return ''
    
  makeLastPlayedString: (user) ->
    session = user.sessions.last()
    return '' if not session
    campaign = session.collection.campaign
    levelOriginal = session.get('level').original
    campaignLevel = campaign.get('levels')[levelOriginal]
    return "#{campaign.get('fullName')}, #{campaignLevel.name}"
    