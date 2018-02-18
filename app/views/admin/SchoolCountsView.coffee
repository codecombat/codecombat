RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
Classroom = require 'models/Classroom'
CourseInstance = require 'models/CourseInstance'
TrialRequest = require 'models/TrialRequest'
User = require 'models/User'
utils = require 'core/utils'

# TODO: shouldn't classroom users and user students be mostly the same?
# TODO: match anonymous trial requests with real users via email
# TODO: sanitize and use student.schoolName, can't use it directly
# TODO: example untriaged student: no geo IP, not attached to teacher with school
# TODO: example untriaged teacher: deleted but owner of a classroom
# TODO: use student geoip on their teacher

module.exports = class SchoolCountsView extends RootView
  id: 'admin-school-counts-view'
  template: require 'templates/admin/school-counts'
  state: ''

  initialize: ->
    return super() unless me.isAdmin()
    @batchSize = utils.getQueryVariable('batchsize', 50000)
    @loadData()
    super()

  updateLoadingState: (update) ->
    console.log(new Date().toISOString(), update)
    @state = "#{@state}<div>#{update}</div>"
    @render?()

  loadData: ->
    fetchBatch = (baseUrl, results, beforeId) =>
      url = "#{baseUrl}?options[limit]=#{@batchSize}"
      url += "&options[beforeId]=#{beforeId}" if beforeId
      new Promise((resolve) -> setTimeout(resolve.bind(null, Promise.resolve($.get(url))), 100))
      .then (batchResults) =>
        return Promise.resolve([]) if @destroyed
        results = results.concat(batchResults)
        if batchResults.length < @batchSize
          @updateLoadingState("Received #{results.length} from #{baseUrl} TOTAL")
          Promise.resolve(results)
        else
          @updateLoadingState("Received #{results.length} from #{baseUrl} so far")
          fetchBatch(baseUrl, results, batchResults[batchResults.length - 1]._id)

    Promise.all([
      fetchBatch("/db/classroom/-/users", [])
      fetchBatch("/db/course_instance/-/non-hoc", [])
      fetchBatch("/db/user/-/students", [])
      fetchBatch("/db/user/-/teachers", [])
      fetchBatch("/db/trial.request/-/users", [])
    ])
    .then ([classrooms, courseInstances, students, teachers, trialRequests]) =>
      teacherMap = {} # Used to make sure teachers and students only counted once
      studentMap = {} # Used to make sure teachers and students only counted once
      studentNonHocMap = {} # Used to exclude HoC users
      teacherStudentMap = {} # Used to link students to their teacher locations
      unknownSchoolCount = 1 # Used to separate unique but unknown schools

      @updateLoadingState("Processing #{courseInstances.length} course instances...")
      for courseInstance in courseInstances
        studentNonHocMap[courseInstance.ownerID] = true
        studentNonHocMap[studentID] = true for studentID in courseInstance.members ? []

      console.log(new Date().toISOString(), "Processing #{teachers.length} teachers...")
      @state = "Processing #{courseInstances.length} course instances..."
      for teacher in teachers
        teacherMap[teacher._id] = teacher.geo ? {}

      @updateLoadingState("Processing #{classrooms.length} classrooms...")
      for classroom in classrooms
        teacherID = classroom.ownerID
        teacherMap[teacherID] ?= {}
        teacherStudentMap[teacherID] ?= {}
        for studentID in classroom.members
          continue if teacherMap[studentID]
          continue unless studentNonHocMap[studentID]
          studentMap[studentID] = {}
          teacherStudentMap[teacherID][studentID] = true

      @updateLoadingState("Processing #{students.length} students...")
      for student in students
        continue unless studentNonHocMap[student._id]
        continue if teacherMap[student._id]
        studentMap[student._id] = {geo: student.geo}

      delete studentNonHocMap[studentId] for studentId in studentNonHocMap # Don't need these anymore

      @updateLoadingState("Cloning #{Object.keys(teacherMap).length} teacherMap...")
      orphanTeacherMap = {}
      orphanTeacherMap[teacherID] = true for teacherID of teacherMap
      @updateLoadingState("Cloning #{Object.keys(studentMap).length} studentMap...")
      orphanStudentMap = {}
      orphanStudentMap[studentID] = true for studentID of studentMap

      @updateLoadingState("Processing #{trialRequests.length} trial requests...")
      countryStateDistrictSchoolCountsMap = {}
      for trialRequest in trialRequests
        teacherID = trialRequest.applicant
        unless teacherMap[teacherID]
          # E.g. parents
          # console.log("Skipping non-teacher #{teacherID} trial request #{trialRequest._id}")
          continue
        props = trialRequest.properties
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
          if _.isEmpty(country)
            country = 'unknown'
          else
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

      @updateLoadingState("Processing #{Object.keys(orphanTeacherMap).length} orphaned teachers with geo IPs...")
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

      @updateLoadingState("Processing #{Object.keys(orphanTeacherMap).length} orphaned teachers with 10+ students...")
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

      @updateLoadingState("Processing #{Object.keys(orphanStudentMap).length} orphaned students with geo IPs...")
      for studentID of orphanStudentMap
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

      @updateLoadingState('Building country graphs...')
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

      @updateLoadingState("teacherMap #{Object.keys(teacherMap).length} totalTeachers #{totalTeachers} orphanTeacherMap #{Object.keys(orphanTeacherMap).length}  @untriagedTeachers #{@untriagedTeachers}")
      @updateLoadingState("studentMap #{Object.keys(studentMap).length} totalStudents #{totalStudents} orphanStudentMap #{Object.keys(orphanStudentMap).length}  @untriagedStudents #{@untriagedStudents}")

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

      @updateLoadingState('Done...')
      @render?()
