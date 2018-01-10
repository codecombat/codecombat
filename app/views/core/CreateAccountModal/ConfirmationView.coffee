require('app/styles/modal/create-account-modal/confirmation-view.sass')
CocoView = require 'views/core/CocoView'
State = require 'models/State'
template = require 'templates/core/create-account-modal/confirmation-view'
forms = require 'core/forms'
NcesSearchInput = require './teacher/NcesSearchInput'

module.exports = class ConfirmationView extends CocoView
  id: 'confirmation-view'
  template: template
  
  events:
    'click #start-btn': 'onClickStartButton'

  initialize: ({ @signupState } = {}) ->
    @saveUserPromise = Promise.resolve()

  onClickStartButton: ->
    @saveUserPromise.then =>
      classroom = @signupState.get('classroom')
      if @signupState.get('path') is 'student'
        # force clearing of _cc GET param from url if on /students
        application.router.navigate('/', {replace: true})
        application.router.navigate('/students')
      else
        application.router.navigate('/play')
      document.location.reload()

  afterRender: ->
    target = @$el.find('#nces-search-input')
    return unless target[0]
    if @ncesSearchInput
      target.replaceWith(@ncesSearchInput.$el)
    else
      @ncesSearchInput = new NcesSearchInput({
        el: target[0]
        propsData: {
          label: $.i18n.t("teachers_quote.school_name")
          displayKey: 'name'
          name: 'School Name'
          initialValue: ''
        }
      })
      @ncesSearchInput.$on 'navSearchChoose', (displayKey, fullNcesEntry) =>
        # Ignore updateValue event (what they typed), only use selected search result values
        me.set({
          school: fullNcesEntry
        })
        @ncesSearchInput.$data.value = fullNcesEntry[displayKey]
        @saveUserPromise = new Promise(me.save().then)
