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

  afterRender: ->
    super()
    @setCSSVariables()
    window.addEventListener 'resize', @setCSSVariables

  onSubmitButtonClick: (e) ->
    storage.save('roblox-clicked', true)
    window.tracker?.trackEvent "Roblox Explored", engageAction: "submit_button_click"
    @hide()

  setCSSVariables: () ->
    viewportWidth = window.innerWidth || document.documentElement.clientWidth;
    document.documentElement.style.setProperty('--vw', "#{viewportWidth}");

  hide: ->
    storage.save('roblox-clicked', true)
    super()    

  destroy: ->
    $("#modal-wrapper").off('mousemove')
    window.removeEventListener('resize', @setCSSVariables)
    super()
