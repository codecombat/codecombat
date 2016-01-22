ModalView = require 'views/core/ModalView'
template = require 'templates/courses/activate-licenses-modal'
CocoCollection = require 'collections/CocoCollection'
Prepaids = require 'collections/Prepaids'
User = require 'models/User'

module.exports = class ActivateLicensesModal extends ModalView
  id: 'activate-licenses-modal'
  template: template

  events:
    'change input': 'updateSelectionSpans'
    'submit form': 'onSubmitForm'

  initialize: (options) ->
    @classroom = options.classroom
    @users = options.users
    @user = options.user
    @prepaids = new Prepaids()
    @prepaids.comparator = '_id'
    @prepaids.fetchByCreator(me.id)
    @supermodel.loadCollection(@prepaids, 'prepaids')

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
    @$('#licenses-remaining-span').text(remaining)
    depleted = remaining < 0
    @$('#not-depleted-span').toggleClass('hide', depleted)
    @$('#depleted-span').toggleClass('hide', !depleted)
    @$('#activate-licenses-btn').toggleClass('disabled', depleted).toggleClass('btn-success', not depleted).toggleClass('btn-default', depleted)

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
    prepaid = @prepaids.find((prepaid) -> prepaid.get('properties')?.endDate? and prepaid.openSpots())
    prepaid = @prepaids.find((prepaid) -> prepaid.openSpots()) unless prepaid
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
