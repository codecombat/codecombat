require('app/styles/modal/mine-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'app/templates/core/mine-modal'
storage = require 'core/storage'

# define expectations for good rates before releasing

module.exports = class MineModal extends ModalView
  id: 'mine-modal'
  template: template
  hasAnimated: false
  events:
    'click #close-modal': 'hide'
    'click #submit-button': 'onSubmitButtonClick'  

  onSubmitButtonClick: (e) ->
    storage.save('roblox-clicked', true)
    window.tracker?.trackEvent "Roblox Explored", engageAction: "submit_button_click"
    @hide()

  hide: ->
    storage.save('roblox-clicked', true)
    super()    

  destroy: ->
    $("#modal-wrapper").off('mousemove')
    super()
