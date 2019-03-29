<template lang="pug">

.container
  form
    label
      | Teacher email:
      input(v-model.trim="teacherEmail", :disabled="dataFetching")
    button(type="submit", @click.prevent="submitEmail", :disabled="dataFetching")
      | Next


  div(v-if="teacher")
    label
      input(type="button" @click.prevent="displayReport" value="Create report!", :disabled="!(dataReady)")
    div
      label
        | Teacher name:
        input(v-model:value="teacherFullName")
    div
      label
        | Account Manager Name:
        input(v-model:value="accountManagerFullName")
    div
      label
        | Account Manager Email:
        input(v-model:value="accountManager.email")
    div
      label
        | School Name:
        input(v-model:value="schoolName")
    div
      label
        | School Address:
        input(v-model:value="schoolAddress")
    div
      label
        | Start Date:
        input(v-model:value="startDate")
    div
      label
        | End Date:
        input(v-model:value="endDate")

    .row
      .col-xs-6
        h2
          | Classrooms:
        div(v-for="classroom in classrooms")
          label
            //- input(type="checkbox", v-model:value="startDate")
            input(type="checkbox", v-model:value="isClassroomSelected[classroom._id]")
            | {{classroom.name}}  [{{classroom.members.length}}] {{classroom.archived ? '(archived)' : ''}}

      .col-xs-6
        h2
          | Courses:
        div(v-for="course in courses")
          label(v-if="isCourseVisible[course._id]")
            input(type="checkbox", v-model:value="isCourseSelected[course._id]", :disabled="!isCourseVisible[course._id]")
            | {{course.name}}

    h2
      | Insights (markdown):
    p
      h2 ## Header
      b **bold**
      = " "
      i *italics*
      = " "
      | [link text](url)
    .row
      div.col-xs-6
        textarea(v-model:insightsMarkdown="insightsMarkdown")

      div.col-xs-6
        h4(style="border-bottom: 1px solid black") Insights
        div(v-html="insightsHtml")

    label
      input(type="button" @click.prevent="displayReport" value="Create report!", :disabled="!(dataReady)")
</template>

<script lang="coffee">

OutcomeReportResultView = require 'views/admin/OutcomeReportResultView'
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
co = require('co')
helper = require 'lib/coursesHelper'
utils = require 'core/utils'

