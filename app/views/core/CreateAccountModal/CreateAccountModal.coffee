ModalView = require 'views/core/ModalView'
ChooseAccountTypeView = require 'views/core/CreateAccountModal/ChooseAccountTypeView'
SegmentCheckView = require 'views/core/CreateAccountModal/SegmentCheckView'
CoppaDenyView = require 'views/core/CreateAccountModal/CoppaDenyView'
BasicInfoView = require 'views/core/CreateAccountModal/BasicInfoView'
SingleSignOnAlreadyExistsView = require 'views/core/CreateAccountModal/SingleSignOnAlreadyExistsView'
State = require 'models/State'
template = require 'templates/core/create-account-modal/create-account-modal'
forms = require 'core/forms'
User = require 'models/User'
application  = require 'core/application'
# Classroom = require 'models/Classroom'
errors = require 'core/errors'
# COPPADenyModal = require 'views/core/COPPADenyModal'
utils = require 'core/utils'


module.exports = class CreateAccountModal extends ModalView
  id: 'create-account-modal'
  template: template

  events:
    # 'click .teacher-path-button': -> @state.set { path: 'teacher', screen: 'segment-check' }
    # 'click .student-path-button': -> @state.set { path: 'student', screen: 'segment-check' }
    # 'click .individual-path-button': -> @state.set { path: 'individual', screen: 'segment-check' }
    # 'click .back-to-account-type': -> @state.set { path: null, screen: 'choose-account-type' }
    'click .back-to-segment-check': -> @state.set { screen: 'segment-check' }
    # 'input .class-code-input': (e) ->
    #   classCode = $(e.currentTarget).val()
    #   @checkClassCode(classCode)
    #   @state.set { classCode }, { silent: true }
    # 'input .birthday-form-group': ->
    #   { birthdayYear, birthdayMonth, birthdayDay } = forms.formToObject(@$('form'))
    #   birthday = new Date Date.UTC(birthdayYear, birthdayMonth - 1, birthdayDay)
    #   @state.set { birthdayYear, birthdayMonth, birthdayDay, birthday }, { silent: true }
    # 'submit form.segment-check': (e) ->
    #   e.preventDefault()
    #   if @state.get('path') is 'student'
    #     @state.set { screen: 'basic-info' } if @state.get('segmentCheckValid')
    #   else if @state.get('path') is 'individual'
    #     if isNaN(@state.get('birthday').getTime())
    #       forms.setErrorToProperty @$el, 'birthdayDay', 'Required'
    #     else
    #       age = (new Date().getTime() - @state.get('birthday').getTime()) / 365.4 / 24 / 60 / 60 / 1000
    #     if age > 13
    #       @state.set { screen: 'basic-info' }
    #     else
    #       @state.set { screen: 'coppa-deny' }
        
    # 'input form.basic-info': (e) ->
    #   data = forms.formToObject(e.currentTarget)
    #   @checkBasicInfo(data)

  #   'submit form': 'onSubmitForm'
    # 'input input[name="name"]': 'onNameChange'
  #   'click #gplus-signup-btn': 'onClickGPlusSignupButton'
  #   'click #gplus-login-btn': 'onClickGPlusLoginButton'
  #   'click #facebook-signup-btn': 'onClickFacebookSignupButton'
  #   'click #facebook-login-btn': 'onClickFacebookLoginButton'
  #   'click #close-modal': 'hide'
  #   'click #switch-to-login-btn': 'onClickSwitchToLoginButton'

  # Initialization

  initialize: (options={}) ->
    @state = new State {
      # path: null
      # screen: 'choose-account-type' # segment-check, basic-info, (extras), confirmation, coppa-deny
      path: 'individual' # TODO: Remove!
      screen: 'basic-info' # TODO: Remove!
      segmentCheckValid: false
      basicInfoValid: false
      facebookEnabled: application.facebookHandler.apiLoaded
      gplusEnabled: application.gplusHandler.apiLoaded
    }
    
    # @classroom = new Classroom()

    @listenTo @state, 'all', @render #TODO: debounce
    # @listenTo @classroom, 'all', @render #TODO: debounce

    # @onNameChange = _.debounce(_.bind(@checkNameExists, @), 500)
    
    @customSubviews = {
      choose_account_type: new ChooseAccountTypeView()
      segment_check: new SegmentCheckView({ sharedState: @state })
      coppa_deny_view: new CoppaDenyView({ sharedState: @state })
      basic_info_view: new BasicInfoView({ sharedState: @state })
      sso_already_exists: new SingleSignOnAlreadyExistsView({ sharedState: @state })
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
