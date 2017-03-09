SetupAccountPanel = Vue.extend
  name: 'setup-account-panel'
  template: require('templates/core/create-account-modal/setup-account-panel')()
  data: -> {
    supportEmail: "<a href='mailto:support@codecombat.com'>support@codecombat.com</a>"
    saving: true
    error: ''
  }
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
      application.router.navigate('teachers/classes', {trigger: true})
      document.location.reload()
    clickBack: -> @$emit('back')

module.exports = SetupAccountPanel
