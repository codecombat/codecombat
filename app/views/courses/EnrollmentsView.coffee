RootView = require 'views/core/RootView'
Classrooms = require 'collections/Classrooms'
State = require 'models/State'
Prepaids = require 'collections/Prepaids'
template = require 'templates/courses/enrollments-view'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
HowToEnrollModal = require 'views/teachers/HowToEnrollModal'
TeachersContactModal = require 'views/teachers/TeachersContactModal'
ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'

module.exports = class EnrollmentsView extends RootView
  id: 'enrollments-view'
  template: template

  events:
    'input #students-input': 'onInputStudentsInput'
    'click #enroll-students-btn': 'onClickEnrollStudentsButton'
    'click #how-to-enroll-link': 'onClickHowToEnrollLink'
    'click #contact-us-btn': 'onClickContactUsButton'

  initialize: ->
    @state = new State({
      totalEnrolled: 0
      totalNotEnrolled: 0
      classroomNotEnrolledMap: {}
      classroomEnrolledMap: {}
      numberOfStudents: 15
      totalCourses: 0
      prepaidGroups: {
        'available': []
        'pending': []
      }
    })

    @courses = new Courses()
    @supermodel.trackRequest @courses.fetch({data: { project: 'free' }})
    @members = new Users()
    @classrooms = new Classrooms()
    @classrooms.comparator = '_id'
    @listenToOnce @classrooms, 'sync', @onceClassroomsSync
    @supermodel.trackRequest @classrooms.fetchMine()
    @prepaids = new Prepaids()
    @prepaids.comparator = '_id'
    @supermodel.trackRequest @prepaids.fetchByCreator(me.id)
    @debouncedRender = _.debounce @render, 0
    @listenTo @prepaids, 'all', -> @state.set('prepaidGroups', @prepaids.groupBy((p) -> p.status()))
    @listenTo(@state, 'all', @debouncedRender)

  onceClassroomsSync: ->
    for classroom in @classrooms.models
      @supermodel.trackRequests @members.fetchForClassroom(classroom, {remove: false, removeDeleted: true})

  onLoaded: ->
    @calculateEnrollmentStats()
    @state.set('totalCourses', @courses.size())
    super()

  calculateEnrollmentStats: ->
    @removeDeletedStudents()
    
    # sort users into enrolled, not enrolled
    groups = @members.groupBy (m) -> m.isEnrolled()
    enrolledUsers = new Users(groups.true)
    @notEnrolledUsers = new Users(groups.false)

    map = {} 
    
    for classroom in @classrooms.models
      map[classroom.id] = _.countBy(classroom.get('members'), (userID) -> enrolledUsers.get(userID)?).false
    
    @state.set({
      totalEnrolled: enrolledUsers.size()
      totalNotEnrolled: @notEnrolledUsers.size()
      classroomNotEnrolledMap: map
    })
    
    true
    
  removeDeletedStudents: (e) ->
    for classroom in @classrooms.models
      _.remove(classroom.get('members'), (memberID) =>
        not @members.get(memberID) or @members.get(memberID)?.get('deleted')
      )
    true

  onClickHowToEnrollLink: ->
    @openModalView(new HowToEnrollModal())

  onClickContactUsButton: ->
    @openModalView(new TeachersContactModal({ enrollmentsNeeded: @state.get('numberOfStudents') }))
    
  onInputStudentsInput: ->
    input = @$('#students-input').val()
    if input isnt "" and (parseFloat(input) isnt parseInt(input) or _.isNaN parseInt(input))
      @$('#students-input').val(@state.get('numberOfStudents'))
    else
      @state.set('numberOfStudents', Math.max(parseInt(@$('#students-input').val()) or 0, 0))

  numberOfStudentsIsValid: -> 0 < @get('numberOfStudents') < 100000

  onClickEnrollStudentsButton: ->
    modal = new ActivateLicensesModal({ selectedUsers: @notEnrolledUsers, users: @members })
    @openModalView(modal)
