RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
Classroom = require 'models/Classroom'
TrialRequest = require 'models/TrialRequest'
User = require 'models/User'

# TODO: trim orphaned students: course instances != Single Player, hourOfCode != true
# TODO: match anonymous trial requests with real users via email

module.exports = class SchoolCountsView extends RootView
  id: 'admin-school-counts-view'
  template: require 'templates/admin/school-counts'

  initialize: ->
    return super() unless me.isAdmin()
    @classrooms = new CocoCollection([], { url: "/db/classroom/-/users", model: Classroom })
    @supermodel.loadCollection(@classrooms, 'classrooms', {cache: false})
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
    teacherStudentMap = {} # Used to link students to their teacher locations
    orphanedSchoolStudentMap = {} # Used to link student schoolName to teacher Nces data
    countryStateDistrictSchoolCountsMap = {} # Data graph

    console.log(new Date().toISOString(), 'Processing classrooms...')
    for classroom in @classrooms.models
      teacherID = classroom.get('ownerID')
      teacherMap[teacherID] ?= {}
      teacherMap[teacherID] = true
      teacherStudentMap[teacherID] ?= {}
      for studentID in classroom.get('members')
        studentMap[studentID] = true
        teacherStudentMap[teacherID][studentID] = true

    console.log(new Date().toISOString(), 'Processing teachers...')
    for teacher in @teachers.models
      teacherMap[teacher.id] ?= {}
      delete studentMap[teacher.id]

    console.log(new Date().toISOString(), 'Processing students...')
    for student in @students.models when not teacherMap[student.id]
      schoolName = student.get('schoolName')
      studentMap[student.id] = true
      orphanedSchoolStudentMap[schoolName] ?= {}
      orphanedSchoolStudentMap[schoolName][student.id] = true

    console.log(new Date().toISOString(), 'Processing trial requests...')
    # TODO: this step is crazy slow
    orphanSchoolsMatched = 0
    orphanStudentsMatched = 0
    for trialRequest in @trialRequests.models
      teacherID = trialRequest.get('applicant')
      unless teacherMap[teacherID]
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
        for orphanSchool, students of orphanedSchoolStudentMap
          if school is orphanSchool or school.replace(/unified|elementary|high|district|#\d+|isd|unified district|school district/ig, '').trim() is orphanSchool.trim()
            orphanSchoolsMatched++
            for studentID, val of students
              orphanStudentsMatched++
              countryStateDistrictSchoolCountsMap[country][state][district][school].students[studentID] = true
            delete orphanedSchoolStudentMap[school]
    console.log(new Date().toISOString(), "#{orphanSchoolsMatched} orphanSchoolsMatched #{orphanStudentsMatched} orphanStudentsMatched")

    console.log(new Date().toISOString(), 'Building graph...')
    @totalSchools = 0
    @totalStudents = 0
    @totalTeachers = 0
    @totalStates = 0
    @stateCounts = []
    stateCountsMap = {}
    @districtCounts = []
    for country, stateDistrictSchoolCountsMap of countryStateDistrictSchoolCountsMap
      continue unless /usa/ig.test(country)
      for state, districtSchoolCountsMap of stateDistrictSchoolCountsMap
        @totalStates++
        stateData = {state: state, districts: 0, schools: 0, students: 0, teachers: 0}
        for district, schoolCountsMap of districtSchoolCountsMap
          stateData.districts++
          districtData = {state: state, district: district, schools: 0, students: 0, teachers: 0}
          for school, counts of schoolCountsMap
            studentCount = Object.keys(counts.students).length
            teacherCount = Object.keys(counts.teachers).length
            @totalSchools++
            @totalStudents += studentCount
            @totalTeachers += teacherCount
            stateData.schools++
            stateData.students += studentCount
            stateData.teachers += teacherCount
            districtData.schools++
            districtData.students += studentCount
            districtData.teachers += teacherCount
          @districtCounts.push(districtData)
        @stateCounts.push(stateData)
        stateCountsMap[state] = stateData
    @untriagedStudents = Object.keys(studentMap).length - @totalStudents

    @stateCounts.sort (a, b) ->
      return -1 if a.students > b.students
      return 1 if a.students < b.students
      return -1 if a.teachers > b.teachers
      return 1 if a.teachers < b.teachers
      return -1 if a.districts > b.districts
      return 1 if a.districts < b.districts
      b.state.localeCompare(a.state)
    @districtCounts.sort (a, b) ->
      if a.state isnt b.state
        return -1 if stateCountsMap[a.state].students > stateCountsMap[b.state].students
        return 1 if stateCountsMap[a.state].students < stateCountsMap[b.state].students
        return -1 if stateCountsMap[a.state].teachers > stateCountsMap[b.state].teachers
        return 1 if stateCountsMap[a.state].teachers < stateCountsMap[b.state].teachers
        a.state.localeCompare(b.state)
      else
        return -1 if a.students > b.students
        return 1 if a.students < b.students
        return -1 if a.teachers > b.teachers
        return 1 if a.teachers < b.teachers
        a.district.localeCompare(b.district)
    super()
