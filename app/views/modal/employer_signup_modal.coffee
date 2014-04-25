View = require 'views/kinds/ModalView'
template = require 'templates/modal/employer_signup_modal'
forms = require('lib/forms')
User = require 'models/User'
auth = require('lib/auth')
me = auth.me

module.exports = class EmployerSignupView extends View
  id: "employer-signup"
  template: template
  closeButton: true

  
  subscriptions:
    "server-error": "onServerError"
    "created-user-without-reload": "linkedInAuth"
    
  events:
    "click #contract-agreement-button": "agreeToContract"
    
  
  constructor: (options) ->
    super(options)
    @authorizedWithLinkedIn = IN?.User?.isAuthorized()
    #TODO: If IN.User.logout is called after authorizing, then the modal is reopened
    # and the user reauths, there will be a javascript error due to the 
    # contract callback context not finding @render
    #window.tracker?.trackEvent 'Started Employer Signup'
    @reloadWhenClosed = false
    window.contractCallback = =>  
      @authorizedWithLinkedIn = IN?.User?.isAuthorized()
      @render()
      
  onServerError: (e) -> # TODO: work error handling into a separate forms system
    @disableModalInProgress(@$el)
  
  afterInsert: ->
    super()
    linkedInButtonParentElement = document.getElementById("linkedInAuthButton")?.parentNode
    if linkedInButtonParentElement
      IN.parse()
      if me.get('anonymous')
        $(".IN-widget").get(0).addEventListener('click', @createAccount, true)
        console.log "Parsed linkedin button element!"
        console.log linkedInButtonParentElement
  
  getRenderData: ->
    context = super()
    context.userIsAuthorized = @authorizedWithLinkedIn
    context.userHasSignedContract = false
    context.userIsAnonymous = context.me.get('anonymous')
    if @authorizedWithLinkedIn
      context.firstName = application.linkedinHandler.linkedInData.firstName
    context
    
  agreeToContract: ->
    application.linkedinHandler.constructEmployerAgreementObject (err, profileData) =>
      if err? then return handleAgreementFailure err
      $.ajax
        url: "/db/user/#{me.id}/agreeToEmployerAgreement"
        data: profileData
        type: "POST"
        success: @handleAgreementSuccess
        error: @handleAgreementFailure
        
  handleAgreementSuccess: (result) ->
    me.fetch()
    window.location.reload()
    
  handleAgreementFailure: (error) ->
    
  createAccount: (e) =>
    console.log "Tried to create account!"
    e.stopPropagation()
    forms.clearFormAlerts(@$el)
    userObject = forms.formToObject @$el
    delete userObject.subscribe
    for key, val of me.attributes when key in ["preferredLanguage", "testGroupNumber", "dateCreated", "wizardColor1", "name", "music", "volume", "emails"]
      userObject[key] ?= val
    subscribe = true
    #TODO: Enable all email subscriptions
    
    userObject.emails ?= {}
    userObject.emails.generalNews ?= {}
    userObject.emails.generalNews.enabled = subscribe
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    window.tracker?.trackEvent 'Finished Signup'
    @enableModalInProgress(@$el)
    auth.createUserWithoutReload userObject, null
    
  linkedInAuth: (e) =>
    console.log "Authorizing with linkedin"
    @listenTo me,"sync", ->
      IN.User.authorize(@recordUserDetails, @)
    me.fetch()
    @reloadWhenClosed = true
    
    
  recordUserDetails: (e) =>
    #TODO: refactor this out
    @render()
    
  destroy: ->
    reloadWhenClosed = @reloadWhenClosed
    super()
    if reloadWhenClosed
      window.location.reload()
    
    

    
 