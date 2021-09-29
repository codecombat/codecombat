require('app/styles/play/ladder/share-ladder-link-modal.sass')
ModalView = require 'views/core/ModalView'

module.exports = class ShareLadderLinkModal extends ModalView
  id: 'share-ladder-link-modal'
  template: require 'templates/play/ladder/share-ladder-link-modal'
  plain: false

  events:
    'click #copy-url-btn': 'onClickCopyURLButton'

  initialize: ({@shareURL, @eventProperties}) ->

  onClickCopyURLButton: ->
    @$('#copy-url-input').val(@shareURL).select()
    @tryCopy()
    window.tracker?.trackEvent('Share Ladder Link Modal - Copy URL', @eventProperties, ['Google Analytics'])
