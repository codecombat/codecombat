ModalComponent = require 'views/core/ModalComponent'
HoC2018VictoryComponent = require('./HoC2018VictoryModal.vue').default

module.exports = class HoC2018VictoryModal extends ModalComponent
  id: 'hoc-victory-modal'
  template: require 'templates/core/modal-base-flat'
  closeButton: true
  VueComponent: HoC2018VictoryComponent

  initialize: ->
    @propsData = {
      navigateCertificate: () => 
      ,
      shareURL: ""
    }

  constructor: (options) ->
    super(options)
    if not options.shareURL
      throw new Error("HoC2018VictoryModal requires shareURL value.")
    _.merge(@propsData, options)

