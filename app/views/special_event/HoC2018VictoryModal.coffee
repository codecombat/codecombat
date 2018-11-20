ModalComponent = require 'views/core/ModalComponent'
HoC2018VictoryComponent = require('./HoC2018VictoryModal.vue').default

module.exports = class HoC2018VictoryModal extends ModalComponent
  id: 'hoc-victory-modal'
  template: require 'templates/core/modal-base-flat'
  closeButton: true
  VueComponent: HoC2018VictoryComponent

  initialize: ->
    @propsData = {}

  constructor: (options) ->
    super(options)
