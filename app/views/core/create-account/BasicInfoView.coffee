ModalView = require 'views/core/ModalView'
AuthModal = require 'views/core/AuthModal'
template = require 'templates/core/create-account-modal/basic-info-view'
forms = require 'core/forms'
User = require 'models/User'

module.exports = class BasicInfoView extends ModalView
  id: 'basic-info-view'
  template: template

  events:
    'input input[name="name"]': 'onNameChange'
    'click .back-to-account-type': -> @trigger 'nav-back'
    'submit form#basic-info-form': (e) ->
      e.preventDefault()
      console.log "Submitting..."
      data = forms.formToObject(e.currentTarget)
      valid = @checkBasicInfo(data)
      if valid
        @onSubmitForm(e)
    'click .login-link': ->
      @openModalView(new AuthModal())
    'click .use-suggested-name-link': (e) ->
      @$('input[name="name"]').val(@suggestedName)
      forms.clearFormAlerts(@$el.find('input[name="name"]').closest('.row'))

  initialize: ({ @sharedState } = {}) ->
    @onNameChange = _.debounce(_.bind(@checkNameExists, @), 500)

  checkNameExists: ->
    name = $('input[name="name"]', @$el).val()
    console.log 'Checking name: ', name
    return forms.clearFormAlerts(@$el) if name is ''
    jqxhr = User.getUnconflictedName name, (newName) =>
      forms.clearFormAlerts(@$el)
      if name is newName
        @suggestedName = undefined
        return true
      else
        console.log "Suggesting name: #{newName}"
        @suggestedName = newName
        forms.setErrorToProperty @$el, 'name', "Username already taken!<br>Try <a class='use-suggested-name-link'>#{newName}</a>?" # TODO: Translate!
        return false
    jqxhr.then (val) -> return val

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
      required: ['email', 'name', 'password'].concat (if @sharedState.get('path') is 'student' then ['firstName', 'lastName'] else [])
    }
    forms.clearFormAlerts(@$('form'))
    res = tv4.validateMultiple data, formSchema
    console.log res.errors
    forms.applyErrorsToForm(@$('form'), res.errors) unless res.valid
    return res.valid and @checkNameExists()

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
    if @sharedState.get('birthday')
      attrs.birthday = @sharedState.get('birthday').toISOString()
  
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
    @createUser()

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
  
  onUserSaveError: (user, jqxhr) ->
    @$('#signup-button').text($.i18n.t('signup.sign_up')).attr('disabled', false)
    if _.isObject(jqxhr.responseJSON) and jqxhr.responseJSON.property
      error = jqxhr.responseJSON
      if jqxhr.status is 409 and error.property is 'name'
        @newUser.unset 'name'
        return @createUser()
      return forms.applyErrorsToForm(@$el, [jqxhr.responseJSON])
    errors.showNotyNetworkError(jqxhr)
  
  onUserCreated: ->
    Backbone.Mediator.publish "auth:signed-up", {}
    if @gplusAttrs
      window.tracker?.trackEvent 'Google Login', category: "Signup", label: 'GPlus'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'GPlus'
    else if @facebookAttrs
      window.tracker?.trackEvent 'Facebook Login', category: "Signup", label: 'Facebook'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'Facebook'
    else
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'CodeCombat'
    if @sharedState.get('classCode')
      url = "/courses?_cc="+@state.get('classCode')
      location.href = url
    else
      window.location.reload()
  
