RootView = require 'views/core/RootView'
template = require 'templates/teachers-free-trial'
CocoCollection = require 'collections/CocoCollection'
TrialRequest = require 'models/TrialRequest'

# TODO: distinguish between this type of existing trial requests and others

module.exports = class TeachersFreeTrialView extends RootView
  id: 'teachers-free-trial-view'
  template: template
  logoutRedirectURL: false

  events:
    'click .submit-button': 'onClickSubmit'
    'click .input-age-other': 'onClickTextBox'

  constructor: (options) ->
    super options
    @email = me.get('email')
    @refreshData()

  refreshData: ->
    @fetchingData = true
    @existingRequests = new CocoCollection([], { url: '/db/trial.request/-/own', model: TrialRequest, comparator: '_id' })
    @listenToOnce @existingRequests, 'sync', =>
      @fetchingData = false
      @render?()
    @supermodel.loadCollection(@existingRequests, 'own_trial_requests', {cache: false})

  onClickTextBox: (e) ->
    $('.radio-other').prop("checked", true)

  onClickSubmit: (e) ->
    school = $('.input-school').val()
    location = $('.input-location').val()
    age = $('input[name=age]:checked').val()
    age = $('.input-age-other').val() if age is 'other'
    numStudents = $('.input-num-students').val()
    heardAbout = $('.input-heard-about').val()

    # Validate input
    $('.container-email-address').removeClass('has-error')
    $('.container-school').removeClass('has-error')
    $('.container-location').removeClass('has-error')
    $('.container-age').removeClass('has-error')
    $('.container-num-students').removeClass('has-error')
    $('.container-heard-about').removeClass('has-error')
    $('.error-message').hide()
    unless school
      $('.container-school').addClass('has-error')
      $('.error-message').show()
      return
    unless location
      $('.container-location').addClass('has-error')
      $('.error-message').show()
      return
    unless age
      $('.container-age').addClass('has-error')
      $('.error-message').show()
      return
    unless numStudents
      $('.container-num-students').addClass('has-error')
      $('.error-message').show()
      return
    unless heardAbout
      $('.container-heard-about').addClass('has-error')
      $('.error-message').show()
      return

    # Save trial request
    trialRequest = new TrialRequest
      type: 'course'
      properties:
        email: @email
        school: school
        location: location
        age: age
        numStudents: numStudents
        heardAbout: heardAbout
    trialRequest.save {},
      error: (model, response, options) =>
        console.error 'Error saving trial request', response
      success: (model, response, options) =>
        @refreshData()
        window.tracker?.trackEvent 'Submit Trial Request', category: 'Teachers', label: 'Trial Request', ['Mixpanel']
