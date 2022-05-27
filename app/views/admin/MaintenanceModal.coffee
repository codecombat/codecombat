ModalComponent = require 'views/core/ModalComponent'
MaintenanceComponent = require('./components/MaintenanceModal.vue').default

module.exports = class MainteanceModal extends ModalComponent
  id: 'maintenance-modal'
  template: require('app/templates/core/modal-base-flat')
  VueComponent: MaintenanceComponent
  propsData: null

  constructor: (options) ->
    super options

  destroy: ->
    @onDestroy?()
    super()
