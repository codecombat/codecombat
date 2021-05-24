require('app/styles/courses/enrollments-view.sass')
RootView = require 'views/core/RootView'
Classrooms = require 'collections/Classrooms'
State = require 'models/State'
User = require 'models/User'
Prepaids = require 'collections/Prepaids'
template = require 'templates/courses/enrollments-view'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
HowToEnrollModal = require 'views/teachers/HowToEnrollModal'
TeachersContactModal = require 'views/teachers/TeachersContactModal'
ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
utils = require 'core/utils'
ShareLicensesModal = require 'views/teachers/ShareLicensesModal'

{
  STARTER_LICENSE_COURSE_IDS
  FREE_COURSE_IDS
} = require 'core/constants'

module.exports = class EnrollmentsView extends RootView
  id: 'enrollments-view'
  template: template
  enrollmentRequestSent: false

  events:
    'click #enroll-students-btn': 'onClickEnrollStudentsButton'
    'click #how-to-enroll-link': 'onClickHowToEnrollLink'
    'click #contact-us-btn': 'onClickContactUsButton'
    'click .share-licenses-link': 'onClickShareLicensesLink'

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
      shouldUpsell: false
    })
    window.tracker?.trackEvent 'Classes Licenses Loaded', category: 'Teachers', ['Mixpanel']
    super(options)

    @utils = utils
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
    @supermodel.trackRequest @prepaids.fetchMineAndShared()
    @listenTo @prepaids, 'sync', @onPrepaidsSync
    @debouncedRender = _.debounce @render, 0
    @listenTo @prepaids, 'sync', @updatePrepaidGroups
    @listenTo(@state, 'all', @debouncedRender)

    if me.isSchoolAdmin()
      @newAdministeredClassrooms = new Classrooms()
      @allAdministeredClassrooms = []
      @listenTo @newAdministeredClassrooms, 'sync', @newAdministeredClassroomsSync
      teachers = me.get('administratedTeachers') ? []
      @totalAdministeredTeachers = teachers.length
      teachers.forEach((teacher) =>
        @supermodel.trackRequest @newAdministeredClassrooms.fetchByOwner(teacher)
      )

    me.getClientCreatorPermissions()?.then(() => @render?())

    leadPriorityRequest = me.getLeadPriority()
    @supermodel.trackRequest leadPriorityRequest
    leadPriorityRequest.then (r) => @onLeadPriorityResponse(r)

  afterRender: ->
    super()
    @$('[data-toggle="tooltip"]').tooltip(placement: 'top', html: true, animation: false, container: '#site-content-area')

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

  newAdministeredClassroomsSync: ->
    @allAdministeredClassrooms.push(
      @newAdministeredClassrooms
        .models
        .map((c) -> c.attributes)
        .filter((c) -> c.courses.length > 1 or (c.courses.length == 1 and c.courses[0]._id != utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE))
    )

    @totalAdministeredTeachers -= 1
    if @totalAdministeredTeachers is 0
      students = @uniqueStudentsPerYear(_.flatten(@allAdministeredClassrooms))
      @state.set('uniqueStudentsPerYear', students)

  relativeToYear: (momentDate) ->
    year = momentDate.year()
    shortYear = year - 2000
    start = "#{year}-06-30" # One day earlier to ease comparison
    end = "#{year + 1}-07-01" # One day later to ease comparison
    if moment(momentDate).isBetween(start, end)
      displayStartDate = "7/1/#{shortYear}"
      displayEndDate = "6/30/#{year + 1}"
    else if moment(momentDate).isBefore(start)
      displayStartDate = "7/1/#{shortYear - 1}"
      displayEndDate = "6/30/#{year}"
    else if moment(momentDate).isAfter(end)
      displayStartDate = "7/1/#{shortYear + 1}"
      displayEndDate = "6/30/#{year + 2}"

    return $.i18n.t('school_administrator.date_thru_date', {
      startDateRange: displayStartDate
      endDateRange: displayEndDate
    })

  # Count total students in classrooms (both active and archived) created between
  # July 1-June 30 as the cut off for each school year (e.g. July 1, 2019-June 30, 2020)
  uniqueStudentsPerYear: (allClassrooms) =>
    dateFromObjectId = (objectId) ->
      return new Date(parseInt(objectId.substring(0, 8), 16) * 1000)

    years = {}
    for classroom in allClassrooms
      { _id, members } = classroom
      if members?.length > 0
        creationDate = moment(dateFromObjectId(_id))
        year = @relativeToYear(creationDate)
        if not years[year]
          years[year] = new Set(members)
        else
          yearSet = years[year]
          members.forEach(yearSet.add, yearSet)

    return years

  onLoaded: ->
    @calculateEnrollmentStats()
    @state.set('totalCourses', @courses.size())
    super()

  onPrepaidsSync: ->
    @prepaids.each (prepaid) =>
      prepaid.creator = new User()
      # We never need this information if the user would be `me`
      if prepaid.get('creator') isnt me.id
        @supermodel.trackRequest prepaid.creator.fetchCreatorOfPrepaid(prepaid)

    @decideUpsell()

  onLeadPriorityResponse: ({ priority }) ->
    @state.set({ leadPriority: priority })
    @decideUpsell()

  decideUpsell: ->
    # There are also non classroom prepaids.  We only use the course or starter_license prepaids to determine
    # if we should skip upsell (we ignore the others).

    coursePrepaids = @prepaids.filter((p) => p.get('type') == 'course')

    skipUpsellDueToExistingLicenses = coursePrepaids.length > 0
    shouldUpsell = me.useStripe() and !skipUpsellDueToExistingLicenses and (@state.get('leadPriority') is 'low') and (me.get('country') not in ['australia']) and not me.get('administratedTeachers')?.length

    @state.set({ shouldUpsell })

    if shouldUpsell and not @upsellTracked
      @upsellTracked = true
      application.tracker?.trackEvent 'Starter License Upsell: Banner Viewed', {price: @state.get('centsPerStudent'), seats: @state.get('quantityToBuy')}

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
    $.ajax({
      type: 'POST',
      url: '/db/trial.request.slacklog',
      data: {
        event: 'EnrollmentsView clicked contact us',
        name: me?.broadName(),
        email: me?.get('email')
      }
    })
    window.tracker?.trackEvent 'Classes Licenses Contact Us', category: 'Teachers', ['Mixpanel']
    modal = new TeachersContactModal()
    @openModalView(modal)
    modal.on 'submit', =>
      @enrollmentRequestSent = true
      @debouncedRender()

  onClickEnrollStudentsButton: ->
    window.tracker?.trackEvent 'Classes Licenses Enroll Students', category: 'Teachers', ['Mixpanel']
    modal = new ActivateLicensesModal({ selectedUsers: @notEnrolledUsers, users: @members })
    @openModalView(modal)
    modal.once 'hidden', =>
      @prepaids.add(modal.prepaids.models, { merge: true })
      @debouncedRender() # Because one changed model does not a collection update make

  onClickShareLicensesLink: (e) ->
    prepaidID = $(e.currentTarget).data('prepaidId')
    @shareLicensesModal = new ShareLicensesModal({prepaid: @prepaids.get(prepaidID)})
    @shareLicensesModal.on 'setJoiners', (prepaidID, joiners) =>
      prepaid = @prepaids.get(prepaidID)
      prepaid.set({ joiners })
    @openModalView(@shareLicensesModal)

  getEnrollmentExplanation: ->
    t = {}
    for i in [1..5]
      t[i] = $.i18n.t("teacher.enrollment_explanation_#{i}")
    return "<p>#{t[1]} <b>#{t[2]}</b> #{t[3]}</p><p><b>#{t[4]}:</b> #{t[5]}</p>"
