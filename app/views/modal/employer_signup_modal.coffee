View = require 'views/kinds/ModalView'
template = require 'templates/modal/employer_signup_modal'

module.exports = class EmployerSignupView extends View
  id: "employer-signup"
  template: template
  closeButton: true
  
  subscriptions: 
    'employer-linkedin-auth': 'showContractScreen'
  
  constructor: (options) ->
    super(options)
    @authorizedWithLinkedIn = IN?.User?.isAuthorized()
    window.contractCallback = ->  window.Backbone.Mediator.publish("employer-linkedin-auth")
  
  afterInsert: ->
    super()
    unless @authorizedWithLinkedIn
      linkedInButtonParentElement = document.getElementById("linkedInAuthButton").parentNode
      IN.parse(linkedInButtonParentElement) if linkedInButtonParentElement
  
  showContractScreen: =>
    @render()
  getRenderData: ->
    context = super()
    context.userIsAuthorized = @authorizedWithLinkedIn
    if @authorizedWithLinkedIn
      context.firstName = application.linkedinHandler.linkedInData.firstName
    context
 