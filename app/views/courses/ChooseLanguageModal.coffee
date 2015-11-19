ModalView = require 'views/core/ModalView'
template = require 'templates/courses/choose-language-modal'

module.exports = class ChooseLanguageModal extends ModalView
  id: 'choose-language-modal'
  template: template
  
  events:
    'click .lang-choice-btn': 'onClickLanguageChoiceButton'
    
  initialize: (options) ->
    @logoutFirst = options.logoutFirst

  onClickLanguageChoiceButton: (e) ->
    @chosenLanguage = $(e.target).data('language')
    console.log 'click language choice button'
    if @logoutFirst
      @logoutUser()
    else
      @saveLanguageSetting()
      
  logoutUser: ->
    console.log 'logout'
    $.ajax({
      method: 'POST'
      url: '/auth/logout'
      context: @
      success: @onUserLoggedOut
    })

  onUserLoggedOut: ->
    console.log 'login new user'
    me.clear()
    me.fetch({
      url: '/auth/whoami'
    })
    @listenToOnce me, 'sync', @saveLanguageSetting

  saveLanguageSetting: ->
    aceConfig = _.clone(me.get('aceConfig') or {})
    aceConfig.language = @chosenLanguage
    me.set('aceConfig', aceConfig)
    res = me.patch()
    if res
      @$('#choice-area').hide()
      @$('#saving-progress').removeClass('hide')
      @listenToOnce me, 'sync', @onLanguageSettingSaved
    else
      @onLanguageSettingSaved()
        
  onLanguageSettingSaved: ->
    @trigger('set-language')
    @hide()
