ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/code-play-create-account-modal'

module.exports = class CodePlayCreateAccountModal extends ModalView
  id: 'code-play-create-account-modal'
  template: template
  plain: true

  events:
    'click .close': 'hide'
    'click .code-play-sign-up-button': 'onClickCodePlaySignupButton'

  initialize: (options={}) ->
    lang = me.get('preferredLanguage')
    @codePlayGeo = switch
      when me.isFromUk() then 'uk'
      when me.setToGerman() then 'de'
      when me.setToSpanish() then 'es'
      else 'en'
    # TODO: figure out India

  onClickCodePlaySignupButton: (e) ->
    document.location.href = '//lenovogamestate.com/register/?cocoId='+me.id
