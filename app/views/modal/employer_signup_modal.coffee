View = require 'views/kinds/ModalView'
template = require 'templates/modal/employer_signup_modal'
forms = require 'lib/forms'
User = require 'models/User'
auth = require 'lib/auth'
me = auth.me

module.exports = class EmployerSignupView extends View
  id: 'employer-signup'
  template: template
  closeButton: true

  subscriptions:
    'server-error': 'onServerError'
    'linkedin-loaded': 'onLinkedInLoaded'
    'created-user-without-reload': 'createdAccount'

  events:
    'click #contract-agreement-button': 'agreeToContract'
    'click #create-account-button': 'createAccount'
    'click #more-info-button': 'submitMoreInfoEmail'
    'click .login-link': 'setHashToOpenModalAutomatically'
    'keydown': 'checkForFormSubmissionEnterPress'

  constructor: (options) ->
    super(options)
    @authorizedWithLinkedIn = IN?.User?.isAuthorized()
    window.tracker?.trackEvent 'Started Employer Signup'
    @reloadWhenClosed = false
    @linkedinLoaded = Boolean(IN.parse)
    @waitingForLinkedIn = false
    @sentMoreInfoEmail = false
    window.contractCallback = =>
      @authorizedWithLinkedIn = IN?.User?.isAuthorized()
      @render()

  onLinkedInLoaded: =>
    @linkedinLoaded = true
    if @waitingForLinkedIn
      @renderLinkedInButton()

  renderLinkedInButton: =>
    IN.parse()

  onServerError: (e) ->
    @disableModalInProgress(@$el)

  afterInsert: ->
    super()
    linkedInButtonParentElement = document.getElementById('linkedInAuthButton')
    if linkedInButtonParentElement
      if @linkedinLoaded
        @renderLinkedInButton()
      else
        @waitingForLinkedIn = true

  getRenderData: ->
    context = super()
    context.userIsAuthorized = @authorizedWithLinkedIn
    context.userHasSignedContract = 'employer' in me.get('permissions')
    context.userIsAnonymous = context.me.get('anonymous')
    context.sentMoreInfoEmail = @sentMoreInfoEmail
    context

  agreeToContract: ->
    application.linkedinHandler.constructEmployerAgreementObject (err, profileData) =>
      if err? then return handleAgreementFailure err
      $.ajax
        url: "/db/user/#{me.id}/agreeToEmployerAgreement"
        data: profileData
        type: 'POST'
        success: @handleAgreementSuccess
        error: @handleAgreementFailure

  handleAgreementSuccess: (result) ->
    window.tracker?.trackEvent 'Employer Agreed to Contract'
    me.fetch()
    window.location.reload()

  handleAgreementFailure: (error) ->
    alert "There was an error signing the contract. Please contact team@codecombat.com with this error: #{error.responseText}"

  checkForFormSubmissionEnterPress: (e) ->
    if e.which is 13
      if $('#signup-email').val() isnt '' and $('#signup-password').val() isnt ''
        @createAccount(e)
      else if $('#more-info-email').val() isnt ''
        @submitMoreInfoEmail e

  createAccount: (e) =>
    window.tracker?.trackEvent 'Finished Employer Signup'
    el = $('#signup-form')
    e.stopPropagation()
    forms.clearFormAlerts(el)
    userObject = forms.formToObject el
    delete userObject.subscribe
    for key, val of me.attributes when key in ['preferredLanguage', 'testGroupNumber', 'dateCreated', 'wizardColor1', 'name', 'music', 'volume', 'emails']
      userObject[key] ?= val
    userObject.emails ?= {}
    userObject.emails.employerNotes = {enabled: true}
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(el, res.errors) unless res.valid
    @enableModalInProgress(el)
    auth.createUserWithoutReload userObject, null

  submitMoreInfoEmail: (e) =>
    emailAddress = $('#more-info-email').val()
    window.tracker?.trackEvent 'Employer requested more information.'
    successFunc = =>
      @sentMoreInfoEmail = true
      @render()
    errorFunc = =>
      alert('Something went wrong! Please contact team@codecombat.com for more information and inform them of this error.')
    $.ajax
      type: 'POST'
      url: '/contact'
      data:
        email: emailAddress
        message: "THIS IS AN AUTOMATED MESSAGE FROM THE EMPLOYER SIGNUP FORM \n Please send me more info about hiring CodeCombat players."
      success: successFunc
      error: errorFunc
    $.post '/stacklead', email: emailAddress

  setHashToOpenModalAutomatically: (e) ->
    window.location.hash = 'employerSignupLoggingIn'

  createdAccount: ->
    @reloadWhenClosed = true
    @listenTo me, 'sync', =>
      @render()
      IN.parse()
    me.fetch()

  destroy: ->
    reloadWhenClosed = @reloadWhenClosed
    super()
    if reloadWhenClosed
      window.location.reload()
