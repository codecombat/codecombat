ModalView = require 'views/core/ModalView'
ChooseAccountTypeView = require 'views/core/CreateAccountModal/ChooseAccountTypeView'
SegmentCheckView = require 'views/core/CreateAccountModal/SegmentCheckView'
CoppaDenyView = require 'views/core/CreateAccountModal/CoppaDenyView'
BasicInfoView = require 'views/core/CreateAccountModal/BasicInfoView'
SingleSignOnAlreadyExistsView = require 'views/core/CreateAccountModal/SingleSignOnAlreadyExistsView'
SingleSignOnConfirmView = require 'views/core/CreateAccountModal/SingleSignOnConfirmView'
State = require 'models/State'
template = require 'templates/core/create-account-modal/create-account-modal'
forms = require 'core/forms'
User = require 'models/User'
application  = require 'core/application'
# Classroom = require 'models/Classroom'
errors = require 'core/errors'
# COPPADenyModal = require 'views/core/COPPADenyModal'
utils = require 'core/utils'

###
CreateAccountModal is a wizard-style modal with several subviews, one for each
`screen` that the user navigates forward and back through.

There are three `path`s, one for each account type (individual, student).
Teacher account path will be added later; for now it defers to /teachers/signup)
Each subview handles only one `screen`, but all three `path` variants because their logic is largely the same.

They `screen`s are:
  choose-account-type: Sets the `path`.
  segment-check: Checks required info for the path (age, )
    coppa-deny: Seen if the indidual segment-check age is < 13 years old
  basic-info: This is the form for username/password/email/etc.
              It asks for whatever is needed for this type of user.
              It also handles the actual user creation.
              A user may create their account here, or connect with facebook/g+
    sso-confirm: Alternate version of basic-info for new facebook/g+ users
    sso-already-exists: Altername version of basic-info for when facebook/g+
                        user already exists, prompting them to sign in.
  extras: Not yet implemented
  confirmation: Not yet implemented

NOTE: BasicInfoView's two children (SingleSignOn...View) inherit from it.
This allows them to have the same form-handling logic, but different templates.
###

