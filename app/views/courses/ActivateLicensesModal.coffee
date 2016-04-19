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
    'change select.classroom-select': 'replaceStudentList'
    'submit form': 'onSubmitForm'

  getInitialState: (options) ->
    selectedUserModels = _.filter(options.selectedUsers.models, (user) -> not user.isEnrolled())
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
    @prepaids.comparator = '_id'
    @prepaids.fetchByCreator(me.id)
    @supermodel.trackCollection(@prepaids)
    @classrooms = new Classrooms()
    @classrooms.fetchMine({
      data: {archived: false}
      success: =>
        @classrooms.each (classroom) =>
          classroom.users = new Users()
          jqxhrs = classroom.users.fetchForClassroom(classroom, { removeDeleted: true })
          @supermodel.trackRequests(jqxhrs)
      })
    @supermodel.trackCollection(@classrooms)
    
    @listenTo @state, 'change', @render
    @listenTo @state.get('selectedUsers'), 'change add remove reset', ->
      @state.set { visibleSelectedUsers: new Users(@state.get('selectedUsers').filter (u) => @users.get(u)) }
      @render()
    @listenTo @users, 'change add remove reset', ->
      @state.set { visibleSelectedUsers: new Users(@state.get('selectedUsers').filter (u) => @users.get(u)) }
      @render()
    @listenTo @prepaids, 'sync add remove', ->
      @state.set {
        unusedEnrollments: @prepaids.totalMaxRedeemers() - @prepaids.totalRedeemers()
      }
  
  afterRender: ->
    super()
    # @updateSelectedStudents() # TODO: refactor to event/state style

  updateSelectedStudents: (e) ->
    userID = $(e.currentTarget).data('user-id')
    user = @users.get(userID)
    if @state.get('selectedUsers').contains(user)
      @state.get('selectedUsers').remove(user)
    else
      @state.get('selectedUsers').add(user)
    # @render() # TODO: Have @state automatically listen to children's change events?
  
  replaceStudentList: (e) ->
    selectedClassroomID = $(e.currentTarget).val()
    @classroom = @classrooms.get(selectedClassroomID)
    if selectedClassroomID is 'all-students'
      @classroom = new Classroom({ _id: 'all-students', name: 'All Students' }) # TODO: This is a horrible hack so the select shows the right option!
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

  redeemUsers: (usersToRedeem) ->
    if not usersToRedeem.size()
      @finishRedeemUsers()
      @hide()
      return

    user = usersToRedeem.first()
    prepaid = @prepaids.find((prepaid) -> prepaid.get('properties')?.endDate? and prepaid.openSpots() > 0)
    prepaid = @prepaids.find((prepaid) -> prepaid.openSpots() > 0) unless prepaid
    $.ajax({
      method: 'POST'
      url: _.result(prepaid, 'url') + '/redeemers'
      data: { userID: user.id }
      context: @
      success: (prepaid) ->
        user.set('coursePrepaidID', prepaid._id)
        usersToRedeem.remove(user)
        # pct = 100 * (usersToRedeem.originalSize - usersToRedeem.size() / usersToRedeem.originalSize)
        # @$('#progress-area .progress-bar').css('width', "#{pct.toFixed(1)}%")
        application.tracker?.trackEvent 'Enroll modal finished enroll student', category: 'Courses', userID: user.id
        @redeemUsers(usersToRedeem)
      error: (jqxhr, textStatus, errorThrown) ->
        if jqxhr.status is 402
          message = arguments[2]
        else
          message = "#{jqxhr.status}: #{jqxhr.responseText}"
        @state.set { error: message } # TODO: Test this! ("should" never happen. Only on server responding with an error.)
    })

  finishRedeemUsers: ->
    @trigger 'redeem-users', @state.get('selectedUsers')
