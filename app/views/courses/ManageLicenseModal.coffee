require('app/styles/courses/manage-license-modal.sass')
ModalView = require 'views/core/ModalView'
State = require 'models/State'
template = require 'templates/courses/manage-licenses-modal'
CocoCollection = require 'collections/CocoCollection'
Prepaids = require 'collections/Prepaids'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
User = require 'models/User'
Users = require 'collections/Users'

module.exports = class ManageLicenseModal extends ModalView
  id: 'manage-license-modal'
  template: template

  events:
    'change input[type="checkbox"][name="user"]': 'updateSelectedStudents'
    'change .select-all-users-checkbox': 'toggleSelectAllStudents'
    'change select.classroom-select': 'replaceStudentList'
    'submit form': 'onSubmitForm'
    'click #get-more-licenses-btn': 'onClickGetMoreLicensesButton'
    'click #selectPrepaidType .radio': 'onSelectPrepaidType'
    'click .change-tab': 'onChangeTab'
    'click #selectUser .radio': 'onSelectUser'
    'click .revoke-student-button': 'onClickRevokeStudentButton'

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
    @prepaids.comparator = 'endDate' # use prepaids in order of expiration
    @supermodel.trackRequest @prepaids.fetchMineAndShared()
    @classrooms = new Classrooms()
    @selectedPrepaidType = null
    @selectedUser = null
    @prepaidByGroup = {}
    @teacherPrepaidIds = []
    @activeTab = 'apply'
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
          @teacherPrepaidIds.push(prepaid.get('_id'))
          type = prepaid.typeDescriptionWithTime()
          @prepaidByGroup[type] = @prepaidByGroup?[type] || {num: 0, prepaid}
          @prepaidByGroup[type].num += (prepaid.get('maxRedeemers') || 0) - (_.size(prepaid.get('redeemers')) || 0)

  onLoaded: ->
    @prepaids.reset(@prepaids.filter((prepaid) -> prepaid.status() is 'available'))
    @selectedPrepaidType = Object.keys(@prepaidByGroup)[0]
    if(@users.length)
       @selectedUser = @users.models[0].id
    super()
  
  afterRender: ->
    super()
    # @updateSelectedStudents() # TODO: refactor to event/state style

  updateSelectedStudents: (e) ->
    userID = $(e.currentTarget).data('user-id')
    user = @users.get(userID)
    if @state.get('selectedUsers').findWhere({ _id: user.id })
      @state.get('selectedUsers').remove(user.id)
    else
      @state.get('selectedUsers').add(user)
    @$(".select-all-users-checkbox").prop('checked', @areAllSelected())
    # @render() # TODO: Have @state automatically listen to children's change events?

  studentsPrepaidsFromTeacher: () ->
    user = @users.get(@selectedUser)
    return user.get('products').filter((p) =>
      p.product == 'course' && _.contains @teacherPrepaidIds, p.productId
    )

  enrolledUsers: ->
    prepaid = @prepaidByGroup[@selectedPrepaidType]?.prepaid
    return [] unless prepaid
    @users.filter((user) ->
      p = prepaid.numericalCourses()
      s = p & user.prepaidNumericalCourses()
      not (p ^ s)
    )

  unenrolledUsers: ->
    prepaid = @prepaidByGroup[@selectedPrepaidType]?.prepaid
    return [] unless prepaid
    @users.filter((user) ->
      p = prepaid.numericalCourses()
      s = p & user.prepaidNumericalCourses()
      p ^ s
    )

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
    prepaid.redeem(user, {
      success: (prepaid) =>
        user.set('products', user.get('products').concat(prepaid.convertToProduct()))
        usersToRedeem.remove(user)
        @state.get('selectedUsers').remove(user)
        @updateVisibleSelectedUsers()
        # pct = 100 * (usersToRedeem.originalSize - usersToRedeem.size() / usersToRedeem.originalSize)
        # @$('#progress-area .progress-bar').css('width', "#{pct.toFixed(1)}%")
        application.tracker?.trackEvent 'Enroll modal finished enroll student', category: 'Courses', userID: user.id
        @redeemUsers(usersToRedeem)
      error: (prepaid, jqxhr) =>
        @state.set { error: jqxhr.responseJSON.message }
    })

  finishRedeemUsers: ->
    @trigger 'redeem-users', @state.get('selectedUsers')

  onSelectPrepaidType: (e) ->
    @selectedPrepaidType = $(e.target).parent().children('input').val()
    @state.set {
      unusedEnrollments: @prepaidByGroup[@selectedPrepaidType].num
    }
    @renderSelectors("#license-type-select")

  onClickGetMoreLicensesButton: ->
    @hide?() # In case this is opened in /teachers/licenses itself, otherwise the button does nothing

  onSelectUser: (e) -> 
    @selectedUser= $(e.target).parent().children('input').val()
    @renderSelectors("#student-licenses")


  onChangeTab: (e) ->
    @activeTab = $(e.target).data('tab')
    @renderSelectors('.modal-body-content')
    @renderSelectors('#tab-nav')

  onClickRevokeStudentButton: (e) ->
    button = $(e.currentTarget)
    prepaidId = button.data('prepaid-id')
    user = @students.get(@selectedUser)
    s = $.i18n.t('teacher.revoke_confirm').replace('{{student_name}}', user.broadName())
    return unless confirm(s)
    #product TODO
    prepaid = user.makeCourseProduct(prepaidId)
    button.text($.i18n.t('teacher.revoking'))
    prepaid.revoke(user, {
      success: =>
        user.unset('coursePrepaid')
      error: (prepaid, jqxhr) =>
        msg = jqxhr.responseJSON.message
        noty text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000
      complete: => @debouncedRender()
    })


