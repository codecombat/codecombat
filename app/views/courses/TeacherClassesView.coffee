RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-classes-view'
Classrooms = require 'collections/Classrooms'
Courses = require 'collections/Courses'
Campaign = require 'models/Campaign'
Campaigns = require 'collections/Campaigns'
LevelSessions = require 'collections/LevelSessions'
CourseInstances = require 'collections/CourseInstances'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'
User = require 'models/User'
utils = require 'core/utils'

module.exports = class TeacherClassesView extends RootView
  id: 'teacher-classes-view'
  template: template
  
  events:
    'click .edit-classroom': 'onClickEditClassroom'
    'click .archive-classroom': 'onClickArchiveClassroom'
    'click .unarchive-classroom': 'onClickUnarchiveClassroom'

  constructor: (options) ->
    super(options)
    @classrooms = new Classrooms()
    @classrooms.fetchMine()
    @supermodel.trackCollection(@classrooms)
    
    @courses = new Courses()
    @courses.fetch()
    @supermodel.trackCollection(@courses)
    
    @campaigns = new Campaigns()
    @campaigns.fetchByType('course')
    @supermodel.trackCollection(@campaigns)
    
    @courseInstances = new CourseInstances()
    @courseInstances.fetchByOwner(me.id)
    @supermodel.trackCollection(@courseInstances)
    
    # Level Sessions loaded after onLoaded to prevent race condition in calculateDots      
    
  calculateDots: ->
    #for classroom in classrooms
    for classroom in @classrooms.models
      # map [user, level] => session so we don't have to do find TODO
      # for course in courses
      for course, courseIndex in @courses.models
        # get the course instance
        instance = @courseInstances.getByCourseAndClassroom(course, classroom)
        # skip the rest if nobody has gotten to that course
        continue if not instance
        # start counting number of students finished
        instance.numCompleted = 0
        # get the campaign
        campaign = @campaigns.get(course.get('campaignID'))
        # for user in courseinstance
        for userID in instance.get('members')
          # for level in campaign
          allComplete = _.every campaign.getLevels().models, (level) ->
            return true if level.get('type')?.indexOf('ladder') > -1
            #TODO: Hella slow! Do the mapping first!
            session = _.find classroom.sessions.models, (session) ->
              session.get('creator') == userID and session.get('level').original == level.get('original')
            # sessionMap[userID][level].completed()
            session?.completed()
          if allComplete
            instance.numCompleted += 1
            

  onLoaded: ->
    console.log("loaded!")
    @capitalizeLanguageNames(@classrooms)
    for classroom in @classrooms.models
      classroom.sessions = new LevelSessions()
      classroom.sessions.fetchForAllClassroomMembers(classroom)
      @listenTo classroom.sessions, 'sync', ->
        @calculateDots()
        @render()
    super()
    
    
    
    
    # 
    # @listenToOnce @classrooms, 'sync', @afterSyncClassrooms
    # #TODO: Refactor below! How should I fetch many interdependent things/do their callbacks?
    # @levelMapping = {}
    # @courses = new Courses()
    # @courses.fetch()
    # @listenToOnce @courses, 'sync', =>
    #   @courses.forEach (course, index) =>
    #     console.log arguments
    #     campaign = new Campaign({ id: course.get('campaignID') })
    #     campaign.fetch()
    #     @listenToOnce campaign, 'sync', (campaign, levels) =>
    #       # debugger
    #       console.log "Campaign #{index} loaded"
    #       console.log @levelMapping
    #       campaignID = campaign.get('id')
    #       levelIDs = _.map levels, (level) =>
    #         level._id
    #       levelIDs.forEach (levelID) =>
    #         console.log "old mapping:", @levelMapping[levelID]
    #         @levelMapping[levelID] = index
    #       @afterSyncLevels(@levelMapping)
    # 
  afterSyncClassrooms: () =>
    @capitalizeLanguageNames(@classrooms)
    @render()
    @classrooms.forEach (classroom) =>
      classroom.levelSessions = sessions = new LevelSessions()
      sessions.fetchForClassroomMembers(classroom.id)
      @listenToOnce sessions, 'sync', (data) => 
        sessions.completedSessions() #TODO
        @render()
        
  afterSyncLevels: (levelMapping) => #TODO: this arg is redundant, dunno why @ isn't binding right
    @calculateHighestComplete(levelMapping)
    @render()
  
  #TODO: Refactor so other views can use this
  #TODO: Consider efficiency
  #TODO: Consider race conditions w/ load order
  calculateHighestComplete: (levelMapping) =>
    @classrooms.forEach (classroom) =>
      highest = 0
      classroom.levelSessions.forEach (session) =>
        courseNo = levelMapping[session.id]
        console.log courseNo
        if courseNo > highest
          highest = courseNo
      classroom.highestCompleteNo = highest
      #for each classroom, loop over its level sessions
      #for each level session, update the highest complete
    null
    
  capitalizeLanguageNames: (classrooms) =>
    classrooms.forEach (classroom) =>
      language = classroom.get('aceConfig').language
      capitalLanguage = utils.capitalLanguages[language]
      classroom.capitalLanguage = capitalLanguage
    
  onClickEditClassroom: (e) =>
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render
    
  onClickArchiveClassroom: (e) ->
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    classroom.set('archived', true)
    classroom.save {}, {
      success: =>
        @render()
    }
    
  onClickUnarchiveClassroom: (e) ->
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    classroom.set('archived', false)
    classroom.save {}, {
      success: =>
        @render()
    }