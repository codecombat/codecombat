ModalView = require 'views/core/ModalView'
AuthModal = require 'views/core/AuthModal'
ChooseAccountTypeView = require './ChooseAccountTypeView'
SegmentCheckView = require './SegmentCheckView'
CoppaDenyView = require './CoppaDenyView'
BasicInfoView = require './BasicInfoView'
SingleSignOnAlreadyExistsView = require './SingleSignOnAlreadyExistsView'
SingleSignOnConfirmView = require './SingleSignOnConfirmView'
ConfirmationView = require './ConfirmationView'
State = require 'models/State'
template = require 'templates/core/create-account-modal/create-account-modal'
forms = require 'core/forms'
User = require 'models/User'
application  = require 'core/application'
errors = require 'core/errors'
utils = require 'core/utils'

###
CreateAccountModal is a wizard-style modal with several subviews, one for each
`screen` that the user navigates forward and back through.

There are three `path`s, one for each account type (individual, student).
Teacher account path will be added later; for now it defers to /teachers/signup)
Each subview handles only one `screen`, but all three `path` variants because
their logic is largely the same.

They `screen`s are:
  choose-account-type: Sets the `path`.
  segment-check: Checks required info for the path (age, )
    coppa-deny: Seen if the indidual segment-check age is < 13 years old
  basic-info: This is the form for username/password/email/etc.
              It asks for whatever is needed for this type of user.
              It also handles the actual user creation.
              A user may create their account here, or connect with facebook/g+
    sso-confirm: Alternate version of basic-info for new facebook/g+ users
  sso-already-exists: When facebook/g+ user already exists, this prompts them to sign in.
  extras: Not yet implemented
  confirmation: When an account has been successfully created, this view shows them their info and
    links them to a landing page based on their account type.

NOTE: BasicInfoView's two children (SingleSignOn...View) inherit from it.
This allows them to have the same form-handling logic, but different templates.
###

module.exports = class CreateAccountModal extends ModalView
  id: 'create-account-modal'
  template: template
  closesOnClickOutside: false
  retainSubviews: true

  events:
    'click .login-link': 'onClickLoginLink'

  initialize: (options={}) ->
    classCode = utils.getQueryVariable('_cc', undefined)
    @signupState = new State {
      path: if classCode then 'student' else null
      screen: if classCode then 'segment-check' else 'choose-account-type'
      ssoUsed: null # or 'facebook', 'gplus'
      classroom: null # or Classroom instance
      facebookEnabled: application.facebookHandler.apiLoaded
      gplusEnabled: application.gplusHandler.apiLoaded
      classCode
      birthday: new Date('') # so that birthday.getTime() is NaN
      authModalInitialValues: {}
    }
    
    { startOnPath } = options
    if startOnPath is 'student'
      @signupState.set({ path: 'student', screen: 'segment-check' })
    if startOnPath is 'individual'
      @signupState.set({ path: 'individual', screen: 'segment-check' })

    @listenTo @signupState, 'all', _.debounce @render

    @listenTo @insertSubView(new ChooseAccountTypeView()),
      'choose-path': (path) ->
        if path is 'teacher'
          application.router.navigate('/teachers/signup', trigger: true)
        else
          @signupState.set { path, screen: 'segment-check' }

    @listenTo @insertSubView(new SegmentCheckView({ @signupState })),
      'choose-path': (path) -> @signupState.set { path, screen: 'segment-check' }
      'nav-back': -> @signupState.set { path: null, screen: 'choose-account-type' }
      'nav-forward': (screen) -> @signupState.set { screen: screen or 'basic-info' }

    @listenTo @insertSubView(new CoppaDenyView({ @signupState })),
      'nav-back': -> @signupState.set { screen: 'segment-check' }

    @listenTo @insertSubView(new BasicInfoView({ @signupState })),
      'sso-connect:already-in-use': -> @signupState.set { screen: 'sso-already-exists' }
      'sso-connect:new-user': -> @signupState.set {screen: 'sso-confirm'}
      'nav-back': -> @signupState.set { screen: 'segment-check' }
      'signup': -> @signupState.set { screen: 'confirmation' }

    @listenTo @insertSubView(new SingleSignOnAlreadyExistsView({ @signupState })),
      'nav-back': -> @signupState.set { screen: 'basic-info' }

    @listenTo @insertSubView(new SingleSignOnConfirmView({ @signupState })),
      'nav-back': -> @signupState.set { screen: 'basic-info' }
      'signup': -> @signupState.set { screen: 'confirmation' }
        
    @insertSubView(new ConfirmationView({ @signupState }))

    # TODO: Switch to promises and state, rather than using defer to hackily enable buttons after render
    application.facebookHandler.loadAPI({ success: => @signupState.set { facebookEnabled: true } unless @destroyed })
    application.gplusHandler.loadAPI({ success: => @signupState.set { gplusEnabled: true } unless @destroyed })
    
    @once 'hidden', ->
      if @signupState.get('screen') is 'confirmation' and not application.testing
        # ensure logged in state propagates through the entire app
        document.location.reload()
  
  onClickLoginLink: ->
    @openModalView(new AuthModal({ initialValues: @signupState.get('authModalInitialValues') }))