OutcomesReportComponent = {
  data: ->
    accountManager: me.toJSON()
    teacherEmail: utils.getQueryVariable('email')
    teacher: null
    teacherFullName: null
    accountManagerFullName: null
    schoolName: null
    schoolAddress: null
    trialRequest: null
    classrooms: null
    courses: null
    courseInstances: []
    dataReady: false
    dataFetching: false
    isClassroomSelected: {}
    isCourseSelected: {}
    startDate: null
    endDate: moment(new Date()).format('MMM D, YYYY')
    earliestSessionDate: new Date()
    earliestClassroomDate: new Date()
    insightsMarkdown: ""
  computed:
    sessions: ->
      _.flatten(@classrooms.map (c) -> c.sessions)
    selectedSessions: ->
      courseIds = _.zipObject(([c._id, true] for c in @selectedCourses))
      levelOriginals = {}
      for classroom in @selectedClassrooms
        for course in classroom.courses
          continue unless courseIds[course._id]
          for level in course.levels
            levelOriginals[level.original] = true
      return _.filter(@sessions, (s) ->
        return unless s
        levelOriginals[s.level.original])
    studentIDs: ->
      _.uniq _.flatten _.pluck(@classrooms, 'members')
    indexedSessions: ->
      _.indexBy(@sessions, '_id')
    numProgramsWritten: ->
      # Include unselected classrooms and courses because we dont particularly need to filter these numbers down
      _.size(@indexedSessions)
    numShareableProjects: ->
      # Include unselected classrooms and courses because we dont particularly need to filter these numbers down
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
      @courses.filter (c) => @isCourseSelected[c._id] and @isCourseVisible[c._id]
    isCourseVisible: ->
      mapping = {}
      @courses.forEach (course) =>
        mapping[course._id] = _.any @courseInstances, (ci) =>
          (ci.courseID is course._id) and @isClassroomSelected[ci.classroomID] and not _.isEmpty(ci.members)
      mapping
    selectedCourseInstances: ->
      @courseInstances.filter (ci) =>
        (ci.classroomID in @selectedClassrooms.map((c)->c._id)) and (ci.courseID in @selectedCourses.map((c)->c._id))
    selectedStudentIDs: ->
      @studentIDs.filter (studentID) =>
        studentID in _.flatten(@selectedCourseInstances.map((c)->c.members))
    insightsHtml: ->
      marked(@insightsMarkdown, sanitize: false)
    courseStudentCounts: ->
      counts = @courses.map (course) =>
        courseID = course._id ? course
        instancesOfThisCourse = _.where(@selectedCourseInstances, {courseID})
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
      @earliestClassroomDate = new Date(trialRequest?.created)
    classrooms: (classrooms) ->
      for classroom in classrooms
        if _.isUndefined(@isClassroomSelected[classroom._id])
          Vue.set(@isClassroomSelected, classroom._id, not classroom.archived)
    courses: (courses) ->
      for course in courses
        if _.isUndefined(@isCourseSelected[course._id])
          Vue.set(@isCourseSelected, course._id, true)
      alreadyCoveredConcepts = []
      for course in courses
        course.newConcepts = _.difference(course.concepts, alreadyCoveredConcepts)
        alreadyCoveredConcepts = _.union(course.concepts, alreadyCoveredConcepts)
    accountManager: ->
      @accountManagerFullName = "#{@accountManager?.firstName} #{@accountManager?.lastName}"
    dataReady: ->
      console.log "Data ready!", @dataReady

  methods:
    courseCompletion: ->
      return if not @dataReady
      classroomsWithSessions = new Classrooms(@selectedClassrooms)
      classroomsWithSessions.forEach (classroom) =>
        # classroom.sessions = new LevelSessions(_.find(@classrooms, {_id: classroom.id}).sessions)
        classroom.sessions = new LevelSessions(@sessions)
      console.log {@selectedCourses, @selectedCourseInstances, @selectedStudentIDs}
      progressData = helper.calculateAllProgress(
        classroomsWithSessions,
        new Courses(@selectedCourses),
        new CourseInstances(@selectedCourseInstances),
        new Users(@selectedStudentIDs.map (_id) -> {_id})
      )
      console.log progressData
      courseCompletion = {}
      for classroom in @selectedClassrooms
        for course in _.where(classroom.courses, (c) => @isCourseSelected[c._id])
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
              if _.contains(_.find(this.courseInstances, {courseID: course._id, classroomID: classroom._id})?.members, userID)
                if progressDatum.completed
                  courseCompletion[course._id].numerator += 1
                courseCompletion[course._id].denominator += 1
              null
          courseCompletion[course._id].completion = Math.floor((courseCompletion[course._id].numerator / courseCompletion[course._id].denominator)*100)
      console.table courseCompletion
      console.trace()
      courseCompletion

    submitEmail: (e) ->
      @dataReady = false
      @dataFetching = true
      @fetchData().then =>
        @dataReady = true
        @dataFetching = false

    fetchByEmail: ->
      new Promise (accept, reject) =>
        reject("No email provided!") if _.isEmpty(@teacherEmail)
        $.ajax
          type: 'GET',
          url: '/db/user'
          data: {email: @teacherEmail}
          success: (data) => accept(data)
          error: (data) =>
            noty text: 'Failed to find user by that email', type: 'error'
            reject(data)

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
        @trialRequest # toJSONd
        @startDate # string YYYY-MM-DD
        @endDate # string YYYY-MM-DD
        classrooms: @selectedClassrooms
        courses: @selectedCourses
        courseCompletion: @courseCompletion()
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

    fetchData: ->
      @fetchByEmail().then (trimTeacher) =>
        @fetchCompleteUser(trimTeacher).then (teacher) =>
          @teacher = teacher
          Promise.all([
            @fetchTrialRequest(teacher).then (trialRequests) =>
              @trialRequest = trialRequests[0]
            @fetchClassrooms(teacher).then (classrooms) =>
              @classrooms = classrooms
              Promise.all @classrooms.map (classroom) =>
                @fetchStudentSessions(classroom).then (sessions) =>
                  # Freeze the sessions so Vue doesnt create a ton of listeners
                  # and update-dependencies for all the sessions and their properties
                  Object.freeze(sessions)
                  Object.freeze(session) for session in sessions
                  Vue.set classroom, 'sessions', sessions
                  return classroom
              .then (classrooms) =>
                @earliestSessionDate = _.min _.map classrooms, (classroom) ->
                  _.min _.map classroom.sessions, (s) -> new Date(s.created)
            Promise.all([
              @fetchCourseInstances(teacher).then (courseInstances) =>
                @courseInstances = courseInstances
              @fetchCourses().then (courses) =>
                @courses = courses
            ]).then ([courseInstances, courses]) =>
              courseIDs = _.uniq courseInstances.map (courseInstance) =>
                courseInstance.courseID
              indexedCourses = _.indexBy(courses, '_id')
              @courses = utils.sortCourses(courseIDs.map (courseID) =>
                indexedCourses[courseID]
              )
          ]).then (trialRequests, classrooms) =>
            @startDate = moment(_.max([@earliestSessionDate, @earliestClassroomDate])).format('MMM D, YYYY')

    fetchCompleteUser: (data) ->
      new Promise (accept, reject) ->
        user = new User(data)
        user.fetch().then (data) ->
          return accept(data)
        , (error) ->
          return reject(error) if error

    fetchTrialRequest: (teacher) ->
      new Promise (accept, reject) ->
        trialRequests = new TrialRequests()
        trialRequests.fetchByApplicant(teacher._id).then (data) ->
          return accept(data)
        , (error) ->
          return reject(error) if error

    fetchClassrooms: (teacher) ->
      new Promise (accept, reject) ->
        classrooms = new Classrooms()
        classrooms.fetchByOwner(teacher._id).then (data) ->
          accept(data)
        , (error) ->
          reject(error)

    fetchCourseInstances: (teacher) ->
      new Promise (accept, reject) ->
        courseInstances = new CourseInstances()
        courseInstances.fetchByOwner(teacher._id).then (data) ->
          accept(data)
        , (error) ->
          reject(error)

    fetchCourses: ->
      new Promise (accept, reject) ->
        courses = new Courses()
        courses.fetch().then (data) ->
          accept(data)
        , (error) ->
          reject(error)

    fetchStudentSessions: (classroom) ->
      new Promise (accept, reject) ->
        sessions = new LevelSessions()
        jqxhrs = sessions.fetchForAllClassroomMembers(new Classroom(classroom))
        Promise.all(jqxhrs.map (jqxhr) -> new Promise(jqxhr.then)).then (responses) ->
          return accept(_.union.apply(_, responses))

    fetchLinesOfCode: ->
      $.ajax
        type: 'GET',
        url: '/admin/calculate-lines-of-code'
        data: {
          # Include unselected classrooms and courses because we dont particularly need to filter these numbers down
          classroomIDs: @classrooms.map (c) -> c._id
          courseIDs: @courses.map (c) -> c._id
        }
        success: (data) =>
          @linesOfCode = parseInt(data.linesOfCode)
          @myNumProgramsWritten = parseInt(data.programs)
        error: (data) => noty text: 'Failed to fetch lines of code', type: 'error'

}

`export default OutcomesReportComponent`

</script>

<style lang="sass">

#outcomes-report-view
  textarea
    width: 100%
    height: 20em

  @page
    margin-top: 0.5in
    margin-left: 0
    margin-right: 0
    margin-bottom: 0

  @page:first
    margin-top: 0in

  body
    user-select: none
    -moz-user-select: none
    -khtml-user-select: none
    -webkit-user-select: none
    -o-user-select: none

  @media print
    a[href]:after
      content:none
    a[href]
      color: #0b63bc !important
      text-decoration: underline
</style>
