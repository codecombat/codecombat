ModalView = require 'views/core/ModalView'
template = require 'templates/play/level/modal/picoctf-victory-modal'

module.exports = class PicoCTFVictoryModal extends ModalView
  id: 'picoctf-victory-modal'
  template: template
  closesOnClickOutside: false

  initialize: (options) ->
    @session = options.session
    @level = options.level

    form = {flag: options.world.picoCTFFlag, pid: @level.picoCTFProblem.pid}
    @supermodel.addRequestResource(url: '/picoctf/submit', method: 'POST', data: form, success: (response) =>
      console.log 'submitted', form, 'and got response', response
    ).load()

    @playSound 'victory'

  onLoaded: ->
    super()
