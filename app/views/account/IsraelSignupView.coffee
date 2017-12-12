RootView = require 'views/core/RootView'
template = require 'templates/account/israel-signup-view'
forms = require 'core/forms'
errors = require 'core/errors'
utils = require 'core/utils'
User = require 'models/User'
State = require 'models/State'
api = require 'core/api'

class AbortError extends Error

formSchema =
  type: 'object'
  properties: _.pick(User.schema.properties, 'name', 'password')
  required: ['name', 'password']


module.exports = class IsraelSignupView extends RootView
  id: 'israel-signup-view'
  template: template

  events:
    'submit form': 'onSubmitForm'
    'input input[name="name"]': 'onChangeName'
    'input input[name="password"]': 'onChangePassword'

  initialize: ->
    @state = new State({
      fatalError: null
      # Possible errors:
      #   'signed-in': They are logged in
      #   'missing-input': Required query parameters are not provided
      #   'email-exists': Given email exists in our system
      #   Any other string will be shown directly to user

      formError: null
      loading: true
      submitting: false
      queryParams: _.pick(utils.getQueryVariables(),
        'israelId'
        'firstName'
        'lastName'
        'email'
        'school'
        'city'
        'state'
        'district'
        'usertype'
        'token'
      )
      name: ''
      password: ''
    })

    { israelId, token, email } = @state.get('queryParams')
    israelToken = token

    # sanity checks
    if not me.isAnonymous()
      @state.set({fatalError: 'signed-in', loading: false})

    else if not (israelId or israelToken)
      @state.set({fatalError: 'missing-input', loading: false})

    else if email and not forms.validateEmail(email)
      @state.set({fatalError: 'invalid-email', loading: false})

    else
      api.users.getByIsraelIdOrToken({israelId, israelToken})
      .then (user) =>
        if user and not user.anonymous
          return api.auth.loginByIsraelIdOrToken({israelId, israelToken})
          .then =>
            @redirectAfterAuth()
        else if token
          Promise.resolve()
          .then =>
            @signUpWithToken()
        else
          Promise.resolve()
          .then =>
            if email
              return User.checkEmailExists(email)
              .then ({exists}) =>
                if exists
                  @state.set({fatalError: 'email-exists'})
          .then =>
            @state.set({loading: false})
      .catch (e) =>
        console.log('Error:', e)
        @state.set({fatalError: $.i18n.t('loading_error.unknown'), loading: false})

    @listenTo(@state, 'change', _.debounce(@render))

  getRenderData: ->
    c = super()
    return _.extend({}, @state.attributes, c)

  onChangeName: (e) ->
    # sync form info with state, but do not re-render
    @state.set({name: $(e.currentTarget).val()}, {silent: true})

  onChangePassword: (e) ->
    @state.set({password: $(e.currentTarget).val()}, {silent: true})

  displayFormSubmitting: ->
    @$('#create-account-btn').text($.i18n.t('signup.creating')).attr('disabled', true)
    @$('input').attr('disabled', true)

  displayFormStandingBy: ->
    @$('#create-account-btn').text($.i18n.t('login.sign_up')).attr('disabled', false)
    @$('input').attr('disabled', false)

  redirectAfterAuth: ->
    url = '/play'
    url = '/students' if me.isStudent()

    # NOTE: creating the CourseInstance for CS1 is dependent on this redirect.
    # If this is changed, will need to update classroom creation to make sure it still happens.
    url = '/teachers/classes' if me.isTeacher()

    application.router.navigate(url)
    document.location.reload()

  signUpWithToken: ->
    israelToken = @state.get('queryParams').token
    api.users.putIsraelIdOrToken({
      userId: me.id,
      israelToken: israelToken
    })
    .then =>
      return me.signupWithIsraelToken(israelToken)
    .then =>
      @redirectAfterAuth()
    .catch (e) =>
      @displayFormStandingBy()
      console.error 'IsraelSignupView form submission Promise error:', e
      @state.set('formError', e.responseJSON?.message or e.message or 'Unknown Error')

  onSubmitForm: (e) ->

    # validate form with schema
    e.preventDefault()
    forms.clearFormAlerts(@$el)
    @state.set('formError', null)
    data = forms.formToObject(e.currentTarget)
    res = tv4.validateMultiple data, formSchema
    if not res.valid
      forms.applyErrorsToForm(@$('form'), res.errors)
      return

    # check for name conflicts
    queryParams = @state.get('queryParams')
    @displayFormSubmitting()
    User.checkNameConflicts(data.name)
    .then ({ suggestedName, conflicts }) =>
      nameField = @$('input[name="name"]')
      if conflicts
        suggestedNameText = $.i18n.t('signup.name_taken').replace('{{suggestedName}}', suggestedName)
        forms.setErrorToField(nameField, suggestedNameText)
        throw AbortError

      # Save new user settings, particularly properties handed in
      school = _.pick(queryParams, 'state', 'city', 'district')
      school.name = queryParams.school if queryParams.school
      me.set(_.pick(queryParams, 'firstName', 'lastName'))
      me.set('role', 'teacher') if queryParams.usertype is 'T'
      me.set('role', 'student') if queryParams.usertype is 'S'
      me.set({school})
      return me.save()

    .then =>
      return api.users.putIsraelIdOrToken({
        userId: me.id,
        israelId: queryParams.israelId,
        israelToken: queryParams.token
      })

    .then =>
      # sign up
      return me.signupWithPassword(
        @state.get('name'),
        queryParams.email or '',
        @state.get('password')
      )

    .then =>
      if me.isTeacher()
        return api.classrooms.post({
          name: me.broadName()
          aceConfig: { language: 'python' }
        })
        .then(api.prepaids.postForIsraelPilot())


    .then =>
      @redirectAfterAuth()

    .catch (e) =>
      # if we threw the AbortError, the error was handled
      @displayFormStandingBy()
      if e is AbortError
        return
      else
        # Otherwise, show a generic error
        console.error 'IsraelSignupView form submission Promise error:', e
        @state.set('formError', e.responseJSON?.message or e.message or 'Unknown Error')
