RootView = require 'views/core/RootView'
OutcomeReportResult = require 'views/admin/OutcomeReportResult'
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

module.exports = class OutcomesReportView extends RootView
  id: 'outcomes-report-view'
  template: template

  afterRender: ->
    @vueComponent?.$destroy()
    @vueComponent = new OutcomesReportComponent({
      data: {}
      el: @$el.find('#site-content-area')[0]
      store: @store
    })
    super(arguments...)

OutcomesReportComponent = Vue.extend
  template: require('templates/admin/outcomes-report-view')()
  data: ->
    accountManager: me.toJSON()
    # teacherEmail: '589a58412e76b5f0215bb9fd' # TODO: Don't hardcode this. And add get-by-email endpoint.
    teacherEmail: '568e7f2552eea226005180b3' # TODO: Don't hardcode this. And add get-by-email endpoint.
    teacher: null
    teacherFullName: null
    accountManagerFullName: null
    schoolNameAndAddress: null
    trialRequest: null
    startDate: null
    classrooms: null
    courses: null
    sessions: []
    courseInstances: []
    isClassroomSelected: {}
    isCourseSelected: {}
    endDate: moment(new Date()).format('YYYY-MM-DD')
  computed:
    studentIDs: ->
      _.uniq _.flatten _.pluck(@classrooms, 'members')
    percentCourseCompleted: ->
      return 0
      # @courses.forEach (course) =>
      #   console.log {@classrooms}
      #   debugger
      #   console.log "Course #{course.name}"
      #   @studentIDs.forEach (studentID) =>
      #     studentSessions = _.where @sessions, (s) ->
      #       debugger
      #       course
      #       s.creator is studentID and s.state.complete is true
      #     console.log {studentID, studentSessions}
      #     # debugger
      #     null
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
          # levelCount = progressData[classroom._id]?[course._id]?.levelCount or 0
          # userCount = progressData[classroom._id]?[course._id]?.userCount or 0
          # courseCompletion[course._id].denominator += levelCount * userCount
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
      @schoolNameAndAddress = trialRequest?.properties.school
      @startDate = moment(new Date(trialRequest.created)).format('YYYY-MM-DD')
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
    
  methods:
    submitEmail: (e) ->
      $.ajax
        type: 'POST',
        url: '/db/user/-/admin_search'
        data: {search: @teacherEmail}
        success: @fetchCompleteUser
        error: (data) => console.log arguments

    displayReport: (e) ->
      resultView = new OutcomeReportResult({
        teacher:
          fullName: @teacherFullName
          email: @teacherEmail
        accountManager:
          fullName: @accountManagerFullName
          email: @accountManager.email
        @schoolNameAndAddress
        @teacher # toJSON'd
        @trialRequest # toJSON'd
        @startDate # string YYYY-MM-DD
        @endDate # string YYYY-MM-DD
        classrooms: @classrooms.filter (c) => @isClassroomSelected[c._id]
        courses: @courses.filter (c) => @isCourseSelected[c._id]
        @courseCompletion
        @courseStudentCounts
      })
      resultView.render()
      wow = [
        '<html>'
        '<head>'
        $('head').html()
        '</head>'
        '<body>'
        '<div id="#page-container"></div>'
        '</body>'
        '</html>'
      ].join('\n')

      resultWindow = window.open('', 'print', 'status=1,width=850,height=600')
      window.resultWindow = resultWindow

      setTimeout () ->
        $(resultWindow.document.body, "#page-container").empty().append(resultView.el)
      , 500

      resultWindow.document.write(wow)

    
    fetchCompleteUser: (data) ->
      if data.length isnt 1
        noty text: "Didn't find exactly one such user"
        return
      user = new User(data[0])
      user.fetch()
      user.once 'sync', (fullData) =>
        @teacher = fullData.toJSON()
        @fetchTrialRequest()
        @fetchClassrooms()
        @fetchCourses()
    
    fetchTrialRequest: ->
      trialRequests = new TrialRequests()
      trialRequests.fetchByApplicant(@teacher._id)
      trialRequests.once 'sync', =>
        @trialRequest = trialRequests.models[0].toJSON()

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
          Vue.set @$data, 'courses', courseIDs.map (courseID) => courses.get(courseID).toJSON()
    
    fetchStudentSessions: ->
      @classrooms.forEach (classroom) =>
        console.log "Fetching sessions for", classroom
        sessions = new LevelSessions()
        jqxhrs = sessions.fetchForAllClassroomMembers(new Classroom(classroom))
        $.when(jqxhrs...).done =>
          console.log sessions
          Vue.set(classroom, 'sessions', sessions.toJSON())
          sessions.forEach (session) =>
            if not _.contains(@$data.sessions, { _id: session.id })
              @$data.sessions.push(session.toJSON())
              
    fetchCourseInstances: ->
      @classrooms.forEach (classroom) =>
        courseInstances = new CourseInstances()
        courseInstances.fetchForClassroom(classroom._id)
        courseInstances.once 'sync', (courseInstances) =>
          courseInstances.forEach (courseInstance) =>
            if not _.contains(@$data.courseInstances, { _id: courseInstance.id })
              @$data.courseInstances.push(courseInstance.toJSON())

  created: ->
    if @accountManager.firstName && @accountManager.lastName
      @accountManagerFullName = "#{@accountManager.firstName} #{@accountManager.lastName}"
    else
      @accountManagerFullName = @accountManager.name
