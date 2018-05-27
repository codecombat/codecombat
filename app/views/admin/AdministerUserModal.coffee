require('app/styles/admin/administer-user-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/admin/administer-user-modal'
User = require 'models/User'
Prepaid = require 'models/Prepaid'
StripeCoupons = require 'collections/StripeCoupons'
forms = require 'core/forms'
Prepaids = require 'collections/Prepaids'
Classrooms = require 'collections/Classrooms'
TrialRequests = require 'collections/TrialRequests'
fetchJson = require('core/api/fetch-json')
api = require 'core/api'

module.exports = class AdministerUserModal extends ModalView
  id: 'administer-user-modal'
  template: template

  events:
    'click #save-changes': 'onClickSaveChanges'
    'click #create-payment-btn': 'onClickCreatePayment'
    'click #add-seats-btn': 'onClickAddSeatsButton'
    'click #destudent-btn': 'onClickDestudentButton'
    'click #deteacher-btn': 'onClickDeteacherButton'
    'click #reset-progress-btn': 'onClickResetProgressButton'
    'click .update-classroom-btn': 'onClickUpdateClassroomButton'
    'click .add-new-courses-btn': 'onClickAddNewCoursesButton'
    'click .user-link': 'onClickUserLink'
    'click #verified-teacher-checkbox': 'onClickVerifiedTeacherCheckbox'

  initialize: (options, @userHandle) ->
    @user = new User({_id:@userHandle})
    @supermodel.trackRequest @user.fetch({cache: false})
    @coupons = new StripeCoupons()
    @supermodel.trackRequest @coupons.fetch({cache: false})
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(@userHandle, { data: {includeShared: true} })
    @listenTo @prepaids, 'sync', =>
      @prepaids.each (prepaid) =>
        if prepaid.loaded and not prepaid.creator
          prepaid.creator = new User()
          @supermodel.trackRequest prepaid.creator.fetchCreatorOfPrepaid(prepaid)
    @classrooms = new Classrooms()
    @supermodel.trackRequest @classrooms.fetchByOwner(@userHandle)
    @trialRequests = new TrialRequests()
    @supermodel.trackRequest @trialRequests.fetchByApplicant(@userHandle)

  onLoaded: ->
    # TODO: Figure out a better way to expose this info, perhaps User methods?
    stripe = @user.get('stripe') or {}
    @free = stripe.free is true
    @freeUntil = _.isString(stripe.free)
    @freeUntilDate = if @freeUntil then stripe.free else new Date().toISOString()[...10]
    @currentCouponID = stripe.couponID
    @none = not (@free or @freeUntil or @coupon)
    @trialRequest = @trialRequests.first()
    super()
    
  onClickCreatePayment: ->
    service = @$('#payment-service').val()
    amount = parseInt(@$('#payment-amount').val())
    amount = 0 if isNaN(amount)
    gems = parseInt(@$('#payment-gems').val())
    gems = 0 if isNaN(gems)
    if _.isEmpty(service)
      alert('Service cannot be empty')
      return
    else if amount < 0
      alert('Payment cannot be negative')
      return
    else if gems < 0
      alert('Gems cannot be negative')
      return

    data = {
      purchaser: @user.get('_id')
      recipient: @user.get('_id')
      service: service
      created: new Date().toISOString()
      gems: gems
      amount: amount
      description: @$('#payment-description').val()
    }
    $.post('/db/payment/admin', data, => @hide())

  onClickSaveChanges: ->
    stripe = _.clone(@user.get('stripe') or {})
    delete stripe.free
    delete stripe.couponID
    selection = @$el.find('input[name="stripe-benefit"]:checked').val()
    dateVal = @$el.find('#free-until-date').val()
    couponVal = @$el.find('#coupon-select').val()
    switch selection
      when 'free' then stripe.free = true
      when 'free-until' then stripe.free = dateVal
      when 'coupon' then stripe.couponID = couponVal
    @user.set('stripe', stripe)

    newGems = parseInt(@$('#stripe-add-gems').val())
    newGems = 0 if isNaN(newGems)
    if newGems > 0
      purchased = _.clone(@user.get('purchased') ? {})
      purchased.gems ?= 0
      purchased.gems += newGems
      @user.set('purchased', purchased)

    options = {}
    options.success = => @hide()
    @user.patch(options)

  onClickAddSeatsButton: ->
    attrs = forms.formToObject(@$('#prepaid-form'))
    attrs.maxRedeemers = parseInt(attrs.maxRedeemers)
    return unless _.all(_.values(attrs))
    return unless attrs.maxRedeemers > 0
    return unless attrs.endDate and attrs.startDate and attrs.endDate > attrs.startDate
    attrs.startDate = new Date(attrs.startDate).toISOString()
    attrs.endDate = new Date(attrs.endDate).toISOString()
    _.extend(attrs, {
      type: 'course'
      creator: @user.id
      properties:
        adminAdded: me.id
    })
    prepaid = new Prepaid(attrs)
    prepaid.save()
    @state = 'creating-prepaid'
    @renderSelectors('#prepaid-form')
    @listenTo prepaid, 'sync', ->
      @state = 'made-prepaid'
      @renderSelectors('#prepaid-form')

  onClickDestudentButton: (e) ->
    button = @$(e.currentTarget)
    button.attr('disabled', true).text('...')
    Promise.resolve(@user.destudent())
    .then =>
      button.remove()
    .catch (e) =>
      button.attr('disabled', false).text('Destudent')
      noty {
        text: e.message or e.responseJSON?.message or e.responseText or 'Unknown Error'
        type: 'error'
      }
      if e.stack
        throw e

  onClickDeteacherButton: (e) ->
    button = @$(e.currentTarget)
    button.attr('disabled', true).text('...')
    Promise.resolve(@user.deteacher())
    .then =>
      button.remove()
    .catch (e) =>
      button.attr('disabled', false).text('Destudent')
      noty {
        text: e.message or e.responseJSON?.message or e.responseText or 'Unknown Error'
        type: 'error'
      }
      if e.stack
        throw e

  onClickResetProgressButton: ->
    if confirm("Really RESET this person's progress?")
      api.users.resetProgress({ userID: @user.id})

  onClickUpdateClassroomButton: (e) ->
    classroom = @classrooms.get(@$(e.currentTarget).data('classroom-id'))
    if confirm("Really update #{classroom.get('name')}?")
      Promise.resolve(classroom.updateCourses())
      .then =>
        noty({text: 'Updated classroom courses.'})
        @renderSelectors('#classroom-table')
      .catch ->
        noty({text: 'Failed to update classroom courses.', type: 'error'})

  onClickAddNewCoursesButton: (e) ->
    classroom = @classrooms.get(@$(e.currentTarget).data('classroom-id'))
    if confirm("Really update #{classroom.get('name')}?")
      Promise.resolve(classroom.updateCourses({data: {addNewCoursesOnly: true}}))
      .then =>
        noty({text: 'Updated classroom courses.'})
        @renderSelectors('#classroom-table')
      .catch ->
        noty({text: 'Failed to update classroom courses.', type: 'error'})

  onClickUserLink: (e) ->
    userID = @$(e.target).data('user-id')
    @openModalView new AdministerUserModal({}, userID) if userID

  userIsVerifiedTeacher: () ->
    @user.get('verifiedTeacher')

  onClickVerifiedTeacherCheckbox: (e) ->
    checked = @$(e.target).prop('checked')
    @userSaveState = 'saving'
    @render()
    fetchJson("/db/user/#{@user.id}/verifiedTeacher", {
      method: 'PUT',
      json: checked
    }).then (res) =>
      @userSaveState = 'saved'
      @user.set('verifiedTeacher', res.verifiedTeacher)
      @render()
      setTimeout((()=>
        @userSaveState = null
        @render()
      ), 2000)
    null
