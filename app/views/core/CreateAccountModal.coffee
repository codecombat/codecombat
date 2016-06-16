ModalView = require 'views/core/ModalView'
State = require 'models/State'
template = require 'templates/core/create-account-modal'
forms = require 'core/forms'
User = require 'models/User'
application  = require 'core/application'
Classroom = require 'models/Classroom'
errors = require 'core/errors'
# COPPADenyModal = require 'views/core/COPPADenyModal'
utils = require 'core/utils'


module.exports = class CreateAccountModal extends ModalView
  id: 'create-account-modal'
  template: template

  events:
    'click .teacher-path-button': -> @state.set { path: 'teacher', screen: 'segment-check' }
    'click .student-path-button': -> @state.set { path: 'student', screen: 'segment-check' }
    'click .individual-path-button': -> @state.set { path: 'individual', screen: 'segment-check' }
    'input .class-code-input': (e) ->
      classCode = $(e.currentTarget).val()
      @checkClassCode(classCode)
      @state.set { classCode }, { silent: true }
    'submit form.segment-check': (e) ->
      e.preventDefault()
      debugger
      @state.set { screen: 'basic-info' } if @state.get('segmentCheckValid')
    'submit form#basic-info-form': (e) ->
      e.preventDefault()
      console.log "Submitting..."
      data = forms.formToObject(e.currentTarget)
      valid = @checkBasicInfo(data)
      if valid
        @onSubmitForm(e)
    # 'input form.basic-info': (e) ->
    #   data = forms.formToObject(e.currentTarget)
    #   @checkBasicInfo(data)

  #   'submit form': 'onSubmitForm'
    'input input[name="name"]': 'onNameChange'
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
      # screen: 'choose-account-type' # segment-check, basic-info, (extras), confirmation
      path: 'student'
      screen: 'basic-info'
      segmentCheckValid: false
      basicInfoValid: false
    }
    
    @classroom = new Classroom()

    @listenTo @state, 'all', @render #TODO: debounce
    @listenTo @classroom, 'all', @render #TODO: debounce

    @onNameChange = _.debounce(_.bind(@checkNameExists, @), 500)
  #   options.initialValues ?= {}
  #   options.initialValues?.classCode ?= utils.getQueryVariable('_cc', "")
  #   @previousFormInputs = options.initialValues or {}
  #
  #   # TODO: Switch to promises and state, rather than using defer to hackily enable buttons after render
  #   application.gplusHandler.loadAPI({ success: => _.defer => @$('#gplus-signup-btn').attr('disabled', false) })
  #   application.facebookHandler.loadAPI({ success: => _.defer => @$('#facebook-signup-btn').attr('disabled', false) })
  #

  checkClassCode: _.debounce((classCode) ->
    @classroom.fetchByCode(classCode)
    @classroom.once 'sync', => @state.set { classCodeValid: true, segmentCheckValid: true }
    @classroom.once 'error', => @state.set { classCodeValid: false, segmentCheckValid: false }
  , 1000)
  
  checkBasicInfo: (data) ->
    # TODO: Move this to somewhere appropriate
    tv4.addFormat({
      'email': (email) ->
        console.log email
        console.log forms.validateEmail(email)
        if forms.validateEmail(email)
          return null
        else
          return {code: tv4.errorCodes.FORMAT_CUSTOM, message: "Please enter a valid email address."}
    })
    
    # TODO: Move this to somewhere appropriate
    formSchema = {
      type: 'object'
      properties: {
        email: User.schema.properties.email
        name: User.schema.properties.name
        password: User.schema.properties.password
      }
      required: ['email', 'name', 'password'].concat (if @state.get('path') is 'student' then ['firstName', 'lastName'] else [])
    }
    forms.clearFormAlerts(@$('form'))
    res = tv4.validateMultiple data, formSchema
    console.log res.errors
    forms.applyErrorsToForm(@$('form'), res.errors) unless res.valid
    return res.valid

  # afterRender: =>
  #   super()
  #   @$('input:visible:first').focus()

  #
  # afterInsert: ->
  #   super()
  #   _.delay (=> $('input:visible:first', @$el).focus()), 500
  
  
  # User creation
  
  onSubmitForm: (e) ->
    e.preventDefault()
    # @playSound 'menu-button-click'
    forms.clearFormAlerts(@$el)
    attrs = forms.formToObject @$el
    attrs.name = @suggestedName if @suggestedName
    _.defaults attrs, me.pick([
      'preferredLanguage', 'testGroupNumber', 'dateCreated', 'wizardColor1',
      'name', 'music', 'volume', 'emails', 'schoolName'
    ])
    attrs.emails ?= {}
    attrs.emails.generalNews ?= {}
    # attrs.emails.generalNews.enabled = @$el.find('#subscribe').prop('checked')
    attrs.emails.generalNews.enabled = (attrs.subscribe[0] is 'on')
    delete attrs.subscribe
    
    # @classCode = attrs.classCode
    # delete attrs.classCode
  
    error = false
    # birthday = new Date Date.UTC attrs.birthdayYear, attrs.birthdayMonth - 1, attrs.birthdayDay
    # if @classCode
    #   attrs.role = 'student'
    # else if isNaN(birthday.getTime())
    #   forms.setErrorToProperty @$el, 'birthdayDay', 'Required'
    #   error = true
    # else
    #   age = (new Date().getTime() - birthday.getTime()) / 365.4 / 24 / 60 / 60 / 1000
    #   attrs.birthday = birthday.toISOString()
  
    # delete attrs.birthdayYear
    # delete attrs.birthdayMonth
    # delete attrs.birthdayDay
  
    _.assign attrs, @gplusAttrs if @gplusAttrs
    _.assign attrs, @facebookAttrs if @facebookAttrs
    res = tv4.validateMultiple attrs, User.schema
  
    if not res.valid
      forms.applyErrorsToForm(@$el, res.errors)
      error = true
    if not _.any([attrs.password, @gplusAttrs, @facebookAttrs])
      forms.setErrorToProperty @$el, 'password', 'Required'
      error = true
    if not forms.validateEmail(attrs.email)
      forms.setErrorToProperty @$el, 'email', 'Please enter a valid email address'
      error = true
    return if error
  
    @$('#signup-button').text($.i18n.t('signup.creating')).attr('disabled', true)
    @newUser = new User(attrs)
    if @state.get('classCode')
      @signupClassroomPrecheck()
    else
      @createUser()
  #
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
  
  createUser: ->
    options = {}
    window.tracker?.identify()
    if @gplusAttrs
      @newUser.set('_id', me.id)
      options.url = "/db/user?gplusID=#{@gplusAttrs.gplusID}&gplusAccessToken=#{application.gplusHandler.accessToken.access_token}"
      options.type = 'PUT'
    if @facebookAttrs
      @newUser.set('_id', me.id)
      options.url = "/db/user?facebookID=#{@facebookAttrs.facebookID}&facebookAccessToken=#{application.facebookHandler.authResponse.accessToken}"
      options.type = 'PUT'
    @newUser.save(null, options)
    @newUser.once 'sync', @onUserCreated, @
    @newUser.once 'error', @onUserSaveError, @
  
  # onUserSaveError: (user, jqxhr) ->
  #   @$('#signup-button').text($.i18n.t('signup.sign_up')).attr('disabled', false)
  #   if _.isObject(jqxhr.responseJSON) and jqxhr.responseJSON.property
  #     error = jqxhr.responseJSON
  #     if jqxhr.status is 409 and error.property is 'name'
  #       @newUser.unset 'name'
  #       return @createUser()
  #     return forms.applyErrorsToForm(@$el, [jqxhr.responseJSON])
  #   errors.showNotyNetworkError(jqxhr)
  #
  # onUserCreated: ->
  #   Backbone.Mediator.publish "auth:signed-up", {}
  #   if @gplusAttrs
  #     window.tracker?.trackEvent 'Google Login', category: "Signup", label: 'GPlus'
  #     window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'GPlus'
  #   else if @facebookAttrs
  #     window.tracker?.trackEvent 'Facebook Login', category: "Signup", label: 'Facebook'
  #     window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'Facebook'
  #   else
  #     window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'CodeCombat'
  #   if @classCode
  #     url = "/courses?_cc="+@classCode
  #     location.href = url
  #   else
  #     window.location.reload()
  #
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
  
  checkNameExists: (name) ->
    console.log 'Checking name: ', name
    name = $('input[name="name"]', @$el).val()
    return forms.clearFormAlerts(@$el) if name is ''
    User.getUnconflictedName name, (newName) =>
      forms.clearFormAlerts(@$el)
      if name is newName
        @suggestedName = undefined
      else
        console.log "Suggesting name: #{newName}"
        @suggestedName = newName
        forms.setErrorToProperty @$el, 'name', "Username already taken!<br>Try #{newName}?"
  
  # onClickSwitchToLoginButton: ->
  #   AuthModal = require('./AuthModal')
  #   modal = new AuthModal({initialValues: forms.formToObject @$el})
  #   currentView.openModalView(modal)
