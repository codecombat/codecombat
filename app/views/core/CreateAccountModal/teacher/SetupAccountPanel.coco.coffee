SetupAccountPanel = Vue.extend
  name: 'setup-account-panel'
  template: require('templates/core/create-account-modal/setup-account-panel')()
  data: -> {
    supportEmail: "<a href='mailto:support@codecombat.com'>support@codecombat.com</a>"
    saving: true
    error: ''
  }
  computed:
    inEU: ->
      return me.inEU()
  mounted: ->
    @$store.dispatch('modal/createAccount')
    .catch (e) =>
      if e.i18n
        @error = @$t(e.i18n)
      else
        @error = e.message
      if not @error
        @error = @$t('loading_error.unknown')
    .then =>
      @saving = false
  methods:
    clickFinish: ->
      # Save annoucements subscribe info
      me.fetch(cache: false)
      .then =>
        emails = _.assign({}, me.get('emails'))
        emails.generalNews ?= {}
        emails.generalNews.enabled = $('#subscribe-input').is(':checked')
        if @inEU
          emails.teacherNews ?= {}
          emails.teacherNews.enabled = $('#subscribe-input').is(':checked')
          me.set('unsubscribedFromMarketingEmails', !($('#subscribe-input').is(':checked')))
        me.set('emails', emails)
        jqxhr = me.save()
        if not jqxhr
          console.error(me.validationError)
          throw new Error('Could not save user')
        new Promise(jqxhr.then)
        .then =>
          # Make sure to add conditions if we change this to be used on non-teacher path
          window.tracker?.trackEvent 'CreateAccountModal Teacher SetupAccountPanel Finish Clicked', category: 'Teachers'
          application.router.navigate('teachers/classes', {trigger: true})
          document.location.reload()

    clickBack: ->
      window.tracker?.trackEvent 'CreateAccountModal Teacher SetupAccountPanel Back Clicked', category: 'Teachers'
      @$emit('back')

module.exports = SetupAccountPanel
