ModalView = require 'views/core/ModalView'
template = require 'templates/courses/student-sign-up-modal'
auth = require 'core/auth'
forms = require 'core/forms'
User = require 'models/User'
Classroom = require 'models/Classroom'
utils = require 'core/utils'

module.exports = class StudentSignUpModal extends ModalView
  id: 'student-sign-up-modal'
  template: template

  events:
    'click #sign-up-btn': 'onClickSignUpButton'
    'submit form': 'onSubmitForm'
    'click #skip-link': 'onClickSkipLink'

  initialize: (options) ->
    options ?= {}
    @willPlay = options.willPlay
    @classCode = utils.getQueryVariable('_cc') or ''

  afterInsert: ->
    super()
    _.delay (=> @$('input:visible:first').focus()), 500

  onClickSkipLink: ->
    @trigger 'click-skip-link' # defer to view that opened this modal
    @hide?()

  onSubmitForm: (e) ->
    e.preventDefault()
    @signupClassroomPrecheck()

  onClickSignUpButton: ->
    @signupClassroomPrecheck()

  emailCheck: ->
    email = @$('#email').val()
    filter = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,63}$/i  # https://news.ycombinator.com/item?id=5763990
    unless filter.test(email)
      @$('#errors-alert').text($.i18n.t('share_progress_modal.email_invalid')).removeClass('hide')
      return false
    return true

  signupClassroomPrecheck: ->
    if not _.all([@$('#email').val(), @$('#password').val(), @$('#name').val()])
      @$('#errors-alert').text('Enter email, username and password').removeClass('hide')
      return
    classCode = @$('#class-code-input').val()
    if not classCode
      return @signup()
    classroom = new Classroom()
    classroom.fetch({ url: '/db/classroom?code='+classCode })
    classroom.once 'sync', @signup, @
    classroom.once 'error', @onClassroomFetchError, @
    @enableModalInProgress(@$el)

  onClassroomFetchError: ->
    @disableModalInProgress(@$el)
    @$('#errors-alert').text('Classroom code could not be found').removeClass('hide')

  signup: ->
    return unless @emailCheck()
    # TODO: consolidate with AuthModal logic, or make user creation process less magical, more RESTful
    data = forms.formToObject @$el
    delete data.classCode
    for key, val of me.attributes when key in ['preferredLanguage', 'testGroupNumber', 'dateCreated', 'wizardColor1', 'name', 'music', 'volume', 'emails', 'schoolName']
      data[key] ?= val
    Backbone.Mediator.publish "auth:signed-up", {}
    data.emails ?= {}
    data.emails.generalNews ?= {}
    data.emails.generalNews.enabled = false
    # TODO: Doesn't handle failed user creation.  Double posts when placed in onCreateUserSuccess.
    window.tracker?.trackEvent 'Finished Student Signup', category: 'Courses', label: 'Courses Student Signup'
    @enableModalInProgress(@$el)
    user = new User(data)
    user.notyErrors = false
    user.save({}, {
      validate: false # make server deal with everything
      error: @onCreateUserError
      success: @onCreateUserSuccess
    })

  onCreateUserError: (model, jqxhr) =>
    # really need to make our server errors uniform
    if jqxhr.responseJSON
      error = jqxhr.responseJSON
      error = error[0] if _.isArray(error)
      message = _.filter([error.property, error.message]).join(' ')
    else
      message =  jqxhr.responseText
    @disableModalInProgress(@$el)
    @$('#errors-alert').text(message).removeClass('hide')

  onCreateUserSuccess: =>
    classCode = @$('#class-code-input').val()
    if classCode
      url = "/courses?_cc="+classCode
      application.router.navigate(url)
    window.location.reload()
