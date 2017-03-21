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
utils = require 'core/utils'

{
  STARTER_LICENSE_COURSE_IDS
  FREE_COURSE_IDS
} = require 'core/constants'

module.exports = class EnrollmentsView extends RootView
  id: 'enrollments-view'
  template: template

  events:
    'click #enroll-students-btn': 'onClickEnrollStudentsButton'
    'click #how-to-enroll-link': 'onClickHowToEnrollLink'
    'click #contact-us-btn': 'onClickContactUsButton'

  getTitle: -> return $.i18n.t('teacher.enrollments')
  
  i18nData: ->
    starterLicenseCourseList: @state.get('starterLicenseCourseList')

  initialize: (options) ->
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
      shouldUpsell: true
    })
    window.tracker?.trackEvent 'Classes Licenses Loaded', category: 'Teachers', ['Mixpanel']
    super(options)

    @courses = new Courses()
    @supermodel.trackRequest @courses.fetch({data: { project: 'free,i18n,name' }})
    @listenTo @courses, 'sync', ->
      @state.set { starterLicenseCourseList: @getStarterLicenseCourseList() }
    # Listen for language change
    @listenTo me, 'change:preferredLanguage', ->
      @state.set { starterLicenseCourseList: @getStarterLicenseCourseList() }
    @members = new Users()
    @classrooms = new Classrooms()
    @classrooms.comparator = '_id'
    @listenToOnce @classrooms, 'sync', @onceClassroomsSync
    @supermodel.trackRequest @classrooms.fetchMine()
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(me.id)
    @debouncedRender = _.debounce @render, 0
    @listenTo @prepaids, 'sync', @updatePrepaidGroups
    @listenTo(@state, 'all', @debouncedRender)
    @listenTo(me, 'change:enrollmentRequestSent', @debouncedRender)

    leadPriorityRequest = me.getLeadPriority()
    @supermodel.trackRequest leadPriorityRequest
    leadPriorityRequest.then ({ priority }) =>
      shouldUpsell = (priority is 'low')
      @state.set({ shouldUpsell })
      if shouldUpsell
        application.tracker?.trackEvent 'Starter License Upsell: Banner Viewed', {price: @state.get('centsPerStudent'), seats: @state.get('quantityToBuy')}

  getStarterLicenseCourseList: ->
    return if !@courses.loaded
    COURSE_IDS = _.difference(STARTER_LICENSE_COURSE_IDS, FREE_COURSE_IDS)
    starterLicenseCourseList = _.difference(STARTER_LICENSE_COURSE_IDS, FREE_COURSE_IDS).map (_id) =>
      utils.i18n(@courses.findWhere({_id})?.attributes or {}, 'name')
    starterLicenseCourseList.push($.t('general.and') + ' ' + starterLicenseCourseList.pop())
    starterLicenseCourseList.join(', ')

  onceClassroomsSync: ->
    for classroom in @classrooms.models
      @supermodel.trackRequests @members.fetchForClassroom(classroom, {remove: false, removeDeleted: true})

  onLoaded: ->
    @calculateEnrollmentStats()
    @state.set('totalCourses', @courses.size())
    super()

  updatePrepaidGroups: ->
    @state.set('prepaidGroups', @prepaids.groupBy((p) -> p.status()))

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
    window.tracker?.trackEvent 'Classes Licenses Contact Us', category: 'Teachers', ['Mixpanel']
    @openModalView(new TeachersContactModal())

  onClickEnrollStudentsButton: ->
    window.tracker?.trackEvent 'Classes Licenses Enroll Students', category: 'Teachers', ['Mixpanel']
    modal = new ActivateLicensesModal({ selectedUsers: @notEnrolledUsers, users: @members })
    @openModalView(modal)
    modal.once 'hidden', =>
      @prepaids.add(modal.prepaids.models, { merge: true })
      @debouncedRender() # Because one changed model does not a collection update make
