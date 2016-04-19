ModalView = require 'views/core/ModalView'
template = require 'templates/courses/activate-licenses-modal'
CocoCollection = require 'collections/CocoCollection'
Prepaids = require 'collections/Prepaids'
Classrooms = require 'collections/Classrooms'
User = require 'models/User'
Users = require 'collections/Users'

module.exports = class ActivateLicensesModal extends ModalView
  id: 'activate-licenses-modal'
  template: template

  events:
    'change input': 'updateSelectionSpans'
    'change select': 'replaceStudentList'
    'submit form': 'onSubmitForm'

  initialize: (options) ->
    @classroom = options.classroom
    @users = options.users
    @selectedUsers = options.selectedUsers
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
  
  afterRender: ->
    super()
    @updateSelectionSpans()

  updateSelectionSpans: ->
    targets = @$('input[name="targets"]:checked').val()
    if targets is 'given'
      numToActivate = 1
    else
      numToActivate = @$('input[name="user"]:checked:not(:disabled)').length
    @$('#total-selected-span').text(numToActivate)
    remaining = @prepaids.totalMaxRedeemers() - @prepaids.totalRedeemers() - numToActivate
    depleted = remaining < 0
    @$('.not-enough-enrollments').toggleClass('visible', depleted)
    @$('#activate-licenses-btn').toggleClass('disabled', depleted).toggleClass('btn-success', not depleted).toggleClass('btn-default', depleted)
    
  replaceStudentList: (e) ->
    selectedClassroomID = $(e.currentTarget).val()
    @classroom = @classrooms.get(selectedClassroomID)
    if selectedClassroomID == 'all-classrooms'
      @classroom = new Classroom({ id: 'all-students' }) # TODO: This is a horrible hack so the select shows the right option!
      users = _.uniq _.flatten @classrooms.map (classroom) -> classroom.users.models
      @users.reset(users)
    else
      @users.reset(@classrooms.get(selectedClassroomID).users.models)
    @trigger('users:change')
    @render()
    null

  showProgress: ->
    @$('#submit-form-area').addClass('hide')
    @$('#progress-area').removeClass('hide')

  hideProgress: ->
    @$('#submit-form-area').removeClass('hide')
    @$('#progress-area').addClass('hide')

  onSubmitForm: (e) ->
    e.preventDefault()
    @$('#error-alert').addClass('hide')
    @usersToRedeem = new CocoCollection([], {model: User})
    targets = @$('input[name="targets"]:checked').val()
    if targets is 'given'
      @usersToRedeem.add(@user)
    else
      checkedBoxes = @$('input[name="user"]:checked:not(:disabled)')
      _.each checkedBoxes, (el) =>
        $el = $(el)
        userID = $el.data('user-id')
        @usersToRedeem.add @users.get(userID)
    return unless @usersToRedeem.size()
    @usersToRedeem.originalSize = @usersToRedeem.size()
    @showProgress()
    @redeemUsers()

  redeemUsers: ->
    if not @usersToRedeem.size()
      @finishRedeemUsers()
      return

    user = @usersToRedeem.first()
    prepaid = @prepaids.find((prepaid) -> prepaid.get('properties')?.endDate? and prepaid.openSpots() > 0)
    prepaid = @prepaids.find((prepaid) -> prepaid.openSpots() > 0) unless prepaid
    $.ajax({
      method: 'POST'
      url: _.result(prepaid, 'url') + '/redeemers'
      data: { userID: user.id }
      context: @
      success: ->
        @usersToRedeem.remove(user)
        pct = 100 * (@usersToRedeem.originalSize - @usersToRedeem.size() / @usersToRedeem.originalSize)
        @$('#progress-area .progress-bar').css('width', "#{pct.toFixed(1)}%")
        application.tracker?.trackEvent 'Enroll modal finished enroll student', category: 'Courses', userID: user.id
        @redeemUsers()
      error: (jqxhr, textStatus, errorThrown) ->
        if jqxhr.status is 402
          message = arguments[2]
        else
          message = "#{jqxhr.status}: #{jqxhr.responseText}"
        @$('#error-alert').text(message).removeClass('hide')
    })

  finishRedeemUsers: ->
    @trigger 'redeem-users'
