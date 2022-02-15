require('app/styles/courses/activate-licenses-modal.sass')
ModalView = require 'views/core/ModalView'
State = require 'models/State'
template = require 'templates/courses/activate-licenses-modal'
CocoCollection = require 'collections/CocoCollection'
Prepaids = require 'collections/Prepaids'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
User = require 'models/User'
Users = require 'collections/Users'

module.exports = class ActivateLicensesModal extends ModalView
  id: 'activate-licenses-modal'
  template: template

  events:
    'change input[type="checkbox"][name="user"]': 'updateSelectedStudents'
    'change .select-all-users-checkbox': 'toggleSelectAllStudents'
    'change select.classroom-select': 'replaceStudentList'
    'submit form': 'onSubmitForm'
    'click #get-more-licenses-btn': 'onClickGetMoreLicensesButton'
    'click #selectPrepaidType .radio': 'onSelectPrepaidType'

  getInitialState: (options) ->
    selectedUsers = options.selectedUsers or options.users
    selectedUserModels = _.filter(selectedUsers.models, (user) -> not user.isEnrolled())
    {
      selectedUsers: new Users(selectedUserModels)
      visibleSelectedUsers: new Users(selectedUserModels)
      error: null
    }

  initialize: (options) ->
    @state = new State(@getInitialState(options))
    @classroom = options.classroom
    @users = options.users.clone()
    @users.comparator = (user) -> user.broadName().toLowerCase()
    @prepaids = new Prepaids()
    @fetchPrepaids()
    @classrooms = new Classrooms()
    @selectedPrepaidType = null
    @prepaidByGroup = {}
    @supermodel.trackRequest @classrooms.fetchMine({
      data: {archived: false}
      success: =>
        @classrooms.each (classroom) =>
          classroom.users = new Users()
          jqxhrs = classroom.users.fetchForClassroom(classroom, { removeDeleted: true })
          @supermodel.trackRequests(jqxhrs)
      })

    @listenTo @state, 'change', ->
      @renderSelectors('#submit-form-area')
    @listenTo @state.get('selectedUsers'), 'change add remove reset', ->
      @updateVisibleSelectedUsers()
      @renderSelectors('#submit-form-area')
    @listenTo @users, 'change add remove reset', ->
      @updateVisibleSelectedUsers()
      @render()
    @listenTo @prepaids, 'sync add remove reset', ->
        @prepaidByGroup = {}
        @prepaids.each (prepaid) =>
          type = prepaid.typeDescriptionWithTime()
          @prepaidByGroup[type] = @prepaidByGroup?[type] || 0
          @prepaidByGroup[type] += (prepaid.get('maxRedeemers') || 0) - (_.size(prepaid.get('redeemers')) || 0)

  onLoaded: ->
    @prepaids.reset(@prepaids.filter((prepaid) -> prepaid.status() is 'available'))
    @selectedPrepaidType = Object.keys(@prepaidByGroup)[0]
    super()

  afterRender: ->
    super()
    # @updateSelectedStudents() # TODO: refactor to event/state style

  fetchPrepaids: ->
    @prepaids.comparator = 'endDate' # use prepaids in order of expiration
    @supermodel.trackRequest @prepaids.fetchForClassroom(@classroom)

  updateSelectedStudents: (e) ->
    userID = $(e.currentTarget).data('user-id')
    user = @users.get(userID)
    if @state.get('selectedUsers').findWhere({ _id: user.id })
      @state.get('selectedUsers').remove(user.id)
    else
      @state.get('selectedUsers').add(user)
    @$(".select-all-users-checkbox").prop('checked', @areAllSelected())
    # @render() # TODO: Have @state automatically listen to children's change events?

  enrolledUsers: ->
    @users.filter((user) -> user.isEnrolled())

  unenrolledUsers: ->
    @users.filter((user) -> not user.isEnrolled())

  areAllSelected: ->
    return _.all(@unenrolledUsers(), (user) => @state.get('selectedUsers').get(user.id))

  toggleSelectAllStudents: (e) ->
    if @areAllSelected()
      @unenrolledUsers().forEach (user, index) =>
        if @state.get('selectedUsers').findWhere({ _id: user.id })
          @$("[type='checkbox'][data-user-id='#{user.id}']").prop('checked', false)
          @state.get('selectedUsers').remove(user.id)
    else
      @unenrolledUsers().forEach (user, index) =>
        if not @state.get('selectedUsers').findWhere({ _id: user.id })
          @$("[type='checkbox'][data-user-id='#{user.id}']").prop('checked', true)
          @state.get('selectedUsers').add(user)

  replaceStudentList: (e) ->
    selectedClassroomID = $(e.currentTarget).val()
    @classroom = @classrooms.get(selectedClassroomID)
    if not @classroom
      users = _.uniq _.flatten @classrooms.map (classroom) -> classroom.users.models
      @users.reset(users)
      @users.sort()
    else
      @users.reset(@classrooms.get(selectedClassroomID).users.models)
    @render()
    null

  onSubmitForm: (e) ->
    e.preventDefault()
    @state.set error: null
    usersToRedeem = @state.get('visibleSelectedUsers')
    @redeemUsers(usersToRedeem)

  updateVisibleSelectedUsers: ->
    @state.set { visibleSelectedUsers: new Users(@state.get('selectedUsers').filter (u) => @users.get(u)) }

  redeemUsers: (usersToRedeem) ->
    if not usersToRedeem.size()
      @finishRedeemUsers()
      @hide()
      return

    user = usersToRedeem.first()
    prepaid = @prepaids.find((prepaid) => prepaid.status() is 'available' and prepaid.typeDescriptionWithTime() == @selectedPrepaidType)
    options = {
      success: (prepaid) =>
        user.set('coursePrepaid', prepaid.pick('_id', 'startDate', 'endDate', 'type', 'includedCourseIDs'))
        usersToRedeem.remove(user)
        @state.get('selectedUsers').remove(user)
        @updateVisibleSelectedUsers()
        # pct = 100 * (usersToRedeem.originalSize - usersToRedeem.size() / usersToRedeem.originalSize)
        # @$('#progress-area .progress-bar').css('width', "#{pct.toFixed(1)}%")
        application.tracker?.trackEvent 'Enroll modal finished enroll student', category: 'Courses', userID: user.id
        @redeemUsers(usersToRedeem)
      error: (prepaid, jqxhr) =>
        @state.set { error: jqxhr.responseJSON.message }
    }
    if !@classroom.isOwner() and @classroom.hasWritePermission()
      options.data = { sharedClassroomId: @classroom.id }
    prepaid.redeem(user, options)

  finishRedeemUsers: ->
    @trigger 'redeem-users', @state.get('selectedUsers')

  onSelectPrepaidType: (e) ->
    @selectedPrepaidType = $(e.target).parent().children('input').val()
    @state.set {
      unusedEnrollments: @prepaidByGroup[@selectedPrepaidType]
    }
    @renderSelectors("#license-type-select")

  onClickGetMoreLicensesButton: ->
    @hide?() # In case this is opened in /teachers/licenses itself, otherwise the button does nothing
