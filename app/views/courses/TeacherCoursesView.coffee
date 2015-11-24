app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
CocoModel = require 'models/CocoModel'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
User = require 'models/User'
Prepaid = require 'models/Prepaid'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-courses-view'
utils = require 'core/utils'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'

module.exports = class TeacherCoursesView extends RootView
  id: 'teacher-courses-view'
  template: template

  events:
    'click #create-new-class-btn': 'onClickCreateNewclassButton'
    'click .add-students-btn': 'onClickAddStudentsButton'
    'click .course-instance-membership-checkbox': 'onClickCourseInstanceMembershipCheckbox'
    'click #save-changes-btn': 'onClickSaveChangesButton'
    'click #manage-tab-link': 'onClickManageTabLink'
    'click .edit-classroom-small': 'onClickEditClassroomSmall'

  constructor: (options) ->
    super(options)
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @classrooms.comparator = '_id'
    @listenToOnce @classrooms, 'sync', @onceClassroomsSync
    @supermodel.loadCollection(@classrooms, 'classrooms', {data: {ownerID: me.id}})
    @courseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance })
    @courseInstances.comparator = 'courseID'
    @courseInstances.sliceWithMembers = -> return @filter (courseInstance) -> _.size(courseInstance.get('members')) and courseInstance.get('classroomID')
    @supermodel.loadCollection(@courseInstances, 'course_instances', {data: {ownerID: me.id}})
    @members = new CocoCollection([], { model: User })
    @prepaids = new CocoCollection([], { url: "/db/prepaid", model: Prepaid })
    sum = (numbers) -> _.reduce(numbers, (a, b) -> a + b)
    @prepaids.totalMaxRedeemers = -> sum((prepaid.get('maxRedeemers') for prepaid in @models)) or 0
    @prepaids.totalRedeemers = -> sum((_.size(prepaid.get('redeemers')) for prepaid in @models)) or 0
    @prepaids.comparator = '_id'
    @supermodel.loadCollection(@prepaids, 'prepaids', {data: {creator: me.id}})
    @listenTo @members, 'sync', @renderManageTab
    @usersToRedeem = new CocoCollection([], { model: User })
    @hoc = utils.getQueryVariable('hoc')
    @

  onceClassroomsSync: ->
    for classroom in @classrooms.models
      @members.fetch({
        remove: false
        url: "/db/classroom/#{classroom.id}/members"
      })

  onClickCreateNewclassButton: ->
    name = @$('#new-classroom-name-input').val()
    return unless name
    classroom = new Classroom({ name: name })
    classroom.save()
    @classrooms.add(classroom)
    classroom.saving = true
    @renderManageTab()
    @listenTo classroom, 'sync', ->
      classroom.saving = false
      @fillMissingCourseInstances()

  renderManageTab: ->
    isActive = @$('#manage-tab-pane').hasClass('active')
    @renderSelectors('#manage-tab-pane')
    @$('#manage-tab-pane').toggleClass('active', isActive)

  onClickEditClassroomSmall: (e) ->
    classroomID = $(e.target).closest('small').data('classroom-id')
    classroom = @classrooms.get(classroomID)
    modal = new ClassroomSettingsModal({classroom: classroom})
    @openModalView(modal)
    @listenToOnce modal, 'hide', @renderManageTab

  onClickAddStudentsButton: (e) ->
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    modal = new InviteToClassroomModal({classroom: classroom})
    @openModalView(modal)

  onLoaded: ->
    super()
    @linkCourseIntancesToCourses()
    @fillMissingCourseInstances()

  linkCourseIntancesToCourses: ->
    for courseInstance in @courseInstances.models
      courseInstance.course = @courses.get(courseInstance.get('courseID'))

  fillMissingCourseInstances: ->
    # TODO: Give teachers control over which courses are enabled for a given class.
    # Add/remove course instances and columns in the view to match.
    for classroom in @classrooms.models
      classroom.filling = false
      for course in @courses.models
        courseInstance = @courseInstances.findWhere({classroomID: classroom.id, courseID: course.id})
        if not courseInstance
          classroom.filling = true
          courseInstance = new CourseInstance({
            classroomID: classroom.id
            courseID: course.id
          })
          # TODO: figure out a better way to get around triggering validation errors for properties
          # that the server will end up filling in, like an empty members array, ownerID
          courseInstance.save(null, {validate: false})
          courseInstance.course = course
          @courseInstances.add(courseInstance)
          @listenToOnce courseInstance, 'sync', @fillMissingCourseInstances
          @renderManageTab()
          return
    @renderManageTab()

  onClickCourseInstanceMembershipCheckbox: ->
    usersToRedeem = {}
    checkedBoxes = @$('.course-instance-membership-checkbox:checked')
    _.each checkedBoxes, (el) =>
      $el = $(el)
      userID = $el.data('user-id')
      return if usersToRedeem[userID]
      user = @members.get(userID)
      return if user.get('coursePrepaidID')
      courseInstanceID = $el.data('course-instance-id')
      courseInstance = @courseInstances.get(courseInstanceID)
      return if courseInstance.course.get('free')
      usersToRedeem[userID] = user

    @usersToRedeem = new CocoCollection(_.values(usersToRedeem), {model: User})
    @numCourseInstancesToAddTo = checkedBoxes.length
    @renderSelectors '#fixed-area'

  onClickSaveChangesButton: ->
    @$('.course-instance-membership-checkbox').attr('disabled', true)
    checkedBoxes = @$('.course-instance-membership-checkbox:checked')
    raw = _.map checkedBoxes, (el) =>
      $el = $(el)
      userID = $el.data('user-id')
      courseInstanceID = $el.data('course-instance-id')
      courseInstance = @courseInstances.get(courseInstanceID)
      return {
        courseInstance: courseInstance
        userID: userID
      }
    @membershipAdditions = new CocoCollection(raw, { model: User }) # TODO: Allow collections not to have models defined?
    @membershipAdditions.originalSize = @membershipAdditions.size()
    @usersToRedeem.originalSize = @usersToRedeem.size()
    @state = 'saving-changes'
    @renderSelectors '#fixed-area'
    @redeemUsers()

  redeemUsers: ->
    if not @usersToRedeem.size()
      @addMemberships()
      return

    user = @usersToRedeem.first()

    prepaid = @prepaids.find((prepaid) -> prepaid.get('properties').endDate? and prepaid.openSpots())
    prepaid = @prepaids.find((prepaid) -> prepaid.openSpots()) unless prepaid
    $.ajax({
      method: 'POST'
      url: _.result(prepaid, 'url') + '/redeemers'
      data: { userID: user.id }
      context: @
      success: ->
        @usersToRedeem.remove(user)
        @renderSelectors '#fixed-area'
        @redeemUsers()
      error: (jqxhr, textStatus, errorThrown) ->
        if jqxhr.status is 402
          @state = 'error'
          @stateMessage = arguments[2]
        else
          @state = 'error'
          @stateMessage = "#{jqxhr.status}: #{jqxhr.responseText}"
        @renderSelectors '#fixed-area'
    })

  addMemberships: ->
    if not @membershipAdditions.size()
      @renderSelectors '#fixed-area'
      document.location.reload()
      return

    membershipAddition = @membershipAdditions.first()
    courseInstance = membershipAddition.get('courseInstance')
    userID = membershipAddition.get('userID')
    $.ajax({
      method: 'POST'
      url: _.result(courseInstance, 'url') + '/members'
      data: { userID: userID }
      context: @
      success: ->
        @membershipAdditions.remove(membershipAddition)
        @renderSelectors '#fixed-area'
        @addMemberships()
      error: (jqxhr, textStatus, errorThrown) ->
        if jqxhr.status is 402
          @state = 'error'
          @stateMessage = arguments[2]
        else
          @state = 'error'
          @stateMessage = "#{jqxhr.status}: #{jqxhr.responseText}"
        @renderSelectors '#fixed-area'
    })

  onClickManageTabLink: ->
    @$('.nav-tabs a[href="#manage-tab-pane"]').tab('show')
