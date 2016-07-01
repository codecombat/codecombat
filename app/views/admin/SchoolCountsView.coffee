RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
Classroom = require 'models/Classroom'
CourseInstance = require 'models/CourseInstance'
TrialRequest = require 'models/TrialRequest'
User = require 'models/User'
utils = require 'core/utils'

# TODO: match anonymous trial requests with real users via email
# TODO: sanitize and use student.schoolName, can't use it directly
# TODO: example untriaged student: no geo IP, not attached to teacher with school
# TODO: example untriaged teacher: deleted but owner of a classroom
# TODO: use student geoip on their teacher

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
    unknownSchoolCount = 1 # Used to separate unique but unknown schools

    console.log(new Date().toISOString(), "Processing #{@courseInstances.models.length} course instances...")
    for courseInstance in @courseInstances.models
      studentNonHocMap[courseInstance.get('ownerID')] = true
      studentNonHocMap[studentID] = true for studentID in courseInstance.get('members') ? []

    console.log(new Date().toISOString(), "Processing #{@classrooms.models.length} classrooms...")
    for classroom in @classrooms.models
      teacherID = classroom.get('ownerID')
      teacherMap[teacherID] ?= {}
      teacherStudentMap[teacherID] ?= {}
      for studentID in classroom.get('members')
        continue if teacherMap[studentID]
        continue unless studentNonHocMap[studentID]
        studentMap[studentID] = {}
        teacherStudentMap[teacherID][studentID] = true

    console.log(new Date().toISOString(), "Processing #{@teachers.models.length} teachers...")
    for teacher in @teachers.models
      teacherMap[teacher.id] = teacher.get('geo') ? {}
      delete studentMap[teacher.id]

    console.log(new Date().toISOString(), "Processing #{@students.models.length} students...")
    for student in @students.models
      continue unless studentNonHocMap[student.id]
      continue if teacherMap[student.id]
      studentMap[student.id] = {geo: student.get('geo')}

    orphanStudentMap = _.cloneDeep(studentMap)
    orphanTeacherMap = _.cloneDeep(teacherMap)

    console.log(new Date().toISOString(), "Processing #{@trialRequests.models.length} trial requests...")
    countryStateDistrictSchoolCountsMap = {}
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
        for studentID, val of teacherStudentMap[teacherID] when orphanStudentMap[studentID]
          countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true
          delete orphanStudentMap[studentID]
        delete orphanTeacherMap[teacherID]
      else if not _.isEmpty(props.country)
        country = props.country?.trim()
        country = country[0].toUpperCase() + country.substring(1).toLowerCase()
        country = 'Taiwan' if /台灣/ig.test(country)
        country = 'UK' if /^uk$|united kingdom|england/ig.test(country)
        country = 'USA' if /^u\.s\.?(\.a)?\.?$|^us$|america|united states|usa/ig.test(country)
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
        for studentID, val of teacherStudentMap[teacherID] when orphanStudentMap[studentID]
          countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true
          delete orphanStudentMap[studentID]
        delete orphanTeacherMap[teacherID]

    console.log(new Date().toISOString(), "Processing #{Object.keys(orphanTeacherMap).length} orphaned teachers with geo IPs...")
    for teacherID, val of orphanTeacherMap
      continue unless teacherMap[teacherID].country
      country = teacherMap[teacherID].countryName or teacherMap[teacherID].country
      country = 'UK' if country is 'GB' or country is 'United Kingdom'
      country = 'USA' if country is 'US' or country is 'United States'
      state = teacherMap[teacherID].region or 'unknown'
      district = 'unknown'
      school = 'unknown'
      if teacherStudentMap[teacherID] and Object.keys(teacherStudentMap[teacherID]).length >= 10
        school += unknownSchoolCount++
      countryStateDistrictSchoolCountsMap[country] ?= {}
      countryStateDistrictSchoolCountsMap[country][state] ?= {}
      countryStateDistrictSchoolCountsMap[country][state][district] ?= {}
      countryStateDistrictSchoolCountsMap[country][state][district][school] ?= {students: {}, teachers: {}}
      countryStateDistrictSchoolCountsMap[country][state][district][school].teachers[teacherID] = true
      if teacherStudentMap[teacherID] and Object.keys(teacherStudentMap[teacherID]).length >= 10
        for studentID, val of teacherStudentMap[teacherID] when orphanStudentMap[studentID]
          countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true
          delete orphanStudentMap[studentID]
      delete orphanTeacherMap[teacherID]

    console.log(new Date().toISOString(), "Processing #{Object.keys(orphanTeacherMap).length} orphaned teachers with 10+ students...")
    for teacherID, val of orphanTeacherMap
      continue unless teacherStudentMap[teacherID] and Object.keys(teacherStudentMap[teacherID]).length >= 10
      country = 'unknown'
      state = 'unknown'
      district = 'unknown'
      school = "unknown#{unknownSchoolCount++}"
      countryStateDistrictSchoolCountsMap[country] ?= {}
      countryStateDistrictSchoolCountsMap[country][state] ?= {}
      countryStateDistrictSchoolCountsMap[country][state][district] ?= {}
      countryStateDistrictSchoolCountsMap[country][state][district][school] ?= {students: {}, teachers: {}}
      countryStateDistrictSchoolCountsMap[country][state][district][school].teachers[teacherID] = true
      for studentID, val of teacherStudentMap[teacherID] when orphanStudentMap[studentID]
        countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true
        delete orphanStudentMap[studentID]
      delete orphanTeacherMap[teacherID]

    console.log(new Date().toISOString(), "Processing #{Object.keys(orphanStudentMap).length} orphaned students with geo IPs...")
    for studentID, val of orphanStudentMap
      continue unless studentMap[studentID].geo?.country
      country = studentMap[studentID].geo.countryName or studentMap[studentID].geo.country
      country = 'UK' if country is 'GB' or country is 'United Kingdom'
      country = 'USA' if country is 'US' or country is 'United States'
      state = studentMap[studentID].geo.region or 'unknown'
      district = 'unknown'
      school = 'unknown'
      countryStateDistrictSchoolCountsMap[country] ?= {}
      countryStateDistrictSchoolCountsMap[country][state] ?= {}
      countryStateDistrictSchoolCountsMap[country][state][district] ?= {}
      countryStateDistrictSchoolCountsMap[country][state][district][school] ?= {students: {}, teachers: {}}
      countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true
      delete orphanStudentMap[studentID]

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
      totalStudents += @countryGraphs[country].totalStudents
      totalTeachers += @countryGraphs[country].totalTeachers

    # Compare against orphanStudentMap and orphanTeacherMap to catch bugs
    @untriagedStudents = Object.keys(studentMap).length - totalStudents
    @untriagedTeachers = Object.keys(teacherMap).length - totalTeachers

    console.log(new Date().toISOString(), "teacherMap #{Object.keys(teacherMap).length} totalTeachers #{totalTeachers} orphanTeacherMap #{Object.keys(orphanTeacherMap).length}  @untriagedTeachers #{@untriagedTeachers}")
    console.log(new Date().toISOString(), "studentMap #{Object.keys(studentMap).length} totalStudents #{totalStudents} orphanStudentMap #{Object.keys(orphanStudentMap).length}  @untriagedStudents #{@untriagedStudents}")

    for country, graph of @countryGraphs
      graph.stateCounts.sort (a, b) ->
        b.students - a.students or b.teachers - a.teachers or b.schools - a.schools or b.districts - a.districts or b.state.localeCompare(a.state)
      graph.districtCounts.sort (a, b) ->
        if a.state isnt b.state
          stateCountsA = graph.stateCountsMap[a.state]
          stateCountsB = graph.stateCountsMap[b.state]
          stateCountsB.students - stateCountsA.students or stateCountsB.teachers - stateCountsA.teachers or stateCountsB.schools - stateCountsA.schools or stateCountsB.districts - stateCountsA.districts or a.state.localeCompare(b.state)
        else
          b.students - a.students or b.teachers - a.teachers or b.schools - a.schools or b.district.localeCompare(a.district)
    @countryCounts.sort (a, b) ->
      b.students - a.students or b.teachers - a.teachers or b.schools - a.schools or b.country.localeCompare(a.country)

    console.log(new Date().toISOString(), 'Done...')
    super()
