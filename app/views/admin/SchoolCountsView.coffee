RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
Classroom = require 'models/Classroom'
CourseInstance = require 'models/CourseInstance'
TrialRequest = require 'models/TrialRequest'
User = require 'models/User'
utils = require 'core/utils'

# TODO: match anonymous trial requests with real users via email

module.exports = class SchoolCountsView extends RootView
  id: 'admin-school-counts-view'
  template: require 'templates/admin/school-counts'

  initialize: ->
    return super() unless me.isAdmin()
    @classrooms = new CocoCollection([], { url: "/db/classroom/-/users", model: Classroom })
    @supermodel.loadCollection(@classrooms, 'classrooms', {cache: false})
    @courseInstances = new CocoCollection([], { url: "/db/course_instance/-/non-hoc", model: CourseInstance})
    @supermodel.loadCollection(@courseInstances, 'course-instances', {cache: false})
    @students = new CocoCollection([], { url: "/db/user/-/students", model: User })
    @supermodel.loadCollection(@students, 'students', {cache: false})
    @teachers = new CocoCollection([], { url: "/db/user/-/teachers", model: User })
    @supermodel.loadCollection(@teachers, 'teachers', {cache: false})
    @trialRequests = new CocoCollection([], { url: "/db/trial.request/-/users", model: TrialRequest })
    @supermodel.loadCollection(@trialRequests, 'trial-requests', {cache: false})
    super()

  onLoaded: ->
    return super() unless me.isAdmin()

    console.log(new Date().toISOString(), 'onLoaded')

    teacherMap = {} # Used to make sure teachers and students only counted once
    studentMap = {} # Used to make sure teachers and students only counted once
    studentNonHocMap = {} # Used to exclude HoC users
    teacherStudentMap = {} # Used to link students to their teacher locations
    countryStateDistrictSchoolCountsMap = {} # Data graph

    console.log(new Date().toISOString(), "Processing #{@courseInstances.models.length} course instances...")
    for courseInstance in @courseInstances.models
      studentNonHocMap[courseInstance.get('ownerID')] = true
      studentNonHocMap[studentID] = true for studentID in courseInstance.get('members') ? []

    console.log(new Date().toISOString(), "Processing #{@classrooms.models.length} classrooms...")
    for classroom in @classrooms.models
      teacherID = classroom.get('ownerID')
      teacherMap[teacherID] ?= {}
      teacherMap[teacherID] = true
      teacherStudentMap[teacherID] ?= {}
      for studentID in classroom.get('members')
        continue unless studentNonHocMap[studentID]
        studentMap[studentID] = true
        teacherStudentMap[teacherID][studentID] = true

    console.log(new Date().toISOString(), "Processing #{@teachers.models.length} teachers...")
    for teacher in @teachers.models
      teacherMap[teacher.id] ?= {}
      delete studentMap[teacher.id]

    console.log(new Date().toISOString(), "Processing #{@students.models.length} students...")
    for student in @students.models when not teacherMap[student.id]
      continue unless studentNonHocMap[student.id]
      schoolName = student.get('schoolName')
      studentMap[student.id] = true

    console.log(new Date().toISOString(), "Processing trial #{@trialRequests.models.length} requests...")
    for trialRequest in @trialRequests.models
      teacherID = trialRequest.get('applicant')
      unless teacherMap[teacherID]
        # E.g. parents
        # console.log("Skipping non-teacher #{teacherID} trial request #{trialRequest.id}")
        continue
      props = trialRequest.get('properties')
      if props.nces_id and props.country and props.state
        country = props.country
        state = props.state
        district = props.nces_district
        school = props.nces_name
        countryStateDistrictSchoolCountsMap[country] ?= {}
        countryStateDistrictSchoolCountsMap[country][state] ?= {}
        countryStateDistrictSchoolCountsMap[country][state][district] ?= {}
        countryStateDistrictSchoolCountsMap[country][state][district][school] ?= {students: {}, teachers: {}}
        countryStateDistrictSchoolCountsMap[country][state][district][school].teachers[teacherID] = true
        for studentID, val of teacherStudentMap[teacherID]
          countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true
      else if not _.isEmpty(props.country)
        country = props.country
        country = country[0].toUpperCase() + country.substring(1).toLowerCase()
        country = 'UK' if /uk|united kingdom|england/ig.test(country.trim())
        country = 'USA' if /^u\.s\.?(\.a)?\.?$|^us$|america|united states|usa/ig.test(country.trim())
        state = props.state ? 'unknown'
        if country is 'USA'
          stateName = utils.usStateCodes.sanitizeStateName(state)
          state = utils.usStateCodes.getStateCodeByStateName(stateName) if stateName
          state = utils.usStateCodes.sanitizeStateCode(state) ? state
        district = 'unknown'
        school = props.organiziation ? 'unknown'
        countryStateDistrictSchoolCountsMap[country] ?= {}
        countryStateDistrictSchoolCountsMap[country][state] ?= {}
        countryStateDistrictSchoolCountsMap[country][state][district] ?= {}
        countryStateDistrictSchoolCountsMap[country][state][district][school] ?= {students: {}, teachers: {}}
        countryStateDistrictSchoolCountsMap[country][state][district][school].teachers[teacherID] = true
        for studentID, val of teacherStudentMap[teacherID]
          countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true

    console.log(new Date().toISOString(), 'Building country graphs...')
    @countryGraphs = {}
    @countryCounts = []
    totalStudents = 0
    totalTeachers = 0
    for country, stateDistrictSchoolCountsMap of countryStateDistrictSchoolCountsMap
      @countryGraphs[country] =
        districtCounts: []
        stateCounts: []
        stateCountsMap: {}
        totalSchools: 0
        totalStates: 0
        totalStudents: 0
        totalTeachers: 0
      for state, districtSchoolCountsMap of stateDistrictSchoolCountsMap
        if utils.usStateCodes.sanitizeStateCode(state)? or ['GU', 'PR'].indexOf(state) >= 0
          @countryGraphs[country].totalStates++
        stateData = {state: state, districts: 0, schools: 0, students: 0, teachers: 0}
        for district, schoolCountsMap of districtSchoolCountsMap
          stateData.districts++
          districtData = {state: state, district: district, schools: 0, students: 0, teachers: 0}
          for school, counts of schoolCountsMap
            studentCount = Object.keys(counts.students).length
            teacherCount = Object.keys(counts.teachers).length
            @countryGraphs[country].totalSchools++
            @countryGraphs[country].totalStudents += studentCount
            @countryGraphs[country].totalTeachers += teacherCount
            stateData.schools++
            stateData.students += studentCount
            stateData.teachers += teacherCount
            districtData.schools++
            districtData.students += studentCount
            districtData.teachers += teacherCount
          @countryGraphs[country].districtCounts.push(districtData)
        @countryGraphs[country].stateCounts.push(stateData)
        @countryGraphs[country].stateCountsMap[state] = stateData
      @countryCounts.push
        country: country
        schools: @countryGraphs[country].totalSchools
        students: @countryGraphs[country].totalStudents
        teachers: @countryGraphs[country].totalTeachers
      totalStudents += @countryGraphs[country].totalSchools
      totalTeachers += @countryGraphs[country].totalTeachers
    @untriagedStudents = Object.keys(studentMap).length - totalStudents
    @untriagedTeachers = Object.keys(teacherMap).length - totalTeachers

    for country, graph of @countryGraphs
      graph.stateCounts.sort (a, b) ->
        return -1 if a.students > b.students
        return 1 if a.students < b.students
        return -1 if a.teachers > b.teachers
        return 1 if a.teachers < b.teachers
        return -1 if a.schools > b.schools
        return 1 if a.schools < b.schools
        return -1 if a.districts > b.districts
        return 1 if a.districts < b.districts
        b.state.localeCompare(a.state)
      graph.districtCounts.sort (a, b) ->
        if a.state isnt b.state
          return -1 if graph.stateCountsMap[a.state].students > graph.stateCountsMap[b.state].students
          return 1 if graph.stateCountsMap[a.state].students < graph.stateCountsMap[b.state].students
          return -1 if graph.stateCountsMap[a.state].teachers > graph.stateCountsMap[b.state].teachers
          return 1 if graph.stateCountsMap[a.state].teachers < graph.stateCountsMap[b.state].teachers
          return -1 if graph.stateCountsMap[a.state].schools > graph.stateCountsMap[b.state].schools
          return 1 if graph.stateCountsMap[a.state].schools < graph.stateCountsMap[b.state].schools
          a.state.localeCompare(b.state)
        else
          return -1 if a.students > b.students
          return 1 if a.students < b.students
          return -1 if a.teachers > b.teachers
          return 1 if a.teachers < b.teachers
          return -1 if a.schools > b.schools
          return 1 if a.schools < b.schools
          a.district.localeCompare(b.district)
    @countryCounts.sort (a, b) ->
      return -1 if a.students > b.students
      return 1 if a.students < b.students
      return -1 if a.teachers > b.teachers
      return 1 if a.teachers < b.teachers
      return -1 if a.schools > b.schools
      return 1 if a.schools < b.schools
      b.country.localeCompare(a.country)

    console.log(new Date().toISOString(), 'Done...')
    super()
