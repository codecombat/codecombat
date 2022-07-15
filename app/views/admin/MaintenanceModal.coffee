ModalComponent = require 'views/core/ModalComponent'
MaintenanceComponent = require('./components/MaintenanceModal.vue').default

module.exports = class MaintenanceModal extends ModalComponent
  id: 'maintenance-modal'
  template: require('app/templates/core/modal-base-flat')
  VueComponent: MaintenanceComponent

  constructor: (options) ->
    super options
    @propsData = {
      hide: () => @hide()
    }

  destroy: ->
    @onDestroy?()
    super()
