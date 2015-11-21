ModalView = require 'views/core/ModalView'
template = require 'templates/courses/student-sign-up-modal'
auth = require 'core/auth'
forms = require 'core/forms'
User = require 'models/User'

module.exports = class StudentSignUpModal extends ModalView
  id: 'student-sign-up-modal'
  template: template
  
  events:
    'click #sign-up-btn': 'onClickSignUpButton'
    'submit form': 'onSubmitForm'
    'click #skip-link': 'onClickSkipLink'

  initialize: (options) ->
    options ?= {}

  onClickSkipLink: ->
    @trigger 'click-skip-link' # defer to view that opened this modal
    @hide()

  onSubmitForm: (e) ->
    e.preventDefault()
    @signup()

  onClickSignUpButton: ->
    @signup()

  emailCheck: ->
    email = @$('#email').val()
    filter = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i  # https://news.ycombinator.com/item?id=5763990
    unless filter.test(email)
      @$('#errors-alert').text($.i18n.t('share_progress_modal.email_invalid')).removeClass('hide')
      return false
    return true

  signup: ->
    return unless @emailCheck()
    # TODO: consolidate with AuthModal logic, or make user creation process less magical, more RESTful
    data = forms.formToObject @$el
    classCode = data['class-code']
    delete data['class-code']
    for key, val of me.attributes when key in ['preferredLanguage', 'testGroupNumber', 'dateCreated', 'wizardColor1', 'name', 'music', 'volume', 'emails']
      data[key] ?= val
    Backbone.Mediator.publish "auth:signed-up", {}
    data.emails ?= {}
    data.emails.generalNews ?= {}
    data.emails.generalNews.enabled = false
    window.tracker?.trackEvent 'Finished Student Signup', label: 'CodeCombat'
    @enableModalInProgress(@$el)
    user = new User(data)
    user.notyErrors = false
    user.save({}, {
      validate: false # make server deal with everything
      error: (model, jqxhr) =>
        # really need to make our server errors uniform
        if jqxhr.responseJSON
          error = jqxhr.responseJSON
          error = error[0] if _.isArray(error) 
          message = _.filter([error.property, error.message]).join(' ')
        else
          message =  jqxhr.responseText
        @disableModalInProgress(@$el)
        @$('#errors-alert').text(message).removeClass('hide')
      success: -> window.location.reload()
    })