module.exports = class CreateAccountModal extends ModalView
  id: 'create-account-modal'
  template: template

  events:
    'click .back-to-segment-check': -> @state.set { screen: 'segment-check' }

  initialize: (options={}) ->
    classCode = utils.getQueryVariable('_cc', undefined)
    @state = new State {
      path: if classCode then 'student' else null
      screen: if classCode then 'segment-check' else 'choose-account-type'
      facebookEnabled: application.facebookHandler.apiLoaded
      gplusEnabled: application.gplusHandler.apiLoaded
      classCode
      birthday: new Date('') # so that birthday.getTime() is NaN
    }

    @listenTo @state, 'all', @render #TODO: debounce

    @customSubviews = {
      choose_account_type: new ChooseAccountTypeView()
      segment_check: new SegmentCheckView({ sharedState: @state })
      coppa_deny_view: new CoppaDenyView({ sharedState: @state })
      basic_info_view: new BasicInfoView({ sharedState: @state })
      sso_already_exists: new SingleSignOnAlreadyExistsView({ sharedState: @state })
      sso_confirm: new SingleSignOnConfirmView({ sharedState: @state })
    }

    @listenTo @customSubviews.choose_account_type, 'choose-path', (path) ->
      if path is 'teacher'
        application.router.navigate('/teachers/signup', trigger: true)
      else
        @state.set { path, screen: 'segment-check' }
    @listenTo @customSubviews.segment_check, 'choose-path', (path) ->
      @state.set { path, screen: 'segment-check' }
    @listenTo @customSubviews.segment_check, 'nav-back', ->
      @state.set { path: null, screen: 'choose-account-type' }
    @listenTo @customSubviews.segment_check, 'nav-forward', (screen) ->
      @state.set { screen: screen or 'basic-info' }

    @listenTo @customSubviews.basic_info_view, 'sso-connect:already-in-use', ->
      @state.set { screen: 'sso-already-exists' }
    @listenTo @customSubviews.basic_info_view, 'sso-connect:new-user', ->
      @state.set { screen: 'sso-confirm' }
    @listenTo @customSubviews.basic_info_view, 'nav-back', ->
      @state.set { screen: 'segment-check' }

    @listenTo @customSubviews.sso_confirm, 'nav-back', ->
      @state.set { screen: 'basic-info' }

    @listenTo @customSubviews.sso_already_exists, 'nav-back', ->
      @state.set { screen: 'basic-info' }

  #   options.initialValues ?= {}
  #   options.initialValues?.classCode ?= utils.getQueryVariable('_cc', "")
  #   @previousFormInputs = options.initialValues or {}

    # TODO: Switch to promises and state, rather than using defer to hackily enable buttons after render
    
    application.facebookHandler.loadAPI({ success: => @state.set { facebookEnabled: true } unless @destroyed })
    application.gplusHandler.loadAPI({ success: => @state.set { gplusEnabled: true } unless @destroyed })
  
  afterRender: ->
    # @$el.html(@template(@getRenderData()))
    for key, subview of @customSubviews
      subview.setElement(@$('#' + subview.id))
      subview.render()

  # afterRender: =>
  #   super()
  #   @$('input:visible:first').focus()

  #
  # afterInsert: ->
  #   super()
  #   _.delay (=> $('input:visible:first', @$el).focus()), 500
  
  
  # User creation
  
  # signupClassroomPrecheck: ->
  #   classroom = new Classroom()
  #   classroom.fetch({ data: { code: @classCode } })
  #   classroom.once 'sync', @createUser, @
  #   classroom.once 'error', @onClassroomFetchError, @
  #
  # onClassroomFetchError: ->
  #   @$('#signup-button').text($.i18n.t('signup.sign_up')).attr('disabled', false)
  #   forms.setErrorToProperty(@$el, 'classCode', "#{@classCode} is not a valid code. Please verify the code is typed correctly.")
  #   @$('#class-code-input').val('')
  
  #
  # # Google Plus
  #
  # onClickGPlusSignupButton: ->
  #   btn = @$('#gplus-signup-btn')
  #   application.gplusHandler.connect({
  #     context: @
  #     success: ->
  #       btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'))
  #       btn.attr('disabled', true)
  #       application.gplusHandler.loadPerson({
  #         context: @
  #         success: (@gplusAttrs) ->
  #           existingUser = new User()
  #           existingUser.fetchGPlusUser(@gplusAttrs.gplusID, {
  #             context: @
  #             complete: ->
  #               @$('#email-password-row').remove()
  #             success: =>
  #               @$('#gplus-account-exists-row').removeClass('hide')
  #             error: (user, jqxhr) =>
  #               if jqxhr.status is 404
  #                 @$('#gplus-logged-in-row').toggleClass('hide')
  #               else
  #                 errors.showNotyNetworkError(jqxhr)
  #           })
  #       })
  #   })
  #
  # onClickGPlusLoginButton: ->
  #   me.loginGPlusUser(@gplusAttrs.gplusID, {
  #     context: @
  #     success: -> window.location.reload()
  #     error: ->
  #       @$('#gplus-login-btn').text($.i18n.t('login.log_in')).attr('disabled', false)
  #       errors.showNotyNetworkError(arguments...)
  #   })
  #   @$('#gplus-login-btn').text($.i18n.t('login.logging_in')).attr('disabled', true)
  #
  #
  #
  # # Facebook
  #
  # onClickFacebookSignupButton: ->
  #   btn = @$('#facebook-signup-btn')
  #   application.facebookHandler.connect({
  #     context: @
  #     success: ->
  #       btn.find('.sign-in-blurb').text($.i18n.t('signup.creating'))
  #       btn.attr('disabled', true)
  #       application.facebookHandler.loadPerson({
  #         context: @
  #         success: (@facebookAttrs) ->
  #           existingUser = new User()
  #           existingUser.fetchFacebookUser(@facebookAttrs.facebookID, {
  #             context: @
  #             complete: ->
  #               @$('#email-password-row').remove()
  #             success: =>
  #               @$('#facebook-account-exists-row').removeClass('hide')
  #             error: (user, jqxhr) =>
  #               if jqxhr.status is 404
  #                 @$('#facebook-logged-in-row').toggleClass('hide')
  #               else
  #                 errors.showNotyNetworkError(jqxhr)
  #           })
  #       })
  #   })
  #
  # onClickFacebookLoginButton: ->
  #   me.loginFacebookUser(@facebookAttrs.facebookID, {
  #     context: @
  #     success: -> window.location.reload()
  #     error: =>
  #       @$('#facebook-login-btn').text($.i18n.t('login.log_in')).attr('disabled', false)
  #       errors.showNotyNetworkError(jqxhr)
  #   })
  #   @$('#facebook-login-btn').text($.i18n.t('login.logging_in')).attr('disabled', true)
  #
  #
  # # Misc
  #
  # onHidden: ->
  #   super()
  #   @playSound 'game-menu-close'


  # onClickSwitchToLoginButton: ->
  #   AuthModal = require('./AuthModal')
  #   modal = new AuthModal({initialValues: forms.formToObject @$el})
  #   currentView.openModalView(modal)
