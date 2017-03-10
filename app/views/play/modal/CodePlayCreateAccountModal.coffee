ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/code-play-create-account-modal'

module.exports = class CodePlayCreateAccountModal extends ModalView
  id: 'code-play-create-account-modal'
  template: template
  plain: true

  events:
    'click .close': 'hide'
    'click .code-play-sign-up-button': 'onClickCodePlaySignupButton'

  onClickCodePlaySignupButton: (e) ->
    document.location.href = '//lenovogamestate.com/register/?cocoId='+me.id
