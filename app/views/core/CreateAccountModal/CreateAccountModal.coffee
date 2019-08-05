require('app/styles/modal/create-account-modal/create-account-modal.sass')
ModalView = require 'views/core/ModalView'
AuthModal = require 'views/core/AuthModal'
ChooseAccountTypeView = require './ChooseAccountTypeView'
SegmentCheckView = require './SegmentCheckView'
CoppaDenyView = require './CoppaDenyView'
EUConfirmationView = require './EUConfirmationView'
BasicInfoView = require './BasicInfoView'
SingleSignOnAlreadyExistsView = require './SingleSignOnAlreadyExistsView'
SingleSignOnConfirmView = require './SingleSignOnConfirmView'
ExtrasView = require './ExtrasView'
ConfirmationView = require './ConfirmationView'
TeacherSignupComponent = require './teacher/TeacherSignupComponent'
TeacherSignupStoreModule = require './teacher/TeacherSignupStoreModule'
State = require 'models/State'
template = require 'templates/core/create-account-modal/create-account-modal'
forms = require 'core/forms'
User = require 'models/User'
errors = require 'core/errors'
utils = require 'core/utils'
store = require('core/store')
storage = require 'core/storage'

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

# "Teacher signup started" event for reaching the Create Teacher form.
startSignupTracking = ->
  properties =
    category: 'Homepage'
    user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
  window.tracker?.trackEvent(
    'Teacher signup started',
    properties)

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
      facebookEnabled: application.facebookHandler?.apiLoaded
      gplusEnabled: application.gplusHandler?.apiLoaded
      classCode
      birthday: new Date('') # so that birthday.getTime() is NaN
      authModalInitialValues: {}
      accountCreated: false
      signupForm: {
        subscribe: ['on'] # checked by default
        email: options.email ? ''
      }
      subModalContinue: options.subModalContinue
      wantInSchool: false
    }

    { startOnPath } = options
    switch startOnPath
      when 'student' then @signupState.set({ path: 'student', screen: 'segment-check' })
      when 'individual' then @signupState.set({ path: 'individual', screen: 'segment-check' })
      when 'teacher'
        startSignupTracking()
        @signupState.set({ path: 'teacher', screen: if @euConfirmationRequiredInCountry() then 'eu-confirmation' else 'basic-info' })
      else
        if /^\/play/.test(location.pathname) and me.showIndividualRegister()
          @signupState.set({ path: 'individual', screen: 'segment-check' })
    if @signupState.get('screen') is 'segment-check' and not @signupState.get('path') is 'student' and not @segmentCheckRequiredInCountry()
      @signupState.set screen: 'basic-info'

    @listenTo @signupState, 'all', _.debounce @render

    @listenTo @insertSubView(new ChooseAccountTypeView()),
      'choose-path': (path) ->
        if path is 'teacher'
          startSignupTracking()
          window.tracker?.trackEvent 'Teachers Create Account Loaded', category: 'Teachers' # This is a legacy event name
          @signupState.set { path, screen: if @euConfirmationRequiredInCountry() then 'eu-confirmation' else 'basic-info' }
        else
          if path is 'student'
            window.tracker?.trackEvent 'CreateAccountModal Student Path Clicked', category: 'Students'
          if path is 'individual'
            window.tracker?.trackEvent 'CreateAccountModal Individual Path Clicked', category: 'Individuals'
          @signupState.set { path, screen: 'segment-check' }

    @listenTo @insertSubView(new SegmentCheckView({ @signupState })),
      'choose-path': (path) -> @signupState.set { path, screen: 'segment-check' }
      'nav-back': -> @signupState.set { path: null, screen: 'choose-account-type' }
      'nav-forward': (screen) -> @signupState.set { screen: screen or 'basic-info' }

    @listenTo @insertSubView(new CoppaDenyView({ @signupState })),
      'nav-back': -> @signupState.set { screen: 'segment-check' }

    @listenTo @insertSubView(new EUConfirmationView({ @signupState })),
      'nav-back': ->
        if @signupState.get('path') is 'teacher'
          @signupState.set { path: null, screen: 'choose-account-type' }
        else
          @signupState.set { screen: 'segment-check' }
      'nav-forward': (screen) -> @signupState.set { screen: screen or 'basic-info' }

    @listenTo @insertSubView(new BasicInfoView({ @signupState })),
      'sso-connect:already-in-use': -> @signupState.set { screen: 'sso-already-exists' }
      'sso-connect:new-user': -> @signupState.set {screen: 'sso-confirm'}
      'nav-back': ->
        if @euConfirmationRequiredInCountry()
          @signupState.set { screen: 'eu-confirmation' }
        else if @signupState.get('path') is 'teacher'
          @signupState.set { screen: 'choose-account-type' }
        else
          @signupState.set { screen: 'segment-check' }
      'signup': ->
        if @signupState.get('path') is 'student'
          if me.skipHeroSelectOnStudentSignUp()
            @signupState.set { screen: 'confirmation', accountCreated: true }
          else
            @signupState.set { screen: 'extras', accountCreated: true }
        else if @signupState.get('path') is 'teacher'
          store.commit('modal/updateSso', _.pick(@signupState.attributes, 'ssoUsed', 'ssoAttrs'))
          store.commit('modal/updateSignupForm', @signupState.get('signupForm'))
          store.commit('modal/updateTrialRequestProperties', _.pick(@signupState.get('signupForm'), 'firstName', 'lastName'))
          @signupState.set { screen: 'teacher-signup-component' }
        else if @signupState.get('subModalContinue')
          storage.save('sub-modal-continue', @signupState.get('subModalContinue'))
          window.location.reload()
        else
          @signupState.set { screen: 'confirmation', accountCreated: true }

    @listenTo @insertSubView(new SingleSignOnAlreadyExistsView({ @signupState })),
      'nav-back': -> @signupState.set { screen: 'basic-info' }

    @listenTo @insertSubView(new SingleSignOnConfirmView({ @signupState })),
      'nav-back': -> @signupState.set { screen: 'basic-info' }
      'signup': ->
        if @signupState.get('path') is 'student'
          if me.skipHeroSelectOnStudentSignUp()
            @signupState.set { screen: 'confirmation', accountCreated: true }
          else
            @signupState.set { screen: 'extras', accountCreated: true }
        else if @signupState.get('path') is 'teacher'
          store.commit('modal/updateSso', _.pick(@signupState.attributes, 'ssoUsed', 'ssoAttrs'))
          store.commit('modal/updateSignupForm', @signupState.get('signupForm'))
          @signupState.set { screen: 'teacher-signup-component' }
        else if @signupState.get('subModalContinue')
          storage.save('sub-modal-continue', @signupState.get('subModalContinue'))
          window.location.reload()
        else
          @signupState.set { screen: 'confirmation', accountCreated: true }

    @listenTo @insertSubView(new ExtrasView({ @signupState })),
      'nav-forward': -> @signupState.set { screen: 'confirmation' }

    @insertSubView(new ConfirmationView({ @signupState }))

    if me.useSocialSignOn()
      # TODO: Switch to promises and state, rather than using defer to hackily enable buttons after render
      application.facebookHandler.loadAPI({ success: => @signupState.set { facebookEnabled: true } unless @destroyed })
      application.gplusHandler.loadAPI({ success: => @signupState.set { gplusEnabled: true } unless @destroyed })

    @once 'hidden', ->
      if @signupState.get('accountCreated') and not application.testing
        # ensure logged in state propagates through the entire app
        if me.isStudent()
          application.router.navigate('/students', {trigger: true})
        else if me.isTeacher()
          application.router.navigate('/teachers/classes', {trigger: true})
        window.location.reload()

    store.registerModule('modal', TeacherSignupStoreModule)

  afterRender: ->
    target = @$el.find('#teacher-signup-component')
    return unless target[0]
    if @teacherSignupComponent
      target.replaceWith(@teacherSignupComponent.$el)
    else
      @teacherSignupComponent = new TeacherSignupComponent({
        el: target[0]
        store
      })
      @teacherSignupComponent.$on 'back', =>
        if @signupState.get('ssoUsed')
          @signupState.set {ssoUsed: undefined, ssoAttrs: undefined}
        @signupState.set('screen', 'basic-info')

  destroy: ->
    if @teacherSignupComponent
      @teacherSignupComponent.$destroy()
    try
      store.unregisterModule('modal')

  onClickLoginLink: ->
    properties =
      category: 'Homepage'
      subview: @signupState.get('path') || "choosetype"
    window.tracker?.trackEvent('Log in from CreateAccount', properties)
    @openModalView(new AuthModal({ initialValues: @signupState.get('authModalInitialValues'), subModalContinue: @signupState.get('subModalContinue') }))

  segmentCheckRequiredInCountry: ->
    return true unless me.get('country')
    return true if me.inEU() or me.get('country') in ['united-states', 'israel']
    return false

  euConfirmationRequiredInCountry: ->
    return me.get('country') and me.inEU()
