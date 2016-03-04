ModalView = require 'views/core/ModalView'
template = require 'templates/play/level/modal/picoctf-victory-modal'

module.exports = class PicoCTFVictoryModal extends ModalView
  id: 'picoctf-victory-modal'
  template: template
  closesOnClickOutside: false

  initialize: (options) ->
    @session = options.session
    @level = options.level

    console.log 'damn we got dat flag', options.world.picoCTFFlag
    @supermodel.addRequestResource(url: '/picoctf/submit', method: 'POST', data: {flag: options.world.picoCTFFlag}, success: (response) =>
      console.log 'submitted the flag and got response', response
    ).load()

    @playSound 'victory'

  onLoaded: ->
    super()
