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
      @administeredClassrooms = new Classrooms()
      @listenTo @administeredClassrooms, 'sync', @administeredClassroomsSync
      teachers = me.get('administratedTeachers')
      @totalAdministeredTeachers = teachers.length
      teachers.forEach((teacher) =>
        @supermodel.trackRequest @administeredClassrooms.fetchByOwner(teacher)
      )

    me.getClientCreatorPermissions()?.then(() => @render?())

    leadPriorityRequest = me.getLeadPriority()
    @supermodel.trackRequest leadPriorityRequest
    leadPriorityRequest.then (r) => @onLeadPriorityResponse(r)

  afterRender: ->
    super()
    @$('[data-toggle="tooltip"]').tooltip(placement: 'right', html: true, animation: false, container: '#site-content-area')

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

  administeredClassroomsSync: ->
    if --@totalAdministeredTeachers < 0
      @totalAdministeredTeachers = 0

    if @totalAdministeredTeachers is 0
      allClassrooms = @administeredClassrooms
        .models.map((c) -> c.attributes)
        .filter((c) -> c.courses.length > 1 or (c.courses.length == 0 and c.courses[0]._id != '560f1a9f22961295f9427742'))

      relativeToYear = (year, date) ->
        shortYear = year - 2000 # This will only work for the next 80 years :)
        start = new Date("#{year}-7-1")
        end = new Date("#{year + 1}-6-30")
        # TODO: Are the dates inclusive or exclusive?
        if date < start
          return "7/1/#{shortYear - 1} thru 6/30/#{year}"
        else if date > end
          return "7/1/#{shortYear + 1} thru 6/30/#{year + 2}"
        else
          return "7/1/#{shortYear} thru 6/30/#{year + 1}"

      years = {}
      unknownDate = 'No date'

      # Count total students in classrooms (both active and archived) created between
      # July 1-June 30 as the cut off for each school year (e.g. July 1, 2019-June 30, 2020)
      allClassrooms.forEach((classroom) ->
        start = new Date(classroom.classDateStart) if classroom.classDateStart
        end = new Date(classroom.classDateEnd) if classroom.classDateEnd
        startYear = null
        endYear = null

        if not start and not end
          if not years[unknownDate]
            years[unknownDate] = new Set(classroom.members)
          else
            classroom.members.forEach(years[unknownDate].add, years[unknownDate])

        if start
          startYear = relativeToYear(start.getFullYear(), start)
          if not years[startYear]
            years[startYear] = new Set(classroom.members)
          else
            classroom.members.forEach(years[startYear].add, years[startYear])

        if end
          endYear = relativeToYear(end.getFullYear(), end)
          if startYear != endYear
            if not years[endYear]
              years[endYear] = new Set(classroom.members)
            else
              classroom.members.forEach(years[endYear].add, years[endYear])

        if start and end and startYear != endYear
          if end > start
            console.error('Start date is after end date: ', classroom.id, start, end)
          else
            firstYear = start.getFullYear()
            lastYear = end.getFullYear()
            # This means a class has lasted multiple years, which is not the norm. We handle it
            # by adding the students to each year within the time between the years.
            if lastYear - firstYear > 1
              for i in [firstYear..lastYear]
                year = "#{i}-7-1 to #{i + 1}-6-30"
                if not years[year]
                  years[year] = new Set(classroom.members)
                else
                  classroom.members.forEach(years[year].add, years[year])
      )

      @state.set('uniqueStudentsPerYear', years)

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
    shouldUpsell = me.useStripe() and !skipUpsellDueToExistingLicenses and (@state.get('leadPriority') is 'low')

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
