RootView = require 'views/core/RootView'
OutcomeReportResultView = require 'views/admin/OutcomeReportResultView'
template = require 'templates/base-flat'
User = require 'models/User'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
LevelSessions = require 'collections/LevelSessions'
Level = require 'models/Level'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
Users = require 'collections/Users'
Course = require 'models/Course'
Courses = require 'collections/Courses'
CourseInstances = require 'collections/CourseInstances'
require('vendor/co')
require('vendor/vue')
require('vendor/vuex')
helper = require 'lib/coursesHelper'
utils = require 'core/utils'

module.exports = class OutcomesReportView extends RootView
  id: 'outcomes-report-view'
  template: template

  afterRender: ->
    @vueComponent?.$destroy()
    @vueComponent = new OutcomesReportComponent({
      data: {parentView: @}
      el: @$el.find('#site-content-area')[0]
      store: @store
    })
    super(arguments...)

OutcomesReportComponent = Vue.extend
  template: require('templates/admin/outcomes-report-view')()
  data: ->
    accountManager: me.toJSON()
    teacherEmail: 'robin+teacher@codecombat.com' # TODO: Don't hardcode this. And add get-by-email endpoint.
    # teacherEmail: '568e7f2552eea226005180b3' # TODO: Don't hardcode this. And add get-by-email endpoint.
    teacher: null
    teacherFullName: null
    accountManagerFullName: null
    schoolName: null
    schoolAddress: null
    trialRequest: null
    startDate: null
    classrooms: null
    courses: null
    sessions: []
    courseInstances: []
    isClassroomSelected: {}
    isCourseSelected: {}
    endDate: moment(new Date()).format('MMM D, YYYY')
    insightsMarkdown: ""
  computed:
    studentIDs: ->
      _.uniq _.flatten _.pluck(@classrooms, 'members')
    indexedSessions: ->
      _.indexBy(@sessions, '_id')
    numProgramsWritten: ->
      _.size(@indexedSessions)
    numShareableProjects: ->
      shareableLevels = _.flatten @classrooms.map (classroom) ->
        classroom.courses.map (course) ->
          _.filter course.levels, (level) ->
            level.shareable is 'project'
      originals = _.map(shareableLevels, 'original')
      projects = _.where(Object.values(@indexedSessions), (s) -> s.level.original in originals)
      projects.length
    selectedClassrooms: ->
      @classrooms.filter (c) => @isClassroomSelected[c._id]
    selectedCourses: ->
      @courses.filter (c) => @isCourseSelected[c._id]
    insightsHtml: ->
      marked(@insightsMarkdown, sanitize: false)
    dataReady: ->
      return (_.all([@classrooms, @courses, @courseInstances]) and _.all(@classrooms?.map (c) -> c.sessions))
    courseCompletion: ->
      console.log [@classrooms, @courses, @courseInstances, @classrooms?.map (c) -> c.sessions]
      return if not @dataReady
      classroomsWithSessions = new Classrooms(@classrooms)
      classroomsWithSessions.forEach (classroom) =>
        classroom.sessions = new LevelSessions(_.find(@classrooms, {_id: classroom.id}).sessions)
      progressData = helper.calculateAllProgress(
        classroomsWithSessions,
        new Courses(@courses),
        new CourseInstances(@courseInstances),
        new Users(@studentIDs.map (_id) -> {_id})
      )
      courseCompletion = {}
      for classroom in @classrooms
        for course in classroom.courses
          courseCompletion[course._id] ?= {
            _id: course._id
            name: course.name
            completion: 0
          }
          courseCompletion[course._id].numerator ?= 0
          courseCompletion[course._id].denominator ?= 0
          for userID in classroom.members
            for level in course.levels when not level.practice
              progressDatum = progressData.get({
                classroom: new Classroom(classroom)
                course: new Course(course)
                level: new Level(level)
                user: {id: userID}
              })
              if _.contains(_.find(this.courseInstances, {courseID: course._id})?.members, userID)
                if progressDatum.completed
                  courseCompletion[course._id].numerator += 1
                courseCompletion[course._id].denominator += 1
              null
          courseCompletion[course._id].completion = Math.floor((courseCompletion[course._id].numerator / courseCompletion[course._id].denominator)*100)
      console.table courseCompletion
      console.trace()
      courseCompletion
    courseStudentCounts: ->
      counts = @courses.map (course) =>
        courseID = course._id ? course
        instancesOfThisCourse = _.where(@courseInstances, {courseID})
        console.log _.union.apply(null, instancesOfThisCourse.map((i) -> i.members)).length
        {
          _id: courseID
          count: _.union.apply(null, instancesOfThisCourse.map((i) -> i.members)).length
        }
      _.indexBy(counts, '_id')
      
  watch:
    teacher: (teacher) ->
      if teacher.firstName && teacher.lastName
        @teacherFullName = "#{teacher.firstName} #{teacher.lastName}"
      else
        @teacherFullName = null
    trialRequest: (trialRequest) ->
      @schoolName ?= trialRequest?.properties.nces_name
      @schoolName ?= trialRequest?.properties.school
      @schoolName ?= trialRequest?.properties.organization
      @startDate = moment(new Date(trialRequest?.created)).format('MMM D, YYYY')
    classrooms: (classrooms) ->
      for classroom in classrooms
        if _.isUndefined(@isClassroomSelected[classroom._id])
          Vue.set(@isClassroomSelected, classroom._id, true)
    courses: (courses) ->
      for course in courses
        if _.isUndefined(@isCourseSelected[course._id])
          Vue.set(@isCourseSelected, course._id, true)
      alreadyCoveredConcepts = []
      for course in courses
        course.newConcepts = _.difference(course.concepts, alreadyCoveredConcepts)
        alreadyCoveredConcepts = _.union(course.concepts, alreadyCoveredConcepts)
        console.log course.campaignID, course.newConcepts
    accountManager: ->
      @accountManagerFullName = "#{@accountManager?.firstName} #{@accountManager?.lastName}"
    
  methods:
    submitEmail: (e) ->
      $.ajax
        type: 'GET',
        url: '/db/user'
        data: {email: @teacherEmail}
        success: @fetchCompleteUser
        error: (data) => noty text: 'Failed to find user by that email', type: 'error'

    displayReport: (e) ->
      @fetchLinesOfCode().then @finishDisplayReport
    
    finishDisplayReport: ->
      resultView = new OutcomeReportResultView({
        teacher:
          fullName: @teacherFullName
          email: @teacherEmail
        accountManager:
          fullName: @accountManagerFullName
          email: @accountManager.email
        @schoolName
        @schoolAddress
        @trialRequest # toJSON'd
        @startDate # string YYYY-MM-DD
        @endDate # string YYYY-MM-DD
        classrooms: @selectedClassrooms
        courses: @selectedCourses
        @courseCompletion
        @courseStudentCounts
        @numProgramsWritten
        @myNumProgramsWritten
        @linesOfCode
        @numShareableProjects
        @insightsHtml
        backView: @parentView
      })
      resultView.render()
      window.currentView = undefined
      application.router.openView(resultView)

    
    fetchCompleteUser: (data) ->
      user = new User(data)
      console.log data
      user.fetch()
      user.once 'sync', (fullData) =>
        @teacher = fullData.toJSON()
        console.log @teacher
        @fetchTrialRequest()
        @fetchClassrooms()
        @fetchCourses()
    
    fetchTrialRequest: ->
      trialRequests = new TrialRequests()
      trialRequests.fetchByApplicant(@teacher._id)
      trialRequests.once 'sync', =>
        if trialRequests.length is 0
          noty text: "WARNING: No trial request found for that user!", type: 'error'
        @trialRequest = trialRequests.models[0]?.toJSON()

    fetchClassrooms: ->
      classrooms = new Classrooms()
      classrooms.fetchByOwner(@teacher._id)
      classrooms.once 'sync', =>
        @classrooms = classrooms.toJSON()
        @fetchStudentSessions()
        @fetchCourseInstances()

    fetchCourses: ->
      courseInstances = new CourseInstances()
      courseInstances.fetchByOwner(@teacher._id)
      courseInstances.once 'sync', =>
        courses = new Courses()
        courses.fetch()
        courses.once 'sync', =>
          courseIDs = _.uniq courseInstances.map (courseInstance) =>
            courseInstance.get('courseID')
          Vue.set @$data, 'courses', utils.sortCourses(courseIDs.map (courseID) => courses.get(courseID).toJSON())
    
    fetchStudentSessions: ->
      @classrooms.forEach (classroom) =>
        console.log "Fetching sessions for", classroom
        sessions = new LevelSessions()
        jqxhrs = sessions.fetchForAllClassroomMembers(new Classroom(classroom))
        $.when(jqxhrs...).done =>
          console.log sessions
          Vue.set(classroom, 'sessions', sessions.toJSON())
          sessions.forEach (session) =>
            # if not _.detect(@$data.sessions, { _id: session.id })
            @$data.sessions.push(session.toJSON())
              
    fetchCourseInstances: ->
      @classrooms.forEach (classroom) =>
        courseInstances = new CourseInstances()
        courseInstances.fetchForClassroom(classroom._id)
        courseInstances.once 'sync', (courseInstances) =>
          courseInstances.forEach (courseInstance) =>
            if not _.contains(@$data.courseInstances, { _id: courseInstance.id })
              @$data.courseInstances.push(courseInstance.toJSON())
    
    fetchLinesOfCode: ->
      $.ajax
        type: 'GET',
        url: '/admin/calculate-lines-of-code'
        data: {
          classroomIDs: @selectedClassrooms.map (c) -> c._id
          courseIDs: @selectedCourses.map (c) -> c._id
        }
        success: (data) =>
          @linesOfCode = parseInt(data.linesOfCode)
          @myNumProgramsWritten = parseInt(data.programs)
        error: (data) => noty text: 'Failed to fetch lines of code', type: 'error'
