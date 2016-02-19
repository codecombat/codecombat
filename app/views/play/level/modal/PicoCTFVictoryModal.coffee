ModalView = require 'views/core/ModalView'
template = require 'templates/play/level/modal/picoctf-victory-modal'

module.exports = class PicoCTFVictoryModal extends ModalView
  id: 'picoctf-victory-modal'
  template: template
  closesOnClickOutside: false

  initialize: (options) ->
    @session = options.session
    @level = options.level

    # TODO: submit to picoCTF server

    @playSound 'victory'

  onLoaded: ->
    super()
